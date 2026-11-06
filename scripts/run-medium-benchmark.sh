#!/usr/bin/env bash
# ==============================================================================
# run-medium-benchmark.sh — Umfassender Speed-Benchmark mit mittelgroßem Prompt
# ==============================================================================
set -euo pipefail
export LC_ALL=C

OLLAMA_HOST="http://127.0.0.1:11434"
SPEEDUP_HOST="http://127.0.0.1:5002"

PROMPT="Erstelle eine strukturierte architektonische Übersicht für eine Microservices-Plattform im E-Commerce. Gehe kurz auf Event-Driven Architecture, Caching mit Redis und das Saga-Pattern für verteilte Transaktionen ein. Gib einen kompakten Python-Beispielcode für einen Saga-Orchestrator an."
MAX_TOKENS=350

get_vram() {
    rocm-smi --showmemuse 2>/dev/null | awk '/GPU Memory Allocated/ {print $NF "%"}' | head -n1 || echo "N/A"
}

unload_all() {
    # Ollama Modelle entladen
    for m in $(curl -s "${OLLAMA_HOST}/api/tags" 2>/dev/null | jq -r '.models[].name' 2>/dev/null || true); do
        curl -s "${OLLAMA_HOST}/api/generate" -d "{\"model\": \"$m\", \"keep_alive\": 0}" >/dev/null 2>&1 || true
    done
    # llama-speedup entladen
    docker exec llama-speedup pkill -f llama-server >/dev/null 2>&1 || true
    sleep 3
}

benchmark_ollama() {
    local MODEL="$1"
    echo "  [Ollama] Lade/Wärme auf: ${MODEL}..." >&2
    # Warmup
    curl -s "${OLLAMA_HOST}/api/generate" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$MODEL\", \"prompt\": \"Hallo\", \"options\": {\"num_predict\": 5}}" >/dev/null 2>&1 || true

    echo "  [Ollama] Starte Messlauf: ${MODEL}..." >&2
    local START_T
    START_T=$(date +%s%N)
    local RESP
    RESP=$(curl -s "${OLLAMA_HOST}/api/generate" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$MODEL\", \"prompt\": $(echo -n "$PROMPT" | jq -Rs .), \"stream\": false, \"options\": {\"num_predict\": $MAX_TOKENS, \"temperature\": 0.3}}")
    local END_T
    END_T=$(date +%s%N)

    local EVAL_COUNT
    EVAL_COUNT=$(echo "$RESP" | jq -r '.eval_count // 0')
    local EVAL_NS
    EVAL_NS=$(echo "$RESP" | jq -r '.eval_duration // 0')
    local PROMPT_NS
    PROMPT_NS=$(echo "$RESP" | jq -r '.prompt_eval_duration // 0')
    local PROMPT_COUNT
    PROMPT_COUNT=$(echo "$RESP" | jq -r '.prompt_eval_count // 0')

    local TPS="0.0"
    local PROMPT_TPS="0.0"
    if [ "$EVAL_NS" -gt 0 ] && [ "$EVAL_COUNT" -gt 0 ]; then
        TPS=$(awk "BEGIN {printf \"%.2f\", $EVAL_COUNT / ($EVAL_NS / 1000000000)}")
    fi
    if [ "$PROMPT_NS" -gt 0 ] && [ "$PROMPT_COUNT" -gt 0 ]; then
        PROMPT_TPS=$(awk "BEGIN {printf \"%.1f\", $PROMPT_COUNT / ($PROMPT_NS / 1000000000)}")
    fi

    local VRAM
    VRAM=$(get_vram)
    echo "$EVAL_COUNT|$TPS|$PROMPT_TPS|$VRAM"
}

