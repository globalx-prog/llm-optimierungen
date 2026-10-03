# Leitfaden: Kontext-Management & Große Projekte auf AMD Radeon Pro W7800 (48 GB VRAM)

Dieses Handbuch beschreibt die **5 effektivsten Methoden**, wie du mit deinem Setup (AMD Radeon Pro W7800 48 GB VRAM, 64 GB System-RAM, 36 GB NVMe-Swap, Ollama & llama-swap) riesige Codebases und Dokumente verarbeitest, ohne dass dir der Speicher ausgeht.

---

## 🧭 Inhaltsverzeichnis
1. [Das Kernproblem: Warum Kontext den VRAM sprengt](#1-das-kernproblem-warum-kontext-den-vram-sprengt)
2. [Option 1: KV-Cache Quantisierung (q8_0 / q4_0) — 100% im schnellen VRAM](#2-option-1-kv-cache-quantisierung-q8_0--q4_0--100-im-schnellen-vram)
3. [Option 2: KV-Cache Offloading in das 64 GB System-RAM](#3-option-2-kv-cache-offloading-in-das-64-gb-system-ram)
4. [Option 3: RAG & Vektor-Datenbank (ChromaDB in Open WebUI)](#4-option-3-rag--vektor-datenbank-chromadb-in-open-webui)
5. [Option 4: Agentic Tool-Access & Progressive Disclosure (MCP)](#5-option-4-agentic-tool-access--progressive-disclosure-mcp)
6. [Option 5: Prompt-Caching (`--prompt-cache`)](#6-option-5-prompt-caching---prompt-cache)
7. [Entscheidungsmatrix: Wann welche Option?](#7-entscheidungsmatrix-wann-welche-option)

---

## 1. Das Kernproblem: Warum Kontext den VRAM sprengt

Wenn ein LLM ein Token generiert, muss es sich an alle vorherigen Tokens erinnern. Diese Zwischenergebnisse (Attention Keys und Values) werden Schicht für Schicht im sogenannten **KV-Cache** im VRAM abgelegt.

### Die physikalische Formel:
$$\text{VRAM}_{\text{KV}} = 2 \times N_{\text{layers}} \times N_{\text{kv\_heads}} \times D_{\text{head}} \times N_{\text{ctx}} \times \text{BytesPerPrecision}$$

### Was das in der Praxis (FP16 Standard = 2 Bytes) bedeutet:

| Modell-Klasse | Modellgewicht (VRAM) | 8.192 Tokens | 32.768 Tokens | 65.536 Tokens | 131.072 Tokens |
|:---|:---:|:---:|:---:|:---:|:---:|
| **Qwen2.5-Coder-32B** (Q4_K_M) | ~20 GB | + 1,2 GB | + 4,8 GB | + 9,6 GB | + 19,2 GB |
| **Qwen3-Next-80B** (IQ4_XS) | ~42 GB | + 2,1 GB | + 8,5 GB | **+ 17,0 GB 💥** | **+ 34,0 GB 💥** |
| **Llama-3.1-70B** (Q4_K_M) | ~42 GB | + 2,0 GB | + 8,0 GB | **+ 16,0 GB 💥** | **+ 32,0 GB 💥** |

> 💥 **Das Problem:** Bei Modellen mit über 40 GB Grundgewicht führt schon ein Kontext von 32k oder 64k zu **50–60 GB Gesamt-VRAM**. Das überschreitet deine 48 GB und führt zu OOM-Crashes oder drastischen Geschwindigkeitseinbrüchen.

---

## 2. Option 1: KV-Cache Quantisierung (q8_0 / q4_0) — 100% im schnellen VRAM

Dies ist die **effektivste Inferenz-Optimierung**. Anstatt die Keys und Values in 16-Bit (FP16) abzulegen, werden sie komprimiert:

* **`-ctk q8_0 -ctv q8_0` (8-Bit):** Halbiert den VRAM-Verbrauch des Caches (-50%).
* **`-ctk q4_0 -ctv q4_0` (4-Bit):** Viertelt den VRAM-Verbrauch des Caches (-75%).

### VRAM-Vergleich bei 65.536 Tokens Kontext:
| Präzision | 32B Modell Kontext | 70B/80B Modell Kontext | Qualität / Perplexität |
|:---|:---:|:---:|:---:|
| **FP16 (Standard)** | 9,6 GB | 17,0 GB | Referenz (100%) |
| **q8_0** | **4,8 GB** | **8,5 GB** | Keine messbare Einbuße (< 0,05%) |
| **q4_0** | **2,4 GB** | **4,3 GB** | Minimal (< 0,4%) |

### Wie du es nutzen kannst:

#### In `llama-swap` / `llama-server` (Bereits in deiner `config.yaml` integriert!):
In deiner `/home/clemi/Projekte/LLM/llm-optimierungen/configs/llama-swap/config.yaml` ist das Flag `gpu_flags` bereits vorkonfiguriert:
```yaml
macros:
  gpu_flags: >-
    --flash-attn
    -ngl 99
    -ctk q8_0
    -ctv q8_0
    -b 2048
    -ub 512
```

Für **extrem lange Kontexte (bis 131k)** passe das Modell in der Config an:
```yaml
models:
  "qwen-coder-huge-context":
    cmd: |
      llama-server
      -m /models/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf
      -c 131072
      -ctk q4_0 -ctv q4_0
      --flash-attn
      -ngl 99
      --port ${PORT}
```
*Ergebnis:* 20 GB Modell + ~4,8 GB KV-Cache = **nur 24,8 GB VRAM gesamt**. Deine W7800 hat noch 23 GB VRAM frei und generiert mit **25+ Tokens/Sekunde**!

---

## 3. Option 2: KV-Cache Offloading in das 64 GB System-RAM

Wenn du das riesige **80B Reasoning Modell** nutzen willst (welches bereits ~42 GB VRAM für die Gewichte beansprucht) und **keine 4-Bit Cache-Kompression** möchtest:

### Warum KV-Cache-Offloading viel besser ist als Modell-Offloading:
* Beim **Modell-Offload** müssen 40 GB Gewichte bei *jedem einzelnen Token* über den PCIe-Bus transportiert werden (Absturz auf 1–2 t/s).
* Beim **KV-Cache-Offload** liegen die Modellgewichte zu 100% im VRAM. Die GPU liest nur den Token-Verlauf aus dem 64 GB System-RAM nach.
* **Performance:** Bleibt bei **~12–18 Tokens/s** (flüssig lesbar).

### Wie du es nutzen kannst:
In `llama-server` steuerst du den VRAM-Verbrauch so, dass die Gewichte auf der GPU bleiben, der Kontext aber in den Host-RAM allokiert wird:
```bash
llama-server \
  -m /home/models/Qwen3-Next-80B-A3B-Thinking-IQ4_XS.gguf \
  -c 32768 \
  -ngl 99 \
  --flash-attn \
  --threads 12 \
  --host 127.0.0.1 \
  --port 8080
```
Wenn der VRAM voll ist, lagert der Linux-Treiber und llama.cpp den zusätzlichen Kontext-Puffer automatisch in den DDR4/DDR5-RAM aus.

---

## 4. Option 3: RAG & Vektor-Datenbank (ChromaDB in Open WebUI)

### Warum "Alles in den Prompt werfen" eine Falle ist:
Selbst Modelle mit 128k Kontextfenster leiden unter dem sogenannten **"Lost in the Middle"**-Effekt: Details in der Mitte eines 80.000-Wörter-Textes werden oft ignoriert oder halluziniert. Zudem kostet jeder Prompt-Durchlauf Zeit.

### Wie RAG funktioniert:
1. Dein gesamtes Projekt (z. B. 1.000 Quellcodedateien oder PDFs) wird in Chunks zerlegt.
2. Ein lokales Embedding-Modell berechnet Vektoren und speichert sie in **ChromaDB** auf deiner NVMe-SSD.
3. Wenn du eine Frage stellst, sucht ChromaDB in Millisekunden die **3 bis 5 relevantesten Code-Blöcke** heraus.
4. Nur diese relevanten ~2.000 Tokens werden an das Modell geschickt.

### Wie du es in Open WebUI nutzt (Bereits betriebsbereit!):
Dein Open WebUI (`http://localhost:3000`) hat ChromaDB und Vektor-Speicher fest integriert:
1. Öffne Open WebUI im Browser.
2. Klicke links unten auf **Workspace** ➔ **Knowledge** (Wissensdatenbanken).
3. Klicke auf **+ Add Knowledge** und lade dein Projektverzeichnis oder Dokumente hoch.
4. Im Chat gibst du einfach `#` gefolgt vom Namen deiner Wissensdatenbank ein:
   > *"#MeinProjekt Wie ist das Routing im Tunnel-Container aufgebaut?"*
5. **VRAM-Verbrauch:** Nahezu **0 MB extra**. Das Modell antwortet blitzschnell und präzise.

---

## 5. Option 4: Agentic Tool-Access & Progressive Disclosure (MCP)

Das ist die Methode, die moderne Coding-Agenten (wie Antigravity, Claude Code, Cursor) nutzen:

### Das Prinzip:
Statt 100 Dateien auf Vorrat zu lesen, erhält das Modell **Werkzeuge (Tools)**:
* `list_directory`: Das Modell sieht zunächst nur die Ordnerstruktur (~200 Tokens).
* `search_files` (grep): Das Modell sucht nach Funktionen oder Klassen (~500 Tokens).
* `view_file`: Das Modell öffnet **gezielt nur die eine Datei**, die es bearbeiten soll (~1.500 Tokens).

### Wie du es nutzen kannst:
Mit dem vorbereiteten Container **`mcpo`** (aus bumuellps Ökosystem `ghcr.io/bumuellp/mcpo:latest`):
* Der Container exponiert deine lokalen Verzeichnisse und deine lokale SearXNG-Suche über das Model Context Protocol (Port 9000).
* Open WebUI und lokale Agenten können Dateien nach Bedarf "on demand" inspizieren.

---

## 6. Option 5: Prompt-Caching (`--prompt-cache`)

Wenn du wiederholt an derselben großen Codebase arbeitest und der System-Prompt oder Basis-Code gleich bleibt:

### Wie es funktioniert:
Normalerweise muss ein LLM bei jeder neuen Benutzerfrage alle bisherigen Tokens neu evaluieren (Prefill-Phase). Mit Prompt-Caching wird der vorberechnete KV-Cache als Datei auf die NVMe-SSD geschrieben:

```bash
llama-server \
  -m /home/models/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf \
  -c 32768 \
  --prompt-cache /home/clemi/.cache/llama-cache.bin \
  --prompt-cache-all \
  --port 8080
```
*Vorteil:* Bei der 2. Frage entfällt die Berechnungszeit für die ersten 30.000 Tokens komplett – die Antwort beginnt **sofort** ohne spürbare Wartezeit.

---

## 7. Entscheidungsmatrix: Wann welche Option?

| Anwendungsfall | Beste Strategie | VRAM-Bedarf | Geschwindigkeit |
|:---|:---|:---:|:---:|
| **Eine große Datei analysieren** (z. B. 2.000 Zeilen Log/Code) | **Option 1:** Qwen3-32B mit `-ctk q8_0 -ctv q8_0` | ~25 GB VRAM | 🚀 Sehr schnell (~30 t/s) |
| **Mehrere Module querlesen** (bis 65k Tokens) | **Option 1:** Qwen3-32B mit `-ctk q4_0 -ctv q4_0` | ~23 GB VRAM | 🚀 Sehr schnell (~28 t/s) |
| **Schwere Logik auf 80B Modell** mit 32k Kontext | **Option 2:** 80B im VRAM + KV-Cache im 64 GB RAM | 42 GB VRAM + ~9 GB RAM | ⚡ Gut (~12–15 t/s) |
| **Gesamte Repository / Doku durchsuchen** (100+ Dateien) | **Option 3:** Open WebUI Knowledge (RAG / ChromaDB) | Minimal (~2 GB VRAM) | 🚀 Sofortige Antwort |
| **Autonome Code-Bearbeitung / Refactoring** | **Option 4:** Agentic MCP Tools (`view_file`, `grep`) | Dynamisch (nur aktiver Kontext) | 🚀 Höchste Präzision |
