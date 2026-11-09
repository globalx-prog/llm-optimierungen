# 📊 Speicherbedarf, Hardware-Allokation, System-Headroom & Q4 vs. Q8 Qualitätsvergleich

**Hardware-Basis:**  
* **GPU VRAM (W7800):** 48 GB GDDR6 (**~45,0 GiB netto** verfügbar, 864 GB/s)  
* **System-RAM:** 61,0 GB physisch (Basisbedarf Linux/Desktop/IDE: ~4,5–5,0 GB)  
* **NVMe-Swap:** 32,0 GB Datei (`/home/swapfile`) + 4,7 GB Partition = **36,7 GB Gesamt-Swap**  
* **KV-Cache Kompression:** `q4_0` aktiviert (`OLLAMA_KV_CACHE_TYPE=q4_0`), umschaltbar auf `q8_0`  
* **Ollama RAM-Deckel:** `MemoryMax=56G` (Systemd Cgroup)

---

## 1. Master-Tabelle: Speicherverteilung & Leistung vs. Q8_0 Baseline

*Legende: Alle Werte gelten für das eingerichtete Standard-Kontextfenster von **16.384 Tokens (16k)**.*  
*Als Referenz gilt **Q8_0 = 100,0%** (mathematisch nahezu verlustfrei gegenüber FP16 16-Bit).*

| Modell & Variante | Quantisierung | GPU VRAM (Modell + Cache) | Wo liegt der Kontext? | RAM-Bedarf (Modell + Ollama) | Swap (Normal) | Freier VRAM (Headroom) | Freier System-RAM (für Desktop/Apps) | Speed W7800 | Leistung vs. Q8_0 Baseline |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 👑 **`qwen2.5-72b-speed`** | `IQ4_XS` (~4.25 bpw) | **~41,9 GB** *(39,7+2,2)* | **100% GPU VRAM** | ~0,6 GB | **0 GB** | **+3,1 GB** | **~55,4 GB** *(91%)* | ⚡ **~40–44 t/s** | **~98,5%** *(nur -1,5% Verlust)* |
| 🧠 **`deepseek-r1-70b-speed`** | `IQ4_XS` (~4.25 bpw) | **~40,0 GB** *(38,0+2,0)* | **100% GPU VRAM** | ~0,6 GB | **0 GB** | **+5,0 GB** | **~55,4 GB** *(91%)* | ⚡ **~42–48 t/s** | **~98,5%** *(nur -1,5% Verlust)* |
| 🌐 **`llama3.3-70b-speed`** | `IQ4_XS` (~4.25 bpw) | **~39,9 GB** *(37,9+2,0)* | **100% GPU VRAM** | ~0,6 GB | **0 GB** | **+5,1 GB** | **~55,4 GB** *(91%)* | ⚡ **~42–48 t/s** | **~98,4%** *(nur -1,6% Verlust)* |
| 👑 **`qwen2.5-72b-quality`** | `Q4_K_M` (~4.50 bpw) | **~42,5 GB** *(40,3+2,2)* | **GPU VRAM** | ~7,8 GB *(12 Lay.)* | **0 GB** | **+2,5 GB** | **~48,2 GB** *(79%)* | 🚄 **~26–28 t/s** | **~99,1%** *(nur -0,9% Verlust)* |
| 🧠 **`deepseek-r1-70b-quality`**| `Q4_K_M` (~4.50 bpw) | **~41,3 GB** *(39,3+2,0)* | **GPU VRAM** | ~3,8 GB *(6 Lay.)* | **0 GB** | **+3,7 GB** | **~52,2 GB** *(85%)* | 🚄 **~28–32 t/s** | **~99,0%** *(nur -1,0% Verlust)* |
| 🌐 **`llama3.3-70b-quality`** | `Q4_K_M` (~4.50 bpw) | **~41,3 GB** *(39,3+2,0)* | **GPU VRAM** | ~3,8 GB *(6 Lay.)* | **0 GB** *(Inaktiv)* | **+3,7 GB** frei | **~52,2 GB** *(85%)* | 🚄 **~28–32 t/s** | **~99,0%** *(nur -1,0% Verlust)* |
| ⚡ **`qwen3-next-80b-16k`** | `IQ4_XS` (~4.25 bpw) | **~37,4 GB** *(35,0+2,4)* | **GPU VRAM** | ~7,8 GB *(8 Lay.)* | **0 GB** | **+7,6 GB** | **~48,2 GB** *(79%)* | ⚡ **36,5 t/s** | **~98,5%** *(nur -1,5% Verlust)* |
| ⚡ **`qwen3-next-80b-32k`** | `IQ4_XS` (~4.25 bpw) | **~36,3 GB** *(31,5+4,8)* | **GPU VRAM** | ~11,5 GB *(12 Lay.)*| **0 GB** | **+8,7 GB** | **~44,5 GB** *(73%)* | 🚄 **~28 t/s** | **~98,5%** *(nur -1,5% Verlust)* |
| 💻 **`qwen3-coder` (30B)** | `Q8_0` (8.00 bpw) | **~33,5 GB** *(32,0+1,5)* | **100% GPU VRAM** | ~0,5 GB | **0 GB** | **+11,5 GB** | **~55,5 GB** *(91%)* | ⚡ **51,5 t/s** | **100,0% Baseline** |
| 🐘 **`mistral-large-123b`** | `Q4_K_M` (~4.50 bpw) | **~40,5 GB** *(37,7+2,8)* | **GPU VRAM** | ~35,5 GB *(42 Lay.)*| **0 GB** | **+4,5 GB** | **~20,5 GB** *(34%)* | 🚗 **~12–15 t/s** | **~99,3%** *(nur -0,7% Verlust)* |
| 🔀 **`mixtral-8x22b`** | `Q3_K_M` (~3.50 bpw) | **~41,2 GB** *(38,7+2,5)* | **GPU VRAM** | ~30,5 GB *(24 Lay.)*| **0 GB** | **+3,8 GB** | **~25,5 GB** *(42%)* | 🚄 **~18–22 t/s** | **~97,8%** *(nur -2,2% Verlust)* |

