#!/usr/bin/env bash
# ==============================================================================
# benchmark-speeds.sh — LLM Speed, Kontext- & Inferenz-Benchmark Suite
# ==============================================================================
# Unterstützt:
#  - Dynamische Erkennung aller installierten Modelle (Ollama & llama-swap)
#  - Beliebige Modell-Teilmengen (Top 3, Coder, MoE, Spekulativ, Custom Multi-Select)
#  - Beliebige Kontextgrößen (2k, 4k, 8k, 16k, 32k, 64k, 128k oder freie Zahleneingabe)
#  - Schnelldurchsatz-Test ODER Vollkontext-Stresstest (Prefill-t/s + Eval-t/s)
#  - Spekulatives Decoding Vergleich (Ollama vs. llama-swap ROCm)
#  - Automatische Markdown-Protokollierung in docs/BENCHMARK_RESULTS.md
# Hardware-Optimiert für: AMD Radeon Pro W7800 (48 GB GDDR6)
# ==============================================================================
set -euo pipefail
export LC_ALL=C

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCS_DIR="${PROJECT_DIR}/docs"
RESULTS_FILE="${DOCS_DIR}/BENCHMARK_RESULTS.md"

OLLAMA_HOST="${OLLAMA_HOST:-http://127.0.0.1:11434}"
SPEEDUP_HOST="${SPEEDUP_HOST:-http://127.0.0.1:5002}"

DEFAULT_PROMPT="Schreibe eine vollständige, effiziente Python-Funktion für QuickSort mit detaillierten Kommentaren, Type-Hints und Beispielen."
DEFAULT_MAX_TOKENS=256
DEFAULT_NUM_CTX=16384

# Prüfe Dependencies
for cmd in curl jq awk; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}[FEHLER] '${cmd}' ist nicht installiert! Bitte installieren mit: sudo apt install ${cmd}${NC}"
        exit 1
    fi
done

# ------------------------------------------------------------------------------
# Hardware & VRAM Telemetrie
# ------------------------------------------------------------------------------
get_vram_use() {
    if command -v rocm-smi >/dev/null 2>&1; then
        local MEM_INFO
        MEM_INFO=$(rocm-smi --showmeminfo vram 2>/dev/null || true)
        if [ -n "$MEM_INFO" ]; then
            local USED_GB TOTAL_GB
            USED_GB=$(echo "$MEM_INFO" | awk '/VRAM Total Used Memory/ {printf "%.1f", $NF / 1073741824}')
            TOTAL_GB=$(echo "$MEM_INFO" | awk '/VRAM Total Memory/ {printf "%.0f", $NF / 1073741824}')
            if [ -n "$USED_GB" ] && [ -n "$TOTAL_GB" ]; then
                echo "${USED_GB}G / ${TOTAL_GB}G"
                return
            fi
        fi
        # Fallback auf Prozentwert
        local PCT
        PCT=$(rocm-smi --showmemuse 2>/dev/null | awk '/GPU Memory Allocated/ {print $NF "%"}' | head -n1 || echo "")
        [ -n "$PCT" ] && echo "$PCT" && return
    fi
    echo "N/A"
}

get_gpu_mode_info() {
    if [ -f "/sys/class/drm/card0/device/hwmon/hwmon0/power1_cap" ]; then
        local CAP_UW
        CAP_UW=$(cat /sys/class/drm/card0/device/hwmon/hwmon0/power1_cap 2>/dev/null || echo "0")
        local WATT=$(( CAP_UW / 1000000 ))
        if [ "$WATT" -ge 220 ]; then
            echo "Hochleistung (${WATT}W uncapped)"
        elif [ "$WATT" -gt 0 ]; then
            echo "Normalbetrieb (${WATT}W)"
        else
            echo "Standard"
        fi
    else
        echo "Aktiv"
    fi
}

