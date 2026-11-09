# Roadmap & Machbare Erweiterungen (Ecosystem bumuellp & Homelab AI)

Dieses Dokument beschreibt konkrete, praxiserprobte Ausbaustufen für dein lokales LLM- und Homelab-Setup (AMD Radeon Pro W7800 48GB, Ollama, Open WebUI, SearXNG, Cloudflare Tunnel, NAS). Die Vorschläge basieren auf den Architekturen und Werkzeugen aus dem öffentlichen Ökosystem von `bumuellp`.

---

## 📊 Priorisierungs- & Aufwandsmatrix

| Stufe | Maßnahme | Aufwand | Nutzen | Fokus |
|:---:|:---|:---:|:---:|:---|
| 🥇 **1** | **mcpo (Model Context Protocol Gateway)** | Gering | Hoch | Lokale Tools & privates SearXNG für KI-Agenten |
| 🥈 **2** | **Speculative Decoding Benchmark** | Gering | Sehr hoch | 2–3x schnellere Token-Generierung auf W7800 |
| 🥉 **3** | **KV-Cache Quantisierung (q8_0 / q4_0)** | Gering | Hoch | Bis zu 75% VRAM-Ersparnis bei 32k/64k Kontext |
| 4 | **openclaw (Headless Browser Automation)** | Mittel | Mittel | Autonomes Web-Browsing für KI-Agenten |
| 5 | **Docker UFW Bypass Absicherung** | Gering | Hoch | Firewall-Integrität auf Host-Ebene |
| 6 | **CI/CD & NAS-Sync per GitHub Actions** | Mittel | Mittel | Automatisiertes Deployment via SSH/rsync |
| 7 | **CrowdSec L3/L4 & L7 Intrusion Defense** | Mittel | Hoch | Erkennung & Sperrung von Brute-Force/Scannern |
| 8 | **Eigene Agent Skills (skills.sh)** | Gering | Mittel | Wiederverwendbare Runbooks für KI-Assistenten |

---

## 1. 🔌 mcpo: Model Context Protocol Gateway

### Worum geht es?
Das [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) ist der offene Industriestandard, mit dem KI-Agenten (Claude, Cursor, Open WebUI, Antigravity) auf Werkzeuge zugreifen. Das Container-Image `ghcr.io/bumuellp/mcpo:latest` bündelt mehrere MCP-Server (Python/`uvx` und Node.js) in einem einzigen HTTP/SSE-Endpunkt (Port `9000`).

### Dein Vorteil
Dein lokales SearXNG läuft bereits auf `127.0.0.1:8081`. Mit `mcpo` kannst du Open WebUI und externen Agenten Zugriff auf deine private Websuche geben – ohne Daten an externe Such-APIs (Google/Bing) zu senden.

### Konkrete Umsetzung
Erstelle `configs/mcpo/config.json`:
```json
{
  "mcpServers": {
    "searxng": {
      "command": "uvx",
      "args": ["mcp-server-searxng", "--url", "http://searxng:8080"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    }
  }
}
```

Ergänze in deiner Docker Compose:
```yaml
services:
  mcpo:
    image: ghcr.io/bumuellp/mcpo:latest
    container_name: mcpo
    restart: unless-stopped
    ports:
      - "127.0.0.1:9000:9000"
    volumes:
      - ./configs/mcpo/config.json:/app/config.json:ro
      - /home/clemi/Projekte:/workspace:ro
    networks:
      - ai-network
    security_opt:
      - no-new-privileges:true
```

---

## 2. ⚡ Speculative Decoding & N-Gram Beschleunigung

### Worum geht es?
Beim Speculative Decoding generiert ein winziges Modell ("Draft Model", z. B. 1.5B Parameter) mehrere Token-Kandidaten im Voraus, während das große 32B/80B Modell diese Kandidaten in einem einzigen Vorwärtsdurchlauf parallel validiert. 

### Dein Vorteil
* **2–3x höhere Tokens pro Sekunde (t/s)** beim Programmieren und Schreiben.
* Bei reinem Boilerplate/Syntax (JSON, YAML, HTML) bietet `--spec-type ngram-mod` sogar **ohne zweites Modell** einen deutlichen Geschwindigkeitszuwachs durch historische Mustererkennung.

### Konkrete Umsetzung (in `configs/llama-swap/config.yaml`)
Lade das kleine Draft-Modell herunter:
```bash
# Beispiel: Qwen 2.5 Coder 1.5B als Draft für das 32B Modell
huggingface-cli download Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF qwen2.5-coder-1.5b-instruct-q4_k_m.gguf --local-dir /home/models
```
Starte das Modell über den vorbereiteten Eintrag `qwen-coder-speculative` in `llama-swap`.

---

## 3. 🧮 KV-Cache Quantisierung (q8_0 / q4_0)

### Worum geht es?
Der Kontext-Speicher (Key/Value-Tensors) wächst linear mit der Kontextlänge und belegt standardmäßig in FP16 (2 Bytes) enorme Mengen VRAM. 
Formel:
$$\text{VRAM}_{\text{KV}} \approx 2 \times N_{\text{layers}} \times N_{\text{kv\_heads}} \times D_{\text{head}} \times N_{\text{ctx}} \times \text{BytesPerPrecision}$$

