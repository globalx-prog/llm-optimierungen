#!/usr/bin/env bash
# ==============================================================================
# model-download-setup.sh - Interaktiver Download & Setup für empfohlene LLMs
# Optimiert für: AMD Radeon Pro W7800 (48 GB VRAM) | 61 GB RAM | 32 GB NVMe Swap
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

# Symlink-sichere Ermittlung des Skript- und Modelfile-Verzeichnisses
SCRIPT_REAL="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_REAL_DIR="$(dirname "$SCRIPT_REAL")"

if [ -d "${SCRIPT_REAL_DIR}/../modelfiles" ]; then
    MODELFILES_DIR="$(cd "${SCRIPT_REAL_DIR}/../modelfiles" && pwd)"
elif [ -d "/home/clemi/Projekte/LLM/llm-optimierungen/modelfiles" ]; then
    MODELFILES_DIR="/home/clemi/Projekte/LLM/llm-optimierungen/modelfiles"
else
    MODELFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../modelfiles" && pwd)"
fi

SCRIPTS_DIR="/home/clemi/Projekte/LLM/scripts"

clear 2>/dev/null || true
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
FREE_SPACE_GB=$(df -BG --output=avail /home 2>/dev/null | tail -n1 | tr -dc '0-9' || echo "100")
echo -e "  * Freier Festplattenspeicher (/home): ${GREEN}${FREE_SPACE_GB} GB verfügbar${NC}"
if [ -n "${FREE_SPACE_GB}" ] && [ "${FREE_SPACE_GB}" -lt 50 ]; then
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
    KV_FOUND=$(grep "OLLAMA_KV_CACHE_TYPE" /etc/systemd/system/ollama.service | sed -n 's/.*OLLAMA_KV_CACHE_TYPE=\([^ "]*\).*/\1/p' || true)
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

    if ollama list 2>/dev/null | grep -q "${MODEL_NAME}"; then
        echo -e "${GREEN}✓ Modell '${MODEL_NAME}' ist bereits in Ollama installiert!${NC}"
        link_speculative_model "${MODEL_NAME}"
        return 0
    fi

    read -r -p "Möchtest du dieses Modell jetzt herunterladen und einrichten? (j/n): " CONFIRM || true
    if [[ ! "$CONFIRM" =~ ^[jJyY]$ ]]; then
        echo -e "${YELLOW}Überspringe ${MODEL_NAME}.${NC}\n"
        return 0
    fi

    echo -e "\n${BOLD}[Schritt 1] Lade GGUF-Basisschichten via Ollama herunter...${NC}"
    echo -e "${YELLOW}Hinweis: Der Download umfasst ca. 18–48 GB. Bitte Geduld.${NC}"
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

    # Schritt 5: Spekulatives Decoding bereitstellen
    link_speculative_model "${MODEL_NAME}"

    echo -e "\n${GREEN}${BOLD}✓ Erfolgreich eingerichtet: ${MODEL_NAME}${NC}\n"
}

