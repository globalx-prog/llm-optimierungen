# 📊 Vergleichstabelle: Aktuelle LLM-Modelle & Kontextgrößen

> **Hardware-Profil:** AMD Radeon Pro W7800 (48 GB GDDR6 VRAM, ~45,0 GiB netto nutzbar) + 61 GB System-RAM + 32 GB NVMe-Swap  
> **ROCm-Umgebung:** ROCm 6.4 nativ | **KV-Cache:** `q4_0` komprimiert (Standard)  
> 📖 **Vertiefender Leitfaden:** Siehe auch [`GROSSE_MODELLE_HYBRID_VERGLEICH.md`](file:///home/clemi/Projekte/LLM/docs/GROSSE_MODELLE_HYBRID_VERGLEICH.md) für detaillierte Speicherberechnungen, Layer-Splits und Installationsbefehle der 70B–141B Modelle.

---

## 📋 Umfassende Vergleichstabelle (Inkl. Architektur: MoE vs. Dense)

| Modell & Alias | Status | Architektur | Größe & Quant | Hardware-Modus | Vorkonfigurierter Kontext (`num_ctx`) | Maximaler Kontext (Nativ / Skalierung) | Primärer Fokus / Spezialisierung | Coding & Cline (1-10) | Deep Reasoning (1-10) | Allround & Agenten (1-10) | RAG & Kontext (1-10) | Kreativ & Unzensiert (1-10) | Speed auf W7800 | Gesamt Score (100) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 🌐 **`llama3.3-70b-speed`** *(Meta)* | ✅ Installiert | **Dense** *(70B aktiv)* | ~38 GB (`IQ4_XS`) | **100% VRAM** (80/80 Layer) | **32.768 (32k)** | **128k** *(bis 32k voll im VRAM)* | **Weltklasse Allround, Tool-Use & autonome Agenten** | 9.1 | 9.2 | **9.8** 🥇 | 9.4 | 8.8 | **12 t/s (Ollama) / 25,6 t/s (Spek.)** | **95 / 100** |
| ⚡ **`qwen3-next-80b-16k`** | ✅ Installiert | **MoE** *(10/512 aktiv)* | 42 GB (`IQ4_XS`) | 81% GPU / 19% RAM *(40 GPU / 8 RAM)* | **16.384 (16k)** | **64k** *(Hybrid via RAM)* | **Deep Logic, CoT-Denkspuren & komplexe Algorithmen** | 8.5 | **9.7** 🥇 | 8.8 | 8.5 | 8.0 | ⚡ **36,5 t/s** | **92 / 100** |
| ⚡ **`qwen3-next-80b-32k`** | ✅ Installiert | **MoE** *(10/512 aktiv)* | 42 GB (`IQ4_XS`) | 75% GPU / 25% RAM *(36 GPU / 12 RAM)* | **32.768 (32k)** | **64k** *(Hybrid via RAM)* | **Riesiger 32k Denk-Kontext für große Codebasen & Beweise** | 8.5 | **9.7** 🥇 | 8.8 | 9.2 | 8.0 | 🚄 **~28 t/s** | **92 / 100** |
| ⚡ **`qwen3-next-80b`** *(Base)* | ✅ Installiert | **MoE** *(10/512 aktiv)* | 42 GB (`IQ4_XS`) | **100% VRAM** *(kurzer Kontext)* | **8.192 (8k)** | **64k** | **Kompakter Deep-Logic Treiber für Standard-Prompts** | 8.5 | **9.7** 🥇 | 8.8 | 8.2 | 8.0 | ⚡ **~38–40 t/s** | **92 / 100** |
| 💻 **`qwen3-coder`** *(30B)* | ✅ Installiert | **MoE** *(8/128 aktiv)* | 32 GB (`Q8_0`) | **100% VRAM** | **32.768 (32k)** | **128k** *(bis ~44 GB @128k)* | **Primary Driver für Cline: Syntax, Tools & Refactoring** | **9.0** 🥇 | 8.0 | 8.2 | 8.5 | 6.5 | ⚡ **61,6 t/s (Q8) / 80 t/s (Speed)** | **94 / 100** |
| 🎯 **`qwen3.8-35b-distill`** | ✅ Installiert | **MoE** *(8/256 aktiv)* | 30 GB (`Q6_K`) | **100% VRAM** | **65.536 (65k)** | **128k** | **Schneller analytischer Co-Pilot & ausgewogenes Reasoning** | 8.2 | 8.5 | 8.5 | 8.0 | 7.5 | ⚡ **64,7 t/s (gemessen)** | **88 / 100** |
| 🔓 **`qwen3-obliterated`** | ✅ Installiert | **Dense** *(27.3B aktiv)* | 23 GB (`Q6_K`) | **100% VRAM** | **49.152 (~49k)** | **65.536 (65k)** | **100% Unzensiert: Pentesting, Security & neutrale Fakten** | 7.8 | 7.5 | 8.2 | 8.8 | **9.6** 🔓 *(unzensiert)* | ⚡ **17,7 t/s (gemessen)** | **83 / 100** |
| 🎭 **`artemis-31b`** | ✅ Installiert | **Dense** *(30.7B aktiv)* | 33 GB (`Q8_0`) | **100% VRAM** | **32.768 (32k)** | **32.768 (32k)** | **Kreatives Schreiben, Rollenspiel & dialogische Texte** | 7.0 | 7.2 | 8.0 | 8.0 | **9.8** 🎭 *(Kreativ/RP)* | ⚡ **14,7 t/s** | **81 / 100** |
| 👁️ **`qwen2.5vl:7b`** | ✅ Installiert | **Dense** *(8.3B aktiv)* | 6.0 GB *(Standard)* | **100% VRAM** | **32.768 (32k)** | **128k** | **Multimodale Bildanalyse, Screenshots, Diagramme & OCR** | 7.0 | 7.5 | 8.0 | 8.0 | **9.5** 👁️ *(Vision/OCR)* | 🚀 **89,3 t/s (gemessen)** | **80 / 100** |
| 🚀 **`qwen3.8-27b-q8`** | 💡 Empfohlen | **Dense** *(27.3B aktiv)* | ~29 GB (`Q8_0`) | **100% VRAM** | **32.768 (32k)** | **65.536 (65k)** | **Verlustfreie 8-Bit-Präzision, Code & 32k VRAM-Kontext** | **8.3** | **8.0** | **8.5** | **9.0** | 7.5 | ⚡ **~52 t/s** | **84 / 100** |
| 🚀 **`qwen3.8-27b-q4`** | ✅ Installiert | **Dense** *(27.3B aktiv)* | 16 GB (`Q4_0`) | **100% VRAM** | **65.536 (65k)** | **65.536 (65k)** | **Ultra-schneller 65k RAG-Speicherriese für Dokumente** | 7.5 | 7.2 | 7.8 | **9.5** *(65k komplett VRAM)* | 7.0 | 🚀 **75 t/s** | **79 / 100** |
| 👑 **`qwen2.5-72b-speed`** *(Alibaba)* | 📦 Bereit zum Laden | **Dense** *(72.7B aktiv)* | ~39.7 GB (`IQ4_XS`) | **100% VRAM** (80/80 Layer) | **32.768 (32k)** | **128k** *(bis 32k voll im VRAM)* | **Coding- & Syntax-König: Weltweit führendes Open-Source Coding-Modell** | **9.8** 🥇 | 9.5 | 9.4 | 9.2 | 7.5 | **11 t/s (Ollama) / 33,6 t/s (Spek.)** | **96 / 100** |
| 🧠 **`deepseek-r1-70b-speed`** | 📦 Bereit zum Laden | **Dense** *(70B aktiv)* | ~38.0 GB (`IQ4_XS`) | **100% VRAM** (80/80 Layer) | **32.768 (32k)** | **128k** *(bis 32k voll im VRAM)* | **Deep Reasoning & Mathe: Transparente <think>-Denkspuren, o1-mini Niveau** | 9.2 | **10.0** 🥇 | 9.0 | 9.0 | 7.0 | **11 t/s (Ollama) / 14,0 t/s (N-Gram)** | **95 / 100** |
| 👑 **`qwen2.5-72b-quality`** *(Alibaba)* | 💡 TODO (Hybrid) | **Dense** *(72.7B aktiv)* | ~43 GB (`Q4_K_M`) | 85% GPU / 15% RAM *(68 GPU / 12 RAM)* | **16.384 (16k)** | **128k** *(Hybrid via RAM)* | **Weltbester Open-Source Coder, exakte Syntax, JSON & Math** | **9.7** 🥇 | 9.4 | 9.3 | 9.4 | 7.0 | 🚄 **~26–30 t/s** | **96 / 100** |
| 🧠 **`deepseek-r1-70b-quality`** | 💡 TODO (Hybrid) | **Dense** *(70B aktiv)* | ~43 GB (`Q4_K_M`) | 92% GPU / 8% RAM *(74 GPU / 6 RAM)* | **16.384 (16k)** | **128k** *(Hybrid via RAM)* | **Reinrassiges Deep-Reasoning & mathematische Beweisführung** | 9.3 | **9.9** 🥇 | 9.0 | 9.3 | 6.5 | 🚄 **~28–32 t/s** | **95 / 100** |
| 🐘 **`mistral-large-123b`** *(Mistral)* | 💡 TODO (Hybrid) | **Dense** *(123B aktiv)* | ~72 GB (`Q4_K_M`) | 52% GPU / 48% RAM *(46 GPU / 42 RAM)* | **16.384 (16k)** | **128k** *(Hybrid via RAM)* | **Monumentale GPT-4 / Sonnet Klasse, profundes Text- & Reasoning-Verständnis** | 9.3 | 9.5 | **9.7** | 9.6 | 7.8 | 🚶 **~12–16 t/s** | **95 / 100** |
| 🔀 **`mixtral-8x22b`** *(Mistral)* | 💡 TODO (Hybrid) | **MoE** *(39/141B aktiv)* | ~68 GB (`Q3_K_M`) | 57% GPU / 43% RAM *(32 GPU / 24 RAM)* | **16.384 (16k)** | **64k** *(Hybrid via RAM)* | **141B MoE Gigant, flüssig dank nur 39B aktiver Rechenlast** | 8.8 | 9.0 | 9.2 | 9.2 | 8.0 | 🚄 **~18–22 t/s** | **92 / 100** |
| 📚 **`cohere-command-r-plus`** *(Cohere)* | 💡 TODO (Hybrid) | **Dense** *(104B aktiv)* | ~58 GB (`Q3_K_M`) | 56% GPU / 44% RAM *(45 GPU / 35 RAM)* | **16.384 (16k)** | **128k** *(Hybrid via RAM)* | **104B RAG- & Zitationsspezialist für riesige Dokumentensammlungen** | 8.6 | 8.8 | 9.0 | **9.7** | 7.5 | 🚶 **~14–18 t/s** | **90 / 100** |
| 💬 **`llama-3.1-nemotron-70b`** *(Nvidia)* | 💡 TODO (Hybrid) | **Dense** *(70B aktiv)* | ~43 GB (`Q4_K_M`) | 75% GPU / 25% RAM *(60 GPU / 20 RAM)* | **16.384 (16k)** | **128k** *(Hybrid via RAM)* | **Nvidias Flaggschiff-RLHF: Höchste menschliche Dialog- & Antwortpräferenz** | 8.9 | 9.0 | 9.5 | 9.3 | 7.5 | 🚄 **~25–30 t/s** | **93 / 100** |
| 💎 **`qwen2.5-72b-q8`** *(Alibaba)* | 💡 TODO (Hybrid) | **Dense** *(72.7B aktiv)* | ~77 GB (`Q8_0`) | 50% GPU / 50% RAM *(40 GPU / 40 RAM)* | **16.384 (16k)** | **64k** *(Hybrid via RAM)* | **Verlustfreie 8-Bit FP-Präzision auf 72B Basis für absolute Code-Exaktheit** | **9.9** 🥇 | 9.6 | 9.4 | 9.5 | 7.0 | 🚶 **~10–14 t/s** | **96 / 100** |

> ℹ️ **Zusätzliches Hilfsmodell:**  
> **`bge-m3:latest`** (1.2 GB) – Dense Vektorisierungs-Modell (`bert`-Architektur, 567M Parameter) für RAG-Suchindizes (8k Kontext, rein VRAM).

---

## 💡 Was bedeutet MoE vs. Dense für deine Hardware?

* **Dense-Architektur (z. B. Llama 3.3 70B, Artemis 31B, Qwen 27B):**
  * Bei jedem einzelnen generierten Token müssen **100% aller Parameter** durch die Recheneinheiten und den Speicherbus geschleust werden.
  * *Vorteil:* Sehr homogene Wissensrepräsentation, exzellent in Instruktionsbefolgung.
  * *Rechenaufwand:* Höher pro Token, skaliert direkt mit der Parameterzahl.

* **MoE-Architektur (Mixture of Experts – z. B. Qwen3 Next 80B, Qwen3 Coder 30B, Qwen3.8 35B):**
  * Das Modell besitzt zwar enorm viele Gesamtparameter (z. B. 79.7B bei Next-80B oder 30.5B bei Coder-30B), teilt die FFN-Schichten aber in viele kleine „Experten“ auf.
  * **Routing pro Token:** Für jedes Token werden nur wenige Experten dynamisch aktiviert:
    * **`qwen3-next-80b`**: 10 von 512 Experten aktiv ($\approx$ nur 3–4B aktive Rechenlast pro Token).
    * **`qwen3-coder`**: 8 von 128 Experten aktiv ($\approx$ nur 3B aktive Rechenlast pro Token).
    * **`qwen3.8-35b-distill`**: 8 von 256 Experten aktiv ($\approx$ nur 3.5B aktive Rechenlast pro Token).
  * *Der riesige Vorteil auf deiner W7800:* Du erhältst die Denktiefe und das Wissen eines Modells mit 30–80 Milliarden Parametern, aber mit den extrem hohen Rechengeschwindigkeiten eines kleinen 3B–4B Modells (**36 bis 51 t/s**)!

---

## 🔍 Detail-Steckbriefe der Modelle

### 1. `llama3.3-70b-speed` *(Meta Llama 3.3 70B Instruct - IQ4_XS)*
* **Architektur:** **Dense** (70 Milliarden Parameter voll aktiv)
* **Status:** Wird gerade via Hugging Face (`hf.co/bartowski/Llama-3.3-70B-Instruct-GGUF:IQ4_XS`) heruntergeladen.
* **Vorkonfigurierter Kontext:** `num_ctx 16384` (16k) | **Output:** `num_predict 8192`
* **VRAM-Verhalten:** Bei 16k Kontext belegt das Modell ~38 GB + ~2,0 GB KV-Cache = **~40 GB VRAM**. Es verbleiben **~5 GB Puffer** auf der W7800.
* **Kontext-Skalierung:** Kann bei Bedarf auf **32k** (`num_ctx 32768`) gestellt werden und bleibt mit ~42 GB VRAM immer noch zu **100% auf der GPU**.
* **Einsatzgebiet:** Bester Allrounder, komplexe Multi-Step Agenten, Tool Use und strukturierte Textanalysen.

### 2. `qwen3-next-80b-16k` & `qwen3-next-80b-32k` *(80B Thinking)*
* **Architektur:** **MoE** (`qwen3next`, 512 Experten gesamt, 10 aktiv pro Token)
* **Status:** Vollständig eingerichtet und betriebsbereit.
* **Vorkonfigurierter Kontext:** 
  * `qwen3-next-80b-16k`: `num_ctx 16384` (40 Layer GPU / 8 Layer RAM, **36,5 t/s**)
  * `qwen3-next-80b-32k`: `num_ctx 32768` (36 Layer GPU / 12 Layer RAM, **~28 t/s**)
* **Einsatzgebiet:** Höchste logische Denktiefe, mathematische Beweise, algorithmisches Refactoring und transparente `<think>`-Ketten.

### 3. `qwen3-coder` *(Qwen3-Coder-30B-A3B-Instruct - Q8_0)*
* **Architektur:** **MoE** (`qwen3moe`, 128 Experten gesamt, 8 aktiv pro Token)
* **Status:** Betriebsbereit.
* **Vorkonfigurierter Kontext:** `num_ctx 32768` (32k), nativ erweiterbar bis 128k.
* **VRAM-Verhalten:** Läuft zu 100% im VRAM mit rasanten **51,5 t/s**.
* **Einsatzgebiet:** Primärer Coding-Treiber für Cline & VS Code, blitzschnelle Code-Generierung und Tool-Aufrufe.

### 4. `qwen3.8-35b-distill` *(Qwen3.8-35B-A3B-Distill - Q6_K)*
* **Architektur:** **MoE** (`qwen35moe`, 256 Experten gesamt, 8 aktiv pro Token)
* **Status:** Betriebsbereit.
* **Vorkonfigurierter Kontext:** `num_ctx 32768` (32k).
* **VRAM-Verhalten:** 100% VRAM (30 GB Modell + ~2,8 GB Kontext = ~33 GB VRAM).
* **Einsatzgebiet:** Schneller Allrounder und analytischer Co-Pilot mit hoher Geschwindigkeit (**48 t/s**).

### 5. `qwen3-obliterated` *(Qwen3.8-27B-OBLITERATED - Q6_K)*
* **Architektur:** **Dense** (`qwen35`, 27.3B Dense Parameter)
* **Status:** Betriebsbereit.
* **Vorkonfigurierter Kontext:** `num_ctx 49152` (~49k).
* **VRAM-Verhalten:** Durch kompakte 23 GB bleibt enorm viel VRAM für extrem lange Sessions frei.
* **Einsatzgebiet:** Komplett unzensierte Modellantworten, freies Reasoning ohne Content-Filter-Einschränkungen.

### 6. `artemis-31b` *(TheDrummer Artemis-31B-v1.1 - Q8_0)*
* **Architektur:** **Dense** (`gemma4`, 30.7B Dense Parameter)
* **Status:** Betriebsbereit.
* **Vorkonfigurierter Kontext:** `num_ctx 32768` (32k).
* **Einsatzgebiet:** Kreatives Schreiben, Rollenspiel, emotionale Nuancen und dialogorientierte Texte (`temperature: 0.8`).

### 7. `qwen2.5vl:7b` *(Vision & Multimodal)*
* **Architektur:** **Dense** (`qwen25vl`, 8.3B Parameter)
* **Status:** Betriebsbereit.
* **Vorkonfigurierter Kontext:** `num_ctx 32768` (32k).
* **Einsatzgebiet:** Bildanalyse, Diagramm-Auswertung, Screenshots, OCR und multimodale Aufgaben mit **~85 t/s**.

### 8. `qwen3.8-27b-q4` *(Qwen3.8-27B - Q4_0)*
* **Architektur:** **Dense** (`qwen35`, 27.3B Dense Parameter)
* **Status:** Betriebsbereit.
* **Vorkonfigurierter Kontext:** `num_ctx 65536` (65k Tokens).
* **VRAM-Verhalten:** Nur 16 GB Modellgröße $\rightarrow$ voller 65k Kontext passt spielend in die GPU.
* **Einsatzgebiet:** Ultra-schnelle Dokumenten-Durchsuchung und massiver Kontext (**75 t/s**).

---

## 💡 TODO Hybrid-Modelle (Lokal möglich zur maximalen Hardware-Ausnutzung)

Diese Modelle schöpfen deine **48 GB VRAM + 61 GB RAM = ~95 GB nutzbarer Gesamtspeicher** optimal aus. Sie bieten ein Niveau, das an GPT-4 und Claude 3.5 Sonnet heranreicht:

### 9. 👑 `qwen2.5-72b-quality` *(Alibaba Qwen 2.5 72B Instruct - Q4_K_M)*
* **Architektur:** **Dense** (72.7 Milliarden Parameter) | **Größe:** ~43 GB
* **Hardware-Offload:** **68 Layer GPU** (~40 GB VRAM) / **12 Layer RAM** (~7.4 GB System-RAM)
* **Status:** 💡 Vorbereitet in `llm-optimierungen/modelfiles/Modelfile.qwen2.5-72b-quality`
* **Geschwindigkeit:** 🚄 **~26–30 Tokens/s** | **Kontext:** `num_ctx 16384` (erweiterbar bis 128k)
* **Primäre Stärke:** Der weltweite Open-Source Spitzenreiter für Programmier-Syntax, fehlerfreies Tool-Calling und mathematische Korrektheit.

### 10. 🧠 `deepseek-r1-70b-quality` *(DeepSeek-R1-Distill-Llama-70B - Q4_K_M)*
* **Architektur:** **Dense** (70 Milliarden Parameter) | **Größe:** ~43 GB
* **Hardware-Offload:** **74 Layer GPU** (~39.2 GB VRAM) / **6 Layer RAM** (~3.3 GB System-RAM)
* **Status:** 💡 Vorbereitet in `llm-optimierungen/modelfiles/Modelfile.deepseek-r1-70b-quality`
* **Geschwindigkeit:** 🚄 **~28–32 Tokens/s** | **Kontext:** `num_ctx 16384`
* **Primäre Stärke:** Unübertroffen in formaler Deduktion, mathematischen Beweisen und transparenten `<think>`-Schritten.

### 11. 🐘 `mistral-large-123b` *(Mistral Large 2407 - Q4_K_M)*
* **Architektur:** **Dense** (123 Milliarden Parameter!) | **Größe:** ~72 GB
* **Hardware-Offload:** **46 Layer GPU** (~37.7 GB VRAM) / **42 Layer RAM** (~34.3 GB System-RAM)
* **Status:** 💡 Vorbereitet in `llm-optimierungen/modelfiles/Modelfile.mistral-large-123b`
* **Geschwindigkeit:** 🚶 **~12–16 Tokens/s** | **Kontext:** `num_ctx 16384` (bis 128k nativ)
* **Primäre Stärke:** Echtes GPT-4 / Claude 3.5 Sonnet Niveau. Monumentale Sprachbeherrschung, mehrsprachige Synthese und weltweites Spitzenverständnis.

### 12. 🔀 `mixtral-8x22b` *(Mistral AI - Q3_K_M)*
* **Architektur:** **MoE** (141 Milliarden Parameter gesamt, nur 39B aktiv pro Token!) | **Größe:** ~68 GB
* **Hardware-Offload:** **32 Layer GPU** (~38.7 GB VRAM) / **24 Layer RAM** (~29.3 GB System-RAM)
* **Status:** 💡 Vorbereitet in `llm-optimierungen/modelfiles/Modelfile.mixtral-8x22b`
* **Geschwindigkeit:** 🚄 **~18–22 Tokens/s** | **Kontext:** `num_ctx 16384` (bis 64k nativ)
* **Primäre Stärke:** Riesiges Weltwissen bei hoher Recheneffizienz. Trotz 141B Parametern flüssig bedienbar dank MoE-Routing.

### 13. 📚 `cohere-command-r-plus` *(Cohere Command R+ - Q3_K_M)*
* **Architektur:** **Dense** (104 Milliarden Parameter) | **Größe:** ~58 GB
* **Hardware-Offload:** **45 Layer GPU** (~37 GB VRAM) / **35 Layer RAM** (~21 GB System-RAM)
* **Status:** 💡 Lokal ausführbar via Ollama
* **Geschwindigkeit:** 🚶 **~14–18 Tokens/s** | **Kontext:** `num_ctx 16384` (bis 128k)
* **Primäre Stärke:** Weltbester Spezialist für Zitationen, RAG (Retrieval-Augmented Generation) und faktengetreue Aktenanalysen.

### 14. 💬 `llama-3.1-nemotron-70b` *(Nvidia - Q4_K_M)*
* **Architektur:** **Dense** (70 Milliarden Parameter) | **Größe:** ~43 GB
* **Hardware-Offload:** **60 Layer GPU** (~33 GB VRAM) / **20 Layer RAM** (~10 GB System-RAM)
* **Status:** 💡 Lokal ausführbar via Ollama
* **Geschwindigkeit:** 🚄 **~25–30 Tokens/s** | **Kontext:** `num_ctx 16384`
* **Primäre Stärke:** Nvidias meisterhaftes RLHF-Tuning für höchste menschliche Dialogqualität und Nuancenreichtum.

---

## ⚙️ Wie wird der Kontext in Cline oder im Terminal angepasst?

1. **In Cline / Roo-Code (VS Code):**
   * Gehe in die Erweiterungseinstellungen (`Settings` $\rightarrow$ `Ollama`).
   * Wähle das Modell (z. B. `llama3.3-70b-speed` oder `qwen3-coder`).
   * Setze **Context Window** auf den gewünschten Wert (z. B. `16384` oder `32768`).

2. **Dauerhaft im Modelfile anpassen:**
   * Modelfiles liegen in: `/home/clemi/Projekte/LLM/llm-optimierungen/modelfiles/`
   * Wert anpassen:
     ```dockerfile
     PARAMETER num_ctx 32768
     ```
   * Modell aktualisieren:
     ```bash
     ollama create <modell-name> -f /home/clemi/Projekte/LLM/llm-optimierungen/modelfiles/Modelfile.<modell-name>
     ```
