#!/usr/bin/env bash
# ==============================================================================
# speedup-control.sh — Steuerungs- und Test-Skript für Speculative Decoding
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
CONFIG_FILE="${SCRIPT_DIR}/config.yaml"
ENV_FILE="${SCRIPT_DIR}/.env"

if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

PORT="${PORT:-5002}"
BASE_URL="http://127.0.0.1:${PORT}"

# Farbdefinitionen
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    echo -e "${BOLD}${BLUE}LLM Speedup Controller (Speculative Decoding)${NC}"
    echo -e "Nutzung: $0 {start|stop|restart|unload|status|models|logs|test|chat|rollback} [model]"
    echo ""
    echo -e "  ${BOLD}start${NC}    - Startet den llama-speedup Container (Port ${PORT})"
    echo -e "  ${BOLD}stop${NC}     - Stoppt den Service und gibt GPU-Ressourcen frei"
    echo -e "  ${BOLD}restart${NC}  - Startet den Service neu (lädt config.yaml neu ein)"
    echo -e "  ${BOLD}unload${NC}   - Entlädt aktive Modelle sofort aus dem VRAM (optional: [model])"
    echo -e "  ${BOLD}status${NC}   - Zeigt Container-Status, API-Verbindung und VRAM an"
    echo -e "  ${BOLD}models${NC}   - Listet alle registrierten Modelle und Endpunkte auf"
    echo -e "  ${BOLD}logs${NC}     - Zeigt Live-Logs an (inkl. Tokens/s und Acceptance Rate)"
    echo -e "  ${BOLD}test${NC}     - Führt einen Benchmark-Testprompt durch und misst Tokens/s"
    echo -e "  ${BOLD}chat${NC}     - Startet einen interaktiven Terminal-Chat mit dem Modell"
    echo -e "  ${BOLD}rollback${NC} - Schaltet den Speedup-Stack ab und setzt alles zurück"
    echo ""
    exit 1
}

ensure_network() {
    local CTX
    CTX=$(docker context show 2>/dev/null || echo "default")
    if [ "$CTX" = "desktop-linux" ]; then
        echo -e "\n${BOLD}${YELLOW}======================================================================${NC}"
        echo -e "${BOLD}${YELLOW}  ⚠ HINWEIS: Docker verwendet aktuell den Kontext 'desktop-linux'     ${NC}"
        echo -e "${BOLD}${YELLOW}======================================================================${NC}"
        echo -e "Docker Desktop läuft in einer virtuellen Maschine (VM). Dort existieren"
        echo -e "die AMD GPU-Geräteknoten (/dev/kfd, /dev/dri) deiner Radeon Pro W7800 nicht."
        echo -e "\n${CYAN}Lösung: Wechsle mit einem Befehl zum nativen Linux Docker Engine:${NC}"
        echo -e "  ${BOLD}docker context use default${NC}"
        echo -e "(Falls der native Docker-Dienst noch nicht läuft: ${BOLD}sudo systemctl enable --now docker${NC})\n"
    fi

    if command -v docker >/dev/null 2>&1; then
        if ! docker network ls --format '{{.Name}}' | grep -qw "ai-network"; then
            echo -e "${CYAN}Erstelle Docker-Netzwerk 'ai-network'...${NC}"
            docker network create ai-network || true
        fi
    fi
}

cmd_start() {
    echo -e "${BOLD}${BLUE}Starte LLM Speedup Service...${NC}"
    ensure_network

    if ! docker compose -f "$COMPOSE_FILE" up -d; then
        echo -e "${RED}[FEHLER] Container-Start fehlgeschlagen.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Warte auf API-Bereitschaft auf Port ${PORT}...${NC}"
    local TRIES=0
    local MAX_TRIES=30
    while [ $TRIES -lt $MAX_TRIES ]; do
        if curl -s "${BASE_URL}/v1/models" >/dev/null 2>&1; then
            echo -e "\n${BOLD}${GREEN}✔ LLM Speedup ist online und bereit!${NC}"
            echo -e "OpenAI-kompatible API: ${BOLD}${GREEN}${BASE_URL}/v1${NC}\n"
            cmd_models
            return 0
        fi
        sleep 1
        echo -n "."
        TRIES=$((TRIES + 1))
    done

    echo -e "\n${YELLOW}⚠ Dienst startet noch oder benötigt einen Moment zum Initialisieren.${NC}"
    echo -e "Prüfe Logs mit: ${BOLD}$0 logs${NC}"
}

