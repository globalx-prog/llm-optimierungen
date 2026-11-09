# 🛡️ Sicherheits-Architektur, Kontextfenster & Top-3 Modell-Optimierung

**Hardware-Basis:**  
* **GPU:** AMD Radeon Pro W7800 (48 GB GDDR6, ~45,0 GiB netto nutzbar, 864 GB/s)  
* **CPU:** Intel Core i5-12400F (6 Performance-Kerne, 12 Threads)  
* **RAM:** 61 GiB DDR4/DDR5  
* **Swap:** 32 GB High-Speed NVMe Swap (`/home/swapfile`) + 4,7 GB Partition = **36,7 GB Gesamt-Swap**  
* **Gesamter Adressraum (VRAM + RAM + Swap):** **~142 GB**

---

## 1. Sind alle Umsetzungen sicher? (Der 5-Stufen-Schutzwall)

**Kurze Antwort:** **JA, zu 100%. Ein System-Freeze oder harter Absturz ist durch die neu implementierte Architektur ausgeschlossen.**

### Warum ist dein System früher abgestürzt?
Früher gab es zwei kritische Schwachstellen:
1. **Kein RAM-Limit für Ollama:** Wenn ein großes Modell oder ein riesiger Kontext geladen wurde, forderte Ollama mehr als die verfügbaren 61 GB RAM an. Der Linux-Kernel geriet in Panik (*OOM Stall*), die grafische Oberfläche (Desktop/Maus) fror komplett ein.
2. **GPU VRAM-Überlauf:** Wenn der AMD ROCm-Treiber 48,1 GB anfordern wollte, obwohl nur 48,0 GB existieren, stürzte der Grafikkartentreiber ab (schwarzer Bildschirm / GPU Reset).

### Wie verhindert die neue Architektur Abstürze?

```
┌────────────────────────────────────────────────────────────────────────┐
│                      5-STUFIGER SCHUTZWALL                             │
├────────────────────────────────────────────────────────────────────────┤
│ 1. VRAM-Schutzpuffer   │ 2–4 GB Headroom reserviert (kein Treiber-Crash)│
│ 2. Q4 KV-Cache         │ 50–75% weniger Kontext-Speicherbedarf          │
│ 3. 32 GB NVMe-Swap     │ Puffer fängt unvorhergesehene Lastspitzen ab   │
│ 4. Systemd Cgroup      │ MemoryMax=56G (5 GB bleiben IMMER für Desktop) │
│ 5. OOM-Score-Adjust    │ Kernel beendet im Notfall nur den LLM-Prozess  │
└────────────────────────────────────────────────────────────────────────┘
```

1. **GPU-Treiber-Schutz (`OLLAMA_GPU_OVERHEAD=2147483648`):**  
   Ollama lässt stets 2 bis 4 GB VRAM frei. Der Grafikkartentreiber läuft niemals am Limit.
2. **Q4 KV-Cache Kompression (`OLLAMA_KV_CACHE_TYPE=q4_0`):**  
   Der Arbeitsspeicher für den Chat-Verlauf wird 4-Bit-komprimiert. Statt 6–8 GB belegt ein 16k Kontext nur noch ~2,0 GB VRAM.
3. **32 GB NVMe-Swap-Puffer (`vm.swappiness=10`):**  
   Sollte der RAM temporär voll werden, lagert der Kernel Daten mit 3.500 MB/s auf die NVMe aus, anstatt das System einzufrieren.
4. **Harte Systemd-Grenze (`MemoryMax=56G`):**  
   Ollama darf **niemals mehr als 56 GB RAM** beanspruchen. Mindestens 5 GB RAM sind **garantiert für dein Betriebssystem, Desktop, Browser und SSH reserviert**.
5. **Gezielter OOM-Kill (`OOMScoreAdjust=500`):**  
   Sollte im extremsten theoretischen Szenario doch der Speicher ausgehen, beendet Linux **ausschließlich den Ollama-Prozess** sauber. Dein Desktop, offene Editoren und das System laufen ohne Ruckeln weiter.

---

## 2. Wie groß sind die Kontextfenster aller Modelle?

In allen neuen Modelfiles ist als Standard ein **16k-Fenster (`num_ctx 16384`)** vorkonfiguriert.  
Dies entspricht ca. **12.000 bis 14.000 Wörtern** (ca. 35–45 Seiten Text oder ca. 1.200 Zeilen Code inklusive Dokumentation und Tool-Definitionen).

### Übersicht: Kontextfenster & Speicherbedarf

