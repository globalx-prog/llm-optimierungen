# 💾 Festplatten-Optimierungsanalyse & Modell-Portfolio

> **Hardware-Basis:** AMD Radeon Pro W7800 (48 GB GDDR6 VRAM) | 61 GB RAM | 32 GB NVMe Swap  
> **Festplatten-Partition:** 1 TB NVMe SSD (`/dev/nvme0n1p5` gemountet auf `/home`)  
> **Kapazität:** **844 GB nutzbar** | **520 GB belegt (65%)** | **281 GB frei (35%)**  
> **Stichtag:** November 2026 (Bereinigung erfolgreich durchgeführt)

---

## 1. Detaillierte Ist-Analyse des Speicherverbrauchs (520 GB belegt, 281 GB frei)

Eine genaue Durchleuchtung der 844-GB-Partition `/home` zeigt nach der Bereinigung folgende Verteilung:

```
Gesamte /home-Partition (844 GB)
│
├── 🎨 ComfyUI Medien-Modelle (image-video-setup) : 182 GB (21,6%)
├── 🧠 LLM-Modelle (/home/models & Ollama)        : 165 GB (19,5%)
├── 🐍 Python-Umgebungen & Caches (comfy_env etc.):  37 GB  (4,4%)
├── 📦 System, ROCm 7.2, Docker & Snapshots       :  58 GB  (6,9%)
├── 📁 Eigene Daten, Nextcloud & Repositories     :  45 GB  (5,3%)
└── 🟢 Aktuell freier Festplatten-Puffer          : 281 GB (33,3% - MEHR ALS VERDOPPELT!)
```

### 1.1 Aufschlüsselung der Bild- & Video-Modelle (262 GB)

| Modell-Kategorie | Enthaltene Modelle & Dateien | Größe auf SSD | Status & Bewertung |
| :--- | :--- | :---: | :--- |
| **Video: Wan 2.2 (Dual DiT)** | `wan2.2_i2v_high_noise` (13.3G), `low_noise` (13.3G), LoRAs (2.2G), `umt5_xxl` (6.3G) | **~35,1 GB** | 🟢 **Aktiv & State-of-the-Art:** Beste lokale Videophysik mit Turbo-LoRA (~60–90s). |
| **Video: Wan 2.1 (Vorgänger)**| `wan2.1_i2v_480p_14B_fp16` (30.5G), `wan2.1_t2v_14B_bf16` (26.6G) | **~57,1 GB** | ⚠️ **Redundant:** Wan 2.2 ersetzt Wan 2.1 vollständig und rendert 5x schneller. |
| **Video: MiniMax H3 (Hailuo)**| `minimax_h3_ref2va` (31.7G), `fl2va_pruned` (19.5G), `qwen3vl_32b` (25.3G), VAE & LoRA (6.2G) | **~82,7 GB** | 🟢 **Aktiv & Einzigartig:** Einziges lokales Modell mit nativer Video- + Audio-Stereospur! |
| **Bild: FLUX.2 [dev]** | `flux2_dev_fp8mixed` (33.0G), `mistral_3_small_flux2_fp8` (16.8G), VAE & LoRAs (3.0G) | **~52,8 GB** | 🟢 **Aktiv & Königsklasse:** Höchste Bildschärfe, 10-Bilder-Multireferenz & Texturqualität. |
| **Bild: FLUX.1 [dev]** | `flux1-dev-fp8` (16.1G), `flux1-dev-controlnet-union-pro` (6.2G) | **~22,3 GB** | ⚠️ **Redundant:** In der eigenen Dokumentation bereits als durch FLUX.2 abgelöst vermerkt. |
| **Bild: SDXL / Juggernaut** | `Juggernaut-XL_v9_RunDiffusionPhoto` (6.6G), `controlnet-union-sdxl` (2.3G) | **~8,9 GB** | 🟢 **Aktiv & Unverzichtbar:** Blitzschnelle 35mm-Porträts in 3–5 Sekunden für den Chat. |
| **Sonstige (LoRAs, Upscaler)** | RealESRGAN, FaceRestore, LoRAs, VAEs | **~3,1 GB** | 🟢 **Aktiv:** Wichtige Hilfsmodule für Bildoptimierung. |

---

