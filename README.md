# LLM & System Optimierungen (AMD Radeon Pro W7800 / Ollama / Docker)

Repository mit Konfigurationen, Skripten und Tuning-Parametern zur Maximierung der LLM-Performance, VRAM-Effizienz und Systemstabilität auf Ubuntu Linux.

---

## 🎯 Hauptmerkmale & Schutzfunktionen

### 1. Systemsturz-Prävention bei 35–45 GB+ Modellen
* **32 GB Swap in `/home`**: Erstellt `/home/swapfile` auf der NVMe-SSD, um RAM-Spitzen bei riesigen Modellen (70B/80B) abzufangen.
* **Systemd OOM-Schutz (`MemoryMax=56G`, `OOMScoreAdjust=500`)**: Stoppt bei Speicherüberlastung gezielt nur den Ollama-Prozess, statt das gesamte Betriebssystem einzufrieren (Hard Freeze).

### 2. ROCm & AMD GPU (W7800 48GB VRAM) Tuning
* **FlashAttention (`OLLAMA_FLASH_ATTENTION=1`)**: Senkt den VRAM-Verbrauch des KV-Caches um **50–70%**.
* **GPU Overhead (`OLLAMA_GPU_OVERHEAD=1073741824`)**: Reserviert 1 GB VRAM für Treiber/Display-Server. Ollama stehen somit volle **47 GB VRAM** zur Verfügung.
* **Kontext-Länge (`OLLAMA_CONTEXT_LENGTH=16384`)**: Begrenzt den Standard-Kontext, um Speicher-Explosionen zu verhindern.
* **Keep-Alive (`OLLAMA_KEEP_ALIVE=24h`)**: Hält geladene Modelle im VRAM.

### 3. Kernel & OS Optimierungen
* **Swappiness (`vm.swappiness = 10`)**: Verhindert unnötiges Auslagern bei normaler RAM-Nutzung.
* **Memory Mappings (`vm.max_map_count = 1048576`)**: Erhöht Mappings für große GGUF-Tensorbuffer.
* **Docker Log-Limits (`configs/daemon.json`)**: Begrenzt Container-Logs auf max. 10MB x 3 Dateien.

---

## 🚀 Schnellstart

### Automatische Einrichtung
```bash
sudo ./scripts/apply-ollama-oom-fix.sh
```

---

## 📁 Repository-Struktur

```text
.
├── README.md
├── scripts/
│   └── apply-ollama-oom-fix.sh     # Automatisches Setup-Skript
└── configs/
    ├── ollama.service              # Systemd Service Unit mit OOM-Schutz & ROCm Tuning
    ├── 99-ollama-memory.conf       # Sysctl Kernel-Konfiguration
    └── daemon.json                 # Docker Daemon Log-Limits
```
