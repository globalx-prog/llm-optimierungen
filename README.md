# LLM & System Optimierungen (AMD Radeon Pro W7800 / Ollama / llama-swap)

Zentrale Drehscheibe für Konfigurationen, Skripte und Tuning-Parameter zur Maximierung von LLM-Performance, VRAM-Effizienz, Code-Qualität und Systemstabilität auf Ubuntu Linux.

---

## 🚦 Status & Funktionsübersicht

| Komponente / Feature | Status | Beschreibung |
|:---|:---:|:---|
| **ROCm W7800 Tuning & OOM-Schutz** | ✅ Live | 48 GB VRAM Tuning, FlashAttention, 56 GB OOM-Limit, 32 GB Swapfile |
| **Maßgeschneiderte Modelfiles** | ✅ Live | Qwen3-Next-80B, Qwen3.8-35B-Distill, Qwen3.8-27B, Artemis-31B |
| **llama-swap & llama-proxy Stack** | ✅ Live | On-Demand Model Swapping, Idle-VRAM = 0 MB, Port 5002 im `ai-network` |
| **Pre-Commit Hooks (Lokal & Global)** | ✅ Live | Conventional Commits, GGUF-Großdatei-Sperre (>2 MB), Secret-Scanning |
| **Dokumentation & Handbücher** | ✅ Live | Detaillierte Hook-Anleitung & Roadmap für Homelab-Ausbau |
| **mcpo (Model Context Protocol Gateway)**| 🔲 TODO | Port 9000 für Tools & lokale SearXNG-Suche |
| **Speculative Decoding Benchmark** | 🔲 TODO | 1.5B Draft-Modell für 2–3x Token/s Speedup auf W7800 |
| **openclaw Browser Automation** | 🔲 TODO | Headless Playwright/Chromium Container für lokale Agenten |
| **NAS-Synchronisation via GitHub Actions**| 🔲 TODO | Automatischer rsync-Sync von Compose-Dateien auf das DietPi-NAS |
| **CrowdSec IDS/IPS Absicherung** | 🔲 TODO | Multi-Tier Defense für Cloudflare Tunnel & Open WebUI |

---

## 🛠️ Bereits umgesetzte Implementierungen

### 1. Dynamischer Model-Proxy: `llama-swap`
* **On-Demand Swapping**: Modelle werden nur bei eingehenden Requests geladen und nach Ablauf der `ttl` (z. B. 300s für 80B) automatisch entladen. Idle-VRAM fällt auf nahe 0 MB.
* **Speculative Decoding Vorbereitung**: Routen für Draft-Modelle (`--spec-type draft`) und N-Gram Caches (`--spec-type ngram-mod`) in `configs/llama-swap/config.yaml`.
* **KV-Cache Quantisierung (`-ctk q8_0 -ctv q8_0`)**: Halbiert den VRAM-Bedarf des Kontext-Caches – ermöglicht riesige Kontexte (16k–65k) auch bei großen Modellen.
* **Gehärteter Container**: Basiert auf `ghcr.io/bumuellp/llama-proxy:latest` (llama-swap + Vulkan llama-server), gebunden an `127.0.0.1:5002` im Docker-Netzwerk `ai-network`.

### 2. ROCm & AMD GPU (W7800 48GB VRAM) Systemtuning
* **Systemsturz-Prävention**: 32 GB NVMe-Swap (`/home/swapfile`) fängt RAM-Peaks ab; Systemd `MemoryMax=56G` und `OOMScoreAdjust=500` stoppen bei Überlastung gezielt nur den Inferenzprozess statt das Gesamtsystem einzufrieren.
* **FlashAttention (`OLLAMA_FLASH_ATTENTION=1` / `--flash-attn`)**: Senkt den KV-Cache VRAM-Bedarf um 50–70%.
* **GPU Overhead (`OLLAMA_GPU_OVERHEAD=1073741824`)**: Reserviert 1 GB für Desktop/Treiber; 47 GB VRAM stehen voll für Inferenz zur Verfügung.
* **Kernel-Optimierungen**: `vm.swappiness = 10` verhindert vorzeitiges Auslagern; `vm.max_map_count = 1048576` erhöht Buffer-Limits für GGUF-Tensoren.

### 3. Git-Hooks & Code-Qualität (cabumtain-hook Standard)
* **Conventional Commits (`commit-msg`)**: Erzwingt standardisierte Commit-Header (`feat:`, `fix:`, `docs:`, `chore:`, etc.) mit max. 72 Zeichen.
* **Großdatei- & Modell-Schutz (`pre-commit`)**: Verhindert versehentliches Committen von `*.gguf`, `*.safetensors`, `*.bin` und Dateien > 2 MB.
* **Secret-Scanner**: Blockiert Commits mit privaten Schlüsseln (`BEGIN OPENSSH PRIVATE KEY`) oder Cloudflare-Tokens (`TUNNEL_TOKEN=ey...`).
* **Linter**: Automatische Validierung von Shell-Skripten (`shellcheck`) und YAML-Dateien (`yamllint`).
* **Tag Immutability (`pre-push`)**: Schützt SemVer Release-Tags (`v*.*.*`) vor dem Überschreiben oder Löschen.
* **Systemweite Nutzung**: Mit `./scripts/setup-global-hooks.sh` für **alle** Git-Repositories auf dem Rechner aktivierbar.

