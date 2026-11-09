# Leitfaden: Stabile LLM-Nutzung & VRAM-Sicherheitsarchitektur
**Hardware**: AMD Radeon Pro W7800 (48 GB VRAM, Netto ~45,0 GiB) | 61 GB System-RAM | 32 GB Swap

---

## 1. Ursachen-Analyse: Warum ist das System abgestürzt?

Das System ist nicht durch einen normalen Software-Fehler abgestürzt, sondern durch einen **GPU-Treiber-Freeze (Hardware/Kernel-Lockup)**. Die genaue Ursache in den Logs:

### A. Die 128k-Kontext-Falle in Cline
In den Logs von heute war zu sehen:
```text
slot operator(): new prompt, n_ctx_slot = 128000, n_keep = 4, task.n_tokens = 12845
```
Obwohl das Modell `qwen3-coder` 32 GB groß ist, hat Cline einen **Kontext von 128.000 Tokens (128k)** angefordert.
* Der KV-Cache (Kontext-Speicher) bei 128k Tokens in Standard-Präzision (FP16) benötigt **zusätzliche 14–18 GB VRAM**!
* **32 GB Modell + 16 GB KV-Cache = 48 GB VRAM**.
* Die Karte besitzt netto nur 45,0 GiB. Der VRAM war zu **100% bis aufs letzte Megabyte erschöpft**.

### B. Was passiert bei AMD GPUs (`amdgpu` / ROCm), wenn der VRAM überläuft?
1. **Kein Puffer für den Desktop**: Auf deinem System rendert der Desktop (GNOME / Wayland) auf derselben Grafikkarte (`/dev/dri/card1`). Wenn Ollama 100% des VRAMs beschlagnahmt, kann der Desktop keine Grafik-Puffer mehr anfordern.
2. **GTT-Eviction & Driver-Lockup**: Der AMD-Treiber versucht, überzählige VRAM-Seiten über PCIe in den System-RAM (GTT) auszulagern. Bei massiven Tensor-Operationen führt dieser PCIe-Engpass zu einem **Ring GFX Timeout / GPU Page Fault**.
3. **Hard Freeze**: Da der Display-Server einfriert, reagieren Tastatur, Maus und Bildschirm nicht mehr. Das System ist komplett blockiert und muss hart neu gestartet werden.

---

## 2. Die goldene Sicherheits-Regel: Der 4 GB VRAM-Puffer

> [!IMPORTANT]
> **Die 41-GiB-Grenze**:
> Deine AMD Radeon Pro W7800 hat 45,0 GiB netto.
> **Modell-Gewichte + KV-Cache dürfen in Summe NIEMALS 41,0 GiB überschreiten.**
> Die verbleibenden **4,0 GiB** müssen zwingend als Puffer für den Desktop-Display-Server, Treiber-Overhead und Stabilität frei bleiben!

---

## 3. Strategie A: Reiner VRAM-Betrieb (100% GPU, Maximale Geschwindigkeit)

Das Modell und der gesamte Kontext passen vollständig in den VRAM, inklusive **mindestens 4 GB freiem Puffer**.

### Sichere Maximal-Werte für deine Modelle:

| Modell-Alias | Modell-Größe | Max. sicheres Kontextfenster (`num_ctx`) | KV-Cache Bedarf | Gesamt-VRAM | Freier Puffer | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`qwen3.8-27b-q4`** | 16 GB | **65.536** (64k) | ~4 GB | ~20 GB | **25 GB frei** | 🟢 Absolut sicher |
| **`qwen3-obliterated`** | 23 GB | **49.152** (48k) | ~5 GB | ~28 GB | **17 GB frei** | 🟢 Absolut sicher |
| **`qwen3.8-35b-distill`** | 30 GB | **32.768** (32k) | ~4.5 GB | ~34.5 GB | **10.5 GB frei** | 🟢 Absolut sicher |
| **`qwen3-coder` (Q8)** | 32 GB | **32.768** (32k) | ~4.5 GB | ~36.5 GB | **8.5 GB frei** | 🟢 Absolut sicher |
| **`qwen3.8-27b-q8`** | 32 GB | **32.768** (32k) | ~4.5 GB | ~36.5 GB | **8.5 GB frei** | 🟢 Absolut sicher |
| **`artemis-31b`** | 33 GB | **32.768** (32k) | ~4.5 GB | ~37.5 GB | **7.5 GB frei** | 🟢 Absolut sicher |
| **`hermes3-70b`** | 37 GB | **8.192** (8k) | ~2.5 GB | ~39.5 GB | **5.5 GB frei** | 🟢 Stabil im Limit |
| **`qwen3-next-80b`** | 42 GB | **4.096** (4k) | ~1.5 GB | ~43.5 GB | **1.5 GB frei** | 🟡 Grenzwertig (Siehe B) |

