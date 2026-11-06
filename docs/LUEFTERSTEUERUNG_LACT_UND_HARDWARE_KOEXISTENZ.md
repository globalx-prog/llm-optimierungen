# 🌀 AMD Radeon PRO W7800: Lüftersteuerung, Kühlprofile & LACT-Koexistenz

> **Ziel:** Maximale LLM- und Video-Generierungs-Performance ohne thermisches Drosseln (Thermal Throttling) durch eine intelligente, automatisierte Lüftersteuerung – und die präzise Klärung der Zusammenarbeit zwischen eigenen Skripten und dem LACT-Daemon (`lactd`).

---

## 1. 🔍 Die Kernfrage: Arbeiten Skripte gegeneinander oder gegen LACT?

### Kurzantwort:
**Nein, in unserer Konfiguration arbeiten sie perfekt Hand in Hand und NICHT gegeneinander!**  
LACT und das neue Lüfterskript haben eine **strikte Aufgabenteilung (Separation of Concerns)** auf Linux-Treiber-Ebene.

```
┌────────────────────────────────────────────────────────────────────────┐
│               AMD RADEON PRO W7800 (Navi 31 / amdgpu)                  │
├───────────────────────────────────┬────────────────────────────────────┤
│         LACT (`lactd.service`)    │    Lüfterskript (`gpu-fan-control`)│
├───────────────────────────────────┼────────────────────────────────────┤
│ • Regelt Power-Limit (200W / 230W)│ • Regelt Lüfter-PWM (`pwm1`)       │
│ • Regelt DPM & Performance-Level  │ • Schaltet vBIOS Automatik / Manuell│
│ • Überwacht GPU-Taktraten         │ • Dynamischer Hysterese-Wächter    │
│ • `fan_control_enabled: false`    │ • Hält Hotspot unter 76 °C         │
└───────────────────────────────────┴────────────────────────────────────┘
```

---

### Warum entsteht kein Konflikt? (Die technische Erklärung)

In `/etc/lact/config.yaml` ist festgelegt:
```yaml
apply_settings_timer: 5
gpus:
  1002:7449-1DA2:E498-0000:03:00.0:
    fan_control_enabled: false      # <-- Entscheidend!
    power_cap: 200.0
    performance_level: high
```

1. **LACT-Zyklus:** Der Hintergrund-Dienst `lactd` wacht alle `apply_settings_timer: 5` Sekunden auf und wendet seine Einstellungen an.
2. Da `fan_control_enabled` auf `false` (Standard) steht, **rührt LACT die Dateien `pwm1` und `pwm1_enable` niemals an**.
3. Unser Lüfterskript [`scripts/gpu-fan-control.sh`](../scripts/gpu-fan-control.sh) steuert **exklusiv** die Lüfterdateien im Linux-Sysfs (`/sys/class/drm/card0/device/hwmon/hwmon6/pwm1`).
4. **Ergebnis:** LACT kümmert sich um die elektrische Zufuhr (Wattage), das Skript kümmert sich um die Abfuhr der Abwärme. Beide ergänzen sich ohne jede Reibung.

---

### Wann WÜRDE es zu einem Konflikt kommen? (Das "Lüfter-Jojo")

Ein Konflikt würde nur in folgendem Szenario entstehen:
1. Im **LACT-GUI** wird die Lüfterkurve aktiviert (`fan_control_enabled: true`).  
   -> LACT schreibt nun alle 5 Sekunden seinen eigenen Lüfterwert in `pwm1`.
2. Gleichzeitig läuft ein **externer Skript-Loop** (z. B. `gpu-fan-control.sh curve` oder ein Hintergrund-Skript), der alle 2 Sekunden einen anderen Wert setzt.
3. **Folge ("Krieg um pwm1"):** Der Lüfter springt alle paar Sekunden zwischen den zwei unterschiedlichen Werten hin und her (stotterndes Hoch- und Runterdrehen).

