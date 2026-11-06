#!/usr/bin/env bash
# ==============================================================================
# GPU Status & Throttling Monitor
# ==============================================================================
# Zeigt Taktraten, Temperaturen, VRAM-Nutzung, Lüfter, LACT-Status und Drosselung.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "${SCRIPT_DIR}/gpu-fan-control.sh" ]; then
    "${SCRIPT_DIR}/gpu-fan-control.sh" status
else
    echo "======================================================================"
    echo "📊 AMD RADEON PRO W7800 48GB — HARDWARE-STATUS"
    echo "======================================================================"
    lact cli stats 2>/dev/null || true
    echo ""
    lact cli power-limit get 2>/dev/null || true
    echo "======================================================================"
fi
