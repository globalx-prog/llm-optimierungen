
## ⏱️ Vollständiger lokaler Hardware-Benchmark aller installierten Modelle (5. November 2026)

* **Hardware-Plattform:** AMD Radeon Pro W7800 (48 GB GDDR6)
* **GPU-Modus:** 230W uncapped (Hochleistung) | **KV-Cache:** q4_0
* **Testparameter:** 16.384 Tokens Kontextfenster (`num_ctx`), 256 Ausgabe-Tokens (`num_predict`), QuickSort-Algorithmus & Typisierung.

| Modell-Name | Architektur / Quantisierung | Prefill (Prompt-Eval) | Generation (Eval Speed) | VRAM-Peak (von 48 GB) | Gesamtzeit (256 Tok) | Status / Einsatzbereich |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **`qwen3-coder-speed`** | 30B MoE (3.3B aktiv, Q4_K_M) | **72,11 t/s** | ⚡ **75,36 t/s** | **20,6 GB** | 9,07 s | 🥇 Nr. 1 Speed-Coder (Agenten & Cline) |
| **`qwen3-coder-quality`** | 30B MoE (Q8_0 verlustfrei) | **134,86 t/s** | 🚀 **61,56 t/s** | **33,5 GB** | 11,35 s | 🥇 Nr. 1 Qualitäts-Coder (FP16-Präzision) |
| **`qwen3.8-35b-distill`** | 35B Distill (Q6_K) | **149,93 t/s** | 🚀 **64,68 t/s** | **30,3 GB** | 15,58 s | 🌟 Alltags-Sweet-Spot (Allround & Chat) |
| **`deepseek-r1-70b-speed`** | 70B Reasoning (IQ4_XS) | **132,63 t/s** | **10,43 t/s** *(13,95 t/s spec.)* | **39,2 GB** | 33,09 s | 🧠 Reasoning & mathematische Beweise |
| **`llama3.3-70b-speed`** | 70B Dense (IQ4_XS) | **149,45 t/s** | **10,07 t/s** *(25,64 t/s spec.)* | **39,2 GB** | 35,41 s | 🌐 Allround-Flaggschiff & Tool-Use |
| **`llama3.3-70b-abliterated-speed`** | 70B Dense (IQ4_XS unzensiert) | **159,92 t/s** | **9,97 t/s** *(30,02 t/s spec.)* | **39,6 GB** | 34,79 s | 🔥 Unzensiertes Flaggschiff ohne Filter |
| **`qwen2.5-72b-speed`** | 72B Dense (IQ4_XS) | **138,35 t/s** | **9,09 t/s** *(33,57 t/s spec.)* | **41,3 GB** | 36,85 s | 👑 Syntax- & Coding-Referenz 72B |

---

## 🚀 Spekulatives Decoding Benchmark (llama-swap ROCm) vs. Ollama Standard
* **Hardware:** AMD Radeon Pro W7800 (48 GB GDDR6) | Power-Profil: Hochleistung (230W uncapped)
* **Kontext-Allokation:** `16384` Tokens (Q4_0 KV-Cache) | **Testprompt:** Python QuickSort Algorithmus

| Modell | Architektur & Spekulations-Methode | Ollama Standard | llama-swap Spekulativ | Speedup-Faktor | Draft-Akzeptanz | VRAM-Peak |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Qwen 2.5 72B Instruct** | 72B Dense + Qwen2.5-0.5B Draft | 9,09 t/s | **33,57 t/s** | ⚡ **3,69x (+269%)** | **97,1%** (101/104) | 42,0 GB |
| **Llama 3.3 70B Abliterated** | 70B Dense + Llama-3.2-1B Draft | 9,97 t/s | **30,02 t/s** | ⚡ **3,01x (+201%)** | **81,4%** (92/113) | 40,3 GB |
| **Meta Llama 3.3 70B** | 70B Dense + Llama-3.2-1B Draft | 10,07 t/s | **25,64 t/s** | ⚡ **2,55x (+155%)** | **71,6%** (83/116) | 40,2 GB |
| **DeepSeek-R1 Distill 70B** | 70B Distill + N-Gram Context Lookup | 10,43 t/s | **13,95 t/s** | 🚀 **1,34x (+34%)** | *0 MB Extra-VRAM* | 39,1 GB |