benchmark_speedup() {
    local MODEL="$1"
    echo "  [Speedup] Lade/Wärme auf: ${MODEL}..." >&2
    # Warmup
    curl -s "${SPEEDUP_HOST}/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$MODEL\", \"messages\": [{\"role\": \"user\", \"content\": \"Hallo\"}], \"max_tokens\": 5}" >/dev/null 2>&1 || true

    echo "  [Speedup] Starte Messlauf: ${MODEL}..." >&2
    local RESP
    RESP=$(curl -s "${SPEEDUP_HOST}/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$MODEL\", \"messages\": [{\"role\": \"user\", \"content\": $(echo -n "$PROMPT" | jq -Rs .)}], \"max_tokens\": $MAX_TOKENS, \"temperature\": 0.3}")

    local EVAL_COUNT
    EVAL_COUNT=$(echo "$RESP" | jq -r '.usage.completion_tokens // 0')
    local PRED_S
    PRED_S=$(echo "$RESP" | jq -r '.timings.predicted_per_second // 0')
    local PROMPT_S
    PROMPT_S=$(echo "$RESP" | jq -r '.timings.prompt_per_second // 0')
    local ACCEPT_RATE
    ACCEPT_RATE=$(echo "$RESP" | jq -r 'if .timings.draft_n and .timings.draft_n > 0 then ((.timings.draft_n_accepted / .timings.draft_n) * 100 | round | tostring) + "%" else "N/A" end')

    local TPS="0.0"
    if awk -v p="$PRED_S" 'BEGIN {exit !(p > 0)}'; then
        TPS=$(awk "BEGIN {printf \"%.2f\", $PRED_S}")
    fi
    local PROMPT_TPS="0.0"
    if awk -v p="$PROMPT_S" 'BEGIN {exit !(p > 0)}'; then
        PROMPT_TPS=$(awk "BEGIN {printf \"%.1f\", $PROMPT_S}")
    fi

    local VRAM
    VRAM=$(get_vram)
    echo "$EVAL_COUNT|$TPS|$PROMPT_TPS|$VRAM|$ACCEPT_RATE"
}

echo "======================================================================"
echo "    BENCHMARK ALLER LOKALEN MODELLE MITTELGROSSE ANFRAGE (350 TOKENS) "
echo "======================================================================"
echo "Hardware: AMD Radeon Pro W7800 (48 GB GDDR6)"
echo "Prompt: $PROMPT"
echo "----------------------------------------------------------------------"

RESULTS=()

# 1. Llama 3.3 70B (Ollama Standard)
echo -e "\n>>> Test 1/7: Llama 3.3 70B (Ollama Standard) <<<"
unload_all
O1=$(benchmark_ollama "llama3.3-70b-speed")
RESULTS+=("Llama 3.3 70B (Ollama Standard)|$O1|Standard")

# 2. Llama 3.3 70B (Speculative 1B Draft)
echo -e "\n>>> Test 2/7: Llama 3.3 70B (Speculative Decoding 1B Draft) <<<"
unload_all
S1=$(benchmark_speedup "llama3.3-70b-speculative")
RESULTS+=("Llama 3.3 70B (Speculative 1B)|$S1")

# 3. DeepSeek-R1 70B (Ollama Standard)
echo -e "\n>>> Test 3/7: DeepSeek-R1 70B (Ollama Standard) <<<"
unload_all
O2=$(benchmark_ollama "deepseek-r1-70b-speed")
RESULTS+=("DeepSeek-R1 70B (Ollama Standard)|$O2|Standard")

# 4. DeepSeek-R1 70B (N-Gram Speculative)
echo -e "\n>>> Test 4/7: DeepSeek-R1 70B (N-Gram Speculative) <<<"
unload_all
S2=$(benchmark_speedup "deepseek-r1-70b-speculative")
RESULTS+=("DeepSeek-R1 70B (N-Gram Speedup)|$S2")

# 5. Qwen 3.8 35B Distill
echo -e "\n>>> Test 5/7: Qwen 3.8 35B Distill (Ollama) <<<"
unload_all
O3=$(benchmark_ollama "qwen3.8-35b-distill:latest")
RESULTS+=("Qwen 3.8 35B Distill (Ollama)|$O3|Standard")

# 6. Artemis 31B
echo -e "\n>>> Test 6/7: Artemis 31B (Ollama) <<<"
unload_all
O4=$(benchmark_ollama "artemis-31b:latest")
RESULTS+=("Artemis 31B (Ollama)|$O4|Standard")

# 7. Qwen3 Obliterated
echo -e "\n>>> Test 7/7: Qwen3 Obliterated (Ollama) <<<"
unload_all
O5=$(benchmark_ollama "qwen3-obliterated:latest")
RESULTS+=("Qwen3 Obliterated (Ollama)|$O5|Standard")

echo ""
echo "========================================================================================================="
echo "                                        BENCHMARK ERGEBNISSE                                             "
echo "========================================================================================================="
printf "%-35s | %-12s | %-14s | %-8s | %-12s\n" "Modell / Optimierung" "Gen. Speed" "Prompt Eval" "VRAM" "Draft Accept"
echo "------------------------------------+--------------+----------------+----------+-------------"
for r in "${RESULTS[@]}"; do
    IFS='|' read -r name tokens tps prompt_tps vram extra <<< "$r"
    printf "%-35s | %8s t/s | %10s t/s | %8s | %-12s\n" "$name" "$tps" "$prompt_tps" "$vram" "$extra"
done
echo "========================================================================================================="

# Dump raw JSON/text results for easy parsing
echo ""
echo "--- RAW RESULTS ---"
for r in "${RESULTS[@]}"; do
    echo "DATA:$r"
done

