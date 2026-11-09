#!/usr/bin/env bash
# ==============================================================================
# 🌀 gpu-fan-control.sh — Intelligente Lüftersteuerung für AMD Radeon PRO W7800
# ==============================================================================
# Speziell abgestimmt auf das LLM- und Video-Setup mit LACT-Koexistenz.
#
# Profile:
#   silent      - 35% Blower (~1600 RPM, flüsterleise ~34 dB, Office/Idle)
#   balanced    - 50% Blower (~2300 RPM, sanftes Rauschen ~42 dB, Daily LLM)
#   performance - 65% Blower (~3000 RPM, ~50 dB, optimal für 230W Volllast, Junction <76°C)
#   max         - 85% Blower (~4000 RPM, ~60 dB, extreme Kühlung / Sommer)
#   auto        - Übergibt Steuerung an das vBIOS zurück (Werkszustand)
#   curve       - Dynamische Lüfterkurve im Vordergrund (Live-Monitor, Strg+C stoppt)
#   daemon      - Startet dynamische Lüfterkurve im Hintergrund
#   daemon-stop - Stoppt Hintergrund-Wächter und schaltet auf Automatik
#   status      - Zeigt Edge-, Hotspot-, VRAM-Temperatur, RPM, PWM & LACT-Status
#   set-fan <%> - Setzt manuellen Wert zwischen 15% und 100%
#   install-udev- Installiert udev-Regel für Rootless-Steuerung (ohne sudo)
# ==============================================================================

set -e

PID_FILE="/tmp/w7800-fan-curve.pid"
LOG_FILE="/tmp/w7800-fan-curve.log"
LACT_CONFIG="/etc/lact/config.yaml"

# 1. Hardware-Pfade dynamisch ermitteln
CARD_DIR=""
for c in /sys/class/drm/card[0-9]*/device; do
    if [ -f "$c/pp_power_profile_mode" ] || [ -f "$c/power_dpm_force_performance_level" ]; then
        CARD_DIR="$c"
        break
    fi
done

HWMON_DIR=""
if [ -n "$CARD_DIR" ]; then
    for h in "$CARD_DIR"/hwmon/hwmon*; do
        if [ -f "$h/pwm1" ]; then
            HWMON_DIR="$h"
            break
        fi
    done
fi

if [ -z "$HWMON_DIR" ] || [ ! -f "$HWMON_DIR/pwm1" ]; then
    echo "❌ FEHLER: Kein kompatibles AMD hwmon-Device mit pwm1-Lüftersteuerung gefunden!" >&2
    exit 1
fi

PWM_FILE="$HWMON_DIR/pwm1"
PWM_ENABLE="$HWMON_DIR/pwm1_enable"
TEMP_EDGE="$HWMON_DIR/temp1_input"
TEMP_JUNC="$HWMON_DIR/temp2_input"
TEMP_VRAM="$HWMON_DIR/temp3_input"
FAN_RPM="$HWMON_DIR/fan1_input"
POWER_AVG="$HWMON_DIR/power1_average"
POWER_CAP="$HWMON_DIR/power1_cap"

# Prüfe Schreibberechtigung für sysfs
can_write() {
    [ -w "$PWM_FILE" ] && [ -w "$PWM_ENABLE" ]
}

# Sicheres Schreiben in Sysfs
write_sysfs() {
    local file="$1"
    local value="$2"
    if [ -w "$file" ]; then
        echo "$value" > "$file" 2>/dev/null
        return 0
    fi

    # Falls sudo ohne Passwort (oder als root) möglich ist
    if sudo -n true 2>/dev/null; then
        echo "$value" | sudo -n tee "$file" > /dev/null 2>&1
        return 0
    fi

    echo "⚠️  Keine direkten Schreibrechte für $file." >&2
    echo "💡 Lösung: Entweder mit 'sudo' ausführen ODER einmalig die udev-Regel installieren:" >&2
    echo "   sudo /home/clemi/Projekte/LLM/scripts/gpu-fan-control.sh install-udev" >&2
    echo "   (Danach kann der Lüfter dauerhaft ohne Passwort gesteuert werden!)" >&2
    return 1
}

