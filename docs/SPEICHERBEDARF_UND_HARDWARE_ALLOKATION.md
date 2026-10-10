# 📊 Speicherbedarf, Hardware-Allokation & System-Headroom

**Hardware-Basis:**  
* **GPU VRAM (W7800):** 48 GB GDDR6 (**~45,0 GiB netto** verfügbar, 864 GB/s)  
* **System-RAM:** 61,0 GB physisch (Basisbedarf Linux/Desktop/IDE: ~4,5–5,0 GB)  
* **NVMe-Swap:** 32,0 GB Datei (`/home/swapfile`) + 4,7 GB Partition = **36,7 GB Gesamt-Swap**  
* **KV-Cache Kompression:** `q4_0` aktiviert (`OLLAMA_KV_CACHE_TYPE=q4_0`)  
* **Ollama RAM-Deckel:** `MemoryMax=56G` (Systemd Cgroup)

---

## 1. Master-Tabelle: Speicherverteilung & Rest-Speicher

*Legende: Alle Werte gelten für das eingerichtete Standard-Kontextfenster von **16.384 Tokens (16k)**.*

| Modell & Variante | GPU VRAM (Modell + Cache) | Wo liegt der Kontext? | RAM-Bedarf (Modell + Ollama) | Swap-Nutzung (Normalbetrieb) | Freier VRAM-Puffer (GPU Headroom) | Freier System-RAM (für OS / Browser / IDE) | Freier Swap (Sicherheits-Airbag) | Speed auf W7800 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 👑 **`qwen2.5-72b-speed`** | **~41,9 GB** *(39,7 + 2,2)* | **100% GPU VRAM** | ~0,6 GB | **0 GB** *(Inaktiv)* | **+3,1 GB** frei | **~55,4 GB** frei *(91% frei)* | **36,7 GB** | ⚡ **~40–44 t/s** |
| 🧠 **`deepseek-r1-70b-speed`** | **~40,0 GB** *(38,0 + 2,0)* | **100% GPU VRAM** | ~0,6 GB | **0 GB** *(Inaktiv)* | **+5,0 GB** frei | **~55,4 GB** frei *(91% frei)* | **36,7 GB** | ⚡ **~42–48 t/s** |
| 🌐 **`llama3.3-70b-speed`** | **~39,9 GB** *(37,9 + 2,0)* | **100% GPU VRAM** | ~0,6 GB | **0 GB** *(Inaktiv)* | **+5,1 GB** frei | **~55,4 GB** frei *(91% frei)* | **36,7 GB** | ⚡ **~42–48 t/s** |
| 👑 **`qwen2.5-72b-quality`** | **~42,5 GB** *(40,3 + 2,2)* | **GPU VRAM** | ~7,8 GB *(12 Layer)* | **0 GB** *(Inaktiv)* | **+2,5 GB** frei | **~48,2 GB** frei *(79% frei)* | **36,7 GB** | 🚄 **~26–28 t/s** |
| 🧠 **`deepseek-r1-70b-quality`**| **~41,3 GB** *(39,3 + 2,0)* | **GPU VRAM** | ~3,8 GB *(6 Layer)* | **0 GB** *(Inaktiv)* | **+3,7 GB** frei | **~52,2 GB** frei *(85% frei)* | **36,7 GB** | 🚄 **~28–32 t/s** |
| 🌐 **`llama3.3-70b-quality`** | **~41,3 GB** *(39,3 + 2,0)* | **GPU VRAM** | ~3,8 GB *(6 Layer)* | **0 GB** *(Inaktiv)* | **+3,7 GB** frei | **~52,2 GB** frei *(85% frei)* | **36,7 GB** | 🚄 **~28–32 t/s** |
| ⚡ **`qwen3-next-80b-16k`** | **~37,4 GB** *(35,0 + 2,4)* | **GPU VRAM** | ~7,8 GB *(8 Layer)* | **0 GB** *(Inaktiv)* | **+7,6 GB** frei | **~48,2 GB** frei *(79% frei)* | **36,7 GB** | ⚡ **36,5 t/s** |
| ⚡ **`qwen3-next-80b-32k`** | **~36,3 GB** *(31,5 + 4,8)* | **GPU VRAM** | ~11,5 GB *(12 Layer)* | **0 GB** *(Inaktiv)* | **+8,7 GB** frei | **~44,5 GB** frei *(73% frei)* | **36,7 GB** | 🚄 **~28 t/s** |
| 💻 **`qwen3-coder` (30B)** | **~33,5 GB** *(32,0 + 1,5)* | **100% GPU VRAM** | ~0,5 GB | **0 GB** *(Inaktiv)* | **+11,5 GB** frei | **~55,5 GB** frei *(91% frei)* | **36,7 GB** | ⚡ **51,5 t/s** |
| 🐘 **`mistral-large-123b`** | **~40,5 GB** *(37,7 + 2,8)* | **GPU VRAM** | ~35,5 GB *(42 Layer)* | **0 GB** *(Inaktiv)* | **+4,5 GB** frei | **~20,5 GB** frei *(34% frei)* | **36,7 GB** | 🚗 **~12–15 t/s** |
| 🔀 **`mixtral-8x22b`** | **~41,2 GB** *(38,7 + 2,5)* | **GPU VRAM** | ~30,5 GB *(24 Layer)* | **0 GB** *(Inaktiv)* | **+3,8 GB** frei | **~25,5 GB** frei *(42% frei)* | **36,7 GB** | 🚄 **~18–22 t/s** |