link_speculative_model() {
    local MODEL_NAME="$1"
    local TARGET_GGUF=""
    local DRAFT_GGUF=""
    local SPEC_NAME=""

    case "$MODEL_NAME" in
        *qwen2.5-72b*)
            TARGET_GGUF="Qwen2.5-72B-Instruct-IQ4_XS.gguf"
            DRAFT_GGUF="Qwen2.5-0.5B-Instruct-Q4_K_M.gguf"
            SPEC_NAME="qwen2.5-72b-speculative"
            ;;
        *deepseek-r1-70b*)
            TARGET_GGUF="DeepSeek-R1-Distill-Llama-70B-IQ4_XS.gguf"
            # DeepSeek R1 nutzt N-Gram Lookup Decoding: 0 MB Zusatz-VRAM!
            DRAFT_GGUF=""
            SPEC_NAME="deepseek-r1-70b-speculative"
            ;;
        *llama3.3-70b-abliterated*)
            TARGET_GGUF="Llama-3.3-70B-Instruct-abliterated-IQ4_XS.gguf"
            DRAFT_GGUF="Llama-3.2-1B-Instruct-Q4_K_M.gguf"
            SPEC_NAME="llama3.3-70b-abliterated-speculative"
            ;;
        *llama3.3-70b*)
            TARGET_GGUF="Llama-3.3-70B-Instruct-IQ4_XS.gguf"
            DRAFT_GGUF="Llama-3.2-1B-Instruct-Q4_K_M.gguf"
            SPEC_NAME="llama3.3-70b-speculative"
            ;;
        *qwen2.5-coder-32b*)
            TARGET_GGUF="Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf"
            DRAFT_GGUF="Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf"
            SPEC_NAME="qwen2.5-coder-32b-speculative"
            ;;
        *qwen3-coder*)
            TARGET_GGUF="Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf"
            DRAFT_GGUF=""
            SPEC_NAME="qwen3-coder-speculative"
            ;;
        *qwen3.8-35b-distill*)
            TARGET_GGUF="Qwen3.8-35B-A3B-Distill-Q6_K.gguf"
            DRAFT_GGUF=""
            SPEC_NAME="qwen3.8-35b-distill"
            ;;
        *)
            return 0
            ;;
    esac

    echo -e "\n${BOLD}[Schritt 5] Bereite Spekulatives Decoding / llama-speedup vor...${NC}"

    # Finde das Hauptmodell-Blob in /home/models/manifests
    local MANIFEST_FILE=""
    local SEARCH_KEY
    SEARCH_KEY=$(echo "$MODEL_NAME" | sed 's/-speed//; s/-quality//')
    MANIFEST_FILE=$(find /home/models/manifests -type f -path "*${SEARCH_KEY}*" 2>/dev/null | head -n1 || true)

    local BLOB_DIGEST=""
    if [ -n "$MANIFEST_FILE" ] && [ -f "$MANIFEST_FILE" ]; then
        if command -v jq >/dev/null 2>&1; then
            BLOB_DIGEST=$(jq -r '.layers[] | select(.mediaType == "application/vnd.ollama.image.model") | .digest' "$MANIFEST_FILE" 2>/dev/null | head -n1 | sed 's/sha256://' || true)
        fi
        if [ -z "$BLOB_DIGEST" ]; then
            BLOB_DIGEST=$(grep -o '"digest":"sha256:[a-f0-9]*"' "$MANIFEST_FILE" | head -n1 | cut -d':' -f3 || true)
        fi
    fi

    if [ -z "$BLOB_DIGEST" ]; then
        BLOB_DIGEST=$(find /home/models/blobs -maxdepth 1 -type f -size +15G -printf "%T@ %f\n" 2>/dev/null | sort -nr | head -n1 | awk '{print $2}' | sed 's/sha256-//' || true)
    fi

    local SOURCE_BLOB="/home/models/blobs/sha256-${BLOB_DIGEST}"
    local TARGET_PATH="/home/models/${TARGET_GGUF}"

    if [ -f "$SOURCE_BLOB" ]; then
        echo -e "  * Erstelle Hardlink auf Hauptmodell: ${TARGET_GGUF}..."
        if ln -f "$SOURCE_BLOB" "$TARGET_PATH" 2>/dev/null; then
            echo -e "    ${GREEN}✓ Hardlink erfolgreich erstellt (0 Byte Zusatzspeicher).${NC}"
        elif command -v docker &>/dev/null; then
            docker run --rm -v /home/models:/models alpine ln -f "/models/blobs/sha256-${BLOB_DIGEST}" "/models/${TARGET_GGUF}" 2>/dev/null || true
            echo -e "    ${GREEN}✓ Hardlink via Docker erstellt (0 Byte Zusatzspeicher).${NC}"
        else
            sudo ln -f "$SOURCE_BLOB" "$TARGET_PATH" 2>/dev/null || true
            echo -e "    ${GREEN}✓ Hardlink erstellt (0 Byte Zusatzspeicher).${NC}"
        fi
    fi

    if [ -n "$DRAFT_GGUF" ]; then
        local DRAFT_PATH="/home/models/${DRAFT_GGUF}"
        if [ -f "$DRAFT_PATH" ]; then
            echo -e "  * ${GREEN}✓ Benötigtes Draft-Modell '${DRAFT_GGUF}' ist vorhanden.${NC}"
        else
            echo -e "  * ${YELLOW}Draft-Modell '${DRAFT_GGUF}' fehlt noch.${NC}"
            local DRAFT_DL_SCRIPT="/home/clemi/Projekte/LLM/llm-optimierungen/llm-speedup/download-draft-models.sh"
            if [ -f "$DRAFT_DL_SCRIPT" ]; then
                echo -e "  * Starte zielgerichteten automatischen Download des passenden Draft-Modells..."
                case "$DRAFT_GGUF" in
                    *0.5B*)
                        bash "$DRAFT_DL_SCRIPT" 2 || true
                        ;;
                    *Llama*1B*)
                        bash "$DRAFT_DL_SCRIPT" 3 || true
                        ;;
                    *Coder*1.5B*)
                        bash "$DRAFT_DL_SCRIPT" 4 || true
                        ;;
                    *)
                        bash "$DRAFT_DL_SCRIPT" || true
                        ;;
                esac
            fi
        fi
    else
        echo -e "  * ${GREEN}✓ N-Gram / MoE Kontext-Lookup aktiv (0 MB zusätzlicher VRAM-Bedarf).${NC}"
    fi

    # Prüfe ob llama-speedup Container läuft, falls nicht starte ihn
    local CTRL="/home/clemi/Projekte/LLM/llm-optimierungen/llm-speedup/speedup-control.sh"
    if [ -f "$CTRL" ]; then
        if ! curl -s "http://127.0.0.1:5002/v1/models" >/dev/null 2>&1; then
            echo -e "  * Starte llama-speedup Container im Hintergrund..."
            bash "$CTRL" start >/dev/null 2>&1 || true
        fi
    fi

    echo -e "\n${BOLD}${GREEN}✔ Für Spekulatives Decoding erfolgreich vorbereitet!${NC}"
    echo -e "  * Modell-ID:          ${BOLD}${CYAN}${SPEC_NAME}${NC}"
    echo -e "  * OpenAI API (lokal): ${GREEN}http://127.0.0.1:5002/v1${NC} (Bearer: llama-swap)"
    echo -e "  * In Open WebUI:      ${GREEN}http://llama-speedup:8080/v1${NC} (sofort einsatzbereit)\n"
}

