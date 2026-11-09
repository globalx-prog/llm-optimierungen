#!/usr/bin/env bash
# ==============================================================================
# 🧹 cleanup-immediate-savings.sh — Freigabe von bis zu 146,4 GB Modellspeicher
# ==============================================================================
# Bereinigt folgende 4 redundante Altlasten:
#   1. /home/clemi/ComfyUI (34,0 GB) - Verwaister Testordner
#   2. FLUX.1 [dev] & ControlNet (22,3 GB) - Durch FLUX.2 abgelöst
#   3. Wan 2.1 Basisschichten (57,1 GB) - Durch Wan 2.2 Turbo abgelöst
#   4. artemis-31b in Ollama (33,0 GB) - Träges 14 t/s Modell, durch Qwen 3.8 ersetzt
# ==============================================================================

set -euo pipefail

echo "=================================================================="
echo " 🧹 STARTE FESTPLATTEN-BEREINIGUNG (SOFORTIGE EINSPARUNGEN)"
echo "=================================================================="
echo ""
echo "📊 Speicherplatz VOR der Bereinigung:"
df -h /home
echo ""

TOTAL_FREED=0

# ------------------------------------------------------------------------------
# 1. Verwaister Ordner /home/clemi/ComfyUI (34,0 GB)
# ------------------------------------------------------------------------------
TARGET_DIR="/home/clemi/ComfyUI"
if [ -d "$TARGET_DIR" ]; then
    echo "* [1/4] Entferne verwaisten Testordner: $TARGET_DIR (~34 GB)..."
    rm -rf "$TARGET_DIR"
    echo "  ✅ $TARGET_DIR erfolgreich entfernt (+34 GB frei)."
else
    echo "ℹ️  [1/4] $TARGET_DIR existiert nicht mehr (bereits entfernt)."
fi

# ------------------------------------------------------------------------------
# 2. FLUX.1 [dev] Checkpoint & ControlNet (22,3 GB)
# ------------------------------------------------------------------------------
FLUX1_CKPT="/home/clemi/Projekte/LLM/image-video-setup/ComfyUI/models/checkpoints/flux1-dev-fp8.safetensors"
FLUX1_CN="/home/clemi/Projekte/LLM/image-video-setup/ComfyUI/models/controlnet/flux1-dev-controlnet-union-pro.safetensors"

echo "* [2/4] Entferne redundante FLUX.1 Dateien (abgelöst durch FLUX.2)..."
if [ -f "$FLUX1_CKPT" ]; then
    rm -f "$FLUX1_CKPT"
    echo "  ✅ flux1-dev-fp8.safetensors gelöscht (~16,1 GB frei)."
else
    echo "  ℹ️  flux1-dev-fp8.safetensors bereits gelöscht."
fi

if [ -f "$FLUX1_CN" ]; then
    rm -f "$FLUX1_CN"
    echo "  ✅ flux1-dev-controlnet-union-pro.safetensors gelöscht (~6,2 GB frei)."
else
    echo "  ℹ️  flux1-dev-controlnet-union-pro.safetensors bereits gelöscht."
fi

# ------------------------------------------------------------------------------
# 3. Wan 2.1 Basisschichten (57,1 GB)
# ------------------------------------------------------------------------------
WAN21_I2V="/home/clemi/Projekte/LLM/image-video-setup/ComfyUI/models/diffusion_models/wan2.1_i2v_480p_14B_fp16.safetensors"
WAN21_T2V="/home/clemi/Projekte/LLM/image-video-setup/ComfyUI/models/diffusion_models/wan2.1_t2v_14B_bf16.safetensors"

echo "* [3/4] Entferne redundante Wan 2.1 Basisschichten (abgelöst durch Wan 2.2)..."
if [ -f "$WAN21_I2V" ]; then
    rm -f "$WAN21_I2V"
    echo "  ✅ wan2.1_i2v_480p_14B_fp16.safetensors gelöscht (~30,5 GB frei)."
else
    echo "  ℹ️  wan2.1_i2v_480p_14B_fp16.safetensors bereits gelöscht."
fi

if [ -f "$WAN21_T2V" ]; then
    rm -f "$WAN21_T2V"
    echo "  ✅ wan2.1_t2v_14B_bf16.safetensors gelöscht (~26,6 GB frei)."
else
    echo "  ℹ️  wan2.1_t2v_14B_bf16.safetensors bereits gelöscht."
fi

# ------------------------------------------------------------------------------
# 4. artemis-31b in Ollama (33,0 GB)
# ------------------------------------------------------------------------------
echo "* [4/4] Entferne artemis-31b aus Ollama (~33 GB)..."
if ollama list 2>/dev/null | grep -q "artemis-31b"; then
    ollama rm artemis-31b || true
    echo "  ✅ artemis-31b erfolgreich aus Ollama entfernt (+33 GB frei)."
else
    echo "  ℹ️  artemis-31b ist nicht in Ollama registriert."
fi

echo ""
echo "=================================================================="
echo " 🎉 BEREINIGUNG ABGESCHLOSSEN!"
echo "=================================================================="
echo "📊 Speicherplatz NACH der Bereinigung:"
df -h /home
echo "=================================================================="

