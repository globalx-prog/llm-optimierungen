#!/bin/bash
# ==============================================================================
# setup-llama-swap.sh — Setup & Starter für llama-swap / llama-proxy
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$REPO_DIR/configs/llama-swap/config.yaml"
COMPOSE_FILE="$REPO_DIR/docker-compose.llama-swap.yml"
MODELS_DIR="${MODELS_PATH:-/home/models}"

echo "=========================================================="
echo " 🦙 llama-swap / llama-proxy Vorbereitung & Setup"
echo "=========================================================="

# 1. Hardware & GPU-Prüfung (AMD Radeon Pro W7800)
echo "[1/5] Prüfe AMD GPU Render-Nodes..."
if [ -e "/dev/dri" ] && [ -e "/dev/kfd" ]; then
    echo "✔ /dev/dri und /dev/kfd gefunden (AMD ROCm/Vulkan betriebsbereit)."
elif [ -e "/dev/dri" ]; then
    echo "✔ /dev/dri gefunden (Vulkan betriebsbereit)."
else
    echo "⚠ Warnung: Weder /dev/dri noch /dev/kfd gefunden. GPU-Beschleunigung eventuell eingeschränkt."
fi

# 2. Verzeichnisse sicherstellen
echo "[2/5] Prüfe Modell-Verzeichnis ($MODELS_DIR)..."
if [ ! -d "$MODELS_DIR" ]; then
    echo "ℹ Modell-Verzeichnis existiert noch nicht. Erstelle $MODELS_DIR..."
    sudo mkdir -p "$MODELS_DIR"
    sudo chown -R "$(id -u):$(id -g)" "$MODELS_DIR" 2>/dev/null || true
fi
echo "✔ Modell-Verzeichnis: $MODELS_DIR"

# 3. Docker-Netzwerk 'ai-network' sicherstellen
echo "[3/5] Prüfe Docker-Netzwerk 'ai-network'..."
if command -v docker >/dev/null 2>&1; then
    if ! docker network ls --format '{{.Name}}' | grep -qw "ai-network"; then
        echo "ℹ Erstelle Docker-Netzwerk 'ai-network'..."
        docker network create ai-network
    fi
    echo "✔ Docker-Netzwerk 'ai-network' vorhanden."
else
    echo "⚠ Docker ist nicht installiert oder nicht im PATH."
fi

# 4. Konfigurationsprüfung
echo "[4/5] Prüfe Konfigurationsdatei..."
if [ -f "$CONFIG_FILE" ]; then
    echo "✔ Konfiguration gefunden: $CONFIG_FILE"
else
    echo "❌ Fehler: $CONFIG_FILE fehlt!"
    exit 1
fi

# 5. Nutzungsübersicht & Startoptionen
echo "[5/5] Fertig vorbereitet!"
echo "=========================================================="
echo " 🚀 Nächste Schritte:"
echo ""
echo " A) Start über Docker Compose (Empfohlen mit bumuellp/llama-proxy):"
echo "    docker compose -f $COMPOSE_FILE up -d"
echo "    Logs anzeigen:"
echo "    docker compose -f $COMPOSE_FILE logs -f"
echo ""
echo " B) Integration in Open WebUI:"
echo "    1. Öffne http://localhost:3000 (Open WebUI)"
echo "    2. Admin-Panel -> Settings -> Connections -> Add Connection"
echo "    3. URL: http://llama-proxy:5002/v1"
echo "    4. API Key: beliebig (z. B. 'llama-swap')"
echo ""
echo " C) Healthcheck / Test-Request:"
echo "    curl -s http://127.0.0.1:5002/v1/models | jq ."
echo "=========================================================="
