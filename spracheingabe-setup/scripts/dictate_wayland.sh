#!/usr/bin/env bash
# ==============================================================================
# Systemweites Diktat-Skript für Ubuntu (GNOME / Wayland)
# ==============================================================================
# Funktion:
# 1. Startet bei Aufruf die Audioaufnahme (Toggle: Ein/Aus).
# 2. Beim zweiten Aufruf wird die Aufnahme beendet.
# 3. Die Audiodatei wird an die lokale Whisper-API gesendet.
# 4. Der transkribierte Text landet im Clipboard (wl-copy) und wird direkt
#    per Tastatursimulation in das aktive Fenster (z.B. Cline / VS Code) eingefügt.
#
# Voraussetzungen:
#   sudo apt install -y libnotify-bin curl jq pipewire-audio-client-libraries wl-clipboard
#   Optional für automatisches Einfügen: wtype oder ydotool
# ==============================================================================

set -euo pipefail

LOCK_FILE="/tmp/whisper_dictate.pid"
AUDIO_FILE="/tmp/whisper_dictate_recording.wav"
API_URL="http://127.0.0.1:8000/v1/audio/transcriptions"
MODEL="Systran/faster-whisper-large-v3-turbo"
LANGUAGE="de"

# Hilfsfunktion für Desktop-Benachrichtigungen
notify() {
    local title="$1"
    local msg="$2"
    local icon="${3:-dialog-information}"
    notify-send -a "Spracheingabe" -i "$icon" "$title" "$msg" 2>/dev/null || true
}

# Prüfen, ob bereits aufgenommen wird (Toggle-Modus)
if [ -f "$LOCK_FILE" ]; then
    REC_PID=$(cat "$LOCK_FILE")
    rm -f "$LOCK_FILE"
    
    if kill -0 "$REC_PID" 2>/dev/null; then
        # Aufnahme beenden
        kill -INT "$REC_PID" 2>/dev/null || true
        wait "$REC_PID" 2>/dev/null || true
    fi

    notify "Transkribiere..." "Sende Audio an lokalen Whisper..." "emblem-synchronizing"

    # Prüfen, ob Audiodatei existiert und nicht leer ist
    if [ ! -s "$AUDIO_FILE" ]; then
        notify "Fehler" "Keine Audiodaten erfasst." "dialog-error"
        exit 1
    fi

    # API-Aufruf an den lokalen Whisper-Container
    RESPONSE=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@$AUDIO_FILE;type=audio/wav" \
        -F "model=$MODEL" \
        -F "language=$LANGUAGE" \
        -F "temperature=0.0" || true)

    # Transkription aus JSON parsen
    TRANSCRIPT=$(echo "$RESPONSE" | jq -r '.text // empty' 2>/dev/null || true)

    # Whitespace trimmen
    TRANSCRIPT="$(echo "$TRANSCRIPT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    if [ -n "$TRANSCRIPT" ]; then
        # Text in Wayland-Clipboard kopieren
        if command -v wl-copy >/dev/null 2>&1; then
            wl-copy "$TRANSCRIPT"
        elif command -v xclip >/dev/null 2>&1; then
            echo -n "$TRANSCRIPT" | xclip -selection clipboard
        fi

        # Automatisches Einfügen ins aktive Fenster versuchen
        if command -v wtype >/dev/null 2>&1; then
            # Kurz warten, damit Fokus stabil bleibt
            sleep 0.1
            wtype -M ctrl -k v -m ctrl || wtype "$TRANSCRIPT"
        elif command -v ydotool >/dev/null 2>&1; then
            ydotool key 29:1 47:1 47:0 29:0 # Ctrl+V
        fi

        notify "Erkannt:" "$TRANSCRIPT" "input-keyboard"
    else
        notify "Fehler" "Transkription fehlgeschlagen oder leer: $RESPONSE" "dialog-error"
    fi

    # Aufräumen
    rm -f "$AUDIO_FILE"
    exit 0
fi

# ==============================================================================
# Aufnahme starten
# ==============================================================================
rm -f "$AUDIO_FILE"

# Mikrofon-Aufnahme im Hintergrund starten (PipeWire/PulseAudio)
if command -v pw-record >/dev/null 2>&1; then
    pw-record --rate 16000 --channels 1 "$AUDIO_FILE" &
    REC_PID=$!
elif command -v parecord >/dev/null 2>&1; then
    parecord --channels=1 --rate=16000 --file-format=wav "$AUDIO_FILE" &
    REC_PID=$!
elif command -v ffmpeg >/dev/null 2>&1; then
    ffmpeg -y -f pulse -i default -ar 16000 -ac 1 "$AUDIO_FILE" >/dev/null 2>&1 &
    REC_PID=$!
else
    notify "Fehler" "Weder pw-record, parecord noch ffmpeg gefunden." "dialog-error"
    exit 1
fi

echo "$REC_PID" > "$LOCK_FILE"
notify "🎙️ Aufnahme läuft..." "Sprechen und Hotkey erneut drücken zum Stoppen." "audio-input-microphone"