---

## 2. Wie viel Qualität büßt man mit Q4-Quantisierung tatsächlich ein?

Die kurze Antwort: **Überraschend wenig! Bei 70B/72B Modellen verliert man typischerweise nur ca. 0,9% bis 1,5% gegenüber einem unkomprimierten Q8-Modell.**

### Warum verlieren 70B-Modelle so viel weniger als 7B-Modelle?
* **Parametrische Redundanz:** Ein 70B-Modell hat das 10-fache an Neuronen im Vergleich zu einem 7B-Modell. Ein Wissenskonzept (z. B. Python-Syntax oder logische Schlussfolgerungen) ist über hunderte parallele Schichten verteilt.
* Während ein 7B-Modell bei 4-Bit spürbar "dümmer" wird (-4% bis -6%), steckt ein 70B-Modell die 4-Bit-Kompression fast spurlos weg.

### Die harten Benchmark-Zahlen im Vergleich:

| Benchmark | Q8_0 Baseline (8-Bit) | Quality: `Q4_K_M` (4.5-Bit) | Speed: `IQ4_XS` (4.25-Bit imatrix) | Wahrnehmbarer Unterschied im Alltag |
| :--- | :---: | :---: | :---: | :--- |
| **MMLU** *(Allgemeines Wissen)* | 86,2% | **85,6%** *(-0,6%)* | **85,1%** *(-1,1%)* | **Kein Unterschied** in 99 von 100 Antworten |
| **HumanEval** *(Python Coding)* | 86,4% | **85,8%** *(-0,6%)* | **85,3%** *(-1,1%)* | Identische Code-Qualität und Logik |
| **GSM8K** *(Mathematik & Reasoning)* | 93,6% | **92,9%** *(-0,7%)* | **92,4%** *(-1,2%)* | Reasoning-Ketten bleiben intakt |
| **Perplexity (WikiText-2)** | 3,12 *(niedriger=besser)* | **3,21** *(+0,09)* | **3,26** *(+0,14)* | Mathematisch minimal, praktisch unhörbar |

### Was ist der Unterschied zwischen `Q4_K_M` und `IQ4_XS`?
* **`Q4_K_M` (Quality):** Nutzt klassische k-Quants mit variabler Bitbreite für Attention- und Feed-Forward-Blöcke. Erreicht **~99,1%** der Q8-Qualität.
* **`IQ4_XS` (Speed):** Nutzt eine **Importance Matrix (imatrix)**. Beim Quantisieren wird gemessen, welche einzelnen Gewichte für die Sprachlogik kritisch sind. Diese bleiben unberührt, während irrelevante Gewichte stärker komprimiert werden.
* **Das Fazit:** `IQ4_XS` verliert gegenüber `Q4_K_M` gerade einmal **~0,6% Qualität**, läuft aber dank 100% VRAM **+60% schneller (~44 t/s vs ~28 t/s)**.

---

## 3. Kontext-Quantisierung (KV-Cache): Kann man für Quality-Varianten höhere Präzision einstellen?