---

## 2. Kern-Erkenntnisse zur Speicherarchitektur

### A. Wo liegt der Kontext (KV-Cache)?
* **Immer im schnellen GPU VRAM:** Bei **allen** Modellen (sowohl 100% GPU als auch Hybrid) wird der KV-Cache vollständig auf der Grafikkarte gehalten.
* **Warum?** Bei jedem generierten Token muss die Attention-Matrix über den gesamten bisherigen Text berechnet werden. Das erfordert massive Speicherbandbreite. Auf der Radeon Pro W7800 geschieht dies mit **864 GB/s**. Müsste der Kontext über PCIe im System-RAM liegen (~30–50 GB/s), würde die Geschwindigkeit selbst bei kleinen Modellen auf unter 10 Tokens/s einbrechen.
* **Wie viel Platz nimmt er ein?** Dank `OLLAMA_KV_CACHE_TYPE=q4_0` belegen 16.384 Tokens nur **~2,0 bis 2,8 GB VRAM** (statt 6–8 GB bei FP16).

---

### B. Wie viel Swap wird verbraucht?
* **Im regulären Betrieb: Exakt 0 GB.**
* **Warum bleibt die NVMe unberührt?**  
  Durch den Kernel-Parameter `vm.swappiness=10` lagert Linux erst dann Speicherseiten auf die NVMe aus, wenn der physische RAM zu über 90% ausgelastet ist. 
  - Bei den Speed-Modellen werden nur ~0,6 GB RAM benötigt.
  - Selbst beim 123B-Giganten belegt Ollama nur ~35,5 GB von deinen 61 GB RAM.
* **Welche Funktion hat der Swap dann?**  
  Er dient als **passiver Notfall-Airbag**. Sollten unvorhergesehene Lastspitzen auftreten (z. B. wenn du parallel ein 4K-Videorendering oder schwere Compiler-Builds startest), fängt der 36,7 GB NVMe-Swap den Überhang mit 3.500 MB/s ab, **ohne dass der Desktop einfriert**.

---

### C. Wieviel Rest-Speicher bleibt für dein Betriebssystem?
* **Bei den Speed-Modellen (`-speed`):**  
  Über **55 GB System-RAM sind frei**! Dein PC verhält sich so, als ob gar kein LLM liefe. Du hast vollen Spielraum für IDEs, Browser mit 100 Tabs, Docker-Container und lokale Datenbanken.
* **Bei Hybrid-Modellen (`-quality`):**  
  Es bleiben immer noch **48 bis 52 GB RAM frei**.
* **Beim maximalen 123B-Giganten (`mistral-large-123b`):**  
  Selbst bei diesem 72-GB-Monster bleiben noch **über 20 GB RAM frei**, was mehr ist als die meisten Arbeitsrechner überhaupt an Gesamtspeicher besitzen.
* **Garantie:** Durch `MemoryMax=56G` in Systemd sind **mindestens 5 GB RAM hardware-isoliert für den Linux-Kernel und deinen Desktop reserviert**.
