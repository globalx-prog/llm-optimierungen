# 💡 Leitfaden & Praxistipp: Sicheres Swap-Management & System-Stabilität

> **Zusammenfassung:** Warum automatisches Swap-Leeren zu Systemabstürzen (Kernel-Deadlocks) mit AMD ROCm führt, wann das Leeren tatsächlich sinnvoll ist und wie der Befehl `clearswap` das System sicher schützt.

---

## 1. Die Kernursache: Warum stürzte das System ab?

Auf Systemen mit großen KI-Workloads (z. B. **64 GB RAM** und **48 GB VRAM** auf der AMD Radeon Pro W7800) allozieren Frameworks wie **ROCm, PyTorch und llama.cpp** riesige Speicherblöcke (`userptr`, Unified Memory, KFD-Puffer).

* **Das Problem:** Ein Hintergrunddienst (`auto-swap-reclaim.timer`) führte minütlich ein blindes `swapoff -a && swapon -a` aus.
* **Der Kernel-Deadlock:**
  1. `swapoff -a` blockiert das gesamte Speichermanagement des Linux-Kernels (`mmap_lock`), um Swap-Seiten synchron zurück in den RAM zu zwingen.
  2. Gleichzeitig versuchten die Kernel-Worker von AMD (`amdgpu_amdkfd_restore_userptr_worker` und `svm_range_restore_work`), 40-GB-Tensoren im RAM zu verwalten.
  3. **Ergebnis:** Ein unauflösbarer **AB-BA Deadlock im Linux-Kernel**. Die CPU-Kerne hingen in Endlosschleifen fest, die grafische Oberfläche (Gnome) froren ein und der Hardware-Watchdog des Mainboards erzwang schließlich einen Kaltstart (`BERT: Hardware Error`).

---

## 2. Grundwissen: Wie arbeitet Linux-Swap wirklich?

### ❌ Mythos: „Swap im RAM = System ist langsam“
* Linux lagert ganz bewusst inaktive („kalte“) Speicherseiten von Hintergrundprozessen aus, die seit Stunden nicht angefasst wurden.
* **Der Vorteil:** Dadurch bleibt der schnelle physische RAM frei für den **Linux-Dateicache (Page Cache)**. Das beschleunigt das Laden von Modellen, SSD-Lesezugriffe und die Systemreaktion drastisch.
* **Regel:** Solange nur ein paar hundert Megabyte (z. B. 200–800 MB) im Swap liegen, gibt es **keinerlei Geschwindigkeitsverlust**.

---

## 3. Wann ist das Leeren von Swap sinnvoll?

| Situation | Swap-Leeren sinnvoll? | Grund / Empfehlung |
| :--- | :---: | :--- |
| **Normaler Desktop- / KI-Betrieb** | ❌ **Nein** | Linux holt benötigte Seiten bei Bedarf („Page Fault“) automatisch mit voller NVMe-Geschwindigkeit zurück. |
| **Während KI rechnet / lädt** | 🛑 **Gefährlich!** | Gefahr eines sofortigen Kernel-Deadlocks mit AMD ROCm / Nvidia-Treibern. |
| **Nach extremen Lastspitzen** |  **Ja (Sinnvoll)** | Ein großer Build oder Videorenderer hat 10–20 GB Swap erzeugt. Der Task ist beendet, 30+ GB RAM sind wieder frei, aber Desktop-Apps reagieren zäh. |
| **Im System-Leerlauf (Idle)** |  **Ja (Sinnvoll)** | Wenn nach intensiven Workloads der RAM wieder völlig frei ist und die GPU ruht. |

---

## 4. Die Lösung: Der Sicherheitsbefehl `clearswap`

Statt eines unkontrollierten minütlichen Dienstes wurde das intelligente Werkzeug `/usr/local/bin/clearswap` eingerichtet.

### Was macht `clearswap` anders?
1. **Sprachunabhängig:** Liest Speicherdaten (`free -m`) sauber und robust aus.
2. **GPU-Schutzprüfung:** Fragt über `rocm-smi` ab, ob die GPU aktuell aktiv rechnet (>15% Last). Falls ja, bricht es sofort ab, um Deadlocks zu verhindern.
3. **RAM-Puffersicherheitscheck:** Prüft, ob mindestens `belegter Swap + 4 GB Puffer` im physischen RAM frei sind (Schutz vor OOM-Kills).
4. **Schont SSD & System:** Wenn weniger als 50 MB belegt sind, wird keine unnötige I/O-Last erzeugt.

### Anwendung:
Wenn du nach intensiven Videorenderings oder großen Modellen das Gefühl hast, dass Speicher aufgeräumt werden soll:

```bash
sudo clearswap
```

#### Beispielausgabe:
```text
======================================================================
          🧹 SICHERES SWAP-RECLAIM (RAM & GPU SCHUTZ)                
======================================================================
Belegter Swap:    0 MB
Verfügbarer RAM:  48692 MB
✓ Swap ist bereits praktisch leer (<50 MB). Keine Aktion nötig.
```

---

## 5. Deaktivierung des fehlerhaften Dienstes

Der alte, minütliche Timer wurde dauerhaft abgeschaltet:
```bash
sudo systemctl stop auto-swap-reclaim.timer
sudo systemctl disable auto-swap-reclaim.timer
```
Damit ist dein System nun vor unkontrollierten Abstürzen geschützt.

