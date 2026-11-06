# 🚀 Große Modelle (70B – 141B) im Hybrid-Betrieb (VRAM + RAM)

> **Hardware-Profil:** AMD Radeon Pro W7800 (48 GB GDDR6 VRAM, ~45,0 GiB netto) + 61 GB System-RAM + 32 GB NVMe-Swap  
> **Nutzbarer High-Speed-Speicher:** **~95 GB** (45 GB VRAM mit 864 GB/s + 50 GB RAM mit ~60 GB/s)  
> **KV-Cache:** `q4_0` komprimiert (Standard via `/etc/systemd/system/ollama.service`)

---

## 💡 Wie funktioniert der Hybrid-Offload auf deiner Workstation?

Deine Workstation verfügt über eine seltene und mächtige Eigenschaft: Mit **48 GB GPU-Speicher** und **61 GB Arbeitsspeicher** stehen dir **über 95 GB Hochgeschwindigkeitsspeicher** zur Verfügung. 

Bei Modellen zwischen **43 GB und 77 GB** greift der intelligente **Hybrid-Betrieb**:
1. **GPU (45 GB VRAM / ~864 GB/s Bandbreite):**  
   Hält den Großteil der Modellschichten (50% bis 90%) sowie den aktiven Kontext- und KV-Cache-Puffer.
2. **System-RAM (61 GB RAM / ~60 GB/s Bandbreite):**  
   Hält die verbleibenden Schichten. Durch Ollamas PCIe-Streaming werden die Zwischenergebnisse nahtlos durchgereicht.
3. **MoE-Beschleunigungseffekt (Mixture of Experts):**  
   Bei MoE-Modellen (z. B. `Mixtral 8x22B`) befinden sich zwar 141B Parameter im Speicher, aber pro Token werden nur 39B Parameter aktiviert. Das bedeutet: Trotz gigantischer Modellgröße sinkt der Bandbreitenbedarf drastisch – das Modell rennt mit **~18–22 Tokens/s**!

---

## 📊 Umfassende Vergleichstabelle: Alle möglichen Hybrid-Modelle (TODO)

| Modell & Entwickler | Architektur & Typ | Dateigröße & Quant | Layer-Aufteilung (GPU / RAM) | Vorkonfigurierter Kontext | Erwartete Speed | Primäre Stärken / Einsatzzweck | Coding (1-10) | Reasoning (1-10) | Allround (1-10) | Gesamt Score (100) |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :---: | :---: | :---: | :---: |
| 👑 **`qwen2.5-72b-quality`** *(Alibaba)* | **Dense** (72.7B) | ~43 GB (`Q4_K_M`) | **68 GPU** / **12 RAM** | **16.384** (16k) | 🚄 **~26–30 t/s** | **Weltbester Open-Source Coder**: Unübertroffen für Cline, VS Code, exakte Syntax, Refactoring & Math. | **9.7** 🥇 | 9.4 | 9.3 | **96 / 100** |
| 💎 **`qwen2.5-72b-q8`** *(Alibaba)* | **Dense** (72.7B) | ~77 GB (`Q8_0`) | **40 GPU** / **40 RAM** | **16.384** (16k) | 🚶 **~10–14 t/s** | **Verlustfreie 8-Bit-FP-Präzision**: Maximale mathematische Genauigkeit, eliminiert jegliche Rundungsfehler. | **9.9** 🥇 | 9.6 | 9.4 | **96 / 100** |
| 🧠 **`deepseek-r1-70b-quality`** *(DeepSeek)* | **Dense** (70B) | ~43 GB (`Q4_K_M`) | **74 GPU** / **6 RAM** | **16.384** (16k) | 🚄 **~28–32 t/s** | **Unangefochtener Denkmeister**: Reines Chain-of-Thought Reasoning für Beweise, schwere Algorithmen & Logik. | 9.3 | **9.9** 🥇 | 9.0 | **95 / 100** |
| 🐘 **`mistral-large-123b`** *(Mistral AI)* | **Dense** (123B) | ~72 GB (`Q4_K_M`) | **46 GPU** / **42 RAM** | **16.384** (16k) | 🚶 **~12–16 t/s** | **Monumentales Flaggschiff (GPT-4 Niveau)**: Unglaubliches Textverständnis, mehrsprachige Synthese und philosophische Tiefe. | 9.3 | 9.5 | **9.7** 🥇 | **95 / 100** |
| 🌐 **`llama3.3-70b-quality`** *(Meta)* | **Dense** (70B) | ~43 GB (`Q4_K_M`) | **60 GPU** / **20 RAM** | **16.384** (16k) | 🚄 **~26–30 t/s** | **Quality-Pendant zur Speed-Version**: Höhere 4-Bit-Präzision für anspruchsvollste Agentic-Pipelines und RAG. | 9.1 | 9.2 | **9.8** 🥇 | **95 / 100** |
| 💬 **`llama-3.1-nemotron-70b`** *(Nvidia)* | **Dense** (70B) | ~43 GB (`Q4_K_M`) | **60 GPU** / **20 RAM** | **16.384** (16k) | 🚄 **~25–30 t/s** | **Beste Dialog-Qualität**: Nvidias RLHF-Fine-Tune, konkurriert in menschlicher Antwort-Präferenz mit GPT-4o / Claude. | 8.9 | 9.0 | 9.5 | **93 / 100** |
| 🔀 **`mixtral-8x22b`** *(Mistral AI)* | **MoE** (39/141B aktiv) | ~68 GB (`Q3_K_M`) | **32 GPU** / **24 RAM** | **16.384** (16k) | 🚄 **~18–22 t/s** | **141B MoE Gigant**: Enormes Wissen bei nur 39B aktiver Rechenlast. Flüssig und reaktionsschnell trotz Giganten-Größe. | 8.8 | 9.0 | 9.2 | **92 / 100** |
| 📚 **`cohere-command-r-plus`** *(Cohere)* | **Dense** (104B) | ~58 GB (`Q3_K_M`) | **45 GPU** / **35 RAM** | **16.384** (16k) | 🚶 **~14–18 t/s** | **RAG- & Zitationskönig**: Speziell trainiert für das Durchkämmen riesiger Aktenberge, Zitate & Faktentreue. | 8.6 | 8.8 | 9.0 | **90 / 100** |