ask_variant_and_install() {
    local BASE_NAME="$1"
    local IQ4_TAG="$2"
    local Q4KM_TAG="$3"
    local SPEED_FILE="$4"
    local QUALITY_FILE="$5"
    local DESC="$6"

    # Schneller Einstieg falls das Modell bereits lokal installiert ist:
    if ollama list 2>/dev/null | grep -q "${BASE_NAME}-speed"; then
        echo -e "\n${BOLD}${GREEN}======================================================================${NC}"
        echo -e "${BOLD}${GREEN}✓ Modell '${BASE_NAME}-speed' ist bereits in Ollama vorhanden!${NC}"
        echo -e "${BOLD}${GREEN}======================================================================${NC}"
        echo -e "  * Richte Verknüpfung für Spekulatives Decoding (llm-speedup) ein..."
        link_speculative_model "${BASE_NAME}-speed"
        return 0
    fi

    echo -e "\n${BOLD}${YELLOW}Welche Variante von ${BASE_NAME} möchtest du installieren?${NC}"
    echo -e "  ${BOLD}1)${NC} ${GREEN}Speed-Variante (Optimiert für 100% VRAM - EMPFOHLEN)${NC}"
    echo -e "     -> Alle Layer auf W7800 GPU, keine PCIe-Drossel"
    echo -e "     -> Höchste Geschwindigkeit & minimale Latenz"
    echo -e "  ${BOLD}2)${NC} ${BLUE}Quality-Variante (Höhere Präzision)${NC}"
    echo -e "     -> Nahezu FP16-Präzision (Q4_K_M oder Q8_0)"
    echo -e "  ${BOLD}3)${NC} Beide Varianten installieren"
    echo -e "  ${BOLD}4)${NC} Zurück zum Hauptmenü"

    read -r -p "Auswahl (1-4): " VAR_CHOICE || true
    case "$VAR_CHOICE" in
        1)
            install_model "${BASE_NAME}-speed" "${IQ4_TAG}" "${SPEED_FILE}" "${DESC} (Speed - 100% VRAM)"
            ;;
        2)
            install_model "${BASE_NAME}-quality" "${Q4KM_TAG}" "${QUALITY_FILE}" "${DESC} (Quality - Maximale Präzision)"
            ;;
        3)
            install_model "${BASE_NAME}-speed" "${IQ4_TAG}" "${SPEED_FILE}" "${DESC} (Speed)"
            install_model "${BASE_NAME}-quality" "${Q4KM_TAG}" "${QUALITY_FILE}" "${DESC} (Quality)"
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

    read -r -p "Gewünschter Modus (1-3): " KV_CHOICE || true
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

