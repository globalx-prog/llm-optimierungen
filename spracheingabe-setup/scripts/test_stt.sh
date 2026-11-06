#!/usr/bin/env bash
# ==============================================================================
# Diagnose- & Test-Skript für den Voice-Stack
# Prüft API-Erreichbarkeit, Modell-Status und nimmt 3 Sekunden Test-Audio auf.
# ==============================================================================

set -euo pipefail

API_URL="http://127.0.0.1:8000"
TEST_AUDIO="/tmp/stt_test_sample.wav"

echo "=== 1. Verbindungstest zum Whisper-Dienst ==="
if curl -s --max-time 3 "${API_URL}/health" >/dev/null; then
    echo "✅ Whisper-Container antwortet (Health OK)."
else
    echo "❌ Whisper-Container unter ${API_URL} nicht erreichbar!"
    echo "   Bitte prüfe: docker compose -f llm-optimierungen/spracheingabe-setup/docker-compose.yml ps"
    exit 1
fi

echo ""
echo "=== 2. Verfügbare Modelle abfragen ==="
MODELS=$(curl -s "${API_URL}/v1/models" | jq -r '.data[].id' 2>/dev/null || echo "unbekannt")
echo "Geladene Modelle:"
echo "$MODELS"

echo ""
echo "=== 3. Mikrofon-Aufnahme Test (3 Sekunden) ==="
echo "Bitte jetzt 3 Sekunden lang etwas sprechen (z.B. 'Hallo, dies ist ein Test der Spracheingabe')..."
sleep 0.5

if command -v pw-record >/dev/null 2>&1; then
    pw-record --rate 16000 --channels 1 "$TEST_AUDIO" &
    PID=$!
elif command -v parecord >/dev/null 2>&1; then
    parecord --channels=1 --rate=16000 --file-format=wav "$TEST_AUDIO" &
    PID=$!
elif command -v ffmpeg >/dev/null 2>&1; then
    ffmpeg -y -f pulse -i default -t 3 -ar 16000 -ac 1 "$TEST_AUDIO" >/dev/null 2>&1 &
    PID=$!
else
    echo "❌ Kein Audio-Aufnahmetool (pw-record / parecord / ffmpeg) gefunden."
    exit 1
fi

sleep 3
kill -INT "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true

echo "Aufnahme beendet. Sende an STT-API..."

RESULT=$(curl -s -X POST "${API_URL}/v1/audio/transcriptions" \
    -H "Content-Type: multipart/form-data" \
    -F "file=@$TEST_AUDIO;type=audio/wav" \
    -F "model=Systran/faster-whisper-large-v3-turbo" \
    -F "language=de")

echo ""
echo "=== 4. Transkriptionsergebnis ==="
TRANSCRIPT=$(echo "$RESULT" | jq -r '.text // empty' 2>/dev/null || echo "$RESULT")
echo "Erkannter Text: \"$TRANSCRIPT\""

rm -f "$TEST_AUDIO"
echo ""
echo "✅ Test abgeschlossen!"