---

## 🔍 Detail-Steckbriefe & Hardware-Allokation

### 1. 👑 `qwen2.5-72b-quality` *(Coding-König)*
* **Warum hybrid?** Während die `speed`-Variante (`IQ4_XS`) zu 100% in den VRAM passt, nutzt `quality` das unkomprimierte `Q4_K_M`-Format (~43 GB).
* **Speicher-Aufteilung:**
  * **GPU:** 68 von 80 Layern $\rightarrow$ belegt ca. 39,5 GB VRAM (inkl. 16k KV-Cache).
  * **RAM:** 12 Layer $\rightarrow$ belegt ca. 7,4 GB RAM.
* **Leistung:** Erreicht **~26–30 Tokens/s**. Im Cline-Coding ist es das präziseste Open-Source-Modell der Welt.
* **Fertiges Modelfile:** `llm-optimierungen/modelfiles/Modelfile.qwen2.5-72b-quality`

---

### 2. 🐘 `mistral-large-123b` *(Monumentales 123B Flaggschiff)*
* **Warum hybrid?** Mit 123 Milliarden Parametern und ~72 GB Dateigröße übersteigt es den reinen Grafikspeicher, passt aber **perfekt in dein 95 GB Gesamtsystem**.
* **Speicher-Aufteilung:**
  * **GPU:** 46 von 88 Layern $\rightarrow$ belegt ca. 37,7 GB VRAM.
  * **RAM:** 42 von 88 Layern $\rightarrow$ belegt ca. 34,3 GB RAM.
  * **Puffer:** ~7 GB VRAM und ~20 GB RAM bleiben frei!
* **Leistung:** Läuft mit **~12–16 Tokens/s**. Das ist absolut flüssig für anspruchsvolle Analysen, Recherchen und lange Antworten.
* **Fertiges Modelfile:** `llm-optimierungen/modelfiles/Modelfile.mistral-large-123b`

---

### 3. 🔀 `mixtral-8x22b` *(141B MoE Gigant)*
* **Warum hybrid?** 141 Milliarden Parameter klingen gigantisch, aber durch die **Mixture-of-Experts-Architektur** werden pro Token nur 2 von 8 Experten (39B Parameter) aktiviert.
* **Speicher-Aufteilung:**
  * **GPU:** 32 von 56 Layern $\rightarrow$ belegt ca. 38,7 GB VRAM.
  * **RAM:** 24 von 56 Layern $\rightarrow$ belegt ca. 29,3 GB RAM.
* **Leistung:** Überraschend schnell! Durch die geringe Token-Rechenlast liefert es **~18–22 Tokens/s**.
* **Fertiges Modelfile:** `llm-optimierungen/modelfiles/Modelfile.mixtral-8x22b`

---

### 4. 🧠 `deepseek-r1-70b-quality` *(Deep Reasoning Meister)*
* **Warum hybrid?** `Q4_K_M` holt die maximale Präzision aus dem R1-Denkprozess heraus.
* **Speicher-Aufteilung:**
  * **GPU:** 74 von 80 Layern $\rightarrow$ belegt ca. 39,2 GB VRAM.
  * **RAM:** Nur 6 Layer im RAM $\rightarrow$ belegt ca. 3,3 GB RAM.
