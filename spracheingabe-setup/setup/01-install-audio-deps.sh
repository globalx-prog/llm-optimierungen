#!/bin/bash
# Installiert notwendige Audio- & Wayland-Hilfsmittel für das Spracheingabe-Diktat
set -euo pipefail

echo "Installiere Systempakete für Wayland Spracheingabe & Diktat..."
sudo apt update
sudo apt install -y curl jq libnotify-bin wl-clipboard wtype

echo "✓ Alle Abhängigkeiten erfolgreich installiert."
echo "▶ Teste dein Setup mit: ./scripts/test_stt.sh"