set_gpu_mode() {
    local TARGET_MODE="$1"
    if [ "$TARGET_MODE" == "daily" ]; then
        local SCRIPT="${SCRIPTS_DIR}/set-gpu-mode-daily.sh"
        if [ -f "$SCRIPT" ]; then
            bash "$SCRIPT"
        else
            echo -e "${RED}[FEHLER] Skript nicht gefunden: ${SCRIPT}${NC}"
        fi
    elif [ "$TARGET_MODE" == "performance" ]; then
        local SCRIPT="${SCRIPTS_DIR}/set-gpu-mode-performance.sh"
        if [ -f "$SCRIPT" ]; then
            bash "$SCRIPT"
        else
            echo -e "${RED}[FEHLER] Skript nicht gefunden: ${SCRIPT}${NC}"
        fi
    fi
}

show_gpu_status() {
    local SCRIPT="${SCRIPTS_DIR}/gpu-status.sh"
    if [ -f "$SCRIPT" ]; then
        bash "$SCRIPT"
    else
        echo -e "${RED}[FEHLER] Status-Skript nicht gefunden: ${SCRIPT}${NC}"
    fi
}

manage_gpu_fan() {
    local SCRIPT="${SCRIPTS_DIR}/gpu-fan-control.sh"
    if [ ! -f "$SCRIPT" ]; then
        echo -e "${RED}[FEHLER] Skript nicht gefunden: ${SCRIPT}${NC}"
        return 1
    fi

    echo -e "\n${BOLD}${CYAN}======================================================================${NC}"
    echo -e "${BOLD}${CYAN}          🌀 AMD W7800 LÜFTER- & KÜHLUNGS-MENÜ                       ${NC}"
    echo -e "${BOLD}${CYAN}======================================================================${NC}"
    echo -e "  1) 🔇 Silent          (35% Blower, ~1600 RPM, flüsterleise ~34 dB)"
    echo -e "  2) ⚖️  Balanced        (50% Blower, ~2300 RPM, sanftes Rauschen ~42 dB)"
    echo -e "  3) 🚀 Performance     (65% Blower, ~3000 RPM, Sweet-Spot 230W, Junction <76°C)"
    echo -e "  4) 🌪️ Max Cooling     (85% Blower, ~4000 RPM, extreme Kühlung ~60 dB)"
    echo -e "  5) 🔄 Auto (vBIOS)    (Lüftersteuerung an Werk-vBIOS übergeben)"
    echo -e "  6) 🌡️ Dynamische Kurve (Live-Wächter im Vordergrund, Strg+C stoppt)"
    echo -e "  7) 🤖 Wächter-Daemon  (Hintergrund-Überwachung starten)"
    echo -e "  8) 🛑 Daemon stoppen  (Hintergrund-Wächter beenden & auf Auto zurücksetzen)"
    echo -e "  9) 🔧 Udev-Regel      (Einmalig Rootless-Rechte ohne sudo einrichten)"
    echo -e "  s) 📊 Status anzeigen (Live-Temperaturen, Drehzahlen, LACT-Check)"
    echo -e "  z) ↩️  Zurück zum Hauptmenü"
    echo -e "${BOLD}${CYAN}======================================================================${NC}"

    read -r -p "Auswahl (1-9, s, z): " FAN_CHOICE || true

    case "$FAN_CHOICE" in
        1) bash "$SCRIPT" silent ;;
        2) bash "$SCRIPT" balanced ;;
        3) bash "$SCRIPT" performance ;;
        4) bash "$SCRIPT" max ;;
        5) bash "$SCRIPT" auto ;;
        6) bash "$SCRIPT" curve ;;
        7) bash "$SCRIPT" daemon ;;
        8) bash "$SCRIPT" daemon-stop ;;
        9) bash "$SCRIPT" install-udev ;;
        s|S) bash "$SCRIPT" status ;;
        *) echo -e "${YELLOW}Zurück zum Hauptmenü.${NC}" ;;
    esac
}