### Dein Vorteil
| Präzision | KV-VRAM bei 32k Kontext | KV-VRAM bei 65k Kontext | Qualitätsverlust |
|:---|:---:|:---:|:---|
| `f16` (Standard) | ~8.5 GB | ~17.0 GB | Referenz (0%) |
| `q8_0` (`-ctk q8_0 -ctv q8_0`) | **~4.3 GB (-50%)** | **~8.5 GB (-50%)** | Nicht messbar (< 0.1% PPL) |
| `q4_0` (`-ctk q4_0 -ctv q4_0`) | **~2.2 GB (-75%)** | **~4.3 GB (-75%)** | Minimal |

Durch `-ctk q8_0 -ctv q8_0` passt dein 80B Modell (IQ4_XS) auch mit 16k Kontext voll in die 48 GB VRAM deiner AMD Radeon Pro W7800.

---

## 4. 🕷️ openclaw: Headless Browser Automation

### Worum geht es?
Das Container-Image `ghcr.io/bumuellp/openclaw:latest` enthält eine gehärtete Chromium- und Playwright-Umgebung mit gepatchten Node-Abhängigkeiten (0 CVEs) unter unprivilegiertem Benutzer (UID 1000).

### Dein Vorteil
Wenn du lokale KI-Agenten nutzt, die eigenständig Web-Recherchen, Formularprüfungen oder UI-Tests ausführen sollen, übernimmt `openclaw` das Browsing lokal und isoliert im Container.

### Konkrete Umsetzung
```yaml
services:
  openclaw:
    image: ghcr.io/bumuellp/openclaw:latest
    container_name: openclaw
    restart: unless-stopped
    ports:
      - "127.0.0.1:3001:3000"
    volumes:
      - openclaw-data:/app/data
    networks:
      - ai-network
    security_opt:
      - no-new-privileges:true
```

---

## 5. 🛡️ Docker UFW Bypass Remediation

### Worum geht es?
(Beschrieben in bumuellps `docker-ufw-runbook.md`): Docker modifiziert Linux-Kernel `iptables` direkt über die `PREROUTING`- und `DOCKER`-Chains. Ports, die mit `0.0.0.0:8080:8080` publiziert werden, umgehen UFW-Regeln (`ufw default deny incoming`) vollständig.

### Dein Vorteil & Status
* **Dein aktueller Stand:** Du nutzt bereits vorbildlich `127.0.0.1:PORT:PORT` Bindings in Open WebUI, SearXNG und llama-swap.
* **Erweiterung:** Falls Container künftig direkt über LAN erreichbar sein sollen (z.B. NAS-Dienste), empfiehlt sich die Installation von [ufw-docker](https://github.com/chaifeng/ufw-docker) oder die explizite Konfiguration der DOCKER-USER Chain:
```bash
sudo ufw-docker install
sudo ufw route allow proto tcp from 192.168.0.0/24 to any port 8080
```

---

## 6. 🚀 CI/CD & NAS-Sync mit GitHub Actions

### Worum geht es?
In `bumuellp/lights-camera-bum-action` stehen vorgefertigte GitHub Actions bereit:
* `sync-rsync-path`: Synchronisiert Verzeichnisse per SSH/rsync auf Remote-Server.
* `run-authorized-ssh-script`: Führt Deployment-Skripte remote aus.
* `bump-version`: Automatische SemVer-Versionierung nach Conventional Commits.

### Dein Vorteil
Du hast ein Verzeichnis `/home/clemi/Projekte/NAS` mit DietPi- und Docker-Konfigurationen. Änderungen im Git-Repository können bei jedem Push automatisch auf dein NAS synchronisiert und die Container neu gestartet werden:

```yaml
# .github/workflows/deploy-nas.yml
name: Deploy to NAS
on:
  push:
    paths: ['NAS/**']
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Rsync Configs to NAS
        uses: bumuellp/lights-camera-bum-action/sync-rsync-path@v1
        with:
          ssh-user: dietpi
          ssh-host: ${{ secrets.NAS_HOST }}
          ssh-key-path: ${{ runner.temp }}/id_ed25519
          local-path: ./NAS/
          remote-directory: /mnt/dietpi_userdata/docker-compose/
```

---

## 7. 🏰 CrowdSec Multi-Tier Defense (L3/4 & L7)

### Worum geht es?
CrowdSec ist ein Open-Source IDS/IPS (Intrusion Detection/Prevention System), das Logdateien in Echtzeit analysiert und verdächtige IPs automatisch über Kernel-Firewalls (nftables) und Reverse-Proxy WAF-Plugins sperrt.

### Dein Vorteil
Wenn du deinen Open WebUI oder NAS-Dienste über den Cloudflare-Tunnel oder Subdomains erreichbar machst, erkennt CrowdSec Scans, Brute-Force-Logins und CVE-Exploits sofort und sperrt die IP-Adressen global ab.

---

## 8. 📝 Eigene Agent Skills verfassen (skills.sh Standard)

### Worum geht es?
Nach dem offenen [skills.sh](https://skills.sh) Standard können operative Workflows in `SKILL.md`-Dateien abgelegt werden. KI-Agenten lesen nur das Inhaltsverzeichnis (Progressive Disclosure) und laden den vollständigen Text erst bei Bedarf.

### Dein Vorteil
Dokumentiere deine Hardware-Tricks (z. B. ROCm Overrides, Swapfile-Anpassung, Recovery nach GPU-Crash) als Agent-Skill in `skills/w7800-tuning/SKILL.md`. Jeder KI-Coding-Assistent weiß dann sofort, welche Flags und Befehle auf deinem System gültig sind.
