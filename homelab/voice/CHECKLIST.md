# Voice Assistant Stack - Implementation Checklist

## ✅ Completed Implementation

### Core Services
- [x] **Mosquitto MQTT Broker**
  - Ports: 1883 (MQTT), 9001 (WebSockets)
  - Config: `/mosquitto/config/mosquitto.conf`
  - Data volumes: mosquitto_data, mosquitto_logs

- [x] **Wyoming OpenWakeword** (Hotword Detection)
  - Port: 10400
  - Models: `default_en`, `default_de`
  - Container: voice-openwakeword

- [x] **Wyoming Faster-Whisper** (Speech-to-Text)
  - Port: 10500
  - Model: `tiny` (German primary, English fallback)
  - Container: voice-whisper
  - Volume: whisper_models (auto-downloads on first run)

- [x] **Wyoming Satellite** (Pipeline Orchestrator)
  - Port: 10700
  - Coordinates: Hotword → STT → MQTT publish
  - Container: voice-satellite-server

- [x] **Ollama Intent Extractor** (LLM-based Intent Recognition)
  - Custom Python service
  - Subscribes to: `voice/text` MQTT topic
  - Publishes to: `voice/intent` MQTT topic
  - Connects to: `assi-ollama-cpu` (Ollama from assi stack)
  - Model: `phi` (lightweight, 2.6GB)

### Configuration Files
- [x] **docker-compose.yml** - Service orchestration
- [x] **mosquitto/config/mosquitto.conf** - MQTT settings
- [x] **ollama-intent-service.py** - Intent extraction logic
- [x] **requirements.txt** - Python dependencies

### Documentation
- [x] **README.md** - Technical architecture & detailed guide
- [x] **DEPLOYMENT.md** - Step-by-step deployment instructions
- [x] **IMPLEMENTATION_SUMMARY.md** - Executive summary & quick reference

### Network Integration
- [x] Configured to use existing `demo` network from assi stack
- [x] Reuses `assi-ollama-cpu` service from assi stack
- [x] External network dependency declared

### Language Support
- [x] German as primary language
- [x] English as fallback
- [x] German-optimized intents in prompt (18 common intents)
- [x] German greetings and responses in hints

## 📋 Pre-Deployment Checklist

### Mini PC Setup
- [ ] Docker installed and running
- [ ] Docker Compose v2.0+ installed
- [ ] Sufficient disk space (~5GB for models)
- [ ] Network connectivity to assi stack

### assi Stack Prerequisites
- [ ] assi stack is running (`docker-compose up -d` in assi folder)
- [ ] `demo` network exists
- [ ] `ollama-cpu` container is running
- [ ] At least one Ollama model downloaded (for Llama3.2)

### Model Downloads
- [ ] `phi` model downloaded on assi-ollama-cpu (`docker exec assi-ollama-cpu ollama pull phi`)
- [ ] Whisper `tiny` model will auto-download on first wyoming-whisper start
- [ ] Estimated time: 15-30 minutes (depends on internet speed)

### Raspberry Pi Setup
- [ ] RPi 3B available with audio input
- [ ] Docker or Wyoming binary installed on RPi
- [ ] Network connectivity to mini PC
- [ ] IP address of mini PC known

## 🚀 Deployment Steps

### Step 1: Prepare Directories
```bash
cd homelab/voice
mkdir -p mosquitto/config mosquitto/data mosquitto/log
```
Status: ✅ Already done

### Step 2: Verify assi Stack
```bash
cd ../assi
docker-compose up -d ollama-cpu ollama-pull-llama-cpu
# Wait for Llama3.2 to download
```
Status: ⏳ Do this before starting voice stack

### Step 3: Download phi Model
```bash
docker exec assi-ollama-cpu ollama pull phi
```
Status: ⏳ Prerequisite for intent extraction

### Step 4: Start Voice Stack
```bash
cd ../voice
docker-compose up -d
```
Status: ⏳ Ready to execute

