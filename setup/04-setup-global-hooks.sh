#!/bin/bash
# ==============================================================================
# setup-global-hooks.sh — Systemweite Git-Hooks für alle Repositories
# ==============================================================================
# Richtet globale Git-Hooks unter ~/.config/git/hooks ein und konfiguriert Git
# via `core.hooksPath`, sodass die Prüfungen auf JEDEM Repository auf dem System
# aktiv sind — ohne dass man in jedem Ordner einzeln etwas konfigurieren muss.
#
# Was global geprüft wird:
#  1. commit-msg:    Erzwingt Conventional Commits (feat, fix, docs, chore, etc.)
#  2. pre-commit:    Blockiert Dateien > 2 MB (GGUF/Modelle), scannt nach Secrets
#                    und führt lokale .pre-commit-config.yaml aus (falls vorhanden).
#  3. pre-push:      Verhindert versehentliches Überschreiben von Release-Tags.
# ==============================================================================
set -euo pipefail

GLOBAL_HOOKS_DIR="${GLOBAL_HOOKS_DIR:-$HOME/.config/git/hooks}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================================="
echo " 🌐 Systemweite Git-Hooks Einrichtung"
echo "=========================================================="

# 1. Zielverzeichnis erstellen
echo "[1/4] Erstelle Verzeichnis für globale Hooks ($GLOBAL_HOOKS_DIR)..."
mkdir -p "$GLOBAL_HOOKS_DIR"

# 2. Globalen commit-msg Hook anlegen (Conventional Commits)
echo "[2/4] Installiere globalen 'commit-msg' Hook..."
cat << 'EOF' > "$GLOBAL_HOOKS_DIR/commit-msg"
#!/usr/bin/env bash
# Globaler Conventional Commits Validator (cabumtain-hook Standard)
set -euo pipefail

commit_msg_file="${1:-}"
if [ -z "$commit_msg_file" ] || [ ! -f "$commit_msg_file" ]; then
    echo "ERROR: Commit-Nachrichtendatei nicht gefunden." >&2
    exit 1
fi

first_line=""
IFS= read -r first_line < "$commit_msg_file" || true

# Ausnahmen für automatische Commits (Merge, Revert, Squash, Fixup)
case "$first_line" in
    Merge*|"Merge branch"*|"Merge remote-tracking"*|"Revert "*|"fixup!"*|"squash!"*)
        exit 0
        ;;
esac

# 1. Maximale Zeilenlänge der ersten Zeile prüfen (max. 72 Zeichen)
length="${#first_line}"
if [ "$length" -gt 72 ]; then
    echo "❌ FEHLER: Die erste Zeile der Commit-Nachricht ist zu lang ($length Zeichen)." >&2
    echo "   Maximal erlaubt sind 72 Zeichen." >&2
    echo "   Deine Nachricht: $first_line" >&2
    exit 1
fi

# 2. Conventional Commit Format prüfen: <type>(<scope>): <beschreibung>
# Zulässige Typen: feat, fix, docs, chore, refactor, test, ci, build, perf, style, revert
conv_regex='^(feat|fix|docs|chore|refactor|test|ci|build|perf|style|revert)(\([a-zA-Z0-9_-]+\))?!?: .+$'

if [[ ! "$first_line" =~ $conv_regex ]]; then
    echo "❌ FEHLER: Commit-Nachricht entspricht nicht dem Conventional-Commit-Standard!" >&2
    echo "" >&2
    echo "   Format:   <typ>(<scope>): <kurze beschreibung>" >&2
    echo "   Beispiele:" >&2
    echo "     feat: add qwen3 model profile" >&2
    echo "     fix(compose): correct network binding" >&2
    echo "     docs: update hardware specifications" >&2
    echo "     chore: clean up obsolete cache" >&2
    echo "" >&2
    echo "   Erlaubte Typen: feat, fix, docs, chore, refactor, test, ci, build, perf, style, revert" >&2
    echo "   Deine Nachricht: \"$first_line\"" >&2
    echo "" >&2
    echo "   Tipp: Zum Umgehen in Notfällen nutze: git commit --no-verify -m \"...\"" >&2
    exit 1
fi

exit 0
EOF
chmod +x "$GLOBAL_HOOKS_DIR/commit-msg"

# 3. Globalen pre-commit Hook anlegen (Großdatei-Schutz, Secrets & Fallback)
echo "[3/4] Installiere globalen 'pre-commit' Hook..."
cat << 'EOF' > "$GLOBAL_HOOKS_DIR/pre-commit"
#!/usr/bin/env bash
# Globaler Pre-Commit Guard: Schutz vor Modell-Uploads & delegiert an pre-commit
set -euo pipefail

# A) Schutz vor versehentlichem Committen von GGUF/Modelldateien (> 2 MB)
MAX_BYTES=2097152 # 2 MB
blocked_files=()

