#!/usr/bin/env python3
"""
Custom Intent Recognition Service via Ollama LLM
Listens for transcribed text and extracts structured intents using an LLM
Publishes results to MQTT
"""
import os
import json
import logging
import asyncio
import paho.mqtt.client as mqtt
import httpx

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "ollama-cpu")
OLLAMA_PORT = int(os.getenv("OLLAMA_PORT", "11434"))
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "phi")
MQTT_HOST = os.getenv("MQTT_HOST", "mosquitto")
MQTT_PORT = int(os.getenv("MQTT_PORT", "1883"))
MQTT_TOPIC_TEXT = os.getenv("MQTT_TOPIC_TEXT", "voice/text")
MQTT_TOPIC_INTENT = os.getenv("MQTT_TOPIC_INTENT", "voice/intent")

# Define common German voice assistant intents
INTENTS_PROMPT = """
You are a voice assistant intent recognizer. Given user speech transcription, extract the intent and entities.

Respond ONLY with valid JSON (no other text).

Common intents:
- toggle_device: Toggle a device on/off (entities: device_name, location)
- set_brightness: Set brightness level (entities: device_name, location, brightness_level)
- set_temperature: Set temperature (entities: device_name, location, temperature_value)
- play_music: Play music (entities: artist, song_name, playlist)
- stop_music: Stop playing music
- get_weather: Get weather info (entities: location)
- get_time: Get current time
- set_reminder: Set a reminder (entities: reminder_text, time_or_duration)
- open_door: Open door/lock (entities: device_name)
- unknown: If intent cannot be determined

User speech: "{text}"

Response format:
{{
  "intent": "<intent_name>",
  "confidence": <0.0-1.0>,
  "entities": {{"<key>": "<value>"}}
}}
"""

class OllamaIntentService:
    def __init__(self):
        self.mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.V2)
        self.mqtt_client.on_connect = self.on_connect
        self.mqtt_client.on_disconnect = self.on_disconnect
        self.mqtt_client.on_message = self.on_message
        self.ollama_url = f"http://{OLLAMA_HOST}:{OLLAMA_PORT}"

    def on_connect(self, client, userdata, connect_flags, rc, properties=None):
        logger.info(f"MQTT connected with result code {rc}")
        self.mqtt_client.subscribe(MQTT_TOPIC_TEXT)
        logger.info(f"Subscribed to {MQTT_TOPIC_TEXT}")

    def on_disconnect(self, client, userdata, disconnect_flags, rc, properties=None):
        logger.warning(f"MQTT disconnected with result code {rc}")

    def on_message(self, client, userdata, msg):
        """Handle incoming text transcriptions"""
        try:
            payload = json.loads(msg.payload.decode())
            text = payload.get("text", "")
            
            if text:
                logger.info(f"Processing transcription: {text}")
                intent_result = asyncio.run(self.extract_intent(text))
                
                if intent_result:
                    logger.info(f"Extracted intent: {intent_result}")
                    self.mqtt_client.publish(
                        MQTT_TOPIC_INTENT,
                        json.dumps(intent_result),
                        qos=1
                    )
        except Exception as e:
            logger.error(f"Error processing message: {e}")

    async def extract_intent(self, text: str) -> dict:
        """Use Ollama to extract intent from text"""
        try:
            prompt = INTENTS_PROMPT.format(text=text)
            
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.post(
                    f"{self.ollama_url}/api/generate",
                    json={
                        "model": OLLAMA_MODEL,
                        "prompt": prompt,
                        "stream": False,
                        "temperature": 0.3,  # Low temperature for deterministic output
                    }
                )
                
                if response.status_code == 200:
                    result = response.json()
                    response_text = result.get("response", "").strip()
                    
                    # Try to extract JSON from response
                    try:
                        # Look for JSON in the response
                        start = response_text.find('{')
                        end = response_text.rfind('}') + 1
                        if start >= 0 and end > start:
                            json_str = response_text[start:end]
                            intent_data = json.loads(json_str)
                            return intent_data
                    except json.JSONDecodeError:
                        logger.warning(f"Could not parse JSON from Ollama response: {response_text}")
                        return {
                            "intent": "unknown",
                            "confidence": 0.0,
                            "entities": {},
                            "raw_response": response_text
                        }
                else:
                    logger.error(f"Ollama API error: {response.status_code}")
                    return None
                    
        except Exception as e:
            logger.error(f"Error calling Ollama: {e}")
            return None

    async def connect_and_run(self):
        """Connect to MQTT and start listening"""
        try:
            self.mqtt_client.connect(MQTT_HOST, MQTT_PORT, keepalive=60)
            logger.info(f"Connected to MQTT at {MQTT_HOST}:{MQTT_PORT}")
            self.mqtt_client.loop_forever()
        except Exception as e:
            logger.error(f"Failed to connect: {e}")
            await asyncio.sleep(5)
            await self.connect_and_run()

async def main():
    service = OllamaIntentService()
    await service.connect_and_run()

if __name__ == "__main__":
    asyncio.run(main())
