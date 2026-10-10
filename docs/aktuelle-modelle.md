# Übersicht der aktuellen LLM-Modelle (Ollama)

> **Hardware:** AMD Radeon Pro W7800 (48 GB VRAM, Netto ~45,0 GiB) | ROCm 6.4 nativ  
> 📘 **Vollständige Modellbewertung & Benchmarks:** Siehe zentrales Dokument [`../../docs/MODELL_UEBERSICHT_UND_BEWERTUNG.md`](../../docs/MODELL_UEBERSICHT_UND_BEWERTUNG.md)  

---

## 📋 Modell-Übersicht

| Modell / Alias | Dateigröße / VRAM | Basis / Quantisierung | Empfohlener Kontext (`num_ctx`) | Haupt-Einsatzzweck & Profil |
| :--- | :--- | :--- | :--- | :--- |
| **`qwen3-coder`** | 32 GB (bis 44 GB @128k) | `Qwen3-Coder-30B-A3B-Instruct (Q8_0)` | **32.768** *(bis 128k möglich)* | **Primary Coding Driver**: Höchste Präzision bei Syntax, Refactoring und stabilem Tool-Calling in Cline. |
| **`qwen3.8-35b-distill`** | 30 GB | `Qwen3.8-35B-A3B-Distill (Q6_K)` | **32.768** | **Schneller Allrounder & Reasoning**: Sehr ausgewogenes Verhältnis aus Geschwindigkeit und logischer Tiefe. |
| **`qwen3-next-80b`** | 42 GB | `Qwen3-Next-80B-A3B-Thinking (IQ4_XS)` | **8.192** *(Output-Buffer: 16k)* | **Deep Logic & Math Thinking**: Für komplexe mathematische Beweise, tiefe Logikketten und ausführliches Reasoning. |
| **`hermes3-70b`** | 37 GB | `Hermes-3-Llama-3.1-70B (IQ4_XS)` | **16.384** | **General Reasoning & Agentic Tool-Use**: Hervorragend für strukturierte Workflows, Funktionsaufrufe und Agenten. |
| **`artemis-31b`** | 33 GB | `TheDrummer_Artemis-31B-v1.1 (Q8_0)` | **32.768** | **Creative Writing & Roleplay**: Lebendige Formulierung, kreatives Schreiben und Dialoge (`temperature: 0.8`). |
| **`qwen3-obliterated`** | 23 GB | `Qwen3.8-27B-OBLITERATED (Q6_K)` | **49.152** | **Unzensierter Allrounder**: Großer VRAM-Headroom für lange Kontexte ohne Filter-Einschränkungen. |
| **`qwen3.8-27b-q8`** | 32 GB | `Qwen3.8-27B (UD-Q8_K_XL)` | **32.768** | **Q8 High-Precision Base**: Nahezu verlustfreie Präzision für Evaluierung und Vergleiche. |
| **`qwen3.8-27b-q4`** | 16 GB | `Qwen3.8-27B (Q4_0)` | **65.536** | **Ultra-schneller Speicher-Champion**: Kompakte Größe erlaubt gigantische 64k Kontextfenster im VRAM. |

---

## ⚙️ Wichtige Start- & Kontext-Parameter

* **Thinking-Modus (z. B. `qwen3-next-80b`):**  
  `temperature: 1.0`, `top_p: 0.95`, `presence_penalty: 0.0`
* **Instruct-Modus (z. B. `qwen3-coder`):**  
  `temperature: 0.2` bis `0.7`, `top_p: 0.8`, `presence_penalty: 1.5`
* **Cline (VS Code):** Kontext zwingend manuell auf **`32768`** setzen!