> **Erkenntnis:** Durch das spekulative Decoding mit Draft-Modellen in `llama-swap` wird die Inferenz der 70B/72B Klasse um den Faktor **2,5x bis 3,7x** beschleunigt. Qwen 2.5 72B erreicht sensationelle **33,57 Tokens/s** bei einer Draft-Trefferquote von **97,1%**!

## ⏱️ Benchmark-Lauf vom 2026-11-05 22:35:18
* **Hardware:** AMD Radeon Pro W7800 (48 GB GDDR6) | Power-Profil: Aktiv
* **Kontext-Ziel:** `16384` Tokens | **Modus:** standard

| Modell | Kontext | Prefill (Prompt-Eval) | Generation (Eval) | VRAM-Peak | Gesamtdauer |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **llama3.3-70b-abliterated-speed:latest** | `16384` | 162.83 t/s | **13.61 t/s** | 39.8G / 45G | 27.04 s |
| **qwen3-coder-speed:latest** | `16384` | 98.93 t/s | **78.94 t/s** | 20.8G / 45G | 8.90 s |
| **qwen3-coder-quality:latest** | `16384` | 130.36 t/s | **62.70 t/s** | 33.5G / 45G | 10.80 s |
| **qwen2.5-72b-speed:latest** | `16384` | 50.18 t/s | **11.91 t/s** | 41.4G / 45G | 32.29 s |
| **deepseek-r1-70b-speed:latest** | `16384` | 85.23 t/s | **13.05 t/s** | 39.3G / 45G | 28.47 s |
| **qwen3.8-35b-distill:latest** | `16384` | 112.85 t/s | **66.60 t/s** | 30.4G / 45G | 10.95 s |
| **llama3.3-70b-speed:latest** | `16384` | 163.93 t/s | **12.91 t/s** | 39.2G / 45G | 28.07 s |
| **qwen3-obliterated:latest** | `16384` | 122.64 t/s | **17.19 t/s** | 24.1G / 45G | 21.67 s |
| **qwen2.5vl:7b** | `16384` | 816.56 t/s | **89.25 t/s** | 9.1G / 45G | 3.05 s |
| **deepseek-r1-70b-speculative** | `16384` | 123.61 t/s | **13.14 t/s** | 39.1G / 45G | 19.80 s |
| **llama3.3-70b-abliterated-speculative** | `16384` | 149.36 t/s | **27.42 t/s** | 40.5G / 45G | 9.67 s |
| **llama3.3-70b-speculative** | `16384` | 149.48 t/s | **24.87 t/s** | 40.5G / 45G | 10.61 s |
| **qwen2.5-72b-ngram** | `16384` | 143.67 t/s | **11.80 t/s** | 40.7G / 45G | 21.98 s |
| **qwen2.5-72b-speculative** | `16384` | 143.33 t/s | **20.23 t/s** | 41.4G / 45G | 12.91 s |

---

## ⏱️ Benchmark-Lauf vom 2026-11-05 (32k Vollkontext-Stresstest, 16.232 Tokens Prefill)
* **Hardware:** AMD Radeon Pro W7800 (48 GB GDDR6) | Power-Profil: Aktiv (230W uncapped)
* **Kontext-Ziel:** `32768` Tokens (Q4_0 KV-Cache) | **Modus:** stress (Payload: 16.232 Tokens Python/Rust/SQL Code)

| Modell | Kontext | Prefill (Prompt-Eval) | Generation (Eval) | Draft-Akzeptanz | VRAM-Peak | Status |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **llama3.3-70b-speculative** | `32768` | **190.58 t/s** | **19.94 t/s** | **80.0%** (36/45) | **42.2 GB** / 48 GB | 🟢 Stabil & responsiv unter Vollast |

---

## ⏱️ Großer 32k Vollkontext-Stresstest & Prefill-Benchmark (2026-11-05 23:16:17)
* **Hardware:** AMD Radeon Pro W7800 (48 GB GDDR6) | Power-Profil: Aktiv (230W uncapped)
* **Kontext-Ziel:** `32768` Tokens (Q4_0 KV-Cache) | **Modus:** stress (Payload: ~16.200 Tokens realer Python-, Rust- und SQL-Code)
* **Testumfang:** 9 Modelle im Volllast-Vergleich bei 50% vorbefülltem Kontext