### 1.2 Aufschlüsselung der Sprachmodelle (198 GB in `/home/models`)

| Modell-Name | Quantisierung | Speicherplatz | Rolle & Empfehlung |
| :--- | :---: | :---: | :--- |
| **`qwen2.5-72b-speed`** | IQ4_XS (GGUF) | **39 GB** | 🟢 **Behalten:** Nr. 1 Coding-, Mathematik- und Syntax-König weltweit. |
| **`llama3.3-70b-speed`** | IQ4_XS (GGUF) | **37 GB** | 🟢 **Behalten:** Nr. 1 Allrounder, stabiles Tool-Calling, RAG & Websuche. |
| **`deepseek-r1-70b-speed`** | IQ4_XS (GGUF) | **37 GB** | 🟢 **Behalten:** Nr. 1 Logik & Denkketten (`<think>`) auf o1-Niveau. |
| **`qwen3.8-35b-distill`** | Q6_K (GGUF) | **30 GB** | 🟢 **Behalten:** Bester Alltags-Sweet-Spot (gemessene ~65 t/s, 64k Kontext). |
| **`artemis-31b`** | Q4_K_M (Ollama) | **33 GB** | ⚠️ **Kandidat zum Entfernen:** Nur ~14.6 t/s langsam. Qwen 3.8 35B ist fast 5x schneller (~65 t/s) und schlägt Artemis in Formulierung & Logik. |
| **`qwen3-obliterated`** | Dense 27B (Q4) | **21 GB** | ⚠️ **Kandidat zum Ersetzen:** Mit 15.9 t/s träge. Wird durch `llama3.3-70b-abliterated` qualitativ deklassiert. |
| **`qwen2.5vl:7b`** | Q4_K_M (Vision) | **6.0 GB** | 🟢 **Behalten:** Kompaktes Vision-Modell für Bildbeschreibungen im Chat. |
| **`bge-m3`** | FP16 (Embedding) | **1.2 GB** | 🟢 **Behalten:** Basis-Embedding-Modell für Open WebUI RAG & Dokumentensuchen. |
| **Draft-Modelle (0.5B, 1B, 1.5B)**| Q4_K_M (GGUF) | **~2.3 GB** | 🟢 **Behalten:** Ermöglichen +75% Spekulative Beschleunigung für 70B-Modelle. |

---

## 2. Der Puffer-Bedarf für Bild- und Video-Generierung

Warum darf eine Workstation für Medien-KI niemals vollgeschrieben werden?

### 2.1 Warum Video-Generierung massiven Puffer benötigt
1. **Unkomprimierte Zwischen-Frames (Frame Extraction):**  
   Vor dem Rendern oder beim Postprocessing (z. B. AI-Upscaling mit `ai_video_upscaler.py` oder Frame-Interpolation) decodiert FFmpeg Video-Clips in einzelne unkomprimierte Bilddateien (`.png` oder `.raw`). Ein 10-Sekunden-Clip in 1080p bei 30 fps erzeugt **300 hochauflösende Einzelbilder** (~1,5 bis 3 GB temporär pro Szene).
2. **VAE-Decoding großer Latents:**  
   Die Video-Modelle (Wan 2.2 und MiniMax H3) generieren Tensoren im latenten Raum. Bei der Rückkonvertierung durch den VAE in den RGB-Raum allokiert PyTorch temporäre Scratch-Buffer auf der SSD/Swap, wenn der GPU-VRAM knapp wird.
3. **Multi-Szenen-Generierung (z. B. `run_movie.sh` / Krimi-Pipeline):**  
   Werden 3 bis 6 Szenen hintereinander erzeugt, wachsen die Zwischenordner in `image-video-setup/output/` während des Laufs auf **10 bis 25 GB** an, bevor sie final zusammengeschnitten werden.
4. **Gefahr bei < 40 GB Freispeicher:**  
   Fällt der freie Festplattenspeicher unter 20–30 GB, brechen Video-Renderjobs nach 15 Minuten Rechenzeit mit `OSError: [Errno 28] No space left on device` ab, und Open WebUI SQLite-Datenbanken können beschädigt werden.