cmd_stop() {
    echo -e "${BOLD}${YELLOW}Stoppe LLM Speedup Service...${NC}"
    docker compose -f "$COMPOSE_FILE" down
    echo -e "${GREEN}✔ Service gestoppt. VRAM ist vollständig freigegeben.${NC}"
}

cmd_unload() {
    local MODEL="${1:-}"
    if [ -n "$MODEL" ]; then
        echo -e "${YELLOW}Entlade Modell '${MODEL}' aus VRAM...${NC}"
        local RESP
        RESP=$(curl -s -X POST "${BASE_URL}/api/models/unload/${MODEL}" || echo "")
        echo -e "${GREEN}✔ Modell '${MODEL}' entladen: ${RESP}${NC}"
    else
        echo -e "${YELLOW}Entlade alle aktiven Modelle aus dem VRAM...${NC}"
        local RESP
        RESP=$(curl -s -X POST "${BASE_URL}/api/models/unload" || echo "")
        echo -e "${GREEN}✔ Alle Modelle entladen: ${RESP}${NC}"
    fi
}

cmd_status() {
    echo -e "${BOLD}${BLUE}=== Service Status ===${NC}"
    docker compose -f "$COMPOSE_FILE" ps || true

    echo -e "\n${BOLD}${BLUE}=== API-Erreichbarkeit ===${NC}"
    if curl -s "${BASE_URL}/v1/models" >/dev/null 2>&1; then
        echo -e "${GREEN}✔ API ist aktiv auf ${BASE_URL}/v1${NC}"
    else
        echo -e "${RED}✖ API antwortet aktuell nicht auf Port ${PORT}.${NC}"
    fi

    echo -e "\n${BOLD}${BLUE}=== GPU & VRAM-Auslastung ===${NC}"
    if command -v rocm-smi >/dev/null 2>&1; then
        rocm-smi --showmeminfo vram --showtemp || true
    elif [ -f /sys/class/drm/card0/device/mem_info_vram_used ]; then
        local USED TOTAL
        USED=$(cat /sys/class/drm/card*/device/mem_info_vram_used 2>/dev/null | head -n1 || echo 0)
        TOTAL=$(cat /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null | head -n1 || echo 0)
        if [ "$TOTAL" -gt 0 ]; then
            local USED_GB TOTAL_GB
            USED_GB=$(awk "BEGIN {printf \"%.2f\", $USED/1024/1024/1024}")
            TOTAL_GB=$(awk "BEGIN {printf \"%.2f\", $TOTAL/1024/1024/1024}")
            echo -e "VRAM: ${BOLD}${USED_GB} GB${NC} von ${TOTAL_GB} GB belegt"
        fi
    fi
}

cmd_models() {
    echo -e "${BOLD}${BLUE}Verfügbare Modelle laut API:${NC}"
    local JSON
    JSON=$(curl -s "${BASE_URL}/v1/models" 2>/dev/null || echo "")
    if [ -n "$JSON" ] && command -v jq >/dev/null 2>&1; then
        echo "$JSON" | jq -r '.data[] | "  * \(.id)"' 2>/dev/null || echo "$JSON"
    elif [ -n "$JSON" ]; then
        echo "$JSON"
    else
        echo -e "${YELLOW}Keine Modelle gefunden (Dienst läuft möglicherweise nicht).${NC}"
    fi
}

cmd_logs() {
    echo -e "${BOLD}${BLUE}Zeige Live-Logs (Strg+C zum Beenden)...${NC}"
    docker compose -f "$COMPOSE_FILE" logs -f --tail=100
}

