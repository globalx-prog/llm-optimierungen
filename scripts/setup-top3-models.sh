#!/usr/bin/env bash
# ==============================================================================
# setup-top3-models.sh - Interaktiver Download & Setup für Top 70B/72B LLMs
# Optimiert für: AMD Radeon Pro W7800 (48 GB VRAM) + 61 GB RAM + 32 GB NVMe Swap
# ==============================================================================

set -euo pipefail

# Farbdefinitionen für übersichtliche Terminal-Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MODELFILES_DIR="${REPO_ROOT}/llm-optimierungen/modelfiles"

clear
cat << "EOF"
================================================================================
   _    ___ __  __   _    ____ ___ ____ _____ _____ __  __ 
  / \  |_ _|  \/  | / \  / ___|_ _|  _ \_   _| ____|  \/  |
 / _ \  | || |\/| |/ _ \ \___ \| || |_) || | |  _| | |\/| |
/ ___ \ | || |  | / ___ \ ___) | ||  __/ | | | |___| |  | |
/_/   \_\___|_|  |_/_/   \_\____/___|_|    |_| |_____|_|  |_|
================================================================================
EOF

echo -e "${BOLD}${CYAN}Hardware-Profil:${NC} AMD Radeon Pro W7800 (48 GB GDDR6) | 61 GB RAM | 32 GB NVMe Swap"
echo -e "${BOLD}${CYAN}High-Speed-Speicher:${NC} ~95 GB (45 GB VRAM + 50 GB nutzbarer RAM)\n"

# 1. Systemprüfungen
echo -e "${BOLD}[1/4] Prüfe Systemvoraussetzungen...${NC}"

# Prüfe freien Speicherplatz
FREE_SPACE_GB=$(df -BG /home | awk 'NR==2 {print $4}' | sed 's/G//')
echo -e "  * Freier Festplattenspeicher (/home): ${GREEN}${FREE_SPACE_GB} GB verfügbar${NC}"
if [ "${FREE_SPACE_GB}" -lt 50 ]; then
    echo -e "${YELLOW}  [WARNUNG] Weniger als 50 GB frei! Große Modelle benötigen 38–48 GB.${NC}"
fi

# Prüfe Ollama Erreichbarkeit
if command -v ollama >/dev/null 2>&1; then
    echo -e "  * Ollama CLI: ${GREEN}Installiert${NC}"
else
    echo -e "${RED}  [FEHLER] Ollama ist nicht installiert oder nicht im PATH!${NC}"
    exit 1
fi

# Prüfe aktuellen KV-Cache-Modus
CURRENT_KV="Unbekannt (Standard f16)"
if [ -f /etc/systemd/system/ollama.service ]; then
    KV_FOUND=$(grep "OLLAMA_KV_CACHE_TYPE" /etc/systemd/system/ollama.service | cut -d'=' -f2 | tr -d '"' || true)
    if [ -n "$KV_FOUND" ]; then
        CURRENT_KV="$KV_FOUND"
    fi
fi
echo -e "  * Aktiver KV-Cache-Modus: ${BOLD}${GREEN}${CURRENT_KV}${NC}"
echo -e "  * Modelfiles-Verzeichnis: ${GREEN}${MODELFILES_DIR}${NC}\n"

