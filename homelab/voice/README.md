# Voice Assistant Stack (Wyoming Protocol)

A lightweight voice processing engine using the Wyoming protocol for a homemade voice assistant. This stack runs on the mini PC and processes audio from a Raspberry Pi.

## Architecture

```
Raspberry Pi 3B (Audio Source)
    ↓
    └─→ Audio Stream → Voice Mini PC Stack (Docker)
                       ├─ wyoming-openwakeword (hotword detection)
                       ├─ wyoming-faster-whisper (speech-to-text)
                       ├─ wyoming-satellite (orchestrator for hotword + STT)
                       ├─ ollama-intent-extractor (LLM-based intent extraction)
                       ├─ mosquitto (MQTT broker)
                       
MQTT Topic Flow:
  wyoming-satellite detects speech → publishes to voice/text
                                            ↓
                        ollama-intent-extractor (listens on voice/text)
                                            ↓
                        extracts intent via Ollama → publishes to voice/intent
                                            ↓
                        Spring Boot app subscribes to voice/intent
```

## Services

### wyoming-openwakeword
- **Purpose**: Hotword/wake word detection (e.g., "Hey Assistant")
- **Port**: 10400
- **Models**: `default_en`, `default_de` (German & English)
- **Processing**: Lightweight, can run on RPi 3B

### wyoming-faster-whisper
- **Purpose**: Speech-to-text (STT)
- **Port**: 10500
- **Model**: `tiny` (very lightweight)
- **Language**: German primary, English fallback
- **Processing**: Runs on mini PC for better performance

### ollama-intent-extractor
- **Purpose**: Listens to transcribed text via MQTT and extracts structured intents
- **Backend**: Uses lightweight `phi` Ollama model from assi stack
- **Connection**: Reaches Ollama via demo network (`assi-ollama-cpu`)
- **Processing**: Calls Ollama API to extract intent using a carefully crafted prompt
- **Output**: Publishes JSON intent data back to MQTT

### wyoming-satellite
- **Purpose**: Orchestrates hotword detection + speech-to-text pipeline
- **Port**: 10700
- **Coordinates**: Hotword detection → STT (text transcription sent to MQTT)
- **This is what RPi connects to**

### mosquitto
- **Purpose**: MQTT message broker for intent/text distribution
- **Ports**: 1883 (MQTT), 9001 (WebSockets)
- **Topics**:
  - `voice/text` - Transcribed text from speech (published by satellite)
  - `voice/intent` - Structured intent data (published by ollama-intent-extractor)

## Setup

### Prerequisites
- Docker & Docker Compose on mini PC
- `ollama-cpu` service running in assi stack
- Existing `demo` network from assi stack

### First-time Setup

1. **Create Mosquitto data directories** (if not auto-created):
   ```bash
   mkdir -p mosquitto/config
   mkdir -p mosquitto/data
   mkdir -p mosquitto/log
   ```

2. **Start the stack**:
   ```bash
   docker-compose up -d
   ```

3. **Wait for Whisper model download** (first run):
   - Check logs: `docker-compose logs wyoming-faster-whisper`
   - This may take several minutes for the `tiny` model

4. **Verify services**:
   ```bash
   docker-compose ps
   ```

## Connecting Raspberry Pi

### Option 1: Simple audio streaming (Wyoming Protocol)
The RPi runs `wyoming-satellite` client and connects to `wyoming-satellite` server on mini PC:

```bash
# On RPi 3B:
docker run -it --network host \
  rhasspy/wyoming-satellite:latest \
  --uri tcp://192.168.X.X:10700
```

### Option 2: Raw audio over network
Send raw audio frames to the Whisper service directly on port 10500.

## Testing

### Test Hotword Detection
```bash
docker exec -it voice-openwakeword \
  curl http://localhost:10400/detect?model=default_en
```

### Test Speech-to-Text
Send audio to Whisper on port 10500

### Monitor MQTT
```bash
# Subscribe to all voice topics
docker exec voice-mosquitto \
  mosquitto_sub -t "voice/#" -v
```

### Check Intent Extraction Logs
```bash
docker-compose logs ollama-intent-extractor -f
```

### Verify Ollama Connection
```bash
docker exec voice-ollama-intent \
  curl http://assi-ollama-cpu:11434/api/tags
```

## Language Support

- **German (90%)**: Primary language model in Whisper
- **English**: Fallback if German confidence is low
- Modify `docker-compose.yml` command for `wyoming-faster-whisper` to change language behavior

## Performance Notes

- **RPi 3B**: Suitable for audio capture and hotword detection
- **Mini PC**: Handles STT and intent extraction
- **Model sizes**: `tiny` Whisper (~39MB), `phi` Ollama (~2.6GB)
- **GPU acceleration**: Not used in current setup (CPU-only) for broad compatibility

## Publishing Intent to Spring Boot

Your Spring Boot application subscribes to:
- Topic: `voice/intent`
- Message format: JSON with `intent`, `entities`, and `confidence`

Example payload:
```json
{
  "intent": "turn_on_light",
  "entities": {
    "room": "living_room",
    "device": "light"
  },
  "confidence": 0.95
}
```

## Customization

### Change Whisper Model Size
Edit `docker-compose.yml`, `wyoming-faster-whisper` command:
- `tiny` (lightweight, faster, lower accuracy)
- `base` (better accuracy, slower)
- Only use on mini PC with sufficient resources

### Change Ollama Model for Intent
Edit `INTENT_RECOGNIZER` environment variables or use different Ollama models:
- `phi` (2.6GB, fast)
- `neural-chat` (4GB, better context understanding)
- Ensure model is pulled on ollama-cpu

### Add Custom Hotwords
Modify `wyoming-openwakeword` command to include custom models

## Troubleshooting

### Ollama connection fails
- Verify `ollama-cpu` is running in assi stack: `docker ps | grep ollama`
- Check network connectivity: `docker network ls | grep demo`
- Ensure model is downloaded: `docker exec assi-ollama-cpu ollama list`
- Test connection: `docker exec voice-ollama-intent ping assi-ollama-cpu`

### Whisper very slow
- `tiny` model should process ~3-5 seconds audio in 1-2 seconds
- If slower, check mini PC CPU load: `top`
- Consider limiting other services if running on same machine

### Intent extraction not working
- Check logs: `docker-compose logs ollama-intent-extractor`
- Ensure Ollama `phi` model is downloaded on assi stack
- Verify MQTT connection: `docker-compose logs mosquitto`
- Test Ollama directly: `docker exec assi-ollama-cpu ollama run phi "test"`

### Text not appearing in MQTT
- Verify wyoming-satellite is running: `docker-compose ps`
- Check satellite logs: `docker-compose logs wyoming-satellite`
- Monitor MQTT for text messages: `docker exec voice-mosquitto mosquitto_sub -t "voice/text" -v`

## Next Steps

1. Set up RPi audio capture and Wyoming satellite client
2. Create Spring Boot endpoint subscribing to `voice/intent` MQTT topic
3. Configure custom intents in the system
4. Add voice feedback (TTS) if needed