cmd_test() {
    local MODEL="${1:-llama3.3-70b-speculative}"
    echo -e "${BOLD}${BLUE}Prüfe API-Verbindung zu ${BASE_URL}...${NC}"

    if ! curl -s "${BASE_URL}/v1/models" >/dev/null 2>&1; then
        echo -e "${RED}[FEHLER] API ist unter ${BASE_URL}/v1 nicht erreichbar.${NC}"
        echo -e "Prüfe den Container-Status mit: ${BOLD}$0 status${NC} oder ${BOLD}$0 logs${NC}"
        return 1
    fi

    # VRAM-Schutz: Entlade eventuell noch in Ollama geladene Modelle
    curl -s "http://127.0.0.1:11434/api/generate" -d '{"keep_alive": 0}' >/dev/null 2>&1 || true
    sleep 1

    echo -e "${BOLD}${BLUE}Sende Test-Prompt an '${MODEL}' über ${BASE_URL}/v1...${NC}"
    echo -e "${YELLOW}Prompt: 'Schreibe ein kurzes Python-Skript für Fibonacci-Zahlen mit Kommentaren.'${NC}\n"

    local START_TIME
    START_TIME=$(date +%s%N)

    local RAW_RESPONSE
    RAW_RESPONSE=$(curl -sS "${BASE_URL}/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer llama-swap" \
        -d "{
            \"model\": \"${MODEL}\",
            \"messages\": [{\"role\": \"user\", \"content\": \"Schreibe ein kurzes Python-Skript für Fibonacci-Zahlen mit Kommentaren.\"}],
            \"max_tokens\": 300,
            \"temperature\": 0.2
        }" 2>&1 || true)

    local END_TIME
    END_TIME=$(date +%s%N)
    local ELAPSED_MS=$(( (END_TIME - START_TIME) / 1000000 ))

    if [ -z "$RAW_RESPONSE" ]; then
        echo -e "${RED}[FEHLER] Keine Antwort erhalten (Verbindungsabbruch oder Timeout).${NC}"
        return 1
    fi

    echo -e "${BOLD}${GREEN}=== Antwort des Modells ===${NC}"
    if command -v jq >/dev/null 2>&1; then
        # Prüfe auf Fehlermeldung
        local ERR_MSG
        ERR_MSG=$(echo "$RAW_RESPONSE" | jq -r '.error.message // empty' 2>/dev/null || true)
        if [ -n "$ERR_MSG" ]; then
            echo -e "${RED}[FEHLER VOM SERVER] ${ERR_MSG}${NC}"
            echo -e "\n${YELLOW}Tipp: Existiert die Modelldatei in /home/models? Prüfe mit:${NC}"
            echo -e "  ls -lh /home/models"
            return 1
        fi

        local CONTENT
        CONTENT=$(echo "$RAW_RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null || true)
        local REASONING
        REASONING=$(echo "$RAW_RESPONSE" | jq -r '.choices[0].message.reasoning_content // empty' 2>/dev/null || true)

        if [ -n "$REASONING" ]; then
            echo -e "${YELLOW}[Reasoning / <think>]:${NC}\n$REASONING\n"
        fi
        if [ -n "$CONTENT" ]; then
            echo "$CONTENT"
        elif [ -z "$REASONING" ]; then
            echo "$RAW_RESPONSE" | jq -r '.choices[0].message // .'
        fi
        echo -e "\n${BOLD}${CYAN}=== Performance-Metriken ===${NC}"
        local TOKENS
        TOKENS=$(echo "$RAW_RESPONSE" | jq -r '.usage.completion_tokens // empty' 2>/dev/null || true)
        if [ -n "$TOKENS" ] && [ "$TOKENS" -gt 0 ]; then
            local SECONDS
            SECONDS=$(awk "BEGIN {printf \"%.2f\", $ELAPSED_MS/1000}")
            local TPS
            TPS=$(awk "BEGIN {printf \"%.1f\", $TOKENS/($ELAPSED_MS/1000)}")
            echo -e "Generierte Tokens: ${BOLD}${TOKENS}${NC}"
            echo -e "Dauer:             ${BOLD}${SECONDS} s${NC} (${ELAPSED_MS} ms)"
            echo -e "Geschwindigkeit:   ${BOLD}${GREEN}${TPS} Tokens/s${NC} 🚀"
        else
            echo -e "Laufzeit: ${ELAPSED_MS} ms"
        fi
    else
        echo "$RAW_RESPONSE"
        echo -e "Laufzeit: ${ELAPSED_MS} ms"
    fi
}

cmd_chat() {
    local MODEL="${1:-llama3.3-70b-speculative}"
    echo -e "${BOLD}${CYAN}======================================================================${NC}"
    echo -e "${BOLD}${CYAN}  Interaktiver Live-Chat mit Spekulativ-Modell '${MODEL}'${NC}"
    echo -e "${BOLD}${CYAN}======================================================================${NC}"
    echo -e "Backend: ${GREEN}${BASE_URL}/v1${NC} | Zum Beenden tippe: ${YELLOW}exit${NC} oder ${YELLOW}q${NC}\n"

    if ! curl -s "${BASE_URL}/v1/models" >/dev/null 2>&1; then
        echo -e "${RED}[FEHLER] API ist unter ${BASE_URL}/v1 nicht erreichbar. Starte Dienst mit '$0 start'.${NC}"
        return 1
    fi

    # VRAM-Schutz
    curl -s "http://127.0.0.1:11434/api/generate" -d '{"keep_alive": 0}' >/dev/null 2>&1 || true

    local HISTORY="[]"

    while true; do
        echo -e "${BOLD}${YELLOW}Du:${NC}"
        read -r -p "> " USER_INPUT || break
        [ -z "$USER_INPUT" ] && continue
        [[ "$USER_INPUT" =~ ^(exit|quit|q)$ ]] && break

        HISTORY=$(echo "$HISTORY" | jq --arg msg "$USER_INPUT" '. + [{"role": "user", "content": $msg}]')

        echo -e "\n${BOLD}${GREEN}${MODEL}:${NC}"
        local PAYLOAD
        PAYLOAD=$(jq -n --arg m "$MODEL" --argjson msgs "$HISTORY" '{model: $m, messages: $msgs, stream: true}')

        local FULL_REPLY=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^data:\ (.*) ]]; then
                local DATA="${BASH_REMATCH[1]}"
                [ "$DATA" = "[DONE]" ] && break
                local DELTA
                DELTA=$(echo "$DATA" | jq -r '.choices[0].delta.content // empty' 2>/dev/null || true)
                if [ -n "$DELTA" ]; then
                    printf "%s" "$DELTA"
                    FULL_REPLY+="$DELTA"
                fi
            fi
        done < <(curl -sN "${BASE_URL}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer llama-swap" \
            -d "$PAYLOAD" 2>/dev/null || true)

        echo -e "\n"
        HISTORY=$(echo "$HISTORY" | jq --arg msg "$FULL_REPLY" '. + [{"role": "assistant", "content": $msg}]')
    done
    echo -e "\n${GREEN}Chat beendet.${NC}\n"
}