### ⚠️ Entscheidende Einstellung in Cline (VS Code)
Das Modelfile setzt zwar Standard-Werte, aber **wenn in Cline ein höherer Wert eingetragen ist, überschreibt Cline das Modelfile!**
* Bei `qwen3-coder`: In den Cline Settings **exakt `32768`** eintragen (niemals 128000!).
* Bei `hermes3-70b`: In den Cline Settings **exakt `8192`** eintragen.
* Bei `qwen3-next-80b`: In den Cline Settings **exakt `4096`** eintragen.

---

## 4. Strategie B: Große Modelle (70B / 80B) mit 12k–16k Kontext

Wenn ein Modell bereits 37–42 GB groß ist und du **12.000 bis 16.000 Tokens Kontext** benötigst, reicht der VRAM bei Standard-FP16 nicht mehr aus. 

Hier gibt es zwei sichere Lösungen, die Systemabstürze zu 100% ausschließen:

---

### Option B.1 (Beste Lösung): KV-Cache Quantisierung (`q4_0` / `q8_0`)
Ollama speichert den Kontext standardmäßig als 16-Bit (`f16`). Durch Quantisierung des Caches sinkt der Speicherbedarf drastisch ohne spürbaren Qualitätsverlust:
* **`q8_0` (8-Bit)**: Halbiert den KV-Cache VRAM-Bedarf um **50%**.
* **`q4_0` (4-Bit)**: Reduziert den KV-Cache VRAM-Bedarf um **75%**!

**Vergleich bei 80B mit 16k Kontext**:
* Bei `f16`: **~6 GB VRAM** $\rightarrow$ 42 GB + 6 GB = **48 GB (Crash!)**
* Bei `q4_0`: **~1.5 GB VRAM** $\rightarrow$ 42 GB + 1.5 GB = **43.5 GB (Passt voll in den VRAM!)**

**Aktivierung in `/etc/systemd/system/ollama.service`**:
```ini
Environment="OLLAMA_KV_CACHE_TYPE=q4_0"
```

---

### Option B.2: Kontrolliertes Layer-Offloading in den System-RAM (`num_gpu`)
Falls du den Kontext noch weiter vergrößern willst oder den VRAM entlasten möchtest, werden gezielt einige Modell-Layer in deinen 61 GB Arbeitsspeicher ausgelagert.

Beispiel für `qwen3-next-80b` (hat insgesamt 80 Layer):
* Statt alle 80 Layer auf die GPU zu zwingen, werden **72 Layer auf der GPU** und **8 Layer auf der CPU** berechnet.
* VRAM-Verbrauch des Modells sinkt von 42 GB auf **ca. 37 GB**.
* **Ergebnis**: Auf der GPU sind nun **8 GB VRAM frei** für bis zu **24k Tokens Kontext**!

**Modelfile mit sicherem Layer-Offloading (`Modelfile.next80b-hybrid`)**:
```dockerfile
FROM hf.co/bartowski/Qwen_Qwen3-Next-80B-A3B-Thinking-GGUF:IQ4_XS

# 72 von 80 Layern auf die GPU, Rest im schnellen 61 GB RAM
PARAMETER num_gpu 72

# Jetzt sind sichere 16k Kontext möglich
PARAMETER num_ctx 16384
PARAMETER num_predict 8192
PARAMETER temperature 0.6
```

---

## 5. Systemd Sicherheits-Härtung (Der 4 GB Schutzwall)

Um sicherzustellen, dass Ollama selbst bei Fehlbedienung (z. B. versehentlich 128k in Cline gewählt) **niemals mehr als 41 GB VRAM beanspruchen kann**, wird der GPU-Overhead in der Service-Unit fest auf **4 GB** eingestellt.

### Empfohlene `/etc/systemd/system/ollama.service`:
```ini
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3

# Schutz: Verhindert OOM-Systemsturz
MemoryMax=56G
OOMScoreAdjust=500

# Pfade & Netzwerk
Environment="OLLAMA_MODELS=/home/models"
Environment="OLLAMA_HOST=0.0.0.0:11434"

# 4 GB fester Sicherheits-Puffer für die W7800 48GB GPU
Environment="OLLAMA_GPU_OVERHEAD=4294967296"

# KV-Cache Quantisierung (Spart 75% VRAM bei Kontext)
Environment="OLLAMA_KV_CACHE_TYPE=q4_0"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_KEEP_ALIVE=24h"

[Install]
WantedBy=default.target
```

---

## 6. Zusammenfassung der Sicherheits-Checkliste

1. **In Cline niemals 128k einstellen**, wenn du mit 32GB+ Modellen arbeitest. Für `qwen3-coder` ist `32768` das stabile Limit.
2. **Große Modelle (37GB / 42GB)**:
   - Entweder mit `q4_0` Cache und max. 8k–12k Tokens betreiben.
   - Oder über `num_gpu` einige Layer in den CPU-RAM auslagern.
3. **4 GB GPU-Overhead aktivieren**: So schützt die Systemd-Konfiguration deine Grafikkarte vor Überlastung.