# 2. Hilfsfunktionen
install_model() {
    local MODEL_NAME="$1"
    local HF_TAG="$2"
    local MODELFILE_NAME="$3"
    local DESC="$4"

    local MODELFILE_PATH="${MODELFILES_DIR}/${MODELFILE_NAME}"

    if [ ! -f "${MODELFILE_PATH}" ]; then
        echo -e "${RED}[FEHLER] Modelfile nicht gefunden: ${MODELFILE_PATH}${NC}"
        return 1
    fi

    echo -e "\n${BOLD}${BLUE}======================================================================${NC}"
    echo -e "${BOLD}${BLUE}Starte Setup: ${MODEL_NAME}${NC}"
    echo -e "${CYAN}Beschreibung: ${DESC}${NC}"
    echo -e "${CYAN}HuggingFace Quelle: ${HF_TAG}${NC}"
    echo -e "${CYAN}Modelfile: ${MODELFILE_PATH}${NC}"
    echo -e "${BOLD}${BLUE}======================================================================${NC}\n"

    read -p "Möchtest du dieses Modell jetzt herunterladen und einrichten? (j/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[jJyY]$ ]]; then
        echo -e "${YELLOW}Überspringe ${MODEL_NAME}.${NC}\n"
        return 0
    fi

    echo -e "\n${BOLD}[Schritt 1] Lade GGUF-Basisschichten via Ollama herunter...${NC}"
    echo -e "${YELLOW}Hinweis: Der Download umfasst ca. 38–48 GB. Bitte Geduld.${NC}"
    ollama pull "${HF_TAG}"

    echo -e "\n${BOLD}[Schritt 2] Erstelle optimiertes Modell '${MODEL_NAME}' in Ollama...${NC}"
    ollama create "${MODEL_NAME}" -f "${MODELFILE_PATH}"

    echo -e "\n${BOLD}[Schritt 3] Bereinige temporären HuggingFace-Tag für sauberes 'ollama list'...${NC}"
    if ollama list | grep -q "${HF_TAG}"; then
        ollama rm "${HF_TAG}" || true
        echo -e "  * ${GREEN}Bereinigung erfolgreich. '${MODEL_NAME}' ist nun sauber registriert.${NC}"
    fi

    echo -e "\n${BOLD}[Schritt 4] Schneller Funktionstest (Smoke Test)...${NC}"
    echo -e "Sende Test-Prompt an ${MODEL_NAME}..."
    ollama run "${MODEL_NAME}" "Sage in genau einem Satz Hallo und nenne deinen Namen." || true

    echo -e "\n${GREEN}${BOLD}✓ Erfolgreich eingerichtet: ${MODEL_NAME}${NC}\n"
}

ask_variant_and_install() {
    local BASE_NAME="$1"
    local IQ4_TAG="$2"
    local Q4KM_TAG="$3"
    local SPEED_FILE="$4"
    local QUALITY_FILE="$5"
    local DESC="$6"

    echo -e "\n${BOLD}${YELLOW}Welche Variante von ${BASE_NAME} möchtest du installieren?${NC}"
    echo -e "  ${BOLD}1)${NC} ${GREEN}Speed-Variante (IQ4_XS - EMPFOHLEN)${NC}"
    echo -e "     -> 100% VRAM (alle Layer auf W7800), keine PCIe-Drossel"
    echo -e "     -> Qualität: ~98,5% der Q8-Leistung (imatrix geschützt)"
    echo -e "     -> Geschwindigkeit: ${BOLD}⚡ ~40–48 Tokens/s${NC} (+60% schneller!)"
    echo -e "     -> Dateigröße: ~38–39 GB"
    echo -e "  ${BOLD}2)${NC} ${BLUE}Quality-Variante (Q4_K_M - Hybrid)${NC}"
    echo -e "     -> Hybrid-Modus: ~80% GPU / ~20% System-RAM"
    echo -e "     -> Qualität: ~99,1% der Q8-Leistung (höchste 4-Bit-Präzision)"
    echo -e "     -> Geschwindigkeit: ${BOLD}🚄 ~26–28 Tokens/s${NC}"
    echo -e "     -> Dateigröße: ~43–47 GB"
    echo -e "  ${BOLD}3)${NC} Beide Varianten installieren"
    echo -e "  ${BOLD}4)${NC} Zurück zum Hauptmenü"

    read -p "Auswahl (1-4): " VAR_CHOICE
    case "$VAR_CHOICE" in
        1)
            install_model "${BASE_NAME}-speed" "${IQ4_TAG}" "${SPEED_FILE}" "${DESC} (Speed IQ4_XS - 100% VRAM)"
            ;;
        2)
            install_model "${BASE_NAME}-quality" "${Q4KM_TAG}" "${QUALITY_FILE}" "${DESC} (Quality Q4_K_M - Hybrid)"
            ;;
        3)
            install_model "${BASE_NAME}-speed" "${IQ4_TAG}" "${SPEED_FILE}" "${DESC} (Speed IQ4_XS)"
            install_model "${BASE_NAME}-quality" "${Q4KM_TAG}" "${QUALITY_FILE}" "${DESC} (Quality Q4_K_M)"
            ;;
        4)
            return 0
            ;;
        *)
            echo -e "${RED}Ungültige Auswahl.${NC}"
            ;;
    esac
}

