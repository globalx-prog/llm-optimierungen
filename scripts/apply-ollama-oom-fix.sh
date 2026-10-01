#!/bin/bash
# apply-ollama-oom-fix.sh — Systemsturz-Prävention für Ollama & AMD Radeon W7800 (48GB VRAM)
set -euo pipefail

echo "=========================================================="
echo " Starte Ollama OOM & System-Crash-Schutz Einrichtung..."
echo "=========================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# 1. 32 GB Swap in /home anlegen (falls noch nicht vorhanden)
if [ ! -f /home/swapfile ]; then
    echo "[1/4] Erstelle 32 GB Swap-Datei in /home/swapfile..."
    fallocate -l 32G /home/swapfile
    chmod 600 /home/swapfile
    mkswap /home/swapfile
    swapon /home/swapfile
    if ! grep -q "/home/swapfile" /etc/fstab; then
        echo "/home/swapfile none swap defaults 0 0" >> /etc/fstab
    fi
    echo "✔ Swap-Datei erfolgreich eingerichtet."
else
    echo "[1/4] /home/swapfile existiert bereits."
    swapon /home/swapfile 2>/dev/null || true
fi

# 2. Sysctl Kernel-Limits anpassen
echo "[2/4] Optimiere Kernel-Parameter (vm.swappiness=10, max_map_count=1048576)..."
cp "$REPO_DIR/configs/99-ollama-memory.conf" /etc/sysctl.d/99-ollama-memory.conf
sysctl --system >/dev/null 2>&1 || sysctl -p /etc/sysctl.d/99-ollama-memory.conf

# 3. Systemd-Unit für Ollama aktualisieren
echo "[3/4] Konfiguriere /etc/systemd/system/ollama.service (FlashAttention, 1GB Overhead, OOM-Protection)..."
cp "$REPO_DIR/configs/ollama.service" /etc/systemd/system/ollama.service

# 4. Systemd neu laden & Ollama neu starten
echo "[4/4] Lade systemd Konfiguration neu & starte Ollama neu..."
systemctl daemon-reload
systemctl restart ollama

echo "=========================================================="
echo " SUCCESS: Schutzplan erfolgreich eingerichtet!"
echo " System & Ollama sind nun vor OOM-Abstürzen geschützt."
echo "=========================================================="
