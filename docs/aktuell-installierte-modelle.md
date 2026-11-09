# Übersicht der aktuellen LLM-Modelle (Ollama)

> **Hardware:** AMD Radeon Pro W7800 (48 GB VRAM, Netto ~45,0 GiB) | ROCm 6.4 nativ  
> 📘 **Vollständige Modellbewertung & Benchmarks:** Siehe zentrales Dokument [`../../docs/MODELL_UEBERSICHT_UND_BEWERTUNG.md`](../../docs/MODELL_UEBERSICHT_UND_BEWERTUNG.md)  

---

## 📋 Modell-Übersicht

| Modell / Alias | Dateigröße / VRAM | Basis / Quantisierung | Empfohlener Kontext (`num_ctx`) | Haupt-Einsatzzweck & Profil |
| :--- | :--- | :--- | :--- | :--- |
| **`llama3.3-70b-speed`** | 35.3 GB | `Llama-3.3-70B-Instruct (IQ4_XS)` | **32.768** *(100% VRAM)* | **Weltklasse Allround & Agenten**: Metas stärkstes 70B-Modell, blitzschnell (~42–48 t/s) für Tool-Use und Reasoning. |
| **`qwen3-coder`** | 30.3 GB (bis 44 GB @128k) | `Qwen3-Coder-30B-A3B-Instruct (Q8_0)` | **32.768** *(bis 128k möglich)* | **Primary Coding Driver**: Höchste Präzision bei Syntax, Refactoring und stabilem Tool-Calling in Cline (~51 t/s). |
| **`qwen3.8-35b-distill`** | 28.0 GB | `Qwen3.8-35B-A3B-Distill (Q6_K)` | **65.536** *(100% VRAM)* | **Schneller Allrounder & Reasoning**: Sehr ausgewogenes Verhältnis aus Speed (~48 t/s) und 64k Kontextfenster. |
| **`qwen3-next-80b-16k`** | 39.9 GB | `Qwen3-Next-80B-A3B-Thinking (IQ4_XS)` | **16.384** *(Output-Buffer: 16k)* | **Deep Logic & Math Thinking**: Für komplexe mathematische Beweise, tiefe Logikketten und ausführliches Reasoning. |
| **`qwen3-next-80b-32k`** | 39.9 GB | `Qwen3-Next-80B-A3B-Thinking (IQ4_XS)` | **32.768** *(Hybrid VRAM+RAM)* | **Deep Logic (Long Context)**: Großer 32k Reasoning-Puffer für ausgedehnte logische Ableitungen (~28 t/s). |
| **`artemis-31b`** | 31.5 GB | `TheDrummer_Artemis-31B-v1.1 (Q8_0)` | **32.768** | **Creative Writing & Roleplay**: Lebendige Formulierung, kreatives Schreiben und Dialoge (`temperature: 0.8`). |
| **`qwen3-obliterated`** | 21.8 GB | `Qwen3.8-27B-OBLITERATED (Q6_K)` | **49.152** | **Unzensierter Allrounder**: Großer VRAM-Headroom für lange Kontexte ohne Filter-Einschränkungen (~60 t/s). |
| **`qwen2.5vl:7b`** | 5.6 GB | `Qwen2.5-VL-7B-Instruct (Q4_K_M)` | **32.768** *(100% VRAM)* | **Multimodal / Vision**: Bildanalyse, Diagramme, Screenshots und OCR (~85 t/s). |
| **`bge-m3`** | 1.1 GB | `BAAI/bge-m3 (F16)` | **8.192** | **Embedding / Vektorsuche**: Dense Retrieval für RAG und semantische Suche. |

---

## ⚙️ Wichtige Start- & Kontext-Parameter

* **Thinking-Modus (z. B. `qwen3-next-80b`):**  
  `temperature: 1.0`, `top_p: 0.95`, `presence_penalty: 0.0`
* **Instruct-Modus (z. B. `qwen3-coder`):**  
  `temperature: 0.2` bis `0.7`, `top_p: 0.8`, `presence_penalty: 1.5`
* **Cline (VS Code):** Kontext zwingend manuell auf **`32768`** setzen!