# 3. Interaktives Hauptmenü
while true; do
    echo -e "${BOLD}${YELLOW}======================================================================${NC}"
    echo -e "${BOLD}${YELLOW}       👑 MODELL-DOWNLOAD & STELLSCHRAUBEN-SETUP (W7800 48GB)         ${NC}"
    echo -e "${BOLD}${YELLOW}======================================================================${NC}"
    echo -e "  ${BOLD}[Top Flaggschiff-Modelle (70B / 72B)]${NC}"
    echo -e "  ${BOLD}1)${NC} 👑 ${CYAN}Qwen 2.5 72B Instruct${NC}          (🥇 Nr. 1 für Coding, Cline & Tools)"
    echo -e "  ${BOLD}2)${NC} 🧠 ${CYAN}DeepSeek-R1-Distill-70B${NC}        (🥇 Nr. 1 für Deep Reasoning & Mathe)"
    echo -e "  ${BOLD}3)${NC} 🌐 ${CYAN}Llama 3.3 70B Instruct${NC}         (🥇 Nr. 1 für Agenten, RAG & Allround)"
    echo -e "  ${BOLD}4)${NC} 🔓 ${RED}Llama 3.3 70B Abliterated${NC}      (🔥 Stärkstes unzensiertes 70B ohne Guardrails)"
    echo -e ""
    echo -e "  ${BOLD}[High-Speed Sweet Spot & Coder (~55 – 110 t/s)]${NC}"
    echo -e "  ${BOLD}5)${NC} ⚡ ${GREEN}Qwen 3.8 35B Distill${NC}           (🚀 Alltags-Sweet-Spot, gemessene ~65 t/s, 64k!)"
    echo -e "  ${BOLD}6)${NC} 💻 ${GREEN}Qwen 3 Coder 30B (MoE)${NC}          (⚡ Ultra-Speed MoE Coder, ~80–110 t/s, 3.3B aktiv)"
    echo -e "  ${BOLD}7)${NC} 💻 ${CYAN}Qwen 2.5 Coder 32B (Speculative)${NC} (⚡ Bewährter Dense Coder, ~55–65 t/s mit 1.5B Draft)"
    echo -e ""
    echo -e "  ${BOLD}[MoE & Hybrid-Schwergewichte (100B+)]${NC}"
    echo -e "  ${BOLD}8)${NC} 🔀 ${BLUE}Mixtral 8x7B Instruct${NC}          (Schnelles 47B MoE Modell, ~35–50 t/s)"
    echo -e "  ${BOLD}9)${NC} 🔀 ${BLUE}Mixtral 8x22B (141B MoE)${NC}       (141B MoE Gigant, flüssig dank MoE)"
    echo -e "  ${BOLD}10)${NC} 🐘 ${BLUE}Mistral Large 2407 (123B)${NC}     (Monumentales 123B Hybrid-Modell)"
    echo -e "  --------------------------------------------------------------------"
    echo -e "  ${BOLD}[Paket-Downloads]${NC}"
    echo -e "  ${BOLD}A)${NC} 🚀 ${GREEN}ALLE TOP 3 SPEED-MODELLE AUF EINMAL${NC} (Qwen 72B + R1 70B + Llama 70B)"
    echo -e "  ${BOLD}B)${NC} ⚡ ${GREEN}CODING-SPEED-DUO${NC}                   (Qwen 3 Coder 30B MoE + Qwen 3.8 35B)"
    echo -e "  --------------------------------------------------------------------"
    echo -e "  ${BOLD}[Hardware & Performance Stellschrauben]${NC}"
    echo -e "  ${BOLD}G)${NC} 🍃 ${CYAN}GPU Normalbetrieb setzen${NC}       (200W, leise & kühl, Junction <90°C)"
    echo -e "  ${BOLD}P)${NC} 🚀 ${YELLOW}GPU Hochleistung setzen${NC}        (230W uncapped, kein Throttling)"
    echo -e "  ${BOLD}F)${NC} 🌀 ${CYAN}Lüfter- & Kühlprofile${NC}          (Silent / Balanced / Performance / Dynamische Kurve)"
    echo -e "  ${BOLD}S)${NC} 📊 ${GREEN}GPU-Status & Throttling prüfen${NC} (Taktrate, Hotspot-Temperatur, Power)"
    echo -e "  ${BOLD}K)${NC} ⚙️  ${YELLOW}KV-Cache Modus umschalten${NC}      (q4_0 vs q8_0, aktuell: ${BOLD}${GREEN}${CURRENT_KV}${NC})"
    echo -e "  ${BOLD}T)${NC} ⏱️  ${GREEN}LLM-Speed & Kontext-Benchmark${NC}  (Alle Modelle, Teilgruppen, beliebige Kontextgröße)"
    echo -e "  ${BOLD}C)${NC} 🧹 ${CYAN}Festplatten-Bereinigung${NC}        (Alte Caches & ungenutzte Schichten leeren)"
    echo -e "  ${BOLD}q)${NC} Beenden"
    echo -e "${BOLD}${YELLOW}======================================================================${NC}"

    read -r -p "Deine Auswahl (1-10, A-B, G/P/F/S/K/T/C oder q): " MAIN_CHOICE || true

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
            ask_variant_and_install \
                "llama3.3-70b-abliterated" \
                "hf.co/bartowski/Llama-3.3-70B-Instruct-abliterated-GGUF:IQ4_XS" \
                "hf.co/bartowski/Llama-3.3-70B-Instruct-abliterated-GGUF:Q4_K_M" \
                "Modelfile.llama3.3-70b-abliterated-speed" \
                "Modelfile.llama3.3-70b-abliterated-quality" \
                "Llama 3.3 70B Abliterated - Stärkstes unzensiertes Modell der Welt"
            ;;
        5)
            install_model \
                "qwen3.8-35b-distill" \
                "hf.co/empero-ai/Qwen3.8-35B-A3B-Distill-GGUF:Q6_K" \
                "Modelfile.qwen3.8-35b-distill" \
                "Qwen 3.8 35B Distill - Alltags-Sweet-Spot für 48GB VRAM (gemessene ~65 t/s, 64k Kontext)"
            ;;
        6)
            ask_variant_and_install \
                "qwen3-coder" \
                "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M" \
                "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q8_0" \
                "Modelfile.qwen3-coder-speed" \
                "Modelfile.qwen3-coder-quality" \
                "Qwen 3 Coder 30B (MoE) - Blitzschneller Agenten-Coder (~80-110 t/s)"
            ;;
        7)
            ask_variant_and_install \
                "qwen2.5-coder-32b" \
                "hf.co/bartowski/Qwen2.5-Coder-32B-Instruct-GGUF:Q4_K_M" \
                "hf.co/bartowski/Qwen2.5-Coder-32B-Instruct-GGUF:Q8_0" \
                "Modelfile.qwen2.5-coder-32b-speed" \
                "Modelfile.qwen2.5-coder-32b-quality" \
                "Qwen 2.5 Coder 32B - Bewährter High-Speed Coder (inkl. Spekulatives Decoding ~60 t/s)"
            ;;
        8)
            install_model \
                "mixtral-8x7b" \
                "hf.co/TheBloke/Mixtral-8x7B-Instruct-v0.1-GGUF:Q4_K_M" \
                "Modelfile.mixtral-8x7b" \
                "Mixtral 8x7B Instruct - 47B MoE (13B aktiv), flüssige ~35-50 t/s"
            ;;
        9)
            install_model \
                "mixtral-8x22b" \
                "hf.co/bartowski/Mixtral-8x22B-Instruct-v0.1-GGUF:Q3_K_M" \
                "Modelfile.mixtral-8x22b" \
                "Mixtral 8x22B MoE - 141B Parameter, flüssig dank Mixture of Experts"
            ;;
        10)
            install_model \
                "mistral-large-123b" \
                "hf.co/bartowski/Mistral-Large-Instruct-2407-GGUF:Q4_K_M" \
                "Modelfile.mistral-large-123b" \
                "Mistral Large 2407 (123B) - Echtes GPT-4 / Sonnet Niveau im Hybrid-Modus"
            ;;
        a|A)
            echo -e "\n${BOLD}${GREEN}Richte alle Top 3 Speed-Varianten (100% VRAM, ~40-48 t/s) ein...${NC}"
            install_model "qwen2.5-72b-speed" "hf.co/bartowski/Qwen2.5-72B-Instruct-GGUF:IQ4_XS" "Modelfile.qwen2.5-72b-speed" "Qwen 2.5 72B Speed"
            install_model "deepseek-r1-70b-speed" "hf.co/bartowski/DeepSeek-R1-Distill-Llama-70B-GGUF:IQ4_XS" "Modelfile.deepseek-r1-70b-speed" "DeepSeek-R1-70B Speed"
            install_model "llama3.3-70b-speed" "hf.co/bartowski/Llama-3.3-70B-Instruct-GGUF:IQ4_XS" "Modelfile.llama3.3-70b-speed" "Llama 3.3 70B Speed"
            ;;
        b|B)
            echo -e "\n${BOLD}${GREEN}Richte das Coding-Speed-Duo (~65 - 110 t/s) ein...${NC}"
            install_model "qwen3-coder-speed" "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M" "Modelfile.qwen3-coder-speed" "Qwen 3 Coder Speed (MoE ~80-110 t/s)"
            install_model "qwen3.8-35b-distill" "hf.co/empero-ai/Qwen3.8-35B-A3B-Distill-GGUF:Q6_K" "Modelfile.qwen3.8-35b-distill" "Qwen 3.8 35B Distill (~65 t/s)"
            ;;
        g|G)
            set_gpu_mode "daily"
            ;;
        p|P)
            set_gpu_mode "performance"
            ;;
        f|F)
            manage_gpu_fan
            ;;
        s|S)
            show_gpu_status
            ;;
        k|K)
            toggle_kv_cache
            ;;
        t|T)
            BENCH="${SCRIPTS_DIR}/benchmark-speeds.sh"
            if [ -f "$BENCH" ]; then
                bash "$BENCH"
            else
                echo -e "${RED}[FEHLER] Benchmark-Skript nicht gefunden: ${BENCH}${NC}"
            fi
            ;;
        c|C)
            CLEANUP="${SCRIPTS_DIR}/system-disk-cleanup.sh"
            if [ -f "$CLEANUP" ]; then
                bash "$CLEANUP"
            else
                echo -e "${RED}[FEHLER] Cleanup-Skript nicht gefunden: ${CLEANUP}${NC}"
            fi
            ;;
        q|Q)
            echo -e "\n${GREEN}Setup beendet. Viel Erfolg beim Experimentieren!${NC}\n"
            break
            ;;
        *)
            echo -e "\n${RED}Ungültige Eingabe! Bitte eine der Menüoptionen wählen.${NC}\n"
            ;;
    esac

    echo ""
    read -r -p "Drücke [Enter] für das Hauptmenü..." || true
    clear 2>/dev/null || true
done