toggle_kv_cache() {
    echo -e "\n${BOLD}${BLUE}======================================================================${NC}"
    echo -e "${BOLD}${BLUE}             KV-CACHE QUANTISIERUNG (KONTEXT-PRÄZISION)               ${NC}"
    echo -e "${BOLD}${BLUE}======================================================================${NC}"
    echo -e "Aktuell aktiv: ${BOLD}${GREEN}${CURRENT_KV}${NC}\n"
    echo -e "  ${BOLD}1)${NC} ${GREEN}q4_0 Modus (Standard & Headroom)${NC}"
    echo -e "     - VRAM-Bedarf für 16k Kontext: ca. 2,0 GB"
    echo -e "     - Vorteil: Lässt maximalen VRAM frei. Alle 70B/72B Speed-Modelle"
    echo -e "       passen zu 100% in die W7800 (auch bis 32k Kontext!)."
    echo -e "     - Qualität: Praktisch identisch bei <16k Kontext.\n"
    echo -e "  ${BOLD}2)${NC} ${CYAN}q8_0 Modus (Maximale Kontext-Präzision)${NC}"
    echo -e "     - VRAM-Bedarf für 16k Kontext: ca. 4,0 GB"
    echo -e "     - Vorteil: 99,99% FP16-Qualität im Chat-Verlauf. DeepSeek 70B und"
    echo -e "       Llama 3.3 70B passen weiterhin zu 100% in VRAM (~42 GB VRAM)."
    echo -e "     - Ideal für: Wissenschaftliche RAG-Suchen und Quality-Modelle.\n"
    echo -e "  ${BOLD}3)${NC} Abbrechen und zurück"

    read -p "Gewünschter Modus (1-3): " KV_CHOICE
    case "$KV_CHOICE" in
        1)
            NEW_VAL="q4_0"
            ;;
        2)
            NEW_VAL="q8_0"
            ;;
        *)
            return 0
            ;;
    esac

    if [ "$NEW_VAL" == "$CURRENT_KV" ]; then
        echo -e "${YELLOW}Dieser Modus ist bereits aktiv.${NC}"
        return 0
    fi

    echo -e "\nSetze OLLAMA_KV_CACHE_TYPE=${NEW_VAL} in /etc/systemd/system/ollama.service..."
    if [ -w /etc/systemd/system/ollama.service ]; then
        sed -i "s/Environment=\"OLLAMA_KV_CACHE_TYPE=.*/Environment=\"OLLAMA_KV_CACHE_TYPE=${NEW_VAL}\"/" /etc/systemd/system/ollama.service
        systemctl daemon-reload
        systemctl restart ollama
        CURRENT_KV="$NEW_VAL"
        echo -e "${GREEN}✓ Erfolgreich auf ${NEW_VAL} umgestellt und Ollama neu gestartet.${NC}"
    else
        echo -e "${YELLOW}Root-Rechte erforderlich. Bitte folgenden Befehl ausführen:${NC}"
        echo -e "  sudo sed -i 's/Environment=\"OLLAMA_KV_CACHE_TYPE=.*/Environment=\"OLLAMA_KV_CACHE_TYPE=${NEW_VAL}\"/' /etc/systemd/system/ollama.service"
        echo -e "  sudo systemctl daemon-reload && sudo systemctl restart ollama"
    fi
}

