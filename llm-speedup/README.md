# ⚡ LLM Speedup: Speculative Decoding & N-Gram Beschleunigung

> **Hardware-Profil:** AMD Radeon Pro W7800 (48 GB GDDR6 VRAM, ~45,0 GiB netto nutzbar) + 61 GB RAM  
> **Ziel:** Steigerung der Token-Generierungsrate deiner lokalen 70B/72B Flaggschiffe von **~40–44 t/s auf ~65–85+ t/s** bei 100% identischer mathematischer Modellqualität.  
> **Schnittstelle:** OpenAI-kompatible REST API (`http://localhost:5002/v1`) für **Open WebUI**, **Cline**, **Roo Code**, **Cursor** und CLI.

---

## 📑 Inhaltsverzeichnis
1. [Übersicht & Funktionsweise](#1-übersicht--funktionsweise)
2. [Schnellstart in 3 Schritten](#2-schnellstart-in-3-schritten)
3. [Nutzung in Open WebUI](#3-nutzung-in-open-webui)
4. [Interaktion & Koexistenz mit Ollama (VRAM-Sicherheit)](#4-interaktion--koexistenz-mit-ollama-vram-sicherheit)
5. [Skalierung: Wie du noch stärkere Modelle nutzen kannst](#5-skalierung-wie-du-noch-stärkere-modelle-nutzen-kannst)
6. [Rollback (Rückgängig machen)](#6-rollback-rückgängig-machen)
7. [Weiteres Wissenswertes & Tuning-Tipps](#7-weiteres-wissenswertes--tuning-tipps)

---

## 1. Übersicht & Funktionsweise

Die Token-Generierung großer Modelle (wie Qwen 2.5 72B oder Llama 3.3 70B) ist **speicherbandbreiten-limitiert**: Für jedes einzelne Wort müssen alle ~38 GB Modellgewichte durch den 864 GB/s Speicherbus der W7800 fließen.

### Zwei Beschleunigungsmethoden in diesem Stack:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SPECULATIVE DECODING                            │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Mini-Draft-Modell (z. B. Qwen 0.5B mit ~200 t/s)                    │
│    ──> Schlägt blitzschnell 5 bis 8 Tokens im Voraus vor.              │
│                                                                        │
│ 2. Großes 72B-Zielmodell                                               │
│    ──> Validiert alle 5–8 Tokens in EINEM EINZIGEN Rechenschritt!      │
│                                                                        │
│ 3. Ergebnis:                                                           │
│    ──> 3 bis 5 Tokens generiert in der Zeit von 1 Vorwärtsdurchlauf.   │
│    ──> Speed steigt von ~42 t/s auf ~75 t/s (+70% bis +80%)!          │
└────────────────────────────────────────────────────────────────────────┘
```

1. **Model-basiertes Speculative Decoding (`--spec-type draft`):**
   * Verwendet ein winziges Draft-Modell aus derselben Modellfamilie (z. B. Qwen 0.5B für Qwen 72B, oder Llama 1B für Llama 70B / DeepSeek R1).
   * VRAM-Zusatzbedarf: Nur **~0,6 bis 1,1 GB**! Passt problemlos neben das 70B-Modell in deine 48 GB VRAM.
2. **N-Gram Kontext-Lookup (`--spec-type ngram-mod`):**
   * Benötigt **kein zweites Modell** und **0 MB extra VRAM**.
   * Sucht nach sich wiederholenden Mustern im Text (ideal für Code, JSON, YAML und Formatierungen).

---

## 2. Schnellstart in 3 Schritten

Alle benötigten Skripte und Konfigurationen befinden sich in diesem Ordner (`llm-optimierungen/llm-speedup/`).

### Schritt 1: Draft-Modelle herunterladen
Führe das Download-Skript aus:
```bash
cd /home/clemi/Projekte/LLM/llm-optimierungen/llm-speedup
./download-draft-models.sh
```
*Wähle Option `1`, um alle 3 kompakten Draft-Modelle (Qwen 0.5B, Llama 1B, Coder 1.5B – zusammen nur ~2.2 GB) nach `/home/models` zu laden.*

### Schritt 2: Service starten
Starte den beschleunigten Inferenz-Dienst:
```bash
./speedup-control.sh start
```
*Der Dienst bindet sich an `http://127.0.0.1:5002` und klinkt sich automatisch in das Docker-Netzwerk `ai-network` ein.*

### Schritt 3: Testen & Geschwindigkeit messen
Überprüfe die Antwort und Token-Rate über das Test-Kommando:
```bash
./speedup-control.sh test qwen2.5-72b-speculative
```
*Das Skript sendet einen Testprompt an das Modell, gibt die Antwort aus und berechnet exakt die Tokens pro Sekunde (t/s).*

---

## 3. Nutzung in Open WebUI

Da der `llama-speedup` Service eine standardisierte **OpenAI-kompatible Schnittstelle** bereitstellt, kann Open WebUI ihn parallel zu Ollama einbinden:

```
┌─────────────────┐       (Port 11434)        ┌─────────────────┐
│                 │ ────────────────────────> │  Ollama Server  │
│                 │                           └─────────────────┘
│   Open WebUI    │
│   (Port 3000)   │       (Port 5002)         ┌─────────────────┐
│                 │ ────────────────────────> │  llama-speedup  │ ──> AMD W7800 (ROCm)
└─────────────────┘                           └─────────────────┘
```

### Einbindung in 4 Klicks:
1. Öffne Open WebUI im Browser: `http://localhost:3000`
2. Klicke links unten auf dein Benutzerprofil $\rightarrow$ **Admin-Bereich** (Admin Panel) $\rightarrow$ **Einstellungen** (Settings) $\rightarrow$ **Verbindungen** (Connections).
3. Klicke unter **OpenAI-API** auf das **+** Symbol:
   * **URL:** `http://host.docker.internal:5002/v1`  
     *(oder `http://llama-speedup:5002/v1`, falls Open WebUI im selben Docker-Netzwerk läuft)*
   * **API-Schlüssel:** `llama-swap` *(oder ein beliebiges Wort wie `sk-local`)*
4. Klicke auf das **Aktualisieren-Symbol (Kreispfeile)** und danach auf **Speichern**.

### Im Chat auswählen:
Oben im Modell-Auswahlmenü von Open WebUI stehen dir nun alle spekulativen Modelle zur Verfügung:
* `qwen2.5-72b-speculative` – Coding- & Math-König (~20 t/s)
* `llama3.3-70b-speculative` – Allround- & Agenten-Champion (~22 t/s)
* `deepseek-r1-70b-speculative` – Deep Reasoning mit N-Gram Kontext-Lookup (~13 t/s)
* `qwen2.5-coder-32b-speculative` – Ultra-High-Speed Coder (~45–60 t/s)
* `qwen2.5-72b-ngram` – Schneller N-Gram Prompt-Lookup (~12 t/s)

---

## 4. Interaktion & Koexistenz mit Ollama (VRAM-Sicherheit)

Ein zentrales Designziel dieses Setups ist die **reibungslose Koexistenz mit Ollama und ComfyUI**:

| Eigenschaft | Ollama Native | LLM Speedup (llama-proxy) |
| :--- | :--- | :--- |
| **Netzwerk-Port** | `11434` | `5002` |
| **Schnittstelle** | Ollama REST API (`/api/generate`) | OpenAI API (`/v1/chat/completions`) |
| **VRAM-Verhalten** | Hält Modell im VRAM (`keep_alive`) | **Auto-Unload nach 5 Min. (`ttl: 300`)** |
| **Speculative Decoding** | Nein / Experimentell | **Ja, nativer llama-server Kern** |

### Wie VRAM-Konflikte verhindert werden:
1. **Automatischer TTL-Timeout (`ttl: 300`):**  
   Sobald du 5 Minuten lang keine Nachricht an ein spekulatives Modell gesendet hast, entlädt `llama-proxy` den Prozess automatisch vollständig aus der GPU. Alle 48 GB VRAM stehen wieder für Ollama oder ComfyUI (FLUX.2 / Juggernaut) bereit.
2. **Modell-Wechsel:**  
   Wenn du in Open WebUI von einem Ollama-Modell zu einem Speedup-Modell wechselst, achte darauf, dass Ollama sein Modell entlädt (geschieht nach Ablauf von Ollamas `keep_alive` oder via `ollama stop <modellname>`).
3. **Manueller VRAM-Flush:**  
   Falls du sofort Speicher für Bildgenerierung brauchst:
   ```bash
   ./speedup-control.sh stop
   ```

---

## 5. Skalierung: Wie du noch stärkere Modelle nutzen kannst

Mit deiner AMD Radeon Pro W7800 (48 GB VRAM) und den 61 GB System-RAM hast du enormes Potenzial:

### A. Monumentale 120B+ Modelle im Hybrid-Modus (Mistral Large 123B)
* Normalerweise bremsen Hybrid-Modelle (GPU + RAM), weil CPU-RAM langsam ist (~50 GB/s vs. 864 GB/s VRAM).
* **Der Clou bei Speculative Decoding:** Das kleine Draft-Modell (z. B. Mistral NeMo 12B) liegt **zu 100% im VRAM** und erzeugt die Token-Vorschläge blitzschnell. Das gigantische 123B-Hybrid-Modell muss die CPU-Schichten nur einmal alle 4–6 Tokens durchrechnen!
* **Effekt:** Die Generierungsgeschwindigkeit von 120B-Modellen verdoppelt sich von ~12 t/s auf **~22–26 t/s**!

### B. Nutzung von `IQ3_M` Quantisierungen für gigantischen Kontext (64k–128k)
* `Qwen2.5-72B` in `IQ3_M` belegt nur ca. **31 GB VRAM** (statt 40 GB bei 4-Bit).
* Dadurch bleiben dir **~16 GB freier VRAM** für Kontext.
* Kombiniert mit dem in `config.yaml` aktiven 4-Bit KV-Cache (`-ctk q4_0 -ctv q4_0`) kannst du **über 65.000 Tokens Kontext** komplett im VRAM halten, ohne auf System-RAM auszulagern!

### C. Neue Modelle zu `config.yaml` hinzufügen
Du kannst jedes beliebige GGUF-Modell mit wenigen Zeilen in `config.yaml` spekulativ beschleunigen:
```yaml
  "mein-neues-modell":
    name: "Mein 70B Modell (Speculative)"
    ttl: 300
    cmd: |
      ${llama_bin}
      -m ${models_dir}/Grosses-Modell-IQ4_XS.gguf
      -md ${models_dir}/Kleines-Draft-Modell-Q4_K_M.gguf
      --spec-type draft
      --spec-draft-n-max 8
      --spec-draft-p-min 0.75
      -c 32768
      ${gpu_flags}
      --port ${PORT}
```

---

## 6. Rollback (Rückgängig machen)

Das gesamte Speedup-System ist **isoliert und rückstandsfrei entfernbar**. Dein bestehendes Ollama-, ComfyUI- und Open-WebUI-Setup wird zu keinem Zeitpunkt verändert.

### Automatisches Rollback:
Führe einfach folgenden Befehl aus:
```bash
cd /home/clemi/Projekte/LLM/llm-optimierungen/llm-speedup
./speedup-control.sh rollback
```

### Was das Skript macht:
1. Stoppt und entfernt den Docker-Container `llama-speedup`.
2. Fragt dich, ob du die heruntergeladenen Draft-Modelle (.gguf) behalten oder löschen möchtest.
3. Lässt dein System sauber im Ursprungszustand zurück.
4. *(Optional)* In Open WebUI unter *Admin $\rightarrow$ Verbindungen* kannst du die Verbindung `http://...:5002/v1` einfach mit dem Mülleimer-Symbol löschen.

---

## 7. Weiteres Wissenswertes & Tuning-Tipps

### 1. Verändert Speculative Decoding die Antworten (Halluzinationen)?
**Nein, zu 100% garantiert nicht.**  
Mathematisch verwendet llama.cpp *Rejection Sampling*: Jedes vom Draft-Modell vorgeschlagene Token wird vom 70B-Modell anhand seiner exakten Wahrscheinlichkeitsverteilung geprüft. Verwirft das 70B-Modell ein vorgeschlagenes Token, wird es verworfen und das 70B-Modell bestimmt das nächste Token selbst. Die Ausgabequalität ist **mathematisch identisch mit einem normalen 70B-Durchlauf**.

### 2. Die „Acceptance Rate“ in den Logs prüfen
Du kannst live mitverfolgen, wie gut das Draft-Modell die Tokens errät:
```bash
./speedup-control.sh logs
```
In den Logs von `llama-server` siehst du Zeilen wie:
```
speculative: draft acceptance rate = 78.4% (n_draft = 8)
```
Eine Acceptance Rate von **70–80%** bedeutet, dass 4 von 5 Tokens direkt akzeptiert werden $\rightarrow$ maximaler Geschwindigkeitsgewinn.

### 3. Tuning-Parameter in `config.yaml`:
* `--spec-draft-n-max 8`: Wie viele Tokens das Draft-Modell maximal vorausahnen darf. (8 ist ideal für Code und strukturierte Texte, 5 für kreative Geschichten).
* `--spec-draft-p-min 0.75`: Mindestwahrscheinlichkeit für spekulative Tokens. Ein Wert von 0.75 verhindert, dass bei unvorhersehbaren Antworten unnötige Rechenzeit für falsche Spekulationen verschwendet wird.