#### Wie unser Setup diesen Konflikt verhindert:
* Unser Skript [`gpu-fan-control.sh`](../scripts/gpu-fan-control.sh) liest vor jedem Start `/etc/lact/config.yaml` aus (`check_lact_conflict`).
* Falls in LACT eine Lüftersteuerung aktiviert wurde, gibt das Skript eine klare Warnung aus.
* Zudem verhindert ein PID-Lock (`/tmp/w7800-fan-curve.pid`), dass zwei Skript-Instanzen gleichzeitig laufen.

---

## 2. 🌡️ Warum ist die Lüftersteuerung bei der W7800 so kritisch?

Die **AMD Radeon PRO W7800 (48 GB GDDR6)** besitzt einen Radial-Blower-Kühler. Ab Werk priorisiert das vBIOS **Büro-Lautstärke**:

| Temperatur-Bereich | vBIOS-Verhalten ab Werk | Reale Auswirkung |
| :--- | :--- | :--- |
| **Edge: 50–65 °C / Hotspot: < 80 °C** | Lüfter dreht mit minimalen **20 % (~1.000 RPM)** | Nahezu unhörbar, aber Wärme staut sich im dichten Kühlkörper. |
| **Hotspot: 85–90 °C** | Lüfter steigt zögerlich auf **38–42 %** | **Thermal Downbinning:** RDNA3 senkt Boost-Takt um 100–150 MHz! |
| **Hotspot: > 95 °C** | Lüfter dreht immer noch nicht voll auf | **Starkes Throttling:** Speicherbandbreite bricht ein, um 100 °C zu meiden. |

> [!IMPORTANT]
> **Hotspot vs. Edge:**  
> Lassen Sie sich nicht von der normalen "Edge"-Temperatur (meist 55–65 °C) täuschen! Entscheidend für die Rechenleistung und Speicherbandbreite ist immer der **Junction / Hotspot (`temp2_input`)**.  
> Sobald der Hotspot über 85 °C steigt, verlieren Sie beim Prompt-Processing von 70B-Modellen und beim Diffusions-Rendern spürbare Rechenzeit!

---

## 3. 📊 Die 5 praxiserprobten Lüfter-Profile

| Profil | Befehl | PWM | Drehzahl | Lautstärke | Hotspot (230W Last) | Anwendungsfall |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **Silent** | `./scripts/gpu-fan-control.sh silent` | **35 %** | ~1.600 RPM | **~34 dB(A)** (flüsterleise) | 90–95 °C | Reiner Text-Chat, Code-Editing, Bürobetrieb |
| **Balanced** | `./scripts/gpu-fan-control.sh balanced` | **50 %** | ~2.300 RPM | **~42 dB(A)** (sanftes Rauschen) | 80–84 °C | Standard für normales LLM-Coding & Bildgenerierung |
| **Performance** | `./scripts/gpu-fan-control.sh performance` | **65 %** | ~3.000 RPM | **~50 dB(A)** (monoton kühlend) | **72–76 °C** | **Sweet-Spot für 230W Volllast:** Verhindert Drosselung komplett! |
| **Max Cooling** | `./scripts/gpu-fan-control.sh max` | **85 %** | ~4.000 RPM | **~60 dB(A)** (deutlich hörbar) | **64–68 °C** | Lange unüberwachte Nacht-Batches, heiße Sommertage (>28 °C) |
| **Auto (vBIOS)** | `./scripts/gpu-fan-control.sh auto` | Variabel | variabel | Werkszustand | 92–98 °C | Standard nach Systemstart |

---

## 4. 🚀 Automatisierte Kopplung mit den GPU-Modi

Sie müssen die Lüfterwerte nicht mühsam manuell berechnen. Die beiden Hauptskripte koppeln Power-Budget und Kühlung automatisch:

### 1. Normalbetrieb (Daily Mode — 200W):
```bash
./scripts/set-gpu-mode-daily.sh
```
* Setzt Power-Limit via LACT auf **200 Watt**.
* Schaltet den Lüfter auf leise Automatik (oder Balanced 50%).
* Hält die Karte flüsterleise; Hotspot bleibt bei alltäglichen Aufgaben unter 80–85 °C.