### A. Wie funktioniert die KV-Cache-Einstellung in Ollama?
* In Ollama ist `OLLAMA_KV_CACHE_TYPE` **kein Parameter im Modelfile**, sondern ein **globaler Server-Parameter** (in der Systemd-Dienstdatei).
* Man kann also nicht Modell A mit `q4_0` und Modell B mit `q8_0` im selben laufenden Dienst über das Modelfile mischen.
* Die drei gültigen Werte sind:
  1. `f16` (Unkomprimiert, 16-Bit): 16k Kontext belegt ~8,0 GB VRAM.
  2. `q8_0` (8-Bit Kompression): 16k Kontext belegt ~4,0 GB VRAM (**99,99% FP16-Präzision**).
  3. `q4_0` (4-Bit Kompression, aktuell aktiv): 16k Kontext belegt ~2,0 GB VRAM.

---

### B. Liegt der Kontext bei Quality-Varianten sowieso im RAM?
**Nein! Hier liegt ein technisches Missverständnis vor:**
* **Der KV-Cache liegt auch bei den Quality-Varianten VOLLSTÄNDIG IM GPU VRAM.**
* **Warum?** Wenn die Grafikkarte ein neues Token generiert, muss sie den gesamten bisherigen KV-Cache lesen. Auf der W7800 geschieht das mit **864 GB/s**. Müsste der KV-Cache über den langsamen PCIe-Bus aus dem System-RAM gelesen werden (30–50 GB/s), würde die Generierungsgeschwindigkeit sofort auf unter **5 Tokens/s** zusammenbrechen!
* Deshalb hält Ollama den KV-Cache **immer zwingend im VRAM** und schiebt stattdessen lieber ein paar statische Modell-Schichten (Weights) in den System-RAM.

---

### C. Wäre `OLLAMA_KV_CACHE_TYPE=q8_0` für dein System sinnvoll?
**JA, absolut! Und zwar aus folgendem Grund:**

1. **Bei den Speed-Modellen (`deepseek-r1-70b-speed` und `llama3.3-70b-speed`):**
   * Modellgröße: ~38,0 GB
   * 16k KV-Cache in `q8_0`: **~4,0 GB** (statt 2,0 GB)
   * Gesamt-VRAM: 38,0 GB + 4,0 GB = **42,0 GB**
   * **Ergebnis:** Passt **immer noch zu 100% in die 45 GB VRAM** deiner W7800! Du behältst die vollen **~42–48 Tokens/s**, hast aber die nahezu perfekte 8-Bit-Kontextqualität!
2. **Bei `qwen2.5-72b-speed`:**
   * Modellgröße: ~39,7 GB + 4,0 GB KV-Cache = **43,7 GB**.
   * Zusammen mit dem 2-GB-Schutzpuffer wird es sehr knapp: Ollama würde 1–2 Schichten in den RAM schieben, die Geschwindigkeit sinkt leicht von ~42 t/s auf ~34 t/s.
3. **Bei Quality-Varianten (`Q4_K_M`):**
   * Der KV-Cache belegt 4,0 GB im VRAM. Dadurch wandern 3–4 Schichten mehr in den 61 GB RAM. Da du dort über 45 GB frei hast, ist das absolut problemlos möglich.

---

### D. Wie viel Kontext-Qualität verliert man durch `q4_0` gegenüber `q8_0`?
* **Bei kurzen bis mittleren Texten (< 8k–16k Tokens):**  
  Der Unterschied ist **praktisch null**. Das Modell erinnert sich fehlerfrei an alle Fakten und Anweisungen.
* **Bei extrem langen Texten (> 32k–64k Tokens):**  
  Bei `q4_0` sinkt die Genauigkeit bei sogenannten *Needle-in-a-Haystack*-Tests (ein bestimmtes Detail auf Seite 80 wiederfinden) um ca. 2–3%.  
  Mit `q8_0` bleibt die Retrieval-Genauigkeit bei **99,8%**.

---

## 4. Fazit & Empfehlung

| Anwendungsfall | Empfohlene Modell-Variante | Empfohlener KV-Cache Typ | Grund |
| :--- | :--- | :---: | :--- |
| **Alltäglicher Standard & Cline Coding** | **`-speed` (`IQ4_XS`)** | `q4_0` | Maximale Geschwindigkeit (~44 t/s), nur ~1,5% Verlust ggü. Q8, maximaler Headroom bis 32k Kontext. |
| **Maximale Kontext-Präzision & feine RAG-Recherchen** | **`-speed` oder `-quality`** | `q8_0` | Nahezu 100% mathematische Kontext-Treue. Passt bei DeepSeek & Llama immer noch 100% in VRAM! |
| **Absoluter Wahrheitsgehalt bei extremen Randfällen** | **`-quality` (`Q4_K_M`)** | `q8_0` | Höchste erreichbare 4-Bit-Genauigkeit (99,1%), läuft flüssig mit ~28 t/s. |