# LACT-Konflikt-Diagnose
check_lact_conflict() {
    if [ -f "$LACT_CONFIG" ]; then
        if grep -q "fan_control_enabled: true" "$LACT_CONFIG" 2>/dev/null; then
            echo "⚠️  WARNUNG: In LACT ist 'fan_control_enabled: true' aktiv!"
            echo "   LACT und dieses Skript könnten um pwm1 konkurrieren."
            echo "   Empfehlung: Im LACT-GUI die Lüftersteuerung auf 'Default/Automatic' stellen"
            echo "   oder 'fan_control_enabled: false' in $LACT_CONFIG setzen."
            return 1
        fi
    fi
    return 0
}

show_status() {
    echo "=================================================================="
    echo " 📊 AMD RADEON PRO W7800 (48 GB) — LÜFTER- & TEMPERATUR-STATUS"
    echo "=================================================================="
    echo " Hardware-Pfad: $HWMON_DIR"
    echo ""

    # Temperaturen
    edge=0; junc=0; vram=0
    [ -f "$TEMP_EDGE" ] && edge=$(( $(cat "$TEMP_EDGE" 2>/dev/null || echo 0) / 1000 ))
    [ -f "$TEMP_JUNC" ] && junc=$(( $(cat "$TEMP_JUNC" 2>/dev/null || echo 0) / 1000 ))
    [ -f "$TEMP_VRAM" ] && vram=$(( $(cat "$TEMP_VRAM" 2>/dev/null || echo 0) / 1000 ))

    echo " 🌡️ Temperaturen:"
    echo "   • Edge-Temperatur:     ${edge}°C"
    echo "   • Junction / Hotspot:  ${junc}°C  (Kritischer Sensor für Throttling)"
    echo "   • VRAM-Temperatur:     ${vram}°C"

    # Lüfter-Telemetrie
    rpm="N/A"
    [ -f "$FAN_RPM" ] && rpm="$(cat "$FAN_RPM" 2>/dev/null || echo N/A) RPM"
    pwm_val=$(cat "$PWM_FILE" 2>/dev/null || echo 0)
    pwm_en=$(cat "$PWM_ENABLE" 2>/dev/null || echo 2)
    pwm_pct=$((pwm_val * 100 / 255))

    mode_str="Automatik (vBIOS-Kurve)"
    [ "$pwm_en" = "1" ] && mode_str="Manuell fixiert / Skript-Kurve"

    echo ""
    echo " 🌀 Blower-Lüfter:"
    echo "   • Drehzahl:            $rpm"
    echo "   • Leistung (PWM):      ${pwm_pct}% (PWM ${pwm_val}/255)"
    echo "   • Steuerungsmodus:     $mode_str"

    # Power
    if [ -f "$POWER_CAP" ]; then
        cur_p=$(( $(cat "$POWER_CAP" 2>/dev/null || echo 0) / 1000000 ))
        avg_p=$(( $(cat "$POWER_AVG" 2>/dev/null || echo 0) / 1000000 ))
        echo ""
        echo " ⚡ Leistungsaufnahme:"
        echo "   • Aktuelles Limit:     ${cur_p} W"
        echo "   • Reale Last:          ${avg_p} W"
    fi

    # Daemon Status
    echo ""
    echo " 🤖 Dynamischer Wächter-Daemon:"
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
        echo "   • Status:              AKTIV (PID $(cat "$PID_FILE"))"
    else
        echo "   • Status:              Inaktiv"
    fi

    # LACT Koexistenz-Prüfung
    echo ""
    echo " 🔗 LACT-Integration:"
    if [ -f "$LACT_CONFIG" ]; then
        if grep -q "fan_control_enabled: true" "$LACT_CONFIG" 2>/dev/null; then
            echo "   • LACT-Lüfter:         ⚠️ AKTIV (Möglicher Konflikt: lactd überschreibt alle 5s)"
        else
            echo "   • LACT-Lüfter:         ✅ Inaktiv (Kein Konflikt: LACT regelt Power, Skript regelt Lüfter)"
        fi
    else
        echo "   • LACT-Config:         Nicht gefunden (sysfs direkt)"
    fi

    if can_write; then
        echo "   • Schreibrechte:       ✅ Rootless aktiv (Steuerung ohne sudo möglich)"
    else
        echo "   • Schreibrechte:       ℹ️ sudo erforderlich (Nutze '$0 install-udev' für Rootless)"
    fi
    echo "=================================================================="
}