# ------------------------------------------------------------------------------
# Modell-Erkennung & Verwaltung
# ------------------------------------------------------------------------------
get_installed_ollama_models() {
    local MODELS=()
    local JSON_TAGS
    JSON_TAGS=$(curl -sS "${OLLAMA_HOST}/api/tags" 2>/dev/null || true)

    if [ -n "$JSON_TAGS" ] && echo "$JSON_TAGS" | jq -e '.models' >/dev/null 2>&1; then
        while IFS= read -r m; do
            # Filter Hilfsmodelle (Embeddings) und bekannte inkompatible Alttensoren (z.B. Mixtral 2023)
            if [[ "$m" =~ (bge-m3|nomic-embed|all-minilm|mixtral-8x7b) ]]; then
                continue
            fi
            [ -n "$m" ] && MODELS+=("$m")
        done < <(echo "$JSON_TAGS" | jq -r '.models[].name // empty')
    fi

    # Fallback auf CLI
    if [ ${#MODELS[@]} -eq 0 ] && command -v ollama >/dev/null 2>&1; then
        while IFS= read -r m; do
            if [[ ! "$m" =~ (NAME|bge-m3|nomic-embed|mixtral-8x7b) ]] && [ -n "$m" ]; then
                MODELS+=("$m")
            fi
        done < <(ollama list 2>/dev/null | awk '{print $1}')
    fi

    echo "${MODELS[@]}"
}

get_installed_speedup_models() {
    local MODELS=()
    local JSON_MODELS
    JSON_MODELS=$(curl -sS "${SPEEDUP_HOST}/v1/models" 2>/dev/null || true)

    if [ -n "$JSON_MODELS" ] && echo "$JSON_MODELS" | jq -e '.data' >/dev/null 2>&1; then
        while IFS= read -r m; do
            # Filter nur Modelle heraus, deren GGUF auch physisch vorhanden ist
            if [[ "$m" =~ (qwen2.5-coder-32b) ]]; then
                continue
            fi
            [ -n "$m" ] && MODELS+=("$m")
        done < <(echo "$JSON_MODELS" | jq -r '.data[] | select(.meta.llamaswap.type == "model") | .id')
    fi

    # Fallback-Liste der bekannten funktionierenden Modelle
    if [ ${#MODELS[@]} -eq 0 ]; then
        MODELS=("llama3.3-70b-speculative" "llama3.3-70b-abliterated-speculative" "deepseek-r1-70b-speculative" "qwen2.5-72b-speculative" "qwen2.5-72b-ngram")
    fi

    echo "${MODELS[@]}"
}

unload_all_ollama() {
    local LOADED
    LOADED=$(curl -s "${OLLAMA_HOST}/api/ps" 2>/dev/null | jq -r '.models[].name // empty' 2>/dev/null || true)
    for lm in $LOADED; do
        curl -s "${OLLAMA_HOST}/api/generate" \
            -H "Content-Type: application/json" \
            -d "{\"model\": \"$lm\", \"keep_alive\": 0}" >/dev/null 2>&1 || true
    done
    sleep 1
}

unload_ollama() {
    local MODEL="${1:-}"
    if [ -n "$MODEL" ]; then
        curl -s "${OLLAMA_HOST}/api/generate" \
            -H "Content-Type: application/json" \
            -d "{\"model\": \"$MODEL\", \"keep_alive\": 0}" >/dev/null 2>&1 || true
    fi
    unload_all_ollama
}

unload_speedup() {
    if command -v docker >/dev/null 2>&1; then
        docker exec llama-speedup pkill -f llama-server >/dev/null 2>&1 || true
    fi
    sleep 1
}

# ------------------------------------------------------------------------------
# Kontext-Generator für Stresstests
# ------------------------------------------------------------------------------
generate_stress_prompt() {
    local TARGET_CTX="$1"
    # Ziel-Token für den Prompt: ca. 50% des Kontextes (Rest für Generation & KV-Reserve)
    local PROMPT_TOKENS=$(( TARGET_CTX * 50 / 100 ))
    if [ "$PROMPT_TOKENS" -gt 32000 ]; then
        PROMPT_TOKENS=32000 # Obergrenze
    fi

    # Ein realistischer Python-Algorithmen- und Dokumentationsblock (~220 Tokens)
    local CODE_SNIPPET="
class DistributedCacheNode:
    def __init__(self, node_id: str, capacity: int, replication_factor: int = 3):
        self.node_id = node_id
        self.capacity = capacity
        self.replication_factor = replication_factor
        self.storage = {}
        self.access_log = []

    def put(self, key: str, value: bytes, ttl: int = 3600) -> bool:
        if len(self.storage) >= self.capacity:
            self._evict_lru()
        self.storage[key] = {'data': value, 'ttl': ttl}
        self.access_log.append((key, 'PUT'))
        return True

    def get(self, key: str):
        if key in self.storage:
            self.access_log.append((key, 'GET'))
            return self.storage[key]['data']
        return None

    def _evict_lru(self):
        if self.storage:
            oldest_key = next(iter(self.storage))
            del self.storage[oldest_key]
"
    local REPEAT_COUNT=$(( PROMPT_TOKENS / 220 ))
    [ "$REPEAT_COUNT" -lt 1 ] && REPEAT_COUNT=1

    local FULL_PROMPT="Hier ist ein Auszug aus einer verteilten Cache-Architektur:\n"
    for ((i=1; i<=REPEAT_COUNT; i++)); do
        FULL_PROMPT="${FULL_PROMPT}\n# Modul-Replikation Block ${i}:\n${CODE_SNIPPET}"
    done
    FULL_PROMPT="${FULL_PROMPT}\n\nAufgabe: Analysiere den vorstehenden Code. Erkläre in 3 präzisen Punkten die Schwachstellen der LRU-Eviction und schlage eine Thread-sichere Verbesserung vor."
    echo -e "$FULL_PROMPT"
}

# ------------------------------------------------------------------------------
# Core Benchmark: Ollama
# ------------------------------------------------------------------------------
benchmark_ollama() {
    local MODEL="$1"
    local PROMPT="$2"
    local MAX_TOKENS="$3"
    local NUM_CTX="$4"

    MAX_TOKENS=$(echo "$MAX_TOKENS" | tr -dc '0-9')
    [ -z "$MAX_TOKENS" ] && MAX_TOKENS=256
    NUM_CTX=$(echo "$NUM_CTX" | tr -dc '0-9')
    [ -z "$NUM_CTX" ] && NUM_CTX=16384

    local PROMPT_FILE REQ_FILE
    PROMPT_FILE=$(mktemp /tmp/llm_bench_prompt.XXXXXX)
    REQ_FILE=$(mktemp /tmp/llm_bench_req.XXXXXX)
    printf "%s" "$PROMPT" > "$PROMPT_FILE"

    jq -n \
        --arg model "$MODEL" \
        --rawfile prompt "$PROMPT_FILE" \
        --argjson num_predict "$MAX_TOKENS" \
        --argjson num_ctx "$NUM_CTX" \
        '{model: $model, prompt: $prompt, stream: false, options: {num_predict: $num_predict, num_ctx: $num_ctx, temperature: 0.2}}' > "$REQ_FILE"

    local RESP
    RESP=$(curl -sS "${OLLAMA_HOST}/api/generate" \
        -H "Content-Type: application/json" \
        --data-binary @"$REQ_FILE" 2>/dev/null || true)

    rm -f "$PROMPT_FILE" "$REQ_FILE"

    if [ -z "$RESP" ] || [ "$(echo "$RESP" | jq -r '.error // empty')" != "" ]; then
        local ERR
        ERR=$(echo "$RESP" | jq -r '.error // "Keine Antwort"')
        echo -e "    ${RED}[FEHLER] Ollama: ${ERR}${NC}" >&2
        echo "0|0.00|0|0.00|0.00|N/A"
        return
    fi

    local PROMPT_COUNT PROMPT_DUR_NS EVAL_COUNT EVAL_DUR_NS TOTAL_DUR_NS
    PROMPT_COUNT=$(echo "$RESP" | jq -r '.prompt_eval_count // 0')
    PROMPT_DUR_NS=$(echo "$RESP" | jq -r '.prompt_eval_duration // 0')
    EVAL_COUNT=$(echo "$RESP" | jq -r '.eval_count // 0')
    EVAL_DUR_NS=$(echo "$RESP" | jq -r '.eval_duration // 0')
    TOTAL_DUR_NS=$(echo "$RESP" | jq -r '.total_duration // 0')

    local PROMPT_TPS="0.00"
    if [ "$PROMPT_DUR_NS" -gt 0 ] && [ "$PROMPT_COUNT" -gt 0 ]; then
        PROMPT_TPS=$(awk "BEGIN {printf \"%.2f\", $PROMPT_COUNT / ($PROMPT_DUR_NS / 1000000000)}")
    fi

    local EVAL_TPS="0.00"
    if [ "$EVAL_DUR_NS" -gt 0 ] && [ "$EVAL_COUNT" -gt 0 ]; then
        EVAL_TPS=$(awk "BEGIN {printf \"%.2f\", $EVAL_COUNT / ($EVAL_DUR_NS / 1000000000)}")
    fi

    local TOTAL_S="0.00"
    if [ "$TOTAL_DUR_NS" -gt 0 ]; then
        TOTAL_S=$(awk "BEGIN {printf \"%.2f\", $TOTAL_DUR_NS / 1000000000}")
    fi

    local VRAM_USED
    VRAM_USED=$(get_vram_use)

    # Rückgabe: PROMPT_COUNT|PROMPT_TPS|EVAL_COUNT|EVAL_TPS|TOTAL_S|VRAM_USED
    echo "${PROMPT_COUNT}|${PROMPT_TPS}|${EVAL_COUNT}|${EVAL_TPS}|${TOTAL_S}|${VRAM_USED}"
}

# ------------------------------------------------------------------------------
# Core Benchmark: Speedup (llama-swap / Speculative Decoding)
# ------------------------------------------------------------------------------
benchmark_speedup() {
    local MODEL="$1"
    local PROMPT="$2"
    local MAX_TOKENS="$3"
    local NUM_CTX="$4"

    MAX_TOKENS=$(echo "$MAX_TOKENS" | tr -dc '0-9')
    [ -z "$MAX_TOKENS" ] && MAX_TOKENS=256

    local PROMPT_FILE REQ_FILE
    PROMPT_FILE=$(mktemp /tmp/llm_bench_prompt.XXXXXX)
    REQ_FILE=$(mktemp /tmp/llm_bench_req.XXXXXX)
    printf "%s" "$PROMPT" > "$PROMPT_FILE"

    jq -n \
        --arg model "$MODEL" \
        --rawfile prompt "$PROMPT_FILE" \
        --argjson max_tokens "$MAX_TOKENS" \
        '{model: $model, messages: [{role: "user", content: $prompt}], max_tokens: $max_tokens, temperature: 0.2}' > "$REQ_FILE"

    local START_TIME
    START_TIME=$(date +%s%N)

    local RESP
    RESP=$(curl -sS "${SPEEDUP_HOST}/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer llama-swap" \
        --data-binary @"$REQ_FILE" 2>/dev/null || true)

    rm -f "$PROMPT_FILE" "$REQ_FILE"

    local END_TIME
    END_TIME=$(date +%s%N)
    local ELAPSED_MS=$(( (END_TIME - START_TIME) / 1000000 ))

    if [ -z "$RESP" ] || [ "$(echo "$RESP" | jq -r '.error.message // empty')" != "" ]; then
        local ERR
        ERR=$(echo "$RESP" | jq -r '.error.message // "Keine Antwort"')
        echo -e "    ${RED}[FEHLER] Speedup: ${ERR}${NC}" >&2
        echo "0|0.00|0|0.00|0.00|N/A|N/A"
        return
    fi

    local EVAL_COUNT PROMPT_COUNT
    EVAL_COUNT=$(echo "$RESP" | jq -r '.usage.completion_tokens // 0')
    PROMPT_COUNT=$(echo "$RESP" | jq -r '.usage.prompt_tokens // 0')

    # Präzise timings direkt vom llama-server auslesen falls vorhanden
    local TIMINGS_PRED TIMINGS_PROMPT DRAFT_N DRAFT_ACC
    TIMINGS_PRED=$(echo "$RESP" | jq -r '.timings.predicted_per_second // empty')
    TIMINGS_PROMPT=$(echo "$RESP" | jq -r '.timings.prompt_per_second // empty')
    DRAFT_N=$(echo "$RESP" | jq -r '.timings.draft_n // 0')
    DRAFT_ACC=$(echo "$RESP" | jq -r '.timings.draft_n_accepted // 0')

    local TOTAL_S="0.00"
    local EVAL_TPS="0.00"
    local PROMPT_TPS="0.00"

    if [ -n "$TIMINGS_PRED" ] && [ "$TIMINGS_PRED" != "null" ]; then
        EVAL_TPS=$(awk "BEGIN {printf \"%.2f\", $TIMINGS_PRED}")
    elif [ "$ELAPSED_MS" -gt 0 ] && [ "$EVAL_COUNT" -gt 0 ]; then
        EVAL_TPS=$(awk "BEGIN {printf \"%.2f\", $EVAL_COUNT / ($ELAPSED_MS / 1000)}")
    fi

    if [ -n "$TIMINGS_PROMPT" ] && [ "$TIMINGS_PROMPT" != "null" ]; then
        PROMPT_TPS=$(awk "BEGIN {printf \"%.2f\", $TIMINGS_PROMPT}")
    fi

    if [ "$ELAPSED_MS" -gt 0 ]; then
        TOTAL_S=$(awk "BEGIN {printf \"%.2f\", $ELAPSED_MS / 1000}")
    fi

    local DRAFT_RATE="N/A"
    if [ "$DRAFT_N" -gt 0 ] && [ "$DRAFT_ACC" -gt 0 ]; then
        DRAFT_RATE=$(awk -v acc="$DRAFT_ACC" -v tot="$DRAFT_N" 'BEGIN {printf "%.1f%% (%d/%d)", (acc/tot)*100, acc, tot}')
    fi

    local VRAM_USED
    VRAM_USED=$(get_vram_use)

    # Rückgabe Schema: PROMPT_COUNT|PROMPT_TPS|EVAL_COUNT|EVAL_TPS|TOTAL_S|VRAM_USED|DRAFT_RATE
    echo "${PROMPT_COUNT}|${PROMPT_TPS}|${EVAL_COUNT}|${EVAL_TPS}|${TOTAL_S}|${VRAM_USED}|${DRAFT_RATE}"
}

# ------------------------------------------------------------------------------
# Einzelmessung mit Live-Ausgabe
# ------------------------------------------------------------------------------
run_single_test() {
    local MODEL="$1"
    local NUM_CTX="$2"
    local MAX_TOKENS="$3"
    local MODE="$4" # "standard" oder "stress"
    local PROMPT="$5"

    local IS_SPECULATIVE=0
    if [[ "$MODEL" =~ (speculative|ngram) ]]; then
        IS_SPECULATIVE=1
    fi

    echo -e "\n${BOLD}${BLUE}----------------------------------------------------------------------${NC}" >&2
    echo -e "  ${BOLD}Modell:${NC}        ${CYAN}${MODEL}${NC} $([ "$IS_SPECULATIVE" -eq 1 ] && echo -e "${MAGENTA}[Spekulatives Decoding / llama-swap]${NC}" || echo -e "${BLUE}[Ollama ROCm]${NC}")" >&2
    echo -e "  ${BOLD}Kontext:${NC}       ${YELLOW}${NUM_CTX} Tokens${NC} (Modus: ${MODE})" >&2
    echo -e "  ${BOLD}Tokens Max:${NC}    ${MAX_TOKENS}" >&2
    echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}" >&2

    local P_COUNT P_TPS E_COUNT E_TPS TOT_S VRAM DRAFT_RATE="N/A"

    if [ "$IS_SPECULATIVE" -eq 1 ]; then
        # Spekulatives Modell: Ollama vollständig entladen für VRAM-Freigabe
        echo -e "  * ${CYAN}Entlade Ollama-Modelle für maximale VRAM-Kapazität...${NC}" >&2
        unload_all_ollama

        # Warmup-Lauf
        echo -e "  * ${CYAN}Initialisiere Modell im VRAM (Warmup)...${NC}" >&2
        benchmark_speedup "$MODEL" "Warmup test." 5 "$NUM_CTX" >/dev/null 2>&1 || true

        echo -e "  * ${GREEN}Führe Messlauf durch (${NUM_CTX} Kontext-Allokation)...${NC}" >&2
        local RES
        RES=$(benchmark_speedup "$MODEL" "$PROMPT" "$MAX_TOKENS" "$NUM_CTX")
        IFS='|' read -r P_COUNT P_TPS E_COUNT E_TPS TOT_S VRAM DRAFT_RATE <<< "$RES"
    else
        # Standard Ollama Modell
        unload_speedup
        unload_ollama "$MODEL"

        echo -e "  * ${CYAN}Initialisiere Modell im VRAM (Warmup)...${NC}" >&2
        benchmark_ollama "$MODEL" "Warmup test." 5 2048 >/dev/null 2>&1 || true

        echo -e "  * ${GREEN}Führe Messlauf durch (${NUM_CTX} Kontext-Allokation)...${NC}" >&2
        local RES
        RES=$(benchmark_ollama "$MODEL" "$PROMPT" "$MAX_TOKENS" "$NUM_CTX")
        IFS='|' read -r P_COUNT P_TPS E_COUNT E_TPS TOT_S VRAM <<< "$RES"
    fi

    if [ "$E_COUNT" -gt 0 ]; then
        echo -e "    ${BOLD}⚡ Generation Speed:${NC} ${GREEN}${BOLD}${E_TPS} Tokens/s${NC} (${E_COUNT} Tokens in ${TOT_S} s)" >&2
        if [ "$P_TPS" != "0.00" ]; then
            echo -e "    ${BOLD}📥 Prompt-Prefill:${NC}   ${CYAN}${P_TPS} Tokens/s${NC} (${P_COUNT} Tokens im Prompt)" >&2
        fi
        if [ "$DRAFT_RATE" != "N/A" ] && [ -n "$DRAFT_RATE" ]; then
            echo -e "    ${BOLD}🎯 Draft-Acceptance:${NC} ${YELLOW}${DRAFT_RATE}${NC}" >&2
        fi
        echo -e "    ${BOLD}💾 VRAM-Belegung:${NC}    ${MAGENTA}${VRAM}${NC}" >&2
    else
        echo -e "    ${RED}[FEHLER] Modell konnte nicht inferiert werden (ggf. inkompatibel oder Timeout).${NC}" >&2
    fi

    echo "${MODEL}|${NUM_CTX}|${P_TPS}|${E_TPS}|${VRAM}|${TOT_S}"
}

# ------------------------------------------------------------------------------
# Spekulativer Vergleich (Ollama vs. Speedup)
# ------------------------------------------------------------------------------
run_speculative_comparison() {
    local TITLE="$1"
    local OLLAMA_MODEL="$2"
    local SPEEDUP_MODEL="$3"
    local NUM_CTX="$4"
    local MAX_TOKENS="$5"
    local PROMPT="$6"

    echo -e "\n${BOLD}${BLUE}======================================================================${NC}" >&2
    echo -e "${BOLD}${BLUE} Spekulativer Benchmark: ${TITLE}${NC}" >&2
    echo -e "${CYAN} Kontext: ${NUM_CTX} | Tokens Ziel: ${MAX_TOKENS}${NC}" >&2
    echo -e "${BOLD}${BLUE}======================================================================${NC}" >&2

    # 1. Ollama Normal
    echo -e "\n${BOLD}[1/2] Teste Ollama (${OLLAMA_MODEL})...${NC}" >&2
    unload_speedup
    unload_ollama "$OLLAMA_MODEL"
    benchmark_ollama "$OLLAMA_MODEL" "Warmup." 5 2048 >/dev/null 2>&1 || true

    local O_RES
    O_RES=$(benchmark_ollama "$OLLAMA_MODEL" "$PROMPT" "$MAX_TOKENS" "$NUM_CTX")
    local OP_COUNT OP_TPS OE_COUNT OE_TPS OTOT_S OVRAM
    IFS='|' read -r OP_COUNT OP_TPS OE_COUNT OE_TPS OTOT_S OVRAM <<< "$O_RES"
    echo -e "    ${GREEN}Ollama Ergebnis: ${BOLD}${OE_TPS} t/s${NC} (${OE_COUNT} Tok in ${OTOT_S}s | VRAM: ${OVRAM})" >&2

    # 2. Speedup Speculative
    echo -e "\n${BOLD}[2/2] Teste LLM-Speedup (${SPEEDUP_MODEL})...${NC}" >&2
    unload_ollama "$OLLAMA_MODEL"
    benchmark_speedup "$SPEEDUP_MODEL" "Warmup." 5 "$NUM_CTX" >/dev/null 2>&1 || true

    local S_RES
    S_RES=$(benchmark_speedup "$SPEEDUP_MODEL" "$PROMPT" "$MAX_TOKENS" "$NUM_CTX")
    local SP_COUNT SP_TPS SE_COUNT SE_TPS STOT_S SVRAM SDRAFT
    IFS='|' read -r SP_COUNT SP_TPS SE_COUNT SE_TPS STOT_S SVRAM SDRAFT <<< "$S_RES"
    echo -e "    ${GREEN}Speedup Ergebnis: ${BOLD}${SE_TPS} t/s${NC} (${SE_COUNT} Tok in ${STOT_S}s | VRAM: ${SVRAM})" >&2
    if [ "$SDRAFT" != "N/A" ] && [ -n "$SDRAFT" ]; then
        echo -e "    ${YELLOW}Draft-Acceptance: ${SDRAFT}${NC}" >&2
    fi

    # 3. Auswertung
    local FACTOR="1.00"
    local PERCENT="0.0"
    if awk -v o="$OE_TPS" -v s="$SE_TPS" 'BEGIN {exit !(o > 0 && s > 0)}'; then
        FACTOR=$(awk -v o="$OE_TPS" -v s="$SE_TPS" 'BEGIN {printf "%.2f", s / o}')
        PERCENT=$(awk -v o="$OE_TPS" -v s="$SE_TPS" 'BEGIN {printf "%.1f", ((s - o) / o) * 100}')
        echo -e "\n  ${MAGENTA}⚡ Speedup-Faktor: ${BOLD}${GREEN}${FACTOR}x${NC} schneller! (🚀 ${BOLD}${GREEN}+${PERCENT}% Boost${NC})" >&2
    fi

    echo "${TITLE}|${NUM_CTX}|${OE_TPS}|${SE_TPS}|${FACTOR}x|${SVRAM}"
}

# ------------------------------------------------------------------------------
# Tabellen-Ausgabe & Speichern in Markdown
# ------------------------------------------------------------------------------
save_and_display_results() {
    local -n _RESULTS_ARR=$1
    local BENCH_TYPE="$2"
    local CTX_SIZE="$3"
    local TIMESTAMP
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

    mkdir -p "$DOCS_DIR"

    echo -e "\n${BOLD}${GREEN}========================================================================================================${NC}"
    echo -e "${BOLD}${GREEN}                                LLM SPEED & KONTEXT BENCHMARK REPORT                                    ${NC}"
    echo -e "${BOLD}${GREEN}========================================================================================================${NC}"
    echo -e " Datum: ${TIMESTAMP} | GPU: AMD Radeon Pro W7800 (48GB) | Profil: $(get_gpu_mode_info)"
    echo -e " Kontext-Einstellung: ${BOLD}${CTX_SIZE} Tokens${NC} | Testtyp: ${BENCH_TYPE}"
    echo -e "--------------------------------------------------------------------------------------------------------"

    if [ "$BENCH_TYPE" = "speculative" ]; then
        printf "%-28s | %-10s | %-14s | %-14s | %-10s | %-12s\n" "Modell" "Kontext" "Ollama Normal" "Speculative" "Speedup" "VRAM"
        echo "-----------------------------+------------+----------------+----------------+------------+--------------"
        for line in "${_RESULTS_ARR[@]}"; do
            IFS='|' read -r m_title m_ctx m_o m_s m_factor m_vram <<< "$line"
            printf "%-28s | %10s | %10s t/s | %10s t/s | %10s | %12s\n" "$m_title" "$m_ctx" "$m_o" "$m_s" "$m_factor" "$m_vram"
        done
    else
        printf "%-30s | %-10s | %-16s | %-16s | %-12s | %-10s\n" "Modell" "Kontext" "Prefill (Prompt)" "Eval (Generation)" "VRAM" "Dauer"
        echo "-------------------------------+------------+------------------+------------------+--------------+-----------"
        for line in "${_RESULTS_ARR[@]}"; do
            IFS='|' read -r m_name m_ctx m_ptps m_etps m_vram m_dur <<< "$line"
            printf "%-30s | %10s | %12s t/s | %12s t/s | %12s | %8s s\n" "$m_name" "$m_ctx" "$m_ptps" "$m_etps" "$m_vram" "$m_dur"
        done
    fi
    echo -e "========================================================================================================\n"

    # In Markdown anhängen
    {
        echo ""
        echo "## ⏱️ Benchmark-Lauf vom ${TIMESTAMP}"
        echo "* **Hardware:** AMD Radeon Pro W7800 (48 GB GDDR6) | Power-Profil: $(get_gpu_mode_info)"
        echo "* **Kontext-Ziel:** \`${CTX_SIZE}\` Tokens | **Modus:** ${BENCH_TYPE}"
        echo ""
        if [ "$BENCH_TYPE" = "speculative" ]; then
            echo "| Modell | Kontext | Ollama Standard | Speculative Decoding | Speedup | VRAM |"
            echo "| :--- | :---: | :---: | :---: | :---: | :---: |"
            for line in "${_RESULTS_ARR[@]}"; do
                IFS='|' read -r m_title m_ctx m_o m_s m_factor m_vram <<< "$line"
                echo "| **${m_title}** | \`${m_ctx}\` | ${m_o} t/s | **${m_s} t/s** | **${m_factor}** | ${m_vram} |"
            done
        else
            echo "| Modell | Kontext | Prefill (Prompt-Eval) | Generation (Eval) | VRAM-Peak | Gesamtdauer |"
            echo "| :--- | :---: | :---: | :---: | :---: | :---: |"
            for line in "${_RESULTS_ARR[@]}"; do
                IFS='|' read -r m_name m_ctx m_ptps m_etps m_vram m_dur <<< "$line"
                echo "| **${m_name}** | \`${m_ctx}\` | ${m_ptps} t/s | **${m_etps} t/s** | ${m_vram} | ${m_dur} s |"
            done
        fi
        echo ""
        echo "---"
    } >> "$RESULTS_FILE"

    echo -e "${GREEN}✓ Ergebnisse wurden erfolgreich protokolliert in:${NC} [docs/BENCHMARK_RESULTS.md](${RESULTS_FILE})"
}

# ------------------------------------------------------------------------------
# Interaktive Auswahldialoge
# ------------------------------------------------------------------------------
select_output_token_count() {
    echo -e "\n${BOLD}${YELLOW}1. Wähle die zu generierende Token-Menge (Ausgabelänge):${NC}" >&2
    echo -e "  ${BOLD}1)${NC}   64 Tokens — ⚡ Blitzschneller Funktionstest (~1–2 Sekunden)" >&2
    echo -e "  ${BOLD}2)${NC}  128 Tokens — 📝 Kompakte Funktionsantwort (~2–3 Sekunden)" >&2
    echo -e "  ${BOLD}3)${NC}  256 Tokens — 🎯 ${GREEN}Standard-Benchmark (Optimaler statistischer Durchschnitt)${NC}" >&2
    echo -e "  ${BOLD}4)${NC}  512 Tokens — 💻 Ausführlicher Code-Block (~6–10 Sekunden)" >&2
    echo -e "  ${BOLD}5)${NC} 1024 Tokens — 🔥 ${YELLOW}Dauerlast & Kühlungstest (Prüft Thermal Throttling der W7800)${NC}" >&2
    echo -e "  ${BOLD}6)${NC} 2048 Tokens — 🚀 Extremer Stresstest" >&2
    echo -e "  ${BOLD}7)${NC} ✏️  ${BOLD}Beliebige eigene Token-Menge eingeben${NC}" >&2

    local T_CHOICE
    read -r -p "Auswahl (1-7) [Standard: 3 = 256 Tokens]: " T_CHOICE || true
    case "$T_CHOICE" in
        1) echo 64 ;;
        2) echo 128 ;;
        3|"") echo 256 ;;
        4) echo 512 ;;
        5) echo 1024 ;;
        6) echo 2048 ;;
        7)
            local CUST_TOK
            read -r -p "Gewünschte Token-Menge eingeben (z.B. 100, 300, 800): " CUST_TOK || true
            if [[ "$CUST_TOK" =~ ^[0-9]+$ ]] && [ "$CUST_TOK" -gt 0 ]; then
                echo "$CUST_TOK"
            else
                echo 256
            fi
            ;;
        *) echo 256 ;;
    esac
}

