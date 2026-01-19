# Voice Assistant Deployment Guide

## Prerequisites
1. Docker and Docker Compose installed on mini PC
2. `demo` network created by assi stack: `docker network ls | grep demo`
3. `ollama-cpu` running in assi stack

## Quick Start

### 1. Prepare the environment
```bash
cd homelab/voice
mkdir -p mosquitto/config mosquitto/data mosquitto/log
```

### 2. Ensure assi stack is running
```bash
cd ../assi
docker-compose up -d ollama-cpu ollama-pull-llama-cpu
# Wait for Llama3.2 model to download (5-10 minutes)
docker-compose logs ollama-pull-llama-cpu -f
```

### 3. Download phi model for intent extraction
```bash
# SSH into the mini PC or directly run:
docker exec assi-ollama-cpu ollama pull phi
# This downloads ~2.6GB model (may take a few minutes)
```

### 4. Start voice stack
```bash
cd ../voice
docker-compose up -d
```

### 5. Verify services are running
```bash
docker-compose ps
# Should show all services in "running" state
```

### 6. Test the pipeline
```bash
# Monitor MQTT for text transcriptions
docker exec voice-mosquitto mosquitto_sub -t "voice/text" -v

# In another terminal, monitor intent extraction
docker exec voice-mosquitto mosquitto_sub -t "voice/intent" -v
```

## Connecting Raspberry Pi 3B

### Option 1: Via Wyoming Satellite Client (Recommended)
```bash
# On RPi 3B:
docker run --network host \
  -e SATELLITE_URI=tcp://192.168.X.X:10700 \
  rhasspy/wyoming-satellite:latest
```

Replace `192.168.X.X` with your mini PC's IP address.

### Option 2: Direct audio streaming
If you prefer raw audio streaming instead of Wyoming protocol, send PCM audio to port 10500.

## Troubleshooting During Setup

### Models not downloading
```bash
# Check Ollama container:
docker exec assi-ollama-cpu ollama list

# Pull models manually:
docker exec assi-ollama-cpu ollama pull phi
docker exec assi-ollama-cpu ollama pull llama2
```

### Cannot connect to network
```bash
# Verify demo network exists:
docker network inspect demo

# If missing, recreate in assi folder:
cd ../assi && docker-compose up -d
```

### Intent extraction not working
```bash
# Check intent service logs:
docker-compose logs ollama-intent-extractor -f

# Test Ollama directly:
docker exec assi-ollama-cpu ollama run phi "What is the weather?"

# Monitor MQTT:
docker-compose logs mosquitto -f
```

## Architecture Decisions

### Why Ollama phi model?
- **Size**: 2.6GB (fits on mini PC storage)
- **Speed**: ~500ms inference on CPU
- **Performance**: Good enough for intent extraction
- **Alternative**: Use `neural-chat` (4GB) for better context understanding

### Why German first?
- Whisper tiny model has good German support
- Falls back to English if German confidence < 0.5
- Modify `docker-compose.yml` if you want English primary

### Why MQTT instead of direct HTTP?
- **Decoupled architecture**: Services don't need to know about each other
- **Pub/Sub pattern**: Easy to add multiple subscribers (logging, analytics, etc.)
- **Reliable delivery**: QoS 1 ensures messages arrive
- **Easy integration**: Spring Boot can subscribe easily

## Next Steps

1. **Configure Spring Boot to subscribe to MQTT**:
   - Host: mini PC IP
   - Port: 1883
   - Topic: `voice/intent`

2. **Add custom intents**:
   - Edit `ollama-intent-service.py` INTENTS_PROMPT
   - Add your domain-specific intents

3. **Add TTS (Text-to-Speech) response**:
   - Use `wyoming-piper` for TTS
   - Publish response back to MQTT

4. **Improve hotword detection**:
   - Train custom wake words using `openWakeWord`
   - Add multiple hotwords for different commands