set_fan_pct() {
    local pct="$1"
    local label="$2"

    if [ -z "$pct" ] || [ "$pct" -lt 15 ] || [ "$pct" -gt 100 ]; then
        echo "❌ Ungültiger Prozentwert: '$pct' (Gültig: 15 bis 100%)"
        exit 1
    fi

    # Falls Wächter läuft und ein manuelles Profil gewählt wird, Daemon stoppen
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
        echo "ℹ️  Stoppe aktiven Hintergrund-Wächter (PID $(cat "$PID_FILE"))..."
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi

    check_lact_conflict || true

    local pwm=$((pct * 255 / 100))
    echo "* Schalte auf manuellen Modus (pwm1_enable=1)..."
    if ! write_sysfs "$PWM_ENABLE" "1"; then
        echo "❌ Fehler beim Umschalten auf manuellen Lüftermodus." >&2
        return 1
    fi
    sleep 0.1
    echo "* Setze Lüfterdrehzahl auf ${pct}% (PWM ${pwm}/255)${label:+ ($label)}..."
    if ! write_sysfs "$PWM_FILE" "$pwm"; then
        echo "❌ Fehler beim Setzen der Lüfterdrehzahl." >&2
        return 1
    fi

    sleep 0.5
    rpm="N/A"
    [ -f "$FAN_RPM" ] && rpm="$(cat "$FAN_RPM" 2>/dev/null || echo N/A) RPM"
    echo "✅ Erfolgreich: Lüfter auf ${pct}% (${rpm}) gesetzt."
}

set_fan_auto() {
    # Falls Wächter läuft, stoppen
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
        echo "ℹ️  Stoppe aktiven Hintergrund-Wächter (PID $(cat "$PID_FILE"))..."
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi

    echo "* Übergebe Lüftersteuerung an vBIOS-Automatik (pwm1_enable=2)..."
    if ! write_sysfs "$PWM_ENABLE" "2"; then
        echo "❌ Fehler beim Umschalten auf vBIOS-Automatik." >&2
        return 1
    fi
    sleep 0.5
    echo "✅ Lüftersteuerung wieder an Hardware-vBIOS übergeben."
}