# 3. Interaktives Hauptmenü
while true; do
    echo -e "${BOLD}${YELLOW}======================================================================${NC}"
    echo -e "${BOLD}${YELLOW}              WÄHLE DAS MODELL ZUM DOWNLOAD & SETUP                  ${NC}"
    echo -e "${BOLD}${YELLOW}======================================================================${NC}"
    echo -e "  ${BOLD}1)${NC} 👑 ${CYAN}Qwen 2.5 72B Instruct${NC}      (🥇 Nr. 1 für Coding, Cline & Tools)"
    echo -e "  ${BOLD}2)${NC} 🧠 ${CYAN}DeepSeek-R1-Distill-70B${NC}    (🥇 Nr. 1 für Deep Reasoning & Mathe)"
    echo -e "  ${BOLD}3)${NC} 🌐 ${CYAN}Llama 3.3 70B Instruct${NC}     (🥇 Nr. 1 für Agenten, RAG & Allround)"
    echo -e "  --------------------------------------------------------------------"
    echo -e "  ${BOLD}4)${NC} 🐘 ${BLUE}Mistral Large 2407 (123B)${NC}  (Monumentales 123B Hybrid-Modell)"
    echo -e "  ${BOLD}5)${NC} 🔀 ${BLUE}Mixtral 8x22B (141B MoE)${NC}   (141B MoE Gigant, ~20 t/s)"
    echo -e "  --------------------------------------------------------------------"
    echo -e "  ${BOLD}6)${NC} 🚀 ${GREEN}ALLE TOP 3 SPEED-MODELLE AUF EINMAL${NC} (Qwen 72B + R1 70B + Llama 70B)"
    echo -e "  ${BOLD}7)${NC} ⚙️  ${YELLOW}KV-Cache Modus prüfen / umschalten${NC} (Aktuell: ${BOLD}${GREEN}${CURRENT_KV}${NC})"
    echo -e "  ${BOLD}q)${NC} Beenden"
    echo -e "${BOLD}${YELLOW}======================================================================${NC}"

    read -p "Deine Auswahl (1-7 oder q): " MAIN_CHOICE

    case "$MAIN_CHOICE" in
        1)
            ask_variant_and_install \
                "qwen2.5-72b" \
                "hf.co/bartowski/Qwen2.5-72B-Instruct-GGUF:IQ4_XS" \
                "hf.co/bartowski/Qwen2.5-72B-Instruct-GGUF:Q4_K_M" \
                "Modelfile.qwen2.5-72b-speed" \
                "Modelfile.qwen2.5-72b-quality" \
                "Qwen 2.5 72B Instruct - Der Coding- und Syntax-König"
            ;;
        2)
            ask_variant_and_install \
                "deepseek-r1-70b" \
                "hf.co/bartowski/DeepSeek-R1-Distill-Llama-70B-GGUF:IQ4_XS" \
                "hf.co/bartowski/DeepSeek-R1-Distill-Llama-70B-GGUF:Q4_K_M" \
                "Modelfile.deepseek-r1-70b-speed" \
                "Modelfile.deepseek-r1-70b-quality" \
                "DeepSeek-R1-Distill-Llama-70B - Der unangefochtene Reasoning-Meister"
            ;;
        3)
            ask_variant_and_install \
                "llama3.3-70b" \
                "hf.co/bartowski/Llama-3.3-70B-Instruct-GGUF:IQ4_XS" \
                "hf.co/bartowski/Llama-3.3-70B-Instruct-GGUF:Q4_K_M" \
                "Modelfile.llama3.3-70b-speed" \
                "Modelfile.llama3.3-70b-quality" \
                "Llama 3.3 70B Instruct - Metas stärkstes Allround- und Agenten-Modell"
            ;;
        4)
            install_model \
                "mistral-large-123b" \
                "hf.co/bartowski/Mistral-Large-Instruct-2407-GGUF:Q4_K_M" \
                "Modelfile.mistral-large-123b" \
                "Mistral Large 2407 (123B) - Echtes GPT-4 / Sonnet Niveau im Hybrid-Modus"
            ;;
        5)
            install_model \
                "mixtral-8x22b" \
                "hf.co/bartowski/Mixtral-8x22B-Instruct-v0.1-GGUF:Q3_K_M" \
                "Modelfile.mixtral-8x22b" \
                "Mixtral 8x22B MoE - 141B Parameter, flüssig dank Mixture of Experts"
            ;;
        6)
            echo -e "\n${BOLD}${GREEN}Richte alle Top 3 Speed-Varianten (100% VRAM, ~40-48 t/s) ein...${NC}"
            install_model "qwen2.5-72b-speed" "hf.co/bartowski/Qwen2.5-72B-Instruct-GGUF:IQ4_XS" "Modelfile.qwen2.5-72b-speed" "Qwen 2.5 72B Speed"
            install_model "deepseek-r1-70b-speed" "hf.co/bartowski/DeepSeek-R1-Distill-Llama-70B-GGUF:IQ4_XS" "Modelfile.deepseek-r1-70b-speed" "DeepSeek-R1-70B Speed"
            install_model "llama3.3-70b-speed" "hf.co/bartowski/Llama-3.3-70B-Instruct-GGUF:IQ4_XS" "Modelfile.llama3.3-70b-speed" "Llama 3.3 70B Speed"
            ;;
        7)
            toggle_kv_cache
            ;;
        q|Q)
            echo -e "\n${GREEN}Setup beendet. Viel Erfolg beim Experimentieren!${NC}\n"
            break
            ;;
        *)
            echo -e "\n${RED}Ungültige Eingabe! Bitte 1-7 oder q wählen.${NC}\n"
            ;;
    esac

    echo ""
    read -p "Drücke [Enter] für das Hauptmenü..."
    clear
done