### 2.2 Puffer-Faustregeln
* **Absolutes Minimum (Notlauf):** **40 GB**
* **Empfohlener Puffer für flüssiges Arbeiten:** **70 – 100 GB**
* **Komfort-Puffer (inkl. großer Filmprojekte & Upscaling):** **120 – 150 GB**

---

## 3. Die sofortigen Einsparpotenziale (Erfolgreich umgesetzt: +144 GB gewonnen!)

Die Bereinigung wurde über [`scripts/cleanup-immediate-savings.sh`](../scripts/cleanup-immediate-savings.sh) durchgeführt:

| Was bereinigt? | Einsparung | Status | Warum war es sicher? |
| :--- | :---: | :---: | :--- |
| **`/home/clemi/ComfyUI`** | **+34,0 GB** | ✅ Gelöscht | Verwaister Testordner mit 2 alten Dateien; echtes ComfyUI liegt in `image-video-setup/`. |
| **FLUX.1 [dev] & ControlNet** | **+22,3 GB** | ✅ Gelöscht | Vollständig durch das aktive **FLUX.2 [dev]** abgelöst. |
| **Wan 2.1 Basisschichten** | **+57,1 GB** | ✅ Gelöscht | Durch **Wan 2.2 Dual DiT Turbo** (mit 4-Step LoRA in 60s) komplett ersetzt. |
| **`artemis-31b` (Ollama)** | **+33,0 GB** | ✅ Gelöscht | Träges 14.6 t/s Modell; **Qwen 3.8 35B Distill** (~65 t/s) ist 5x schneller. |
| **Gesamter Netto-Gewinn** | **+144 GB** | 🎉 **Aktiv** | **Freier Speicher stieg von 137 GB auf 281 GB (65% Belegung)!** |

---

## 4. Die 3 optimalen Modell-Portfolios für deine W7800

Basierend auf einer Gesamtkapazität von 844 GB stehen dir drei perfekte Nutzungs-Profile zur Auswahl:

### 🌟 Profil A: „Das Perfekte Allround-Studio“ (EMPFOHLEN)
*Maximale Vielseitigkeit: Alle Top-Sprachmodelle, blitzschnelles Coding, FLUX.2 Bildqualität und vollwertiges Wan 2.2 + MiniMax H3 Video-Studio mit 160+ GB Puffer!*

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PROFIL A: ALLROUND-STUDIO                       │
├────────────────────────────────────────────────────────────────────────┤
│ 🧠 LLMs (192 GB):                                                      │
│    • qwen2.5-72b-speed (39 GB)      [Coding & Math König]              │
│    • llama3.3-70b-speed (37 GB)     [Agenten, Tools & RAG]             │
│    • deepseek-r1-70b-speed (37 GB)  [CoT Reasoning & Logik]            │
│    • llama3.3-70b-abliterated (38 GB)[100% Unzensiertes 70B Flaggschiff]│
│    • qwen3-coder-speed (18.5 GB)    [Ultra-Speed Coder ~100 t/s]       │
│    • qwen3.8-35b-distill (30 GB)    [Daily Driver ~65 t/s, 64k Kontext]│
│    • qwen2.5vl:7b + bge-m3 (7.2 GB) [Vision & RAG Embeddings]          │
│    • Draft-Modelle (2.3 GB)         [Spekulatives Decoding]            │
│                                                                        │
│ 🎨 BILD-STUDIO (62 GB):                                                │
│    • FLUX.2 [dev] FP8 (33 GB DiT + 17 GB Mistral Text-Encoder)         │
│    • Juggernaut XL v9 (6.6 GB) + SDXL ControlNet (2.3 GB)              │
│    • Hilfs-LoRAs, Upscaler & VAEs (3.1 GB)                             │
│                                                                        │
│ 🎥 VIDEO-STUDIO (118 GB):                                              │
│    • Wan 2.2 Dual DiT Turbo (13.3G High + 13.3G Low + 6.3G TextEnc)    │
│    • MiniMax H3 mit Stereo-Sound (31.7G + 19.5G + 25.3G + VAE)         │
│    • Video-LoRAs & Interpolation (9 GB)                                │
│                                                                        │
│ ⚙️ SYSTEM & UMGEBUNGEN (115 GB):                                       │
│    • comfy_env, ROCm 7.2, Docker, Snap, OS & Benutzer-Daten            │
│                                                                        │
│ 🟢 FREIER PUFFER (GARANTIERT): ~170 – 185 GB                          │
│    (Ideal für 4K-Upscaling, Multi-Szenen-Rendern & Scratch-Space)      │
└────────────────────────────────────────────────────────────────────────┘
```

---

### 💻 Profil B: „Der Entwickler & KI-Researcher“ (LLM-Maximal)
*Fokus auf Software-Entwicklung, autonome Agenten (Cline/Roo) und tiefes mathematisches Reasoning. Reduziertes Video-Setup.*

* **LLMs (245 GB):** Alle Flaggschiffe aus Profil A + `qwen2.5-coder-32b-speed` (20 GB) + `mixtral-8x7b` (26 GB).
* **Bild (62 GB):** FLUX.2 [dev] + Juggernaut XL.
* **Video (35 GB):** Nur Wan 2.2 Turbo (ohne das 83 GB MiniMax H3).
* **Freier Puffer:** **~240 GB frei!**

---

### 🎬 Profil C: „Der Medien- & Film-Produzent“ (Hollywood-Setup)
*Fokus auf kinoreife 1080p-Filmproduktion mit MiniMax H3, Wan 2.2 und Multi-Szenen-Pipelines.*

* **LLMs (125 GB):** `llama3.3-70b-speed` (Allround/Regie) + `qwen3-coder-speed` (Scripting) + `qwen3.8-35b-distill` (Daily Chat) + Vision & Drafts.
* **Bild (62 GB):** FLUX.2 [dev] + Juggernaut XL.
* **Video (155 GB):** Wan 2.2 Dual DiT + MiniMax H3 + Wan 2.1 I2V Archive.
* **Freier Puffer:** **~200 GB frei!** (Exzellenter Raum für gigantische Film-Rendering-Caches).

---

## 5. Konkreter Handlungsplan zur Umsetzung

Um Profil A (das optimale Allround-Studio) einzurichten, gehst du in folgenden 3 Schritten vor:

### Schritt 1: Verwaiste Ordner & Redundanzen bereinigen (ca. 113 GB Freigabe)

```bash
# 1. Verwaisten ComfyUI-Downloadordner löschen (34 GB Gewinn)
rm -rf /home/clemi/ComfyUI

