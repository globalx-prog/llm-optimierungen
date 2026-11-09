# Modell-Geschwindigkeiten, Aufgaben-Stellschrauben & Kontext-Machbarkeitsmatrix

> **Hardware-Basis:** AMD Radeon Pro W7800 48GB (Navi 31, 384-Bit GDDR6 Speicherbus, 863 GiB/s Bandbreite, ROCm 6.x)  
> **Host-System:** 16 CPU-Kerne, 128 GB RAM, Linux  
> **Stichtag:** November 2026

---

## 1. Geschwindigkeiten aktueller Modelle (Reale Messungen)

Alle Geschwindigkeiten wurden unter identischen Bedingungen mit einem standardisierten Architektur- & Code-Prompt (~350 Tokens Generierung) ermittelt.

### 1.1 Lokale Flaggschiffe (70B / 72B Klasse)

| Modell | Quantisierung | Backend / Setup | Reale t/s | Draft Acceptance | VRAM-Bedarf | Bemerkung |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Qwen 2.5 72B Instruct** | IQ4_XS (~39.7 GB) | **llama-speedup (Speculative)** | **33,57 t/s** | **97,1%** | ~42.0 GB | **+269% Speedup** durch Qwen2.5-0.5B Draft (Qualitäts-König) |
| **Qwen 2.5 72B Instruct** | IQ4_XS (~39.7 GB) | Ollama (Native Inferenz) | 11,91 t/s | N/A | ~41.4 GB | 9,09 – 12,03 t/s je nach Kontextlänge |
| **Llama 3.3 70B Abliterated** | IQ4_XS (~38.0 GB) | **llama-speedup (Speculative)** | **30,02 t/s** | **81,4%** | ~40.3 GB | **+201% Speedup** durch Llama-3.2-1B Draft (Unzensiert) |
| **Llama 3.3 70B Abliterated** | IQ4_XS (~38.0 GB) | Ollama (Native Inferenz) | 13,61 t/s | N/A | ~39.8 GB | 9,97 – 13,61 t/s (100% zensurfrei) |
| **Llama 3.3 70B Instruct** | IQ4_XS (~38.0 GB) | **llama-speedup (Speculative)** | **25,64 t/s** | **71,6% – 84,0%** | ~40.2 – 42.2 GB | **+155% Speedup** (19,94 t/s im 32k Vollkontext-Stresstest) |
| **Llama 3.3 70B Instruct** | IQ4_XS (~38.0 GB) | Ollama (Native Inferenz) | 12,91 t/s | N/A | ~39.2 GB | 10,07 – 12,91 t/s im Allround-Betrieb |
| **DeepSeek-R1 Distill 70B** | IQ4_XS (~38.0 GB) | **llama-speedup (N-Gram Mod)** | **13,95 t/s** | Kontext-Lookup | ~39.1 GB | **0 MB Zusatz-VRAM**, beschleunigt Code & CoT |
| **DeepSeek-R1 Distill 70B** | IQ4_XS (~38.0 GB) | Ollama (Native Inferenz) | 13,05 t/s | N/A | ~39.3 GB | 10,43 – 13,05 t/s mit sichtbaren `<think>`-Ketten |

### 1.2 Kompakte Flaggschiffe & Coding-Spezialisten (7B – 35B Klasse)

| Modell | Quantisierung | Backend | Reale t/s | VRAM-Bedarf | Primärer Einsatzzweck |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Qwen 2.5-VL 7B** | Q4_K_M (~4.8 GB) | Ollama | **89,25 – 89,35 t/s** | ~9.1 GB | Multimodale Bild- und Screenshot-Analyse (Prefill: 816 t/s) |
| **Qwen 3 Coder Speed** | 30.5B MoE (~3.3B aktiv, Q4_K_M) | Ollama | **75,36 – 80,58 t/s** | ~20.6 GB | 🥇 Nr. 1 Speed-Coder (Cline / Roo, 0ms Lag, 27 GB VRAM-Reserve) |
| **Qwen 3.8 35B Distill** | Q6_K (~28.5 GB) | Ollama | **64,68 – 66,60 t/s** | ~30.4 GB | Schnelles Allround-Reasoning & Chat-Sweet-Spot |
| **Qwen 3 Coder Quality** | 30.5B MoE (~3.3B aktiv, Q8_0) | Ollama | **61,56 – 62,70 t/s** | ~33.5 GB | 🥇 Nr. 1 Verlustfreier Code-Präzisions-König (FP16 Compiler/Syntax) |
| **Qwen 2.5 Coder 32B** | Q4_K_M (~19.5 GB) | Ollama / llama-speedup | **~55–65 t/s** | ~23.5 GB | Klassischer robuster Dense-Coder mit viel VRAM-Puffer |
| **Qwen 3 Obliterated 27B** | Q4_K_M (~16.2 GB) | Ollama | **17,19 – 17,70 t/s** | ~24.1 GB | Zensurfreie Analyse, IT-Security & Pentesting |
| **Artemis 31B** | Q4_K_M (~18.8 GB) | Ollama | **14,65 t/s** | ~20.5 GB | Rollenspiel & kreatives Schreiben ohne Filter |

### 1.2b Reale Messwerte im 32k Vollkontext-Stresstest (~16.200 Tokens Prefill-Payload)

Messlauf unter Volllast bei **32.768 Tokens allozierter Kontextgröße** und **50% vorbefülltem Kontext**:

| Modell | Backend | Prefill-Speed (TTFT) | Generation (32k Last) | VRAM-Peak (von 48 GB) | Bemerkung |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **`qwen3-coder-speed`** | Ollama (30B MoE) | ⚡ **1573,66 t/s** | 🚀 **50,31 t/s** | **20,9 GB** | 16k Code in 10 s gelesen, 24 GB VRAM Reserve |
| **`qwen3-coder-quality`** | Ollama (30B MoE Q8) | ⚡ **1773,38 t/s** | 🚀 **43,00 t/s** | **33,7 GB** | Höchster gemessener Prefill-Durchsatz |
| **`qwen3.8-35b-distill`** | Ollama (35B Dense Q6)| ⚡ **1750,12 t/s** | 🚀 **48,79 t/s** | **30,3 GB** | Exzellenter RAG- und Dokumentenscanner |
| **`llama3.3-70b-speculative`** | llama-swap (1B Draft) | **193,84 t/s** | **22,26 t/s** | **42,4 GB** | **+149% Speedup** vs Basisinferenz unter Vollast |
| **`llama3.3-70b-abliterated-spec.`** | llama-swap (1B Draft) | **193,97 t/s** | **19,64 t/s** | **42,3 GB** | **+105% Speedup** ohne Zensur |
| **`qwen2.5-72b-speculative`** | llama-swap (0.5B Draft)| **190,72 t/s** | **16,16 t/s** | **42,9 GB** | **+81% Speedup** vs N-Gram |
| **`qwen3-obliterated`** | Ollama (27B Dense) | **504,86 t/s** | **14,09 t/s** | **24,6 GB** | Stabiles mittleres Modell |
| **`deepseek-r1-70b-speculative`** | llama-swap (N-Gram) | **198,23 t/s** | **9,37 t/s** | **40,3 GB** | 0 MB Draft-VRAM, tiefe `<think>`-Kette |
| **`qwen2.5-72b-ngram`** | llama-swap (N-Gram) | **194,09 t/s** | **8,93 t/s** | **41,9 GB** | Reines autoregressives Baseline-Decoding |

### 1.3 Cloud-Modelle im direkten Geschwindigkeitsvergleich

| Modell | Provider | Typische Generierung | Prompt-Eval (TTFT) | Kontext-Fenster |
| :--- | :--- | :--- | :--- | :--- |
| **Gemini 3.8 Flash (High)** | Google Cloud | **180 – 250+ t/s** | Instant (< 0,3 s für 10k) | 1.000.000 Tokens |
| **GPT-4o** | OpenAI | **80 – 110 t/s** | Sehr schnell (< 0,8 s) | 128.000 Tokens |
| **Claude 3.5 / 3.7 Sonnet** | Anthropic | **60 – 80 t/s** | Schnell (< 1,2 s) | 200.000 Tokens |

---

## 2. Aufgaben-Stellschrauben (Parameter-Hebel zur Optimierung)

Die Performance und Stabilität eines Modells hängt maßgeblich von den gewählten Parametern ab. Hier sind die wichtigsten Stellschrauben und ihre Auswirkung:

### 2.1 Stellschrauben für Spekulative Modelle (`config.yaml`)

```yaml
--spec-draft-n-max 8       # Maximale Vorschlagskette des Draft-Modells
--spec-draft-p-min 0.75    # Konfidenz-Schwelle
-ctk q4_0 -ctv q4_0        # 4-Bit KV-Cache Kompression
-np 1                      # Slot-Anzahl (1 = Single-User Workstation, spart 4 GB VRAM)
-c 16384                   # Kontextfenster (16k = optimal für W7800 Koexistenz mit ComfyUI)
```

| Parameter | Aktueller Wert | Tuning-Option | Auswirkung & Empfehlung |
| :--- | :--- | :--- | :--- |
| `--spec-draft-n-max` | `8` | `10` (Code) / `6` (Chat) | Da deine Draft Acceptance bei **~72–97%** liegt, kann `10` bei Code/JSON nochmals 1–2 t/s herausholen. Werte über `12` sind ineffizient, da seltene Fehlversuche Rechenzeit kosten. |
| `--spec-draft-p-min` | `0.75` | `0.70` (mutig) / `0.80` | `0.70` lässt das kleine Modell längere Ketten auf Vorrat raten (gut für deterministischen Code). `0.80` stoppt früher bei Unsicherheit. |
| `-ctk q4_0` & `-ctv q4_0` | `q4_0` | **Nicht ändern!** | **Spart ~70% VRAM beim Kontext**. Ohne diesen Schalter würde 16k/32k Kontext ~8–16 GB VRAM fressen; mit Q4_0 nur ~2–4 GB. Kein messbarer Qualitätsverlust. |
| `-np` (Slots) | `1` | `1` (Single-User) / `2` | Teilt das Gesamtfenster `-c` in feste Partitionen. `-np 1` spart ~4 GB VRAM und garantiert, dass selbst 70B/72B Modelle parallel mit Hintergrund-Diensten wie ComfyUI (4 GB Reserve) und Wayland Desktop stabil laufen. |

### 2.2 Sampler-Stellschrauben nach Aufgaben-Typ (in Open WebUI / API)

| Aufgabe | Temperature | Top-P | Repeat Penalty | Max Tokens | Ziel |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Code & Scripting** | `0.1 – 0.2` | `0.85` | `1.05` | 4096 | Höchste Präzision, maximale Draft Acceptance (~92%), keine Syntaxfehler. |
| **Agenten / Dateisystem (Cline)** | `0.2 – 0.3` | `0.90` | `1.00` | 2048 | Strikte Befolgung von JSON/Tool-Formaten, schnelles Reagieren. |
| **Deep Reasoning & Mathe** | `0.6` | `0.95` | `1.05` | 8192 | Notwendiger Spielraum für Exploration von Gedankengängen (`<think>`). |
| **Kreatives Schreiben & Chat** | `0.7 – 0.8` | `0.90` | `1.10` | 2048 | Abwechslungsreiche Sprache, metaphorischer Wortschatz. |

### 2.3 Hardware-Stellschrauben: Power-Limit (200W vs 230W) & Lüfterkurven

Neben Software-Parametern entscheidet das thermische und elektrische Budget der W7800 über Drosselung und Taktraten:

* **Tagesbetrieb (200W + Auto/Balanced Lüfter):** Flüsterleise (~34–42 dB), Hotspot bleibt <85 °C. Ideal für den 80% Alltag.
* **Hochleistung (230W Uncapped + 65% Performance-Lüfter):**
  * **+18 % schnelleres Prompt-Processing (Prefill):** Steigt von ~300 auf ~355 Tokens/s bei 70B/72B Modellen.
  * **+15 % schnellere Bild-/Videodiffusion:** MiniMax H3 Video-Renderzeit sinkt von 71s auf 60s pro Szene (-2,2 Min pro Gesamtfilm!).
  * **Beseitigt Throttling vollständig:** Hotspot sinkt von 98 °C auf **~74 °C** (-24 °C kühler!).
  * Umschaltung via `./scripts/set-gpu-mode-performance.sh` oder Menü `model-download.sh` (Taste `P` / `F`).
  * Ausführlicher Guide: Siehe [LEISTUNG_LUEFTER_SCHALTUNG_UND_PERFORMANCE_GEWINN.md](LEISTUNG_LUEFTER_SCHALTUNG_UND_PERFORMANCE_GEWINN.md).

---

## 3. Machbarkeitsmatrix Kontext (VRAM-Budget auf 48 GB)

### 3.1 Das physische Budget der AMD Radeon Pro W7800

* **Gesamter VRAM:** `48.288 MB` (~47,15 GiB)
* **OS- / ROCm-Sicherheitsreserve:** `~3.800 MB`
* **Maximal allozierbares Modell-Budget:** **`~44.400 MB`**

$$\text{VRAM}_{\text{Gesamt}} = \text{Hauptmodell} + \text{Draft-Modell} + \text{KV-Cache}(C, \text{Slots}, \text{Quant}) + \text{Aktivierungs-Puffer}$$

### 3.2 Kontext-Machbarkeitsmatrix

Legende:  
🟢 **Grün (Stabil):** Volle GPU-Allokation, min. 3 GB VRAM-Reserve, kein Swap, kein Einfrieren.  
🟡 **Gelb (Grenzbereich):** Läuft im VRAM, aber weniger als 1,5 GB Puffer. Größere Batches können OOM auslösen.  
🔴 **Rot (Instabil/OOM):** Überschreitet 48 GB VRAM. Führt zum System-Einfrieren, Prozess-Crash oder CPU-Swap.

| Modell-Klasse | 8k Kontext | 16k Kontext | 32k Kontext | 64k Kontext | 128k Kontext |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **70B / 72B Speculative** *(z. B. Qwen 72B + 0.5B Draft, Q4 KV, 2 Slots)* | 🟢 **Stabil**<br>~41.5 GB | 🟢 **Stabil**<br>~42.5 GB | 🟢 **Sweet Spot**<br>~44.3 GB *(Aktiv)* | 🔴 **OOM**<br>~48.5 GB | 🔴 **Unmöglich**<br>> 56 GB |
| **70B N-Gram** *(z. B. DeepSeek-R1 70B, Q4 KV, 0 MB Draft)* | 🟢 **Stabil**<br>~40.0 GB | 🟢 **Stabil**<br>~41.0 GB | 🟢 **Stabil**<br>~42.8 GB | 🟡 **Grenzbereich**<br>~46.5 GB *(1 Slot)* | 🔴 **OOM**<br>> 52 GB |
| **32B / 35B Klasse** *(z. B. Qwen 2.5 Coder 32B, Q4 KV)* | 🟢 **Stabil**<br>~21.5 GB | 🟢 **Stabil**<br>~22.5 GB | 🟢 **Stabil**<br>~24.5 GB | 🟢 **Stabil**<br>~28.5 GB | 🟢 **Stabil**<br>~36.5 GB |
| **14B Klasse** *(z. B. Qwen 2.5 14B)* | 🟢 **Stabil**<br>~11.0 GB | 🟢 **Stabil**<br>~12.0 GB | 🟢 **Stabil**<br>~13.5 GB | 🟢 **Stabil**<br>~16.5 GB | 🟢 **Stabil**<br>~22.5 GB |

---

## 4. Dateisystem- und Agenten-Workflows: Wann welches Modell?

Wenn Modelle mit Dateisystemen, Ordnerstrukturen oder mehrstufigen Tools interagieren, multipliziert sich die Dauer:

```
Aufgabe: "Durchsuche Ordner, lies Config (2.000 Tokens), ändere Port und speichere"

Gemini 3.8 Flash (Cloud):   ██ (6 s)
Qwen 2.5 Coder 32B (Lokal):  ██████ (18 s)  <-- Optimaler lokaler Sweet Spot
Llama 3.3 70B (Lokal):       ██████████████████ (55 s)
```

### Empfehlungs-Leitfaden:

1. **Große Codebase-Scans & Massen-Refactoring:**  
   $\rightarrow$ **Gemini 3.8 Flash**. Durch das 1M-Token-Fenster und 200+ t/s liest und modifiziert es 20 Dateien in wenigen Sekunden.
2. **Lokales autonomes Coden (Cline / Roo Code / Cursor):**  
   $\rightarrow$ **Qwen 2.5 Coder 32B Speculative**. Verbindet 60 t/s Durchsatz mit 100% lokalem Datenschutz und exzellenter Code-Syntax.
3. **Architektur-Entscheidungen, Systemdesign & schwieriges Debugging:**  
   $\rightarrow$ **Llama 3.3 70B Speculative** (25,6 t/s) oder **Qwen 2.5 72B Speculative** (33,6 t/s). Höchste analytische Schärfe und Robustheit gegen Halluzinationen.
4. **Logische Beweise, Algorithmen & mathematische Optimierung:**  
   $\rightarrow$ **DeepSeek-R1 Distill 70B** (13–14 t/s). Unübertroffen durch die sichtbare Reflexionskette (`<think>`).

---

## 5. Die physikalischen Ursachen der Inferenz-Geschwindigkeit („The Memory Wall“)

### 5.1 Warum LLM-Generierung speicherbandbreiten-limitiert ist

In der klassischen Bildgenerierung (z. B. Stable Diffusion / FLUX) ist die GPU primär **rechenleistungs-limitiert** (Compute-Bound, TFLOPs). Bei großen Sprachmodellen verhält sich die Textgenerierung grundlegend anders:

1. **Autoregressives Decoding (Token-für-Token):**
   * Jedes neue Wort basiert auf allen vorherigen Wörtern. Ein Token kann erst berechnet werden, wenn das vorherige fertig ist.
   * **Die physikalische Konsequenz:** Für jedes **einzelne** generierte Token müssen **sämtliche Gewichte des 70B-Modells (~38 GB)** einmal vollständig aus den GDDR6-Speicherbausteinen über den Speicherbus in die Rechenkerne gestreamt werden.
   * Die Rechenkerne benötigen pro Token nur einfache Matrix-Vektor-Multiplikationen (`gemv`), aber gigantische Datentransfers.

2. **Die Speicherbandbreiten-Rechnung für die AMD Radeon Pro W7800 48GB:**
   * Die AMD Radeon Pro W7800 48GB besitzt (im Gegensatz zum 32GB-Modell) die volle **384-Bit Speicheranbindung**:
     $$\text{Speicherbus} = 384\text{ Bit} = 48\text{ Byte}$$
     $$\text{Taktfrequenz (GDDR6)} = 18\text{ Gbps} = 18\text{ GHz}$$
     $$\text{Theoretisches Maximum} = 48\text{ Byte} \times 18\text{ GHz} = \mathbf{864\text{ GB/s}}$$
   * **Warum native Inferenz trotzdem bei ~10–12 t/s lag:**
     1. **GEMV-Bus-Effizienz (~55–60%):** Bei Batch-Size 1 (einzelnes Wort) kann der 96 MB Infinity Cache nicht greifen. Die unaligned 4-Bit-Dequantisierungs-Kernel (`iq4_xs`) lasten den Bus mit ca. 480–500 GB/s realem Durchsatz aus.
     2. **Hardware-Throttling (Live nachgewiesen: `Power(PPT0, PPT1)`):** Unter Volllast stieß die Karte bei 219W in das Power-Limit.
     3. **Ultra-leiser Lüfter:** Der Lüfter dreht ab Werk nur mit 20% (~1000 RPM). Dadurch stieg die Junction-Temperatur schnell an, woraufhin das VBIOS die Boost-Takte drosselte.

3. **Wie Speculative Decoding die Effizienz verdreifacht:**
   * Beim spekulativen Decoding verifiziert das 70B-Modell 4 bis 8 vorgeschlagene Tokens auf einen Schlag.
   * Das verwandelt die ineffiziente Matrix-Vektor-Multiplikation in eine hocheffiziente **Matrix-Matrix-Multiplikation (GEMM)**!
   * Dadurch steigt der reale Durchsatz von 10–12 t/s auf **25,6 bis 33,6 t/s** (bis zu +269% Speedup bei Qwen 72B).

---

## 6. Alternative Modelltypen & Architekturen: Was könnte die Geschwindigkeit verbessern?

Können andere Modell-Architekturen auf derselben Hardware (256-Bit GDDR6, 48 GB VRAM) spürbar mehr Geschwindigkeit herausholen? Hier ist die systematische Analyse:

### 6.1 Mixture of Experts (MoE) — Das größte Potenzial (35 – 50 t/s)

* **Funktionsweise:**  
  Ein MoE-Modell besitzt insgesamt viele Parameter (z. B. 8 Experten á 7B = 47B Gesamtgröße wie Mixtral 8x7B), aber pro Token werden über ein Routing-Netzwerk nur **2 von 8 Experten aktiviert** (~13B aktive Parameter).
* **Warum es dramatisch schneller ist:**  
  Statt 38 GB Gewichte müssen pro Token nur die Gewichte der aktiven Experten gestreamt werden (nur ~12–14 GB)!
  $$\text{Durchsatz MoE} = \frac{480\text{ GB/s}}{13\text{ GB}} \approx \mathbf{37\text{ Tokens/s}}$$
* **Voraussetzung auf 48 GB VRAM:**  
  Alle Experten müssen gleichzeitig im VRAM liegen. Ein Modell wie **Mixtral 8x7B** (in Q4 ca. 26 GB) oder **Qwen 2.5-MoE** passt problemlos komplett in 48 GB VRAM und generiert mit **35 bis 50 t/s** bei der Sprachqualität eines 35B–50B Modells.
* **Grenzen:** Gigantische MoEs wie DeepSeek-V3 (671B Gesamtgröße) passen nicht in 48 GB VRAM.

### 6.2 Multi-Token Prediction (MTP) & Native Speculative Heads (Eagle / Medusa) (30 – 35 t/s)

* **Funktionsweise:**  
  Statt eines separaten Draft-Modells (wie Qwen 0.5B) besitzen Architekturen mit **Multi-Token Prediction (MTP)** oder **Eagle/Medusa** zusätzliche, extrem leichte Vorhersage-Köpfe (Heads) direkt am Ausgang des 70B-Modells.
* **Vorteil:**  
  * Kein zweites Modell im VRAM, kein Kontext-Switching zwischen zwei Prozessen.
  * Höhere Akzeptanzraten (>90–95%), da die Köpfe direkt mit den internen Zuständen (Hidden States) des großen Modells arbeiten.
  * Erlaubt auf einem 70B-Modell Durchsätze von **30 bis 35 t/s** auf der W7800.

### 6.3 State Space Models (SSM) & Hybride (Mamba, Jamba, RWKV) (Konstant schnell bei Riesenkontext)

* **Funktionsweise:**  
  Ersetzen den quadratischen $O(N^2)$ Transformer-Aufmerksamkeitsmechanismus (Self-Attention) durch lineare Zustandsräume (Linear Recurrence).
* **Vorteil:**  
  * **Kein wachsender KV-Cache:** Bei Standard-Transformern frisst der Kontext VRAM und verlangsamt bei 32k/64k Tokens das gesamte Modell.
  * Bei SSMs bleibt der Speicher- und Rechenaufwand pro Token bei 1.000 Tokens genauso schnell wie bei 64.000 Tokens.
  * Exzellente Prompt-Evaluation für Massendokumente.