### 2. Hochleistungs-Betrieb (Performance Mode — 230W Uncapped):
```bash
./scripts/set-gpu-mode-performance.sh
```
* Hebt das Power-Limit via LACT auf **230 Watt** an (+12.2% Budget für maximale Matrix-Kerne).
* Aktiviert automatisch das **65 % Performance-Kühlprofil**.
* **Ergebnis:** Selbst bei 100% Volllast (Prompt-Processing großer 70B-Modelle oder stundenlangen Film-Renders) bleibt der Hotspot **dauerhaft unter 76 °C** – null Throttling, 100% Durchsatz!

---

## 5. 🌡️ Dynamischer Temperatur-Wächter (Adaptive Kurve)

Wenn Sie eine stufenlose Regelung bevorzugen, die sich in Echtzeit an die Hotspot-Temperatur anpasst:

### Im Vordergrund starten (mit Live-Monitor):
```bash
./scripts/gpu-fan-control.sh curve
```
* Passt die Lüfterdrehzahl alle 2 Sekunden dynamisch an:
  * `< 50 °C:` 35 % (flüsterleise)
  * `50–59 °C:` 45 % (sanftes Anlaufen)
  * `60–69 °C:` 55 % (stabile Token-Generierung)
  * `70–79 °C:` 65 % (starker Luftstrom bei 230W Last)
  * `80–87 °C:` 78 % (aktiver Hitzeschutz)
  * `>= 88 °C:` 90–100 % (Notfall-Turbine)
* Beim Beenden mit **`Strg+C`** wird der Lüfter automatisch wieder an das Hardware-vBIOS übergeben.

### Als Hintergrund-Daemon starten:
```bash
./scripts/gpu-fan-control.sh daemon
```
* Läuft lautlos im Hintergrund.
* Stoppen mit:
```bash
./scripts/gpu-fan-control.sh daemon-stop
```

---

## 6. 🔓 Einmalige Rootless-Aktivierung (Steuerung ohne sudo)

Standardmäßig gehört der Hardware-Pfad `pwm1` dem Benutzer `root`. Um Lüfterprofile oder Umschaltungen im Alltag **ohne jedes Mal ein sudo-Passwort eingeben zu müssen** zu nutzen:

Führen Sie einmalig aus:
```bash
sudo /home/clemi/Projekte/LLM/scripts/gpu-fan-control.sh install-udev
```
* Dies richtet `/etc/udev/rules.d/99-amdgpu-fan.rules` ein.
* Ab diesem Moment hat Ihr Benutzer `clemi` dauerhafte Schreibrechte auf die Lüfterdateien der W7800.
* Alle Skripte (`set-gpu-mode-daily.sh`, `set-gpu-mode-performance.sh`, `model-download-setup.sh`) schalten die Lüfter dann nahtlos im Hintergrund um.

---

## 7. 👑 Komfortable Steuerung im Modell-Download-Menü

Im zentralen Verwaltungs-Tool:
```bash
./scripts/model-download.sh
```
finden Sie unter **`F) 🌀 Lüfter- & Kühlprofile`** ein eigenes Menü, mit dem Sie alle Profile per Tastendruck umschalten, den Status prüfen oder den Hintergrund-Daemon starten können:

```text
  1) 🔇 Silent          (35% Blower, ~1600 RPM, flüsterleise ~34 dB)
  2) ⚖️  Balanced        (50% Blower, ~2300 RPM, sanftes Rauschen ~42 dB)
  3) 🚀 Performance     (65% Blower, ~3000 RPM, Sweet-Spot 230W, Junction <76°C)
  4) 🌪️ Max Cooling     (85% Blower, ~4000 RPM, extreme Kühlung ~60 dB)
  5) 🔄 Auto (vBIOS)    (Lüftersteuerung an Werk-vBIOS übergeben)
  6) 🌡️ Dynamische Kurve (Live-Wächter im Vordergrund, Strg+C stoppt)
  7) 🤖 Wächter-Daemon  (Hintergrund-Überwachung starten)
  8) 🛑 Daemon stoppen  (Hintergrund-Wächter beenden & auf Auto zurücksetzen)
  9) 🔧 Udev-Regel      (Einmalig Rootless-Rechte ohne sudo einrichten)
  s) 📊 Status anzeigen (Live-Temperaturen, Drehzahlen, LACT-Check)
```