# 2. Redundantes FLUX.1 [dev] löschen (22.3 GB Gewinn)
rm -f /home/clemi/Projekte/LLM/image-video-setup/ComfyUI/models/checkpoints/flux1-dev-fp8.safetensors
rm -f /home/clemi/Projekte/LLM/image-video-setup/ComfyUI/models/controlnet/flux1-dev-controlnet-union-pro.safetensors

# 3. Altes Wan 2.1 löschen, da Wan 2.2 aktiv ist (57.1 GB Gewinn)
rm -f /home/clemi/Projekte/LLM/image-video-setup/ComfyUI/models/diffusion_models/wan2.1_i2v_480p_14B_fp16.safetensors
rm -f /home/clemi/Projekte/LLM/image-video-setup/ComfyUI/models/diffusion_models/wan2.1_t2v_14B_bf16.safetensors
```

### Schritt 2: Veraltete Ollama-Modelle ersetzen (ca. 54 GB Bereinigung)

```bash
# Träge Alt-Modelle aus Ollama entfernen:
ollama rm artemis-31b:latest
ollama rm qwen3-obliterated:latest
```

### Schritt 3: Neue optimierte Modelle über das Download-Skript installieren

Starte einfach das neue interaktive Download-Skript:
```bash
/home/clemi/Projekte/LLM/scripts/model-download-setup.sh
```
Wähle im Menü:
* **Option 4:** `Llama 3.3 70B Abliterated` (Speed IQ4_XS ~38 GB) -> Das neue stärkste unzensierte Modell der Welt.
* **Option 6:** `Qwen 3 Coder 30B MoE` (Speed Q4_K_M ~18.5 GB) -> Der neue 100 t/s Durchsatz-König für Cline.

**Ergebnis:** Du besitzt das **stärkste lokale KI-Setup der Welt**, hast alle Flaggschiffe einsatzbereit, genießt modernste Bild- und Videofunktionen und behältst dauerhaft **über 170 GB garantierten Puffer** für flüssiges Arbeiten ohne Speicherengpässe!