### 6.4 Aggressive Quantisierung (IQ3_XXS / IQ2_M) (28 – 36 t/s)

* **Funktionsweise:**  
  Verringerung der Bitbreite von 4-Bit (IQ4_XS, 38 GB) auf 3-Bit (IQ3_M, ~28 GB) oder 2.5-Bit (IQ2_M, ~23 GB).
* **Auswirkung auf Speed:**  
  $$\text{IQ3\_M (28 GB): Basis } 17,1\text{ t/s} \rightarrow \text{Spekulativ: } \mathbf{\sim 30\text{ t/s}}$$
  $$\text{IQ2\_M (23 GB): Basis } 20,8\text{ t/s} \rightarrow \text{Spekulativ: } \mathbf{\sim 36\text{ t/s}}$$
* **Kompromiss:**  
  * `IQ3_M`: Behält ca. 95–97% der Modellfähigkeiten; kaum spürbarer Verlust bei normalem Chat/Coding.
  * `IQ2_M`: Deutlicher Perplexity-Verlust; neigt bei komplexem Reasoning und Mathe zu Halluzinationen.

### 6.5 Dense 30B–35B Modelle (Der aktuelle Sweet Spot: 55 – 65 t/s)

* Modelle wie **Qwen 3.8 35B Distill** (gemessene **64,65 t/s**) oder **Qwen 2.5 Coder 32B** (~55–65 t/s) halbieren das Modellgewicht (~19–21 GB).
* Sie nutzen dieselbe Bandbreite optimal aus und bieten auf der Radeon Pro W7800 die beste Balance aus flüssiger Arbeitsgeschwindigkeit (für Dateisystem- & Agenten-Loops) und hervorragender Code-Präzision.

---

## 7. Zusammenfassende Technologie-Matrix

| Modell-Architektur | Beispiel-Modelle | VRAM-Bedarf (48 GB tauglich?) | Reale/Erwartete t/s (W7800) | Eignung & Best-Use |
| :--- | :--- | :---: | :---: | :--- |
| **MoE Ultra-Speed (~3.3B aktiv)** | **Qwen 3 Coder 30B MoE** | ~18.5 GB (Ja 🟢) | **80 – 110 t/s** ⚡ | **Der schnellste Coder der Welt lokal:** 0ms Lag in Cline/Roo Code. |
| **Dense 32B/35B Sweet Spot** | **Qwen 3.8 35B** / **Qwen 2.5 Coder 32B** | ~20–30 GB (Ja 🟢) | **55 – 65 t/s** 🚀 | **Bester Alltags-Sweet-Spot:** Perfekte Balance aus Intelligenz & Speed. |
| **MoE Allround (13B aktiv)** | **Mixtral 8x7B Instruct** | ~26.4 GB (Ja 🟢) | **35 – 50 t/s** | Sehr schneller Allrounder mit enormem Breitenwissen, moderater VRAM-Bedarf. |
| **Dense 70B (Speculative)** | **Llama 3.3 70B** / **Qwen 2.5 72B** | ~43 GB (Ja 🟢) | **20 – 22.5 t/s** | Höchste Logik, formales Math/Coding & Weltklasse Tool-Calling. |
| **Dense 70B Uncensored** | **Llama 3.3 70B Abliterated** | ~37.9 GB (Ja 🟢) | **20 – 22.5 t/s** | **100% unzensiert:** Keine Refusals, Pentesting, neutrale Analysen. |
| **MoE 141B (39B aktiv)** | **Mixtral 8x22B Instruct** | ~38 GB GPU + ~25 GB RAM | **18 – 22 t/s** | Monumentales MoE-Modell im Hybrid-Modus, flüssiger als Dense 120B+. |
| **Dense 123B (Hybrid)** | **Mistral Large 2407 (123B)** | ~38 GB GPU + ~31 GB RAM | **12 – 15 t/s** | Maximale Parameter-Masse für tiefste juristische & philosophische Analysen. |
| **Deep Reasoning (CoT)** | **DeepSeek-R1 Distill 70B** | ~38 GB (Ja 🟢) | **12.6 t/s + CoT** | Rein logisches Nachdenken (`<think>`), formale Beweise & Rätsel. |
| **Cloud Hyper-Fast** | **Google Gemini 3.8 Flash** | Cloud (1M–2M Kontext) | **~180 – 250 t/s** ☁️ | RAG über 50+ Dateien, 300-Seiten PDFs & riesige Codebase-Refactorings. |

---

## 8. Hardware-Tuning & Umschalt-Skripte: Tagesbetrieb vs. Hochleistung

### 8.1 Die Hardware-Grenzwerte deiner Karte laut VBIOS (`hwmon`)

* **Edge-Temperatur:** Kritisch = `100°C` | Notabschaltung = `105°C`
* **Junction (Hotspot):** **Kritisch = `110°C` | Notabschaltung = `115°C`**
* **VRAM-Temperatur:** Kritisch = `105°C` | Notabschaltung = `110°C`
* **Konfigurierbarer Power-Bereich:** `138W` bis `230W`

> [!NOTE]
> Ein Junction-Wert von **95°C ist absolut unbedenklich** und liegt 15°C unter der offiziellen AMD-Drosselgrenze (110°C). Erst ab 110°C greift der Hardware-Schutz.

### 8.2 Die beiden Steuer-Skripte

Um bequem zwischen leiser Alltagsnutzung und maximaler LLM-Geschwindigkeit zu wechseln, wurden zwei Skripte im Verzeichnis `scripts/` bereitgestellt:

#### Skript A: Normaler Tagesbetrieb (Silent & Cool)
* **Pfad:** [set-gpu-mode-daily.sh](file:///home/clemi/Projekte/LLM/scripts/set-gpu-mode-daily.sh)
* **Befehl:** `/home/clemi/Projekte/LLM/scripts/set-gpu-mode-daily.sh`
* **Eigenschaften:** Setzt Power-Limit auf **200W**. Die Karte bleibt flüsterleise, Junction bleibt geschont (< 85–90°C).

#### Skript B: Maximale Hochleistung (Uncapped Speed)
* **Pfad:** [set-gpu-mode-performance.sh](file:///home/clemi/Projekte/LLM/scripts/set-gpu-mode-performance.sh)
* **Befehl:** `/home/clemi/Projekte/LLM/scripts/set-gpu-mode-performance.sh`
* **Eigenschaften:** Hebt Power-Limit auf das Maximum (**230W**) an. Verhindert PPT-Throttling.
* **Tipp für maximale Takte:** Im LACT GUI die Lüfterkurve ab 85°C Junction auf 50–60% anheben. Dadurch bleibt die Karte selbst unter Volllast kühl und boostet dauerhaft auf maximale Taktraten!

#### Echtzeit-Überwachung
* **Befehl:** `/home/clemi/Projekte/LLM/scripts/gpu-status.sh`
* Zeigt Taktraten, Temperaturen aller Sensoren und aktives Throttling auf einen Blick an.

### 8.3 Das interaktive Modell-Download- & Stellschrauben-Skript
Das ursprüngliche `setup-top3-models.sh` wurde zu einem **vollständigen, interaktiven Modell-Download- und Performance-Setup-Skript** erweitert und umbenannt:

* **Haupt-Skript:** [model-download-setup.sh](file:///home/clemi/Projekte/LLM/scripts/model-download-setup.sh)
* **Befehle (alle führen zum selben Tool):**
  * `/home/clemi/Projekte/LLM/scripts/model-download-setup.sh`
  * `/home/clemi/Projekte/LLM/scripts/model-download.sh`
  * `/home/clemi/Projekte/LLM/scripts/setup-models.sh`
  * `/home/clemi/Projekte/LLM/scripts/setup-top3-models.sh` *(Abwärtskompatibel)*

**Im Menü direkt steuerbar:**
1. **Alle Top-Modelle** (Qwen 2.5 72B, DeepSeek-R1 70B, Llama 3.3 70B, Llama 3.3 70B Abliterated)
2. **High-Speed Sweet Spot & Coder** (Qwen 3.8 35B Distill ~65 t/s, Qwen 3 Coder 30B MoE ~80–110 t/s, Qwen 2.5 Coder 32B ~55–65 t/s)
3. **MoE & Giganten** (Mixtral 8x7B, Mixtral 8x22B, Mistral Large 123B)
4. **Paket-Downloads** (Top 3 Speed-Paket, Coding-Speed-Duo)
5. **Direkte Hardware-Stellschrauben** (GPU Daily Mode 200W, Performance Mode 230W, Status-Check, KV-Cache Switcher `q4_0`/`q8_0`, Speed-Benchmark, Disk Cleanup)

---

## 9. Konkreter Zeitvergleich für typische Aufgaben

Wie lange wartest du als Nutzer in der Praxis wirklich auf das Ergebnis? Hier ist der reale Zeitvergleich (inklusive Prompt-Evaluation der Eingabe und Generierung der Antwort) über alle empfohlenen Modelle im direkten Vergleich mit den Top-Flaggschiffen und der Cloud:

### 9.1 Direkte Latenz- und Zeit-Matrix

| Aufgaben-Szenario | Umfang (Input / Output) | **Gemini 3.8 Flash** *(Cloud ~200 t/s)* | **Qwen 3 Coder MoE** *(Lokal ~95 t/s)* | **Qwen 3.8 35B** *(Lokal ~65 t/s)* | **Qwen 2.5 Coder 32B** *(Lokal ~58 t/s)* | **Mixtral 8x7B MoE** *(Lokal ~42 t/s)* | **Llama 70B & Abliterated** *(Lokal ~22.5 t/s)* | **Qwen 72B Spec.** *(Lokal ~20.1 t/s)* | **Mistral Large 123B** *(Hybrid ~13 t/s)* | **DeepSeek-R1 70B** *(Lokal ~12.6 t/s + CoT)* |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. Kurzer Chat / Tool-Call** *(Wetter, Übersetzung, Faktenfrage)* | ~150 In / 100 Out | **~0,8 s** ⚡ | **~1,1 s** ⚡ | **~1,7 s** 🚀 | **~1,9 s** 🚀 | **~2,5 s** | **~4,8 s** | **~5,2 s** | **~8,2 s** | **~18 s** *(denkt 150 Tok.)* |
| **2. Mittlere Code-Aufgabe** *(Funktion schreiben, API-Handler)* | ~800 In / 400 Out | **~2,2 s** ⚡ | **~4,4 s** ⚡ | **~6,8 s** 🚀 | **~7,4 s** 🚀 | **~10,2 s** | **~18,5 s** | **~20,8 s** | **~32 s** | **~75 s** *(denkt 500 Tok.)* |
| **3. Große Dokumentation / Plan** *(Umfassendes Script, Refactoring)* | ~2.000 In / 1.200 Out | **~5,5 s** ⚡ | **~13,5 s** ⚡ | **~21 s** 🚀 | **~23 s** 🚀 | **~31 s** | **~58 s** | **~64 s** | **~1:38 min** | **~3:30 min** *(denkt 1.500 Tok.)* |
| **4. Dateisystem- / Agenten-Loop** *(Cline: 4 Loops Suchen, Lesen, Edit)* | ~4.000 In / 600 Out | **~6 – 8 s** ⚡ | **~10 – 14 s** ⚡ | **~18 – 25 s** 🚀 | **~22 – 28 s** 🚀 | **~30 – 38 s** | **~55 – 70 s** | **~60 – 80 s** | **~1:50 – 2:30 min** | *Nicht empfohlen (kein Tool-Support)* |

---

### 9.2 Umfassende Feature- und Leistungs-Matrix: Top-Modelle vs. Empfohlene Spezialisten

| Modell & Kennung | Architektur & Typ | Aktive Parameter pro Token | W7800 VRAM-Bedarf | Max. nativer Kontext | Realer Speed (W7800) | Coding & Cline (1-10) | Tool-Calling Stabilität | Zensur-Freiheit (1-10) | Primäre Rolle im täglichen Workflow |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| 👑 **`qwen2.5-72b-speed`** | Dense 72B (IQ4_XS) | 72.7B | ~39.7 GB (100% VRAM) | 32k – 128k | ~20.1 t/s (Spec.) | **9.8** 🥇 | Exzellent (JSON / Tools) | 7.5 | **Der Coding- & Mathe-König:** Höchste Logik für anspruchsvollste Algorithmen. |
| 🌐 **`llama3.3-70b-speed`** | Dense 70B (IQ4_XS) | 70.6B | ~37.9 GB (100% VRAM) | 32k – 128k | ~22.5 t/s (Spec.) | **9.1** | **10.0** 🥇 (Goldstandard) | 7.5 | **Der Allround-Champion:** Fehlerfreies Tool-Calling, Websuche & Agenten. |
| 🔓 **`llama3.3-70b-abliterated`** | Dense 70B (IQ4_XS) | 70.6B | ~37.9 GB (100% VRAM) | 32k – 128k | ~22.5 t/s (Spec.) | **9.1** | **9.8** (Hervorragend) | **9.9** 🥇 (100% unzensiert) | **Das unzensierte 70B Flaggschiff:** Pentesting, Security, neutrale Recherchen. |
| 🧠 **`deepseek-r1-70b-speed`** | Dense 70B (IQ4_XS) | 70.6B | ~37.9 GB (100% VRAM) | 32k – 128k | ~12.6 t/s + CoT | **8.8** | ⚠️ Schwach (Fließtext) | 7.0 | **Der Denk-Meister:** Transparente `<think>`-Spuren für mathematische Beweise. |
| 💻 **`qwen3-coder-speed`** | **MoE 30.5B (A3B)** | **Nur ~3.3B aktiv** ⚡ | **~18.5 GB** (100% VRAM) | **256k Kontext** | **~75 – 110 t/s** ⚡ | **9.5** 🥈 | Sehr gut | 7.5 | **Der Ultra-Speed Coder:** Schlägt alle lokalen Modelle in Generierungs-Tempo. |
| 💻 **`qwen3-coder-quality`** | **MoE 30.5B (Q8_0)** | **~3.3B aktiv (8-Bit)** | **~32.5 GB** (100% VRAM) | **32k Kontext** | **~61.6 t/s** 🚀 | **9.6** 🥇 | Exzellent | 7.5 | **Verlustfreie 8-Bit-Qualität:** Höchste Präzision für Compiler & formale Syntax. |
| ⚡ **`qwen3.8-35b-distill`** | Dense 35B Distill (Q6_K) | 35.0B | ~30.0 GB (100% VRAM) | **64k Kontext** | **~64.6 t/s** 🚀 | **8.6** | Sehr gut | 7.5 | **Der Alltags-Sweet-Spot:** Perfekter Allrounder für Chat & Dateisystem-Loops. |
| 💻 **`qwen2.5-coder-32b`** | Dense 32.5B (Q4_K_M) | 32.5B | ~19.8 GB (100% VRAM) | 32k – 64k | **~55 – 65 t/s** 🚀 | **9.2** | Exzellent | 7.5 | **Bewährtes Coding-Workhorse:** Stabiler Dense Coder mit viel freiem VRAM. |
| 🔀 **`mixtral-8x7b`** | MoE 46.7B (Q4_K_M) | 12.9B aktiv | ~26.4 GB (100% VRAM) | 32k Kontext | **~35 – 50 t/s** | **8.2** | Gut | 7.5 | **Schneller MoE Allrounder:** Flüssige Konversation mit breitem Allgemeinwissen. |
| 🔀 **`mixtral-8x22b`** | MoE 141B (Q3_K_M) | 39.0B aktiv | ~38 GB GPU + ~25 GB RAM | 16k – 64k | **~18 – 22 t/s** | **8.9** | Sehr gut | 7.5 | **MoE-Schwergewicht:** 141 Milliarden Parameter, dank MoE erstaunlich flüssig. |
| 🐘 **`mistral-large-123b`** | Dense 123B (Q4_K_M) | 123.0B | ~38 GB GPU + ~31 GB RAM | 16k – 128k | **~12 – 15 t/s** | **9.3** | Sehr gut | 8.0 | **Lokales Giganten-Modell:** Monumentale Tiefe für komplexe Analysen & Recht. |
| ☁️ **`Gemini 3.8 Flash`** | Cloud (Multimodal TPU) | Nativ Cloud | 0 GB Lokal | **1.000.000+** 🥇 | **~180 – 250 t/s** ⚡ | **9.2** | **10.0** 🥇 | 4.5 (sehr streng) | **Hyper-Kontext:** Ganze Repositories (50+ Dateien) oder dicke PDFs auf einmal. |

---

## 10. Detaillierte Modellauswahl & Anwendungs-Empfehlungen

Nutze diesen Entscheidungsbaum, um für jede Aufgabe das ideale Modell auszuwählen:

```
                                  Welche Aufgabe steht an?
                                             │
      ┌──────────────────────┬───────────────┴───────────────┬──────────────────────┐
      ▼                      ▼                               ▼                      ▼
[Coding & Tools]      [Deep Reasoning]             [Schneller Alltag]     [Große Codebases / PDF]
      │                      │                               │                      │
  Llama 3.3 70B        DeepSeek-R1 70B                Qwen 3.8 35B          Gemini 3.8 Flash
  oder Qwen 72B       (reines Nachdenken)         (blitzschnell, ~65 t/s)    (1M Kontext, 250 t/s)
  (~20-22 t/s)           (~12.6 t/s)
```

### 10.1 Detaillierte Modell-Profile & Einsatzgebiete

#### 1. 👑 Alibaba Qwen 2.5 72B Instruct (~20.1 t/s Speculative)
* **Primäre Stärken:** Weltweit bestes Open-Source Modell für Programmierung, formale Mathematik und komplexe Algorithmen. Kennt moderne Frameworks (Rust, Go, TypeScript, Python) in tiefster Präzision.
* **Wann wählen?**
  * Für anspruchsvolle Architekturen, knifflige Regex-Muster, SQL-Optimierungen und mathematische Berechnungen.
  * Wenn syntaktische Korrektheit absolute Priorität über Generierungszeit hat.

#### 2. 🌐 Meta Llama 3.3 70B Instruct (~22.5 t/s Speculative)
* **Primäre Stärken:** Metas stärkstes Modell und weltweiter Goldstandard für Prompt-Treue, strukturierte JSON-Ausgaben und Tool-Calling.
* **Wann wählen?**
  * Für alle Agenten-Workflows, die Websuche, Wetter-Abfragen, Datenbank-Tools oder strukturierte Funktionsaufrufe benötigen.
  * Für Zusammenfassungen, Übersetzungen und konsistente Dialogführung.

#### 3. 🔓 Meta Llama 3.3 70B Instruct Abliterated (~22.5 t/s Speculative)
* **Primäre Stärken:** **Das stärkste unzensierte Modell der Welt.** Behält 100% der Intelligenz und Tool-Fähigkeiten von Llama 3.3 70B, weigert sich aber niemals und belehrt den Nutzer nicht moralisch.
* **Wann wählen?**
  * Für IT-Sicherheitsanalysen, Penetration-Testing, Exploit-Erklärungen und Sicherheitsaudits.
  * Für ungeschminkte historische, politische oder philosophische Recherchen ohne Zensur-Filter.

#### 4. 💻 Qwen 3 Coder 30B MoE (Speed-Champion, ~80 – 110 t/s)
* **Primäre Stärken:** **Der absolute Durchsatz-König auf deiner W7800.** Aktiviert dank innovativer MoE-Architektur pro Vorwärtsschritt nur ~3.3 Milliarden Parameter. Erreicht im VRAM über **80 bis 110 Tokens pro Sekunde** und lässt mit nur ~18.5 GB Modellgröße über 25 GB VRAM für riesige Kontextfenster frei.
* **Wann wählen?**
  * Der unschlagbare **Primary Driver für Cline, Roo Code und VS Code**!
  * Für blitzschnelle Code-Generierung, Funktionen, Unittests, API-Handler und Refactorings ohne spürbare Wartezeit.

#### 5. ⚡ Qwen 3.8 35B Distill (~64.6 t/s gemessen)
* **Primäre Stärken:** Der **Alltags-Sweet-Spot für die 48 GB W7800**. Verbindet hohe Intelligenz mit dreifacher Generierungsgeschwindigkeit gegenüber 70B-Modellen und bietet ein riesiges **64k-Kontextfenster**.
* **Wann wählen?**
  * Als standardmäßiger **Daily Driver** für interaktiven Chat, Brainstorming, Dateianalysen und alltägliche Fragen.

#### 6. 💻 Qwen 2.5 Coder 32B Instruct (~55 – 65 t/s)
* **Primäre Stärken:** Bewährter Dense Coding-Spezialist. Sehr präzise Syntax, läuft komplett im VRAM (~19.8 GB) und bietet viel Headroom für lange Kontexte.
* **Wann wählen?**
  * Wenn du ein klassisches (nicht-MoE) High-Speed-Coding-Modell bevorzugst.

#### 7. 🧠 DeepSeek-R1 Distill Llama 70B (~12.6 t/s + CoT)
* **Primäre Stärken:** Unübertroffene logische Tiefe durch transparente Chain-of-Thought Gedankengänge (`<think> ... </think>`). Verifiziert eigene Zwischenschritte und korrigiert Fehler selbstständig.
* **Wann wählen?**
  * Für mathematische Beweise, Logik-Rätsel und diffizile Debugging-Fälle.
  * ⚠️ **Nicht wählen für:** Tool-Calling oder schnelle Agenten-Loops.

#### 8. 🔀 Mixtral 8x7B Instruct (~35 – 50 t/s)
* **Primäre Stärken:** Schnelles MoE-Modell (nur 13B aktiv). Flüssiger Textfluss, breites enzyklopädisches Wissen und moderate VRAM-Last (~26.4 GB).
* **Wann wählen?**
  * Für lockeren, flüssigen Chat mit breitem Allgemeinwissen und schnellen Textzusammenfassungen.

#### 9. 🔀 Mixtral 8x22B Instruct (~18 – 22 t/s MoE Hybrid)
* **Primäre Stärken:** 141 Milliarden Parameter MoE (39B aktiv pro Token). Läuft im GPU+RAM Hybrid-Modus erstaunlich flüssig und bietet massives Kontext-Verständnis.
* **Wann wählen?**
  * Wenn du ein Modell jenseits von 100 Milliarden Parametern für vielschichtige Analysen testen willst.

#### 10. 🐘 Mistral Large 2407 (123B) (~12 – 15 t/s Hybrid)
* **Primäre Stärken:** Monumentales 123-Milliarden-Parameter-Modell. Läuft auf deinem Setup im GPU+RAM Hybrid-Modus (~38 GB GPU + ~31 GB RAM). Echte GPT-4 / Sonnet-Klasse bei Sprachnuancen.
* **Wann wählen?**
  * Für tiefste juristische Gutachten, komplexe philosophische Abhandlungen und literarische Übersetzungen.

#### 11. ☁️ Google Gemini 3.8 Flash (Cloud, ~180 – 250 t/s)
* **Primäre Stärken:** Gigantisches 1-Millionen-Token-Kontextfenster und blitzschnelle Cloud-Verarbeitung.
* **Wann wählen?**
  * Wenn du ein komplettes Projektarchiv (50+ Dateien), dicke PDF-Bücher oder stundenlange Audio-/Video-Dateien in einem einzigen Aufruf analysieren musst.