### Step 5: Verify Services
```bash
docker-compose ps
# All services should be in "running" state
```
Status: ⏳ Post-deployment verification

### Step 6: Test MQTT & Pipeline
```bash
# Terminal 1: Monitor text transcriptions
docker exec voice-mosquitto mosquitto_sub -t "voice/text" -v

# Terminal 2: Monitor intent extraction
docker exec voice-mosquitto mosquitto_sub -t "voice/intent" -v

# Terminal 3: Check service logs
docker-compose logs -f
```
Status: ⏳ Local testing

### Step 7: Connect RPi Client
```bash
# On RPi 3B, connect to satellite server at mini PC IP
docker run --network host \
  rhasspy/wyoming-satellite:latest \
  --uri tcp://192.168.X.X:10700
```
Status: ⏳ RPi integration

## 🔍 Verification Checkpoints

### After `docker-compose up -d`
- [ ] All 5 containers running: `docker-compose ps`
- [ ] Mosquitto logs show "listening on port 1883"
- [ ] Whisper is downloading models (check logs)
- [ ] Intent service waiting for Ollama connection

### After Models Download
- [ ] Whisper logs: "models loaded"
- [ ] Intent service: "Connected to Ollama"
- [ ] All services show green health status

### After Testing Speech
- [ ] MQTT `voice/text` topic receives transcriptions
- [ ] Intent service processes transcriptions
- [ ] MQTT `voice/intent` topic receives parsed intents
- [ ] Ollama is responding with structured JSON

## 🎯 Integration Points for Spring Boot

### 1. MQTT Connection
```
Host: 192.168.X.X (mini PC IP)
Port: 1883
Client ID: spring-boot-voice-app
```

### 2. Subscribe to Topic
```
Topic: voice/intent
QoS: 1
Callback: Process intent JSON
```

### 3. Expected Message Format
```json
{
  "intent": "toggle_device",
  "confidence": 0.95,
  "entities": {
    "device_name": "living_room_light",
    "state": "on"
  }
}
```

### 4. Custom Intents Configuration
Edit `ollama-intent-service.py` line ~25 (`INTENTS_PROMPT`) to add:
- Domain-specific intents
- German-specific entity names
- Custom responses/actions

## 📊 Performance Expectations

| Operation | Expected Time | Hardware |
|-----------|---------------|----------|
| First boot (model downloads) | 15-30 min | Mini PC (internet speed dependent) |
| Hotword detection latency | <100ms | RPi 3B |
| STT (3-5 sec audio) | 1-3 sec | Mini PC CPU |
| Intent extraction | ~500ms | Mini PC CPU (with phi) |
| End-to-end (from speech to intent) | 2-4 sec | Combined system |

## 🚨 Troubleshooting Quick Links

- [ ] Cannot connect to MQTT? → See README.md Troubleshooting
- [ ] Ollama connection fails? → See README.md Troubleshooting
- [ ] Whisper very slow? → Check mini PC CPU load
- [ ] Intent extraction not working? → Check ollama-intent-service logs
- [ ] Models not downloading? → Verify internet connection & disk space

## ✨ Optional Enhancements

### Future Additions (Not in this implementation)
- [ ] Text-to-Speech (TTS) with wyoming-piper
- [ ] Multi-user voice identification
- [ ] Custom wake word training
- [ ] Voice command logging & analytics
- [ ] GPU acceleration for Ollama
- [ ] Docker Swarm deployment
- [ ] Kubernetes deployment
- [ ] Web UI for configuration

## 📞 Support & Documentation

- **Main README**: [README.md](README.md)
- **Deployment Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Implementation Summary**: [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)
- **Docker Compose Config**: [docker-compose.yml](docker-compose.yml)
- **Intent Service Code**: [ollama-intent-service.py](ollama-intent-service.py)

---

## Status Summary

✅ **Implementation**: COMPLETE
⏳ **Deployment**: READY TO START
🎯 **Next Action**: Execute Pre-Deployment Checklist

All files are in place and validated. The stack is ready for deployment!