select_context_size() {
    echo -e "\n${BOLD}${YELLOW}2. Kontextgröße (num_ctx / KV-Cache Fenster im VRAM):${NC}" >&2
    echo -e "  ${CYAN}[Tipp: Drücke einfach Enter für den Standard 16.384 Tokens]${NC}" >&2
    echo -e "  ${BOLD}1)${NC}   2.048 (2k)   — Schneller Standard-Kurztest" >&2
    echo -e "  ${BOLD}2)${NC}   4.096 (4k)   — Typische Chat-Anfrage" >&2
    echo -e "  ${BOLD}3)${NC}   8.192 (8k)   — Mittlerer Code-Kontext" >&2
    echo -e "  ${BOLD}4)${NC}  16.384 (16k)  — ${GREEN}W7800 Standard (Optimal für 70B Modelle)${NC}" >&2
    echo -e "  ${BOLD}5)${NC}  32.768 (32k)  — ${YELLOW}VRAM-Maximum für 70B mit Q4-KV-Cache${NC}" >&2
    echo -e "  ${BOLD}6)${NC}  65.536 (64k)  — ${CYAN}MoE Sweet Spot (Qwen 3.8 / Mixtral)${NC}" >&2
    echo -e "  ${BOLD}7)${NC} 131.072 (128k) — ${MAGENTA}Nativ für Qwen 3 Coder Speed (128k VRAM)${NC}" >&2
    echo -e "  ${BOLD}8)${NC} ✏️  ${BOLD}Eigene beliebige Kontextgröße eingeben${NC}" >&2

    local C_CHOICE
    read -r -p "Auswahl (1-8) [Standard: 4 = 16k]: " C_CHOICE || true
    case "$C_CHOICE" in
        1) echo 2048 ;;
        2) echo 4096 ;;
        3) echo 8192 ;;
        4|"") echo 16384 ;;
        5) echo 32768 ;;
        6) echo 65536 ;;
        7) echo 131072 ;;
        8)
            local CUST_CTX
            read -r -p "Gewünschte Kontextgröße in Tokens eingeben (z.B. 12000, 24000): " CUST_CTX || true
            if [[ "$CUST_CTX" =~ ^[0-9]+$ ]] && [ "$CUST_CTX" -gt 256 ]; then
                echo "$CUST_CTX"
            else
                echo -e "${YELLOW}Ungültige Eingabe, verwende Standard (16384).${NC}" >&2
                echo 16384
            fi
            ;;
        *)
            echo 16384
            ;;
    esac
}

