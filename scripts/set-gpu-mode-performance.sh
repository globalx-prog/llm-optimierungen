#!/usr/bin/env bash
# ==============================================================================
# GPU-Modus: Maximale Hochleistung (Uncapped & Full Speed)
# ==============================================================================
# Hebt künstliche Power-Limits auf das VBIOS-Maximum (230W) an.
# Erlaubt der GPU, maximale Boost-Takte und Bandbreite ohne PPT-Throttling
# voll auszuschöpfen.
#
# WICHTIG: Koppelt 230W mit aktiver Kühlung (Standard: 65% Performance-Lüfter
# oder Hintergrund-Daemon), damit der Hotspot gar nicht erst in die Drosselzone
# (>85°C / 95°C) gerät!
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_WATT=230
FAN_PRESET="${1:-performance}"  # performance (65%), daemon (dynamische Kurve), max (85%)

echo "======================================================================"
echo "⚡ AKTIVIERE GPU-MODUS: HOCHLEISTUNG (UNCAPPED / MAX SPEED)"
echo "======================================================================"

echo "* Schritt 1: Setze Power-Limit via LACT auf Maximum (${TARGET_WATT}W)..."
lact cli power-limit set "${TARGET_WATT}"

echo ""
echo "* Schritt 2: Aktiviere Hochleistungs-Kühlung ('${FAN_PRESET}')..."
if [ -f "${SCRIPT_DIR}/gpu-fan-control.sh" ]; then
    "${SCRIPT_DIR}/gpu-fan-control.sh" "${FAN_PRESET}" || {
        echo "⚠️  Lüfter-Anpassung übersprungen (sudo erforderlich oder udev nicht installiert)."
        echo "   Tipp: Führe '${SCRIPT_DIR}/gpu-fan-control.sh install-udev' einmalig aus!"
    }
fi

echo ""
echo "======================================================================"
echo "🚀 HOCHLEISTUNG AKTIV: ${TARGET_WATT}W VBIOS-Limit | Kühlung gekoppelt"
echo "======================================================================"
if [ -f "${SCRIPT_DIR}/gpu-fan-control.sh" ]; then
    "${SCRIPT_DIR}/gpu-fan-control.sh" status
fi