# Dynamische Kurve basierend auf Junction-Temperatur
run_curve_loop() {
    echo "=================================================================="
    echo "🌡️ DYNAMISCHE HYSTERESE-LÜFTERKURVE AKTIV"
    echo "=================================================================="
    echo " Regel-Logik (Hotspot / Junction):"
    echo "   < 50°C   -> 35% (Flüsterleise im Idle)"
    echo "   50-59°C  -> 45% (Sanftes Anlaufen bei Teillast)"
    echo "   60-69°C  -> 55% (Angenehmes Rauschen bei LLM Token-Gen)"
    echo "   70-79°C  -> 65% (Sweet-Spot für 230W Volllast / Prefill)"
    echo "   80-87°C  -> 78% (Aktiver Hitzeschutz gegen Drosselung)"
    echo "   >= 88°C  -> 90-100% (Notfall-Turbine gegen 95°C+ Junction)"
    echo "=================================================================="
    echo " Drücke Strg+C zum Beenden (stellt automatisch vBIOS-Modus wieder her)."
    echo ""

    trap 'echo ""; echo "Beende Wächter und stelle vBIOS-Automatik wieder her..."; write_sysfs "$PWM_ENABLE" "2"; rm -f "$PID_FILE"; exit 0' INT TERM EXIT

    write_sysfs "$PWM_ENABLE" "1"

    local last_pwm=-1
    while true; do
        junc_raw=$(cat "$TEMP_JUNC" 2>/dev/null || echo 0)
        edge_raw=$(cat "$TEMP_EDGE" 2>/dev/null || echo 0)
        vram_raw=$(cat "$TEMP_VRAM" 2>/dev/null || echo 0)

        junc=$((junc_raw / 1000))
        edge=$((edge_raw / 1000))
        vram=$((vram_raw / 1000))

        ref_temp=$junc
        [ "$ref_temp" -le 0 ] && ref_temp=$edge

        if [ "$ref_temp" -lt 50 ]; then
            target_pwm=89   # 35%
        elif [ "$ref_temp" -lt 60 ]; then
            target_pwm=115  # 45%
        elif [ "$ref_temp" -lt 70 ]; then
            target_pwm=140  # 55%
        elif [ "$ref_temp" -lt 80 ]; then
            target_pwm=166  # 65%
        elif [ "$ref_temp" -lt 88 ]; then
            target_pwm=199  # 78%
        else
            target_pwm=255  # 100% Notfall-Maximum
        fi

        # Nur schreiben, wenn sich der Wert geändert hat (schont sysfs Bus)
        if [ "$target_pwm" -ne "$last_pwm" ]; then
            write_sysfs "$PWM_FILE" "$target_pwm"
            last_pwm=$target_pwm
        fi

        target_pct=$((target_pwm * 100 / 255))
        rpm=$(cat "$FAN_RPM" 2>/dev/null || echo "N/A")

        printf "\r[W7800 Wächter] Hotspot: %2d°C | VRAM: %2d°C | Lüfter: %3d%% (%s RPM) " "$junc" "$vram" "$target_pct" "$rpm"
        sleep 2
    done
}

start_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
        echo "ℹ️  Dynamischer Wächter läuft bereits mit PID $(cat "$PID_FILE")."
        return 0
    fi

    check_lact_conflict || true

    echo "* Starte dynamische Lüfterkurve als Hintergrund-Prozess..."
    # Starte ein schlankes Subshell im Hintergrund
    (
        trap 'write_sysfs "$PWM_ENABLE" "2"; rm -f "$PID_FILE"; exit 0' INT TERM EXIT
        write_sysfs "$PWM_ENABLE" "1"
        last_pwm=-1
        while true; do
            junc_raw=$(cat "$TEMP_JUNC" 2>/dev/null || echo 0)
            edge_raw=$(cat "$TEMP_EDGE" 2>/dev/null || echo 0)
            junc=$((junc_raw / 1000))
            edge=$((edge_raw / 1000))
            ref_temp=$junc
            [ "$ref_temp" -le 0 ] && ref_temp=$edge

            if [ "$ref_temp" -lt 50 ]; then
                target_pwm=89   # 35%
            elif [ "$ref_temp" -lt 60 ]; then
                target_pwm=115  # 45%
            elif [ "$ref_temp" -lt 70 ]; then
                target_pwm=140  # 55%
            elif [ "$ref_temp" -lt 80 ]; then
                target_pwm=166  # 65%
            elif [ "$ref_temp" -lt 88 ]; then
                target_pwm=199  # 78%
            else
                target_pwm=255  # 100%
            fi

            if [ "$target_pwm" -ne "$last_pwm" ]; then
                write_sysfs "$PWM_FILE" "$target_pwm"
                last_pwm=$target_pwm
            fi
            sleep 3
        done
    ) > "$LOG_FILE" 2>&1 &

    local pid=$!
    echo "$pid" > "$PID_FILE"
    echo "✅ Hintergrund-Wächter aktiv gestartet (PID: $pid)."
    echo "   Logs: $LOG_FILE"
    echo "   Stoppen mit: $0 daemon-stop oder $0 auto"
}

stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE" 2>/dev/null || true)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "* Beende Hintergrund-Wächter (PID $pid)..."
            kill "$pid" 2>/dev/null || true
            sleep 0.5
        fi
        rm -f "$PID_FILE"
    fi
    echo "* Schalte Lüfter auf vBIOS-Automatik zurück..."
    write_sysfs "$PWM_ENABLE" "2"
    echo "✅ Hintergrund-Wächter beendet und Automatik aktiv."
}