| Modell | Kontext | Prefill (Prompt-Eval) | Generation (Eval) | VRAM-Peak (von 48 GB) | Gesamtdauer | Architektur & Status |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **`qwen3-coder-speed:latest`** | `32768` | ⚡ **1573,66 t/s** | 🚀 **50,31 t/s** | **20,9 GB** / 45 GB | 33,70 s | 30B MoE (3.3B aktiv) — **1,5k t/s Prefill!** |
| **`qwen3-coder-quality:latest`** | `32768` | ⚡ **1773,38 t/s** | 🚀 **43,00 t/s** | **33,7 GB** / 45 GB | 37,18 s | 30B MoE (Q8_0 verlustfrei) — Höchste Präzision |
| **`qwen3.8-35b-distill:latest`** | `32768` | ⚡ **1750,12 t/s** | 🚀 **48,79 t/s** | **30,3 GB** / 45 GB | 37,59 s | 35B Dense (Q6_K) — Blitzschnelle Prompt-Verarbeitung |
| **`llama3.3-70b-speculative`** | `32768` | **193,84 t/s** | **22,26 t/s** | **42,4 GB** / 45 GB | 124,17 s | 70B Dense + 1B Draft — **+149% Speedup** unter Vollast |
| **`llama3.3-70b-abliterated-speculative`** | `32768` | **193,97 t/s** | **19,64 t/s** | **42,3 GB** / 45 GB | 135,80 s | 70B Dense Unzensiert + 1B Draft — **+105% Speedup** |
| **`qwen2.5-72b-speculative`** | `32768` | **190,72 t/s** | **16,16 t/s** | **42,9 GB** / 45 GB | 149,41 s | 72B Dense + 0.5B Draft — **+81% Speedup** vs N-Gram |
| **`qwen3-obliterated:latest`** | `32768` | **504,86 t/s** | **14,09 t/s** | **24,6 GB** / 45 GB | 87,76 s | 27B Dense Unzensiert |
| **`deepseek-r1-70b-speculative`** | `32768` | **198,23 t/s** | **9,37 t/s** | **40,3 GB** / 45 GB | 191,03 s | 70B Reasoning (N-Gram Kontext-Lookup) |
| **`qwen2.5-72b-ngram`** | `32768` | **194,09 t/s** | **8,93 t/s** | **41,9 GB** / 45 GB | 199,21 s | 72B Dense Referenz (Reine Basisinferenz) |

---

### 🔬 Zentrale technische Erkenntnisse aus dem 32k Stresstest

1. **Astronomischer Prompt-Prefill bei 30B/35B Modellen (1.500 – 1.770 t/s):**
   * Die Radeon Pro W7800 verarbeitet dank 230W Power-Profil und ROCm Matrix-Kernen **16.200 Code-Tokens in unter 10 Sekunden**.
   * `qwen3-coder-quality` erreicht mit **1773 t/s** den Spitzenwert beim Einlesen großer Codebasen.

2. **Dauerhafter Spekulativer Speedup auch bei 32k Vollbelegung:**
   * Trotz maximal gefülltem Kontext liefert `llama3.3-70b-speculative` mit **22,26 Tokens/s** mehr als das **2,4-Fache** der reinen Basisinferenz (~9 t/s).
   * `qwen2.5-72b-speculative` hält mit **16,16 t/s** einen deutlichen Vorsprung gegenüber N-Gram (8,93 t/s).

3. **Der ultimative VRAM-Machbarkeitsbeweis für 32k Kontext:**
   * Der höchste gemessene VRAM-Peak lag bei **42,9 GB** (`qwen2.5-72b-speculative`).
   * Bei einem verfügbaren Budget von ca. 45,0 GB verbleiben selbst beim größten 72B-Modell **2,1 GB bis 4,7 GB sicherer Headroom** auf der W7800.
   * **Ergebnis:** Alle 70B- und 72B-Modelle laufen bei 32.768 Tokens zu **100% im VRAM**. Es gab **keine OOM-Fehler, kein Einfrieren und kein Auslagern in langsamen System-RAM oder NVMe-Swap**.

4. **MoE VRAM-Effizienz:**
   * `qwen3-coder-speed` belegt bei vollen 32k Tokens nur **20,9 GB VRAM** (weniger als die Hälfte des W7800 Speichers) und generiert weiterhin mit **über 50 Tokens/s**.

---