select_benchmark_mode() {
    echo -e "\n${BOLD}${YELLOW}3. Wähle den Benchmark-Testmodus:${NC}" >&2
    echo -e "  ${BOLD}1)${NC} ⚡ ${GREEN}Schnelldurchsatz & VRAM-Allokation (Standard)${NC}" >&2
    echo -e "     (Standard-Prompt; misst die reine Ausgabegeschwindigkeit bei reserviertem VRAM)" >&2
    echo -e "  ${BOLD}2)${NC} 🔥 ${CYAN}Vollkontext-Stresstest & Prefill-Benchmark${NC}" >&2
    echo -e "     (Füllt den Kontext mit realem Code vor; misst Prompt-Prefill-t/s UND Generation-t/s unter schwerer Last)" >&2

    local M_CHOICE
    read -r -p "Auswahl (1-2) [Standard: 1]: " M_CHOICE || true
    if [ "$M_CHOICE" = "2" ]; then
        echo "stress"
    else
        echo "standard"
    fi
}

# ------------------------------------------------------------------------------
# Haupt-Benchmark-Orchestrator
# ------------------------------------------------------------------------------
run_benchmark_suite() {
    local TARGET_MODELS=("$@")
    if [ ${#TARGET_MODELS[@]} -eq 0 ]; then
        echo -e "${RED}[FEHLER] Keine Modelle zum Benchmarking ausgewählt!${NC}"
        return 1
    fi

    # 1. Token-Menge (Ausgabelänge)
    local MAX_TOKENS
    MAX_TOKENS=$(select_output_token_count)

    # 2. Kontextgröße (KV-Cache Fenster)
    local CTX
    CTX=$(select_context_size)

    # 3. Testmodus
    local MODE
    MODE=$(select_benchmark_mode)

    local PROMPT_TEXT="$DEFAULT_PROMPT"
    if [ "$MODE" = "stress" ]; then
        echo -e "\n  * ${CYAN}Generiere Kontext-Stresstest-Payload für ${CTX} Tokens...${NC}"
        PROMPT_TEXT=$(generate_stress_prompt "$CTX")
    fi

    echo -e "\n${BOLD}${GREEN}Starte Benchmark-Durchlauf für ${#TARGET_MODELS[@]} Modell(e)...${NC}"
    declare -a RESULTS=()

    for m in "${TARGET_MODELS[@]}"; do
        local LINE
        LINE=$(run_single_test "$m" "$CTX" "$MAX_TOKENS" "$MODE" "$PROMPT_TEXT")
        RESULTS+=("$LINE")
    done

    save_and_display_results RESULTS "$MODE" "$CTX"
}

# ------------------------------------------------------------------------------
# Spekulatives Matrix- & Ausführungsmenü
# ------------------------------------------------------------------------------
run_speculative_matrix() {
    local CTX
    CTX=$(select_context_size)

    declare -a RESULTS=()
    echo -e "\n${BOLD}${CYAN}Starte Spekulatives Decoding Vergleichs-Matrix (${CTX} Kontext)...${NC}\n"

    # 1. Llama 3.3 70B
    if curl -s "${OLLAMA_HOST}/api/tags" | grep -q "llama3.3-70b-speed"; then
        RES=$(run_speculative_comparison "Llama 3.3 70B" "llama3.3-70b-speed" "llama3.3-70b-speculative" "$CTX" "$DEFAULT_MAX_TOKENS" "$DEFAULT_PROMPT")
        RESULTS+=("$RES")
    fi

    # 2. Llama 3.3 70B Abliterated (Unzensiert)
    if curl -s "${OLLAMA_HOST}/api/tags" | grep -q "llama3.3-70b-abliterated"; then
        RES=$(run_speculative_comparison "Llama 3.3 70B Abliterated" "llama3.3-70b-abliterated-speed" "llama3.3-70b-abliterated-speculative" "$CTX" "$DEFAULT_MAX_TOKENS" "$DEFAULT_PROMPT")
        RESULTS+=("$RES")
    fi

    # 3. DeepSeek R1 70B (N-Gram Speculative)
    if curl -s "${OLLAMA_HOST}/api/tags" | grep -q "deepseek-r1-70b"; then
        RES=$(run_speculative_comparison "DeepSeek-R1 70B" "deepseek-r1-70b-speed" "deepseek-r1-70b-speculative" "$CTX" "$DEFAULT_MAX_TOKENS" "$DEFAULT_PROMPT")
        RESULTS+=("$RES")
    fi

    # 4. Qwen 2.5 72B
    if curl -s "${OLLAMA_HOST}/api/tags" | grep -q "qwen2.5-72b"; then
        RES=$(run_speculative_comparison "Qwen 2.5 72B" "qwen2.5-72b-speed" "qwen2.5-72b-speculative" "$CTX" "$DEFAULT_MAX_TOKENS" "$DEFAULT_PROMPT")
        RESULTS+=("$RES")
    fi

    save_and_display_results RESULTS "speculative" "$CTX"
}

menu_speculative_benchmarks() {
    read -r -a SPEEDUP_MODELS <<< "$(get_installed_speedup_models)"

    while true; do
        echo -e "\n${BOLD}${MAGENTA}======================================================================${NC}"
        echo -e "${BOLD}${MAGENTA}   🚀 SPEKULATIVES DECODING & LLAMA-SWAP BENCHMARK                   ${NC}"
        echo -e "${BOLD}${MAGENTA}======================================================================${NC}"
        echo -e "  Verfügbare Modelle: ${CYAN}${SPEEDUP_MODELS[*]:-Keine gefunden}${NC}\n"
        echo -e "  ${BOLD}1)${NC} 📊 ${CYAN}Vollständige Vergleichs-Matrix (Ollama Standard vs. Spekulativ)${NC}"
        echo -e "     (Misst Speedup-Faktor & Draft-Rate für alle 4 70B/72B Flaggschiffe)"
        echo -e "  ${BOLD}2)${NC} 🏎️  ${GREEN}Alle Spekulativen Modelle Standalone durchtesten (Speedrun)${NC}"
        echo -e "     (Reiner llama-swap ROCm Durchsatz & Token-Geschwindigkeit)"
        echo -e "  ${BOLD}3)${NC} 📋 ${YELLOW}Einzelnes Spekulativ-Modell auswählen & testen${NC}"
        echo -e "  ${BOLD}q)${NC} Zurück zum Hauptmenü"
        echo -e "${BOLD}${MAGENTA}----------------------------------------------------------------------${NC}"

        read -r -p "Auswahl (1-3 oder q): " S_SEL || true
        case "$S_SEL" in
            1)
                run_speculative_matrix
                break
                ;;
            2)
                if [ ${#SPEEDUP_MODELS[@]} -gt 0 ]; then
                    run_benchmark_suite "${SPEEDUP_MODELS[@]}"
                else
                    echo -e "${RED}[FEHLER] Keine Spekulationsmodelle erreichbar! Läuft llama-speedup?${NC}"
                fi
                break
                ;;
            3)
                echo -e "\n${BOLD}Verfügbare Spekulations-Modelle:${NC}"
                for i in "${!SPEEDUP_MODELS[@]}"; do
                    printf "  ${BOLD}%2d)${NC} %s\n" "$((i+1))" "${SPEEDUP_MODELS[$i]}"
                done
                read -r -p "Modell-Nummer wählen (1-${#SPEEDUP_MODELS[@]}): " M_NUM || true
                if [[ "$M_NUM" =~ ^[0-9]+$ ]] && [ "$M_NUM" -ge 1 ] && [ "$M_NUM" -le "${#SPEEDUP_MODELS[@]}" ]; then
                    local TARGET="${SPEEDUP_MODELS[$((M_NUM-1))]}"
                    run_benchmark_suite "$TARGET"
                else
                    echo -e "${RED}Ungültige Auswahl.${NC}"
                fi
                break
                ;;
            q|Q)
                break
                ;;
            *)
                echo -e "${RED}Ungültige Eingabe.${NC}"
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Hauptprogramm & CLI-Parameter
# ------------------------------------------------------------------------------
main() {
    if [ $# -gt 0 ]; then
        local CLI_OPT="${1:-}"

        case "$CLI_OPT" in
            1|llama*|llama)
                run_speculative_comparison "Meta Llama 3.3 70B" "llama3.3-70b-speed" "llama3.3-70b-speculative" 16384 "$DEFAULT_MAX_TOKENS" "$DEFAULT_PROMPT"
                return 0
                ;;
            2|deepseek*|deepseek)
                run_speculative_comparison "DeepSeek-R1 Distill 70B" "deepseek-r1-70b-speed" "deepseek-r1-70b-speculative" 16384 "$DEFAULT_MAX_TOKENS" "$DEFAULT_PROMPT"
                return 0
                ;;
            3|qwen*|qwen)
                run_speculative_comparison "Qwen 2.5 72B Instruct" "qwen2.5-72b-speed" "qwen2.5-72b-speculative" 16384 "$DEFAULT_MAX_TOKENS" "$DEFAULT_PROMPT"
                return 0
                ;;
            4|matrix|--speculative|-s)
                run_speculative_matrix
                return 0
                ;;
            --speedup-all)
                read -r -a SPEEDUP_ALL <<< "$(get_installed_speedup_models)"
                run_benchmark_suite "${SPEEDUP_ALL[@]}"
                return 0
                ;;
            --all|all)
                read -r -a ALL_MODELS <<< "$(get_installed_ollama_models)"
                run_benchmark_suite "${ALL_MODELS[@]}"
                return 0
                ;;
            --help|-h)
                echo "Nutzung: $0 [OPTIONEN]"
                echo "Optionen:"
                echo "  (keine)          Interaktives Hauptmenü öffnen"
                echo "  --all            Alle installierten Ollama-Modelle durchtesten"
                echo "  --speculative    Spekulative Vergleichs-Matrix ausführen"
                echo "  --speedup-all    Alle spekulativen Modelle auf llama-swap durchtesten"
                echo "  1|2|3|4          Direkter Schnellvergleich für 70B Modelle"
                return 0
                ;;
        esac
    fi

    while true; do
        clear 2>/dev/null || true
        echo -e "${BOLD}${CYAN}======================================================================${NC}"
        echo -e "${BOLD}${CYAN}      AMD RADEON PRO W7800 — LLM SPEED & KONTEXT BENCHMARK SUITE      ${NC}"
        echo -e "${BOLD}${CYAN}======================================================================${NC}"
        echo -e " Ollama Host:      ${GREEN}${OLLAMA_HOST}${NC}"
        echo -e " LLM-Speedup Host: ${GREEN}${SPEEDUP_HOST}/v1${NC}"
        echo -e " GPU VRAM:         ${BOLD}${GREEN}48 GB GDDR6${NC} (Aktuell belegt: $(get_vram_use))"
        echo -e " GPU Power-Mode:   ${YELLOW}$(get_gpu_mode_info)${NC}\n"

        read -r -a INSTALLED_ARR <<< "$(get_installed_ollama_models)"
        read -r -a SPEEDUP_ARR <<< "$(get_installed_speedup_models)"
        declare -a ALL_COMBINED=("${INSTALLED_ARR[@]}" "${SPEEDUP_ARR[@]}")

        echo -e "${BOLD}${YELLOW}Welche Modelle möchtest du testen?${NC}"
        echo -e "  ${BOLD}1)${NC} 🌐 ${GREEN}ALLE Modelle testen (${#ALL_COMBINED[@]} Modelle: ${#INSTALLED_ARR[@]} Ollama + ${#SPEEDUP_ARR[@]} Spekulativ)${NC}"
        echo -e "  ${BOLD}2)${NC} 📦 ${CYAN}Nur Ollama Standard-Modelle (${#INSTALLED_ARR[@]} Modelle)${NC}"
        echo -e "  ${BOLD}3)${NC} 🚀 ${MAGENTA}Nur Spekulative Modelle (${#SPEEDUP_ARR[@]} Modelle auf llama-swap ROCm)${NC}"
        echo -e "  ${BOLD}4)${NC} 👑 ${CYAN}Top 3 Flaggschiffe (70B / 72B)${NC} (Qwen 72B, R1 70B, Llama 70B)"
        echo -e "  ${BOLD}5)${NC} 💻 ${CYAN}Coding-Spezialisten${NC} (Qwen 3 Coder Speed & Quality, Qwen 2.5 Coder)"
        echo -e "  ${BOLD}6)${NC} ⚡ ${CYAN}High-Speed Sweet Spot & MoE${NC} (Qwen 3.8 Distill, Qwen 3 Coder)"
        echo -e "  ${BOLD}7)${NC} 📊 ${MAGENTA}Spekulative Vergleichs-Matrix (Ollama Standard vs. Spekulativ)${NC}"
        echo -e "  ${BOLD}8)${NC} 📋 ${YELLOW}Benutzerdefinierte Mehrfachauswahl aus Liste${NC}"
        echo -e "  ${BOLD}9)${NC} ✏️  ${YELLOW}Einzelnes Modell direkt eingeben (z.B. llama3.3-70b-speculative)${NC}"
        echo -e "  ${BOLD}q)${NC} Zurück / Beenden"
        echo -e "${BOLD}${CYAN}----------------------------------------------------------------------${NC}"

        read -r -p "Deine Auswahl (1-9 oder q): " MAIN_SEL || true
        [ -z "$MAIN_SEL" ] && continue

        case "$MAIN_SEL" in
            1)
                if [ ${#ALL_COMBINED[@]} -eq 0 ]; then
                    echo -e "${RED}Keine Modelle gefunden!${NC}"
                else
                    run_benchmark_suite "${ALL_COMBINED[@]}"
                fi
                ;;
            2)
                if [ ${#INSTALLED_ARR[@]} -eq 0 ]; then
                    echo -e "${RED}Keine installierten Ollama-Modelle gefunden!${NC}"
                else
                    run_benchmark_suite "${INSTALLED_ARR[@]}"
                fi
                ;;
            3)
                if [ ${#SPEEDUP_ARR[@]} -eq 0 ]; then
                    echo -e "${RED}Keine Spekulationsmodelle erreichbar! Läuft llama-speedup?${NC}"
                else
                    run_benchmark_suite "${SPEEDUP_ARR[@]}"
                fi
                ;;
            4)
                declare -a TARGETS=()
                for m in "${INSTALLED_ARR[@]}"; do
                    if [[ "$m" =~ (qwen2.5-72b|deepseek-r1-70b|llama3.3-70b) ]]; then
                        TARGETS+=("$m")
                    fi
                done
                if [ ${#TARGETS[@]} -eq 0 ]; then
                    echo -e "${YELLOW}Keine Top-3 Flaggschiffe installiert.${NC}"
                else
                    run_benchmark_suite "${TARGETS[@]}"
                fi
                ;;
            5)
                declare -a TARGETS=()
                for m in "${INSTALLED_ARR[@]}"; do
                    if [[ "$m" =~ (coder|qwen3.8-35b) ]]; then
                        TARGETS+=("$m")
                    fi
                done
                if [ ${#TARGETS[@]} -eq 0 ]; then
                    echo -e "${YELLOW}Keine Coder-Modelle installiert.${NC}"
                else
                    run_benchmark_suite "${TARGETS[@]}"
                fi
                ;;
            6)
                declare -a TARGETS=()
                for m in "${INSTALLED_ARR[@]}"; do
                    if [[ "$m" =~ (distill|qwen3-coder-speed) ]]; then
                        TARGETS+=("$m")
                    fi
                done
                if [ ${#TARGETS[@]} -eq 0 ]; then
                    echo -e "${YELLOW}Keine MoE/High-Speed Modelle gefunden.${NC}"
                else
                    run_benchmark_suite "${TARGETS[@]}"
                fi
                ;;
            7)
                menu_speculative_benchmarks
                ;;
            8)
                echo -e "\n${BOLD}Alle verfügbaren Modelle:${NC}"
                echo -e "  ${BLUE}--- Ollama Standard-Modelle ---${NC}"
                for i in "${!INSTALLED_ARR[@]}"; do
                    printf "  ${BOLD}%2d)${NC} %-35s [Ollama]\n" "$((i+1))" "${INSTALLED_ARR[$i]}"
                done
                if [ ${#SPEEDUP_ARR[@]} -gt 0 ]; then
                    echo -e "  ${MAGENTA}--- Spekulative Modelle (llama-swap) ---${NC}"
                    local OFFSET=${#INSTALLED_ARR[@]}
                    for j in "${!SPEEDUP_ARR[@]}"; do
                        printf "  ${BOLD}%2d)${NC} %-35s [Spekulativ 🚀]\n" "$((OFFSET+j+1))" "${SPEEDUP_ARR[$j]}"
                    done
                fi
                echo ""
                read -r -p "Wähle Nummern getrennt durch Komma (z.B. 1,3,8): " USER_INDICES || true
                declare -a SELECTED_MODELS=()
                IFS=',' read -ra ADDR <<< "$USER_INDICES"
                for item in "${ADDR[@]}"; do
                    item=$(echo "$item" | tr -d ' ')
                    if [[ "$item" =~ ^[0-9]+$ ]] && [ "$item" -ge 1 ] && [ "$item" -le "${#ALL_COMBINED[@]}" ]; then
                        SELECTED_MODELS+=("${ALL_COMBINED[$((item-1))]}")
                    fi
                done
                if [ ${#SELECTED_MODELS[@]} -gt 0 ]; then
                    run_benchmark_suite "${SELECTED_MODELS[@]}"
                else
                    echo -e "${RED}Keine gültigen Modelle gewählt.${NC}"
                fi
                ;;
            9)
                echo -e "\nOllama: ${INSTALLED_ARR[*]}"
                echo -e "Spekulativ: ${SPEEDUP_ARR[*]}"
                read -r -p "Modell-Name eingeben: " SINGLE_M || true
                if [ -n "$SINGLE_M" ]; then
                    run_benchmark_suite "$SINGLE_M"
                fi
                ;;
            q|Q)
                echo -e "\n${GREEN}Benchmark beendet.${NC}\n"
                break
                ;;
            *)
                echo -e "\n${RED}Ungültige Auswahl.${NC}"
                ;;
        esac

        echo ""
        if [ -t 0 ]; then
            read -r -p "Drücke [Enter] für das Menü..." || true
        else
            break
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