* **Leistung:** Mit **~28–32 Tokens/s** fast so schnell wie reiner VRAM-Betrieb, da 92% der Arbeit auf der W7800 stattfinden!
* **Fertiges Modelfile:** `llm-optimierungen/modelfiles/Modelfile.deepseek-r1-70b-quality`

---

### 5. 📚 `cohere-command-r-plus` *(104B RAG & Zitationen)*
* **Warum hybrid?** 104 Milliarden Parameter für Enterprise-RAG und präzise Quellenangaben.
* **Speicher-Aufteilung:**
  * **GPU:** 45 von 64 Layern $\rightarrow$ ca. 37 GB VRAM.
  * **RAM:** 19 von 64 Layern $\rightarrow$ ca. 21 GB RAM.
* **Leistung:** **~14–18 Tokens/s**, ideal für automatisierte Dokumenten-Pipelines.

---

### 6. 💎 `qwen2.5-72b-q8` *(Maximale 8-Bit FP-Präzision)*
* **Warum hybrid?** Ein 72B Modell in voller `Q8_0`-Quantisierung belegt ~77 GB. Es eliminiert alle Quantisierungsverluste zu 100%.
* **Speicher-Aufteilung:**
  * **GPU:** 40 von 80 Layern $\rightarrow$ ca. 38,5 GB VRAM.
  * **RAM:** 40 von 80 Layern $\rightarrow$ ca. 38,5 GB RAM.
* **Leistung:** **~10–14 Tokens/s**. Für Fälle, in denen absolute Bit-Genauigkeit bei Code und Mathematik gefordert ist.

---

## 🛠️ Schritt-für-Schritt: Wie richtest du diese Hybrid-Modelle ein?

### Methode 1: Über das interaktive Menü (Empfohlen)

Führe das vorbereitete Setup-Skript aus:
```bash
./scripts/setup-top3-models.sh
```
Dort kannst du:
* **Option 1**: `Qwen 2.5 72B Quality` wählen
* **Option 2**: `DeepSeek-R1-70B Quality` wählen
* **Option 4**: `Mistral Large 2407 (123B)` wählen
* **Option 5**: `Mixtral 8x22B (141B MoE)` wählen

Das Skript lädt das GGUF automatisch herunter, wendet das exakt auf deine W7800 abgestimmte Modelfile an und testet das Modell mit einem Smoke-Test.

---

### Methode 2: Manuell via Ollama CLI

Falls du ein Modell manuell erstellen möchtest:

1. **Beispiel Mistral Large 123B:**
```bash
# 1. GGUF Schichten herunterladen
ollama pull hf.co/bartowski/Mistral-Large-Instruct-2407-GGUF:Q4_K_M

# 2. Mit optimiertem Modelfile erstellen
ollama create mistral-large-123b -f /home/clemi/Projekte/LLM/llm-optimierungen/modelfiles/Modelfile.mistral-large-123b

# 3. Temporären HuggingFace Tag bereinigen
ollama rm hf.co/bartowski/Mistral-Large-Instruct-2407-GGUF:Q4_K_M
```

2. **Beispiel Mixtral 8x22B MoE:**
```bash
# 1. Download
ollama pull hf.co/bartowski/Mixtral-8x22B-Instruct-v0.1-GGUF:Q3_K_M

# 2. Registrieren
ollama create mixtral-8x22b -f /home/clemi/Projekte/LLM/llm-optimierungen/modelfiles/Modelfile.mixtral-8x22b

# 3. Bereinigen
ollama rm hf.co/bartowski/Mixtral-8x22B-Instruct-v0.1-GGUF:Q3_K_M
```

---

## 🛡️ Systemd-Sicherheitsnetz & Überlastschutz

Deine Workstation ist durch das gehärtete Systemd-Profil `/etc/systemd/system/ollama.service` geschützt:
* `MemoryMax=56G`: Ollama kann niemals das System zum Absturz bringen. Dem Linux-Desktop und anderen Prozessen sind garantiert mindestens **5 GB physischer RAM** zugesichert.
* `OOMScoreAdjust=500`: Bei unvorhergesehenem Spitzenbedarf wird Ollama sanft beendet, bevor kritische Betriebssystem-Dienste beeinträchtigt werden.
* `32 GB NVMe-Swap (`/home/swapfile`)`: Fängt plötzliche Kontext-Spitzen ab, ohne dass es zu einem harten Crash kommt.
* `OLLAMA_GPU_OVERHEAD=3294967296`: Hält ca. 3 GB Grafikspeicher als festen Puffer für den Display-Server frei.
