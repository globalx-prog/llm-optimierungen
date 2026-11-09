#!/usr/bin/env bash
# ==============================================================================
# System Disk Cleanup & Docker/Containerd Migration nach /home
# ==============================================================================
# 1. Migriert containerd Image-Store & Snapshots (9.8 GB) nach /home/containerd
# 2. Begrenzt Systemd-Journals dauerhaft auf 300 MB
# 3. Entfernt ungenutzte Nvidia CUDA-Bibliotheken aus Ollama (~2.0 GB)
# 4. Bereinigt Crash-Dumps und APT Caches (~300 MB)
# 5. Entfernt veraltete Snap-Revisions (~3.5 GB)
# ==============================================================================
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "=========================================================="
    echo "  FEHLER: Dieses Skript muss mit Root-Rechten laufen!"
    echo "  Bitte ausführen mit: sudo bash $0"
    echo "=========================================================="
    exit 1
fi

echo "=========================================================="
echo "  1. SPEICHERPLATZ VOR DER BEREINIGUNG"
echo "=========================================================="
df -h /
echo ""

# ------------------------------------------------------------------------------
# 1. Containerd Image-Store nach /home migrieren (LÖST DAS SPEEDUP-PROBLEM!)
# ------------------------------------------------------------------------------
echo "=========================================================="
echo "  2. CONTAINERO NACH /home MIGRIEREN (~9.8 GB frei)"
echo "=========================================================="
if [ -d /var/lib/containerd ] && [ ! -L /var/lib/containerd ]; then
    echo "Stoppe Docker und containerd..."
    systemctl stop docker.socket docker containerd

    echo "Kopiere containerd Daten nach /home/containerd..."
    mkdir -p /home/containerd
    cp -a /var/lib/containerd/. /home/containerd/

    echo "Lösche altes /var/lib/containerd von der Root-Partition..."
    rm -rf /var/lib/containerd

    echo "Erstelle Symlink /var/lib/containerd -> /home/containerd..."
    ln -s /home/containerd /var/lib/containerd

    if [ -f /etc/containerd/config.toml ]; then
        if grep -q "root = " /etc/containerd/config.toml; then
            sed -i 's|^#*root = .*|root = "/home/containerd"|' /etc/containerd/config.toml
        else
            echo 'root = "/home/containerd"' >> /etc/containerd/config.toml
        fi
    fi

    echo "Starte containerd und Docker neu..."
    systemctl start containerd docker
    echo "✓ containerd erfolgreich nach /home migriert! Zukünftige Images landen auf /home."
else
    echo "containerd ist bereits verlinkt oder migriert."
fi
echo ""

# ------------------------------------------------------------------------------
# 2. Systemd-Journal dauerhaft auf 300 MB begrenzen
# ------------------------------------------------------------------------------
echo "=========================================================="
echo "  3. SYSTEMD-JOURNAL AUF 300 MB BEGRENZEN (~800 MB frei)"
echo "=========================================================="
mkdir -p /etc/systemd/journald.conf.d
cat <<EOF > /etc/systemd/journald.conf.d/00-journal-size.conf
[Journal]
SystemMaxUse=300M
EOF

systemctl restart systemd-journald
journalctl --vacuum-size=300M
echo "✓ Journald dauerhaft auf max. 300 MB konfiguriert und bereinigt."
echo ""

# ------------------------------------------------------------------------------
# 3. Ungenutzte Nvidia CUDA-Bibliotheken aus Ollama entfernen
# ------------------------------------------------------------------------------
echo "=========================================================="
echo "  4. UNGENUTZTE CUDA-RUNNER AUS OLLAMA ENTFERNEN (~2.0 GB frei)"
echo "=========================================================="
OLLAMA_LIB="/usr/local/lib/ollama"
FREED_CUDA=0
if [ -d "$OLLAMA_LIB/cuda_v12" ]; then
    echo "Entferne $OLLAMA_LIB/cuda_v12 (~1.2 GB)..."
    rm -rf "$OLLAMA_LIB/cuda_v12"
    FREED_CUDA=1
fi

if [ -d "$OLLAMA_LIB/cuda_v13" ]; then
    echo "Entferne $OLLAMA_LIB/cuda_v13 (~812 MB)..."
    rm -rf "$OLLAMA_LIB/cuda_v13"
    FREED_CUDA=1
fi

if [ "$FREED_CUDA" -eq 1 ]; then
    echo "✓ Ungenutzte CUDA-Bibliotheken entfernt (AMD ROCm v7.2 und Vulkan bleiben aktiv)."
else
    echo "Keine ungenutzten CUDA-Bibliotheken vorhanden."
fi
echo ""

# ------------------------------------------------------------------------------
# 4. Crash-Dumps und Logs bereinigen
# ------------------------------------------------------------------------------
echo "=========================================================="
echo "  5. CRASH-DUMPS BEREINIGEN (~45 MB frei)"
echo "=========================================================="
if [ -d "/var/crash" ]; then
    rm -f /var/crash/* 2>/dev/null || true
    echo "✓ /var/crash bereinigt."
fi
echo ""

# ------------------------------------------------------------------------------
# 5. APT Caches und veraltete Pakete säubern
# ------------------------------------------------------------------------------
echo "=========================================================="
echo "  6. APT CACHES & ALTE KERNEL BEREINIGEN (~250 MB frei)"
echo "=========================================================="
apt-get clean
apt-get autoremove --purge -y
echo "✓ APT bereinigt."
echo ""

# ------------------------------------------------------------------------------
# 6. Alte Snap-Revisions entfernen
# ------------------------------------------------------------------------------
echo "=========================================================="
echo "  7. ALTE SNAP-REVISIONS BEREINIGEN (~3.5 GB frei)"
echo "=========================================================="
if command -v snap &>/dev/null; then
    snap set system refresh.retain=2 2>/dev/null || true
    snap list --all | awk '/deaktiviert|disabled/{print $1, $3}' | while read -r snapname revision; do
        if [ -n "$snapname" ] && [ -n "$revision" ]; then
            echo "Entferne alte Revision: $snapname (rev $revision)..."
            snap remove "$snapname" --revision="$revision" || true
        fi
    done
    echo "✓ Veraltete Snap-Revisions entfernt."
fi
echo ""

# ------------------------------------------------------------------------------
# 7. Symlink für Docker CLI sicherstellen
# ------------------------------------------------------------------------------
if [ ! -L /usr/local/bin/docker ]; then
    ln -sf /usr/bin/docker /usr/local/bin/docker
fi

# ------------------------------------------------------------------------------
# Ergebnis
# ------------------------------------------------------------------------------
echo "=========================================================="
echo "  BEREINIGUNG & MIGRATION ERFOLGREICH ABGESCHLOSSEN!"
echo "=========================================================="
echo "Speicherplatz nach der Bereinigung:"
df -h / /home
