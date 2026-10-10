#!/bin/bash
# ==============================================================================
# setup-pre-commit.sh — Installation & Aktivierung der Git Pre-Commit Hooks
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================================="
echo " 🎯 Pre-Commit Hooks Setup (cabumtain-hook Integration)"
echo "=========================================================="

cd "$REPO_DIR"

# 1. Sicherstellen, dass $HOME/.local/bin im PATH ist
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# 2. Prüfen, ob pre-commit installiert ist
if ! command -v pre-commit >/dev/null 2>&1; then
    echo "[1/3] pre-commit nicht gefunden. Installiere pre-commit..."
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --user --break-system-packages pre-commit || pip3 install --user pre-commit
    elif command -v pip >/dev/null 2>&1; then
        pip install --user --break-system-packages pre-commit || pip install --user pre-commit
    else
        echo "❌ Weder pip noch pre-commit gefunden. Bitte installieren mit:"
        echo "   sudo apt install -y pre-commit"
        exit 1
    fi
fi

echo "✔ pre-commit Version: $(pre-commit --version)"

# 3. Hooks in das Git-Repository einhängen
echo "[2/3] Installiere Git-Hooks (pre-commit & commit-msg)..."
pre-commit install --hook-type commit-msg --hook-type pre-commit

# 4. Initialer Testlauf über alle Dateien (ohne Fehlerabbruch)
echo "[3/3] Führe Testlauf über bestehende Dateien aus..."
pre-commit run --all-files || true

echo "=========================================================="
echo " SUCCESS: Pre-Commit Hooks erfolgreich eingerichtet!"
echo " Ab sofort werden Commits automatisch geprüft auf:"
echo "  • Conventional Commit Header (feat:, fix:, docs:, chore:)"
echo "  • YAML & Shell Syntax"
echo "  • Schutz vor versehentlichem Upload riesiger GGUF-Modelle"
echo "=========================================================="
