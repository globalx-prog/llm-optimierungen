#!/usr/bin/env bash
# ==============================================================================
# Öffnet die Modell-Vergleichsmatrix direkt in LibreOffice Calc
# ==============================================================================

ODS_FILE="/home/clemi/Projekte/LLM/vergleichsmatrix_lokal_vs_cloud.ods"

if command -v flatpak &>/dev/null && flatpak list 2>/dev/null | grep -q "org.libreoffice.LibreOffice"; then
    echo "Öffne $ODS_FILE in LibreOffice Calc..."
    flatpak run org.libreoffice.LibreOffice "$ODS_FILE" >/dev/null 2>&1 &
elif command -v localc &>/dev/null; then
    localc "$ODS_FILE" &
elif command -v libreoffice &>/dev/null; then
    libreoffice --calc "$ODS_FILE" &
else
    xdg-open "$ODS_FILE" &
fi