cmd_rollback() {
    echo -e "${BOLD}${RED}======================================================================${NC}"
    echo -e "${BOLD}${RED}                       ROLLBACK & RÜCKGÄNGIG MACHEN                   ${NC}"
    echo -e "${BOLD}${RED}======================================================================${NC}"
    echo -e "Dieser Schritt stoppt den Speedup-Container und entfernt den Dienst."
    echo -e "Deine bestehenden Ollama-, Open-WebUI- und ComfyUI-Setups bleiben unberührt.\n"

    read -r -p "Möchtest du den LLM-Speedup Dienst jetzt stoppen und entfernen? (j/n): " CONFIRM || true
    if [[ ! "$CONFIRM" =~ ^[jJyY]$ ]]; then
        echo -e "${YELLOW}Rollback abgebrochen.${NC}"
        return 0
    fi

    echo -e "\n[1/3] Stoppe und entferne Docker-Container..."
    docker compose -f "$COMPOSE_FILE" down --remove-orphans || true
    echo -e "${GREEN}✔ Container gestoppt und entfernt.${NC}"

    echo -e "\n[2/3] Heruntergeladene Draft-Modelle:"
    read -r -p "Möchtest du auch die heruntergeladenen Draft-Modelle (.gguf) löschen? (j/n): " DEL_MODELS || true
    if [[ "$DEL_MODELS" =~ ^[jJyY]$ ]]; then
        local TARGET_DIR="${MODELS_PATH:-/home/models}"
        rm -f "${TARGET_DIR}/Qwen2.5-0.5B-Instruct-Q4_K_M.gguf" || true
        rm -f "${TARGET_DIR}/Llama-3.2-1B-Instruct-Q4_K_M.gguf" || true
        rm -f "${TARGET_DIR}/Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf" || true
        echo -e "${GREEN}✔ Draft-Modelle wurden gelöscht.${NC}"
    else
        echo -e "${CYAN}Draft-Modelle bleiben erhalten.${NC}"
    fi

    echo -e "\n[3/3] Open WebUI Hinweis:"
    echo -e "Falls du in Open WebUI unter 'Admin -> Connections' die Verbindung 'http://...:5002/v1' eingetragen hast,"
    echo -e "kannst du diese dort einfach mit einem Klick auf den Mülleimer entfernen."
    echo -e "\n${BOLD}${GREEN}✔ Rollback erfolgreich abgeschlossen!${NC}\n"
}

case "${1:-}" in
    start)
        cmd_start
        ;;
    stop)
        cmd_stop
        ;;
    restart)
        cmd_stop
        sleep 1
        cmd_start
        ;;
    unload)
        cmd_unload "${2:-}"
        ;;
    status)
        cmd_status
        ;;
    models)
        cmd_models
        ;;
    logs)
        cmd_logs
        ;;
    test)
        cmd_test "${2:-llama3.3-70b-speculative}"
        ;;
    chat)
        cmd_chat "${2:-llama3.3-70b-speculative}"
        ;;
    rollback)
        cmd_rollback
        ;;
    *)
        usage
        ;;
esac