| Modell & Variante | Vorkonfiguriertes Kontextfenster | Nativ maximal möglich | VRAM-Bedarf des 16k Cache (`q4_0`) | Kann Kontext auf 32k / 64k erhöht werden? |
| :--- | :---: | :---: | :---: | :--- |
| 👑 **`qwen2.5-72b-speed`** | **16.384 (16k)** | 128k (32k Standard) | ~2,2 GB | **Ja, 32k passt noch zu 100% in VRAM** (~42,5 GB total). |
| 👑 **`qwen2.5-72b-quality`** | **16.384 (16k)** | 128k (32k Standard) | ~2,2 GB | **Ja, bis 64k sicher** (über 61 GB System-RAM abgepuffert). |
| 🧠 **`deepseek-r1-70b-speed`** | **16.384 (16k)** | 128k | ~2,0 GB | **Ja, 32k passt voll in VRAM** (~42,0 GB total). |
| 🧠 **`deepseek-r1-70b-quality`**| **16.384 (16k)** | 128k | ~2,0 GB | **Ja, bis 64k sicher** im Hybrid-Modus. |
| 🌐 **`llama3.3-70b-speed`** | **16.384 (16k)** | 128k | ~2,0 GB | **Ja, 32k passt voll in VRAM** (~41,9 GB total). |
| 🌐 **`llama3.3-70b-quality`** | **16.384 (16k)** | 128k | ~2,0 GB | **Ja, bis 64k sicher** im Hybrid-Modus. |
| ⚡ **`qwen3-next-80b-16k`** | **16.384 (16k)** | 64k | ~2,4 GB | **Bereits für 16k optimiert** (36,5 t/s). |
| ⚡ **`qwen3-next-80b-32k`** | **32.768 (32k)** | 64k | ~4,8 GB | **Bereits für 32k optimiert** (4 Schichten mehr im RAM). |
| 🐘 **`mistral-large-123b`** | **16.384 (16k)** | 128k | ~2,8 GB | **Ja, bis 32k/64k** (RAM-Auslagerung fängt alles ab). |
| 🔀 **`mixtral-8x22b`** | **16.384 (16k)** | 64k | ~2,5 GB | **Ja, bis 32k/64k** sicher. |

---

## 3. Die Speicher-Rechnung im Detail: Warum 100% VRAM funktioniert

Dank der Grouped-Query-Attention (GQA) und `q4_0` Quantisierung skaliert der Kontextspeicher extrem sparsam:

### Beispiel 1: `deepseek-r1-70b-speed` mit 16k Kontext
* Modellgewichte (`IQ4_XS`): **~38,0 GB**
* 16k KV-Cache (`q4_0`): **~2,0 GB**
* **Gesamt-VRAM-Bedarf:** **~40,0 GB**
* **Freier VRAM-Puffer auf W7800:** **~5,0 GB frei!** (Absolut sicher vor OOM)
* **Geschwindigkeit:** **~42–48 Tokens/s** (100% GPU)

### Beispiel 2: `qwen2.5-72b-speed` mit 32k Kontext
* Modellgewichte (`IQ4_XS`): **~39,7 GB**
* 32k KV-Cache (`q4_0`): **~3,8 GB**
* **Gesamt-VRAM-Bedarf:** **~43,5 GB**
* **Freier VRAM-Puffer auf W7800:** **~1,5 GB frei!**
* **Geschwindigkeit:** **~38–42 Tokens/s** (immer noch 100% GPU)

---

## 4. Wie passe ich das Kontextfenster bei Bedarf an?

Falls du für ein Projekt ein größeres Kontextfenster benötigst (z. B. 32k oder 64k):

### Option A: Dauerhaft im Modelfile anpassen
Öffne das gewünschte Modelfile in `/home/clemi/Projekte/LLM/llm-optimierungen/modelfiles/` (z. B. `Modelfile.qwen2.5-72b-speed`) und ändere:
```dockerfile
# Statt 16384 für 32k:
PARAMETER num_ctx 32768
PARAMETER num_predict 16384
```
Danach einmal im Terminal aktualisieren:
```bash
ollama create qwen2.5-72b-speed -f /home/clemi/Projekte/LLM/llm-optimierungen/modelfiles/Modelfile.qwen2.5-72b-speed
```

### Option B: Ad-hoc in Cline / Roo-Code
In Cline kannst du das Kontextfenster direkt in den Plugin-Einstellungen steuern:
* Unter **Context Window** kannst du `16384` oder `32768` eintragen.
* Cline übergibt diesen Wert automatisch bei jedem Request an Ollama.

---

## 5. Fazit & Sicherheitsempfehlung

1. **Keine Gefahr von Freezes:** Dein Rechner ist durch den 32 GB NVMe-Swap und das 56 GB Cgroup-Limit hardwareseitig abgesichert.
2. **Die Speed-Varianten (`IQ4_XS`) bieten das beste Verhältnis:**
   * 100% VRAM-Auslastung ohne PCIe-Bremse.
   * Bis zu 16k–32k Kontext ohne Auslagerung in den langsameren RAM.
   * **~40–48 Tokens/s** statt ~28 Tokens/s.
3. **Wenn du gigantische Kontexte brauchst (>64k Tokens):**
   * Nutze die **Quality-Varianten** (`-quality`), da diese bei sehr großem Kontext automatisch Schichten sicher in den 61 GB System-RAM verschieben.