install_udev_rule() {
    echo "=================================================================="
    echo "🔧 INSTALLIERE UDEV-REGEL FÜR ROOTLESS-LÜFTERSTEUERUNG"
    echo "=================================================================="
    echo "Dies erlaubt das Ändern der Lüftergeschwindigkeit ohne jedes Mal"
    echo "ein sudo-Passwort eingeben zu müssen."
    echo ""

    local rule_file="/etc/udev/rules.d/99-amdgpu-fan.rules"
    local rule_content='ACTION=="add", SUBSYSTEM=="hwmon", ATTRS{name}=="amdgpu", RUN+="/bin/chmod 0666 /sys/class/drm/card%n/device/hwmon/%k/pwm1 /sys/class/drm/card%n/device/hwmon/%k/pwm1_enable"'

    echo "* Erstelle $rule_file..."
    echo "$rule_content" | sudo tee "$rule_file" > /dev/null

    echo "* Wende udev-Regeln sofort auf aktuelle GPU an..."
    sudo chmod 0666 "$PWM_FILE" "$PWM_ENABLE" 2>/dev/null || true
    sudo udevadm control --reload-rules 2>/dev/null || true
    sudo udevadm trigger 2>/dev/null || true

    echo "✅ Udev-Regel erfolgreich installiert!"
    echo "   Ab sofort funktionieren './scripts/gpu-fan-control.sh' und Profilwechsel"
    echo "   vollkommen ohne Root/sudo!"
    echo "=================================================================="
}

# ------------------------------------------------------------------------------
# Hauptsteuerung
# ------------------------------------------------------------------------------
case "$1" in
    status|"")
        show_status
        ;;
    silent)
        set_fan_pct 35 "Silent Desktop (flüsterleise ~34 dB)"
        ;;
    balanced)
        set_fan_pct 50 "Balanced Studio (sanftes Rauschen ~42 dB)"
        ;;
    performance)
        set_fan_pct 65 "Performance Sweet Spot (optimal für 230W, Junction <76°C)"
        ;;
    max)
        set_fan_pct 85 "Max Cooling (starke Kühlung für Dauervolllast)"
        ;;
    auto)
        set_fan_auto
        ;;
    set-fan|fan)
        set_fan_pct "$2" "Benutzerdefiniert"
        ;;
    curve|adaptive)
        check_lact_conflict || true
        run_curve_loop
        ;;
    daemon|daemon-start|bg)
        start_daemon
        ;;
    daemon-stop|stop)
        stop_daemon
        ;;
    install-udev)
        install_udev_rule
        ;;
    help|-h|--help)
        echo "Verwendung: $0 {status|silent|balanced|performance|max|auto|curve|daemon|daemon-stop|set-fan <%>|install-udev}"
        echo ""
        echo "Profile:"
        echo "  status        - Zeigt Live-Temperaturen, Drehzahlen, Watt & LACT-Status"
        echo "  silent        - 35% Blower (~1600 RPM, flüsterleise für Chat/Office)"
        echo "  balanced      - 50% Blower (~2300 RPM, leises Rauschen, Daily-Modus)"
        echo "  performance   - 65% Blower (~3000 RPM, Sweet Spot: Junction <76°C bei 230W)"
        echo "  max           - 85% Blower (~4000 RPM, Notfall/Nacht-Batches)"
        echo "  auto          - Werks-vBIOS Automatik wiederherstellen"
        echo "  curve         - Dynamische Lüfterkurve interaktiv im Vordergrund"
        echo "  daemon        - Dynamische Lüfterkurve im Hintergrund starten"
        echo "  daemon-stop   - Hintergrund-Wächter beenden"
        echo "  set-fan <%>   - Manuellen Prozentwert (15-100) setzen"
        echo "  install-udev  - Udev-Regel für Steuerung ohne sudo einrichten"
        ;;
    *)
        echo "❌ Unbekannter Befehl: '$1'"
        echo "Hilfe anzeigen mit: $0 help"
        exit 1
        ;;
esac