---

## 📋 Offene Aufgaben & Todos (Roadmap)

Detaillierte Anleitungen und Vorlagen zu allen Punkten befinden sich in [WEITERE_SCHRITTE.md](WEITERE_SCHRITTE.md).

- [ ] **TODO 1: GGUF-Modelle in `/home/models` bereitstellen**
  - GGUF-Dateien für die in `config.yaml` definierten Routen herunterladen oder per Symlink verknüpfen (z. B. `Qwen3-Next-80B-A3B-Thinking-IQ4_XS.gguf`).
- [ ] **TODO 2: Speculative Decoding live testen**
  - Download von `qwen2.5-coder-1.5b-instruct-q4_k_m.gguf` als Draft-Modell.
  - Benchmark: Token/s Messung bei `qwen-coder-speculative` vs. Standard `qwen3.8-35b`.
- [ ] **TODO 3: mcpo Container in Docker Compose einbinden**
  - `ghcr.io/bumuellp/mcpo:latest` auf Port 9000 starten.
  - Lokales SearXNG (`http://searxng:8080`) und Filesystem-Tools als MCP für Open WebUI und lokale Agenten freigeben.
- [ ] **TODO 4: openclaw Headless Browser deployen**
  - Container mit Playwright + Chromium (`ghcr.io/bumuellp/openclaw:latest`) auf Port 3001 starten für autonome Recherche lokaler KI-Agenten.
- [ ] **TODO 5: Docker UFW Bypass absichern**
  - Überprüfung der Host-Firewall gemäß bumuellps `docker-ufw-runbook.md`, um sicherzustellen, dass Docker keine unberechtigten Ports im LAN öffnet.
- [ ] **TODO 6: CI/CD & automatisches NAS-Deployment**
  - GitHub Action Workflow einrichten, der Änderungen an `/home/clemi/Projekte/NAS` per SSH/rsync (`lights-camera-bum-action/sync-rsync-path`) automatisch auf das DietPi-NAS überträgt.
- [ ] **TODO 7: CrowdSec Intrusion Defense (L3/4 & L7)**
  - CrowdSec Security Engine und Reverse-Proxy Bouncer installieren, um Cloudflare-Tunnel und Open WebUI gegen Brute-Force und Portscans abzusichern.
- [ ] **TODO 8: Eigene Agent Skills verfassen (skills.sh)**
  - W7800-Diagnose- und Wiederherstellungs-Runbooks als `SKILL.md` paketieren.

---

## 🚀 Schnellstart & Bedienung

### A) llama-swap Stack starten (Docker / bumuellp/llama-proxy)
```bash
# 1. Vorbereitung & Berechtigungen prüfen
./scripts/setup-llama-swap.sh

# 2. Container im bestehenden ai-network starten (Port 5002)
docker compose -f docker-compose.llama-swap.yml up -d

# 3. Geladene Modelle & Status abfragen
curl -s http://127.0.0.1:5002/v1/models | jq .
```

### B) Ollama OOM-Schutz & ROCm-Tuning anwenden
```bash
sudo ./scripts/apply-ollama-oom-fix.sh
```

### C) Git-Hooks aktivieren
* **Nur für dieses Repository:**
  ```bash
  ./scripts/setup-pre-commit.sh
  ```
* **Systemweit für ALLE Repositories auf deinem Rechner:**
  ```bash
  ./scripts/setup-global-hooks.sh
  ```
  *Handbuch & Regeln: [docs/git-hooks-anleitung.md](docs/git-hooks-anleitung.md)*

---

## 📁 Repository-Struktur

```text
.
├── README.md                       # Diese Dokumentation
├── WEITERE_SCHRITTE.md             # Detaillierte Roadmap für Erweiterungen (mcpo, openclaw, CrowdSec)
├── .pre-commit-config.yaml         # Git Hooks Konfiguration (Linter, Großdatei-Schutz)
├── docker-compose.llama-swap.yml   # Docker Compose für llama-proxy (Vulkan/ROCm)
├── configs/
│   ├── llama-swap/
│   │   └── config.yaml             # Modell-Routen, TTLs, KV-Cache & GPU-Flags für llama-swap
│   ├── llama-swap.service          # Nativer Systemd Service für llama-swap (Host-Betrieb)
│   ├── ollama.service              # Systemd Service für Ollama (ROCm Tuning & OOM-Limits)
│   ├── 99-ollama-memory.conf       # Sysctl Kernel-Tuning (Swappiness & Memory Mappings)
│   └── daemon.json                 # Docker Daemon Log-Rotation Limits
├── docs/
│   └── git-hooks-anleitung.md      # Detailliertes Handbuch zu allen Hooks, Standards & Bypass
├── modelfiles/                     # Maßgeschneiderte Ollama Modelfiles (80B, 35B, 27B, 31B)
└── scripts/
    ├── setup-llama-swap.sh         # Setup & Diagnose für llama-swap
    ├── setup-pre-commit.sh         # Lokale Installation der Git Hooks
    ├── setup-global-hooks.sh       # Systemweite Aktivierung der Hooks über core.hooksPath
    └── apply-ollama-oom-fix.sh     # Automatisches Setup-Skript für OOM-Schutz & Swap
```