while IFS= read -r -d '' file; do
    [ -z "$file" ] && continue
    if [ -f "$file" ]; then
        # Dateiendungen prüfen
        case "$file" in
            *.gguf|*.bin|*.pt|*.pth|*.safetensors|*.onnx)
                blocked_files+=("$file (Modell-Tensorformat)")
                continue
                ;;
        esac
        # Dateigröße prüfen
        size=$(stat -c%s "$file" 2>/dev/null || wc -c < "$file" 2>/dev/null || echo 0)
        if [ "$size" -gt "$MAX_BYTES" ]; then
            blocked_files+=("$file ($(( size / 1024 / 1024 )) MB > 2 MB)")
        fi
    fi
done < <(git diff --cached -z --name-only --diff-filter=ACMR 2>/dev/null || true)

if [ "${#blocked_files[@]}" -gt 0 ]; then
    echo "❌ FEHLER: Folgende Dateien überschreiten das Limit von 2 MB oder sind Modelldateien:" >&2
    for b in "${blocked_files[@]}"; do
        echo "   • $b" >&2
    done
    echo "   Große Gewichte (.gguf/.safetensors) gehören nicht ins Git-Repository!" >&2
    echo "   Füge sie stattdessen in .gitignore ein." >&2
    exit 1
fi

# B) Basis-Prüfung auf private SSH-Schlüssel oder Cloudflare-Tokens in gestagten Dateien
leaked_tokens=$(git diff --cached -S"BEGIN OPENSSH PRIVATE KEY" -S"BEGIN RSA PRIVATE KEY" -S"TUNNEL_TOKEN=ey" --name-only 2>/dev/null || true)
if [ -n "$leaked_tokens" ]; then
    echo "❌ SICHERHEITSWARNUNG: Möglicher privater Schlüssel oder Secret gefunden in:" >&2
    echo "$leaked_tokens" >&2
    echo "   Commit abgebrochen. Entferne das Secret vor dem Committen!" >&2
    exit 1
fi

# C) Falls im aktuellen Projekt eine .pre-commit-config.yaml existiert und pre-commit installiert ist:
if [ -f ".pre-commit-config.yaml" ] && command -v pre-commit >/dev/null 2>&1; then
    # Nur ausführen, falls nicht bereits über lokale Hooks aufgerufen
    if [ -z "${PRE_COMMIT_GLOBAL_RUNNING:-}" ]; then
        export PRE_COMMIT_GLOBAL_RUNNING=1
        pre-commit run --hook-stage pre-commit
    fi
fi

exit 0
EOF
chmod +x "$GLOBAL_HOOKS_DIR/pre-commit"

# 4. Globalen pre-push Hook anlegen (Tag Immutability)
echo "[4/4] Installiere globalen 'pre-push' Hook (Tag Protection)..."
cat << 'EOF' > "$GLOBAL_HOOKS_DIR/pre-push"
#!/usr/bin/env bash
# Globaler Tag Immutability Guard (cabumtain-hook Standard)
set -euo pipefail

remote="$1"
url="$2"

while read -r local_ref local_oid remote_ref remote_oid; do
    # Schutz für SemVer-Release-Tags (v*.*.*)
    if [[ "$remote_ref" =~ ^refs/tags/v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        # Löschung verhindern
        if [ "$local_oid" = "0000000000000000000000000000000000000000" ]; then
            echo "❌ FEHLER: Das Löschen veröffentlichter Release-Tags ($remote_ref) ist verboten!" >&2
            exit 1
        fi
        # Überschreibung verhindern
        if [ "$remote_oid" != "0000000000000000000000000000000000000000" ] && [ "$local_oid" != "$remote_oid" ]; then
            echo "❌ FEHLER: Release-Tags ($remote_ref) sind unveränderlich (Tag Immutability Guard)!" >&2
            exit 1
        fi
    fi
done

exit 0
EOF
chmod +x "$GLOBAL_HOOKS_DIR/pre-push"

# 5. Git global konfigurieren
git config --global core.hooksPath "$GLOBAL_HOOKS_DIR"

echo "=========================================================="
echo " SUCCESS: Globale Git-Hooks sind nun aktiv!"
echo " Konfiguration: git config --global core.hooksPath $GLOBAL_HOOKS_DIR"
echo ""
echo " Ab sofort gilt für ALLE Repositories auf deinem System:"
echo "  ✔ Conventional Commits (feat, fix, docs, chore, etc. max 72 Zeichen)"
echo "  ✔ Automatischer Schutz vor versehentlichem GGUF-/Tensor-Upload (> 2 MB)"
echo "  ✔ Secret-Scanning nach privaten Schlüsseln & Tokens"
echo "  ✔ Schutz vor Überschreiben von Release-Tags"
echo "=========================================================="
