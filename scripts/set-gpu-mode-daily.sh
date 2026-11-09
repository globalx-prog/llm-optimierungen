#!/usr/bin/env bash
# ==============================================================================
# GPU-Modus: Normaler Tagesbetrieb (Silent & Cool)
# ==============================================================================
# Für täglichen Chat, Coding und normale Workloads.
# Hält die Karte flüsterleise und begrenzt die Leistungsaufnahme auf 200W.
# Setzt den Lüfter wahlweise auf Automatik (vBIOS) oder sanftes Balanced (50%).
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_WATT=200
FAN_PRESET="${1:-auto}"  # auto, balanced, silent

echo "======================================================================"
echo "🌿 AKTIVIERE GPU-MODUS: TAGESBETRIEB (SILENT / ECO)"
echo "======================================================================"

echo "* Schritt 1: Setze Power-Limit via LACT auf ${TARGET_WATT}W..."
lact cli power-limit set "${TARGET_WATT}"

echo ""
echo "* Schritt 2: Konfiguriere Lüfter auf Modus '${FAN_PRESET}'..."
if [ -f "${SCRIPT_DIR}/gpu-fan-control.sh" ]; then
    "${SCRIPT_DIR}/gpu-fan-control.sh" "${FAN_PRESET}" || {
        echo "⚠️  Lüfter-Anpassung übersprungen (sudo erforderlich oder udev nicht installiert)."
        echo "   Tipp: Führe '${SCRIPT_DIR}/gpu-fan-control.sh install-udev' einmalig aus!"
    }
fi

echo ""
echo "======================================================================"
echo "✅ TAGESBETRIEB AKTIV: Maximal ${TARGET_WATT}W | Flüsterleise | Junction geschont (< 90°C)"
echo "======================================================================"
if [ -f "${SCRIPT_DIR}/gpu-fan-control.sh" ]; then
    "${SCRIPT_DIR}/gpu-fan-control.sh" status
fi
