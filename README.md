# homelab-infrastructure

1. Proxmox: ISO hochladen, VM ID 100 erstellen, 14GB RAM, virtio-scsi.

2. Installation: curl -fsSL https://get.coolabs.io | bash (installiert Coolify).

3. Konfiguration: In der Coolify Web-UI das GitHub Repo verknüpfen und den Pfad zur Compose-Datei angeben.

## Ressourcen-Management (Kritisch bei 16GB)
LLM: Da du wahrscheinlich keine dedizierte GPU im Mini-PC hast, nutzt Ollama die CPU. Ein 8B Parameter Modell benötigt ca. 5–6 GB RAM.

STT: Faster-Whisper ist extrem optimiert für CPUs. Das Modell "Small" oder "Medium" passt gut in die verbleibenden 2–4 GB RAM.

n8n: Verbraucht etwa 1–2 GB RAM.