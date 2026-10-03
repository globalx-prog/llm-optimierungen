# LLM & System Optimierungen (AMD Radeon Pro W7800 / Ollama / llama-swap)

Repository mit Konfigurationen, Skripten und Tuning-Parametern zur Maximierung der LLM-Performance, VRAM-Effizienz und Systemstabilität auf Ubuntu Linux.

---

## 🎯 Hauptmerkmale & Architekturen

### 1. Dynamischer Model-Proxy: `llama-swap` (Neu)
* **On-Demand Model Swapping**: Lädt Modelle nur bei eingehenden Requests und entlädt sie automatisch nach Inaktivität (`ttl`). VRAM-Verbrauch im Leerlauf sinkt auf nahe 0 MB.
* **Speculative Decoding**: Bis zu **2–3x höhere Generierungsgeschwindigkeit** durch Draft-Modelle (`--spec-type draft`) oder N-Gram Caches (`--spec-type ngram-mod`).
* **KV-Cache Quantisierung (`-ctk q8_0 -ctv q8_0`)**: Halbiert den VRAM-Bedarf für den Kontext-Cache bei gleichbleibender Qualität.
* **OpenAI-kompatible API**: Standardisierte Endpunkte (`/v1/chat/completions`, `/v1/models`) direkt für Open WebUI, AI-Agenten (Cursor, Antigravity, Claude Code) und Scripts.

### 2. Systemsturz-Prävention bei 35–45 GB+ Modellen
* **32 GB Swap in `/home`**: Erstellt `/home/swapfile` auf der NVMe-SSD, um RAM-Spitzen bei riesigen Modellen (70B/80B) abzufangen.
* **Systemd OOM-Schutz (`MemoryMax=56G`, `OOMScoreAdjust=500`)**: Stoppt bei Speicherüberlastung gezielt nur den Inferenz-Prozess, statt das gesamte Betriebssystem einzufrieren (Hard Freeze).

### 3. ROCm & AMD GPU (W7800 48GB VRAM) Tuning
* **FlashAttention (`OLLAMA_FLASH_ATTENTION=1` / `--flash-attn`)**: Senkt den VRAM-Verbrauch des KV-Caches um **50–70%**.
* **GPU Overhead (`OLLAMA_GPU_OVERHEAD=1073741824`)**: Reserviert 1 GB VRAM für Treiber/Display-Server. Volle **47 GB VRAM** stehen für Modelle bereit.
* **Kontext-Länge**: Begrenzt Standard-Kontexte, um unkontrollierte Speicher-Explosionen zu verhindern.

### 4. Kernel & OS Optimierungen
* **Swappiness (`vm.swappiness = 10`)**: Verhindert unnötiges Auslagern bei normaler RAM-Nutzung.
* **Memory Mappings (`vm.max_map_count = 1048576`)**: Erhöht Mappings für große GGUF-Tensorbuffer.
* **Docker Log-Limits (`configs/daemon.json`)**: Begrenzt Container-Logs auf max. 10MB x 3 Dateien.

---

## 🚀 Schnellstart

### A) llama-swap Stack starten (Docker / bumuellp/llama-proxy)
```bash
# 1. Vorbereitung & Berechtigungen prüfen
./scripts/setup-llama-swap.sh

# 2. Container im bestehenden ai-network starten (Port 5002)
docker compose -f docker-compose.llama-swap.yml up -d

# 3. Prüfen
curl -s http://127.0.0.1:5002/v1/models | jq .
```

### B) Ollama OOM-Schutz einrichten
```bash
sudo ./scripts/apply-ollama-oom-fix.sh
```

### C) Pre-Commit Hooks aktivieren (cabumtain-hook)
```bash
./scripts/setup-pre-commit.sh
```

---

## 📁 Repository-Struktur

```text
.
├── README.md
├── .pre-commit-config.yaml         # Git Hooks (cabumtain-hook, Linter, Schutz vor GGUF-Upload)
├── docker-compose.llama-swap.yml   # Docker Compose für llama-proxy (Vulkan/ROCm)
├── configs/
│   ├── llama-swap/
│   │   └── config.yaml             # Modell-Routen, TTLs & GPU-Flags für llama-swap
│   ├── llama-swap.service          # Native Systemd Service Unit für llama-swap
│   ├── ollama.service              # Systemd Service Unit für Ollama (ROCm & OOM-Schutz)
│   ├── 99-ollama-memory.conf       # Sysctl Kernel-Konfiguration
│   └── daemon.json                 # Docker Daemon Log-Limits
├── modelfiles/                     # Maßgeschneiderte Ollama Modelfiles
└── scripts/
    ├── setup-llama-swap.sh         # Setup & Diagnose für llama-swap
    ├── setup-pre-commit.sh         # Installation & Aktivierung der Git Hooks
    └── apply-ollama-oom-fix.sh     # Automatisches Setup-Skript für OOM-Schutz
```
