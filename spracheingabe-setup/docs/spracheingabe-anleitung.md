# 🎙️ Spracheingabe-Setup (Voice-to-Text & Diktat)

Vollständige Anleitung zur Integration von lokaler **Spracheingabe (Speech-to-Text)** in dein LLM-Setup – sowohl für **Open WebUI** (Web & Mobil) als auch für **Cline in VS Code**, das **Terminal** und das gesamte **Ubuntu-Desktop-System (GNOME / Wayland)**.

---

## 🏛️ Architektur & Überblick

Deine bestehende Infrastruktur (**Ollama**, **AMD Radeon Pro W7800 mit 48 GB VRAM**, **Docker `ai-network`**, **Cloudflare Tunnel**, **Tailscale** und **Cline in VS Code**) wird um einen zentralen, OpenAI-kompatiblen Whisper-Dienst erweitert.

```
                              ┌────────────────────────────────────────┐
                              │               MIKROFON                 │
                              └──────────────────┬─────────────────────┘
                                                 │
                   ┌─────────────────────────────┴─────────────────────────────┐
                   ▼                                                           ▼
         [ Szenario 1: Browser ]                                    [ Szenario 2: Desktop / VS Code ]
           Open WebUI (Web/Handy)                                     Cline (VS Code) & Terminal
                   │                                                           │
                   │ (HTTP / Audio-Upload)                                     │ (Push-to-Talk Shortcut)
                   ▼                                                           ▼
       ┌────────────────────────┐                                   ┌─────────────────────────────┐
       │   Open WebUI Container │                                   │  dictate_wayland.sh Skript  │
       │   (:8080 @ ai-network) │                                   │  (PipeWire / wl-clipboard)  │
       └───────────┬────────────┘                                   └──────────────┬──────────────┘
                   │                                                               │
                   └─────────────────────────────┬─────────────────────────────────┘
                                                 │
                                                 ▼ (POST /v1/audio/transcriptions)
                                  ┌──────────────────────────────┐
                                  │   whisper-stt Container      │
                                  │   (:8000 @ ai-network)       │
                                  │   faster-whisper-large-v3    │
                                  │   (CPU INT8 - 0 MB VRAM!)    │
                                  └──────────────┬───────────────┘
                                                 │
                                                 ▼ (Transkribierter Text)
                                  ┌──────────────────────────────┐
                                  │        Ollama LLM            │
                                  │  (qwen3-coder / 70b / 80b)   │
                                  │  volle 48 GB VRAM frei!      │
                                  └──────────────────────────────┘
```

### 💡 Warum CPU-Inferenz für Whisper die beste Wahl ist
Deine AMD Radeon Pro W7800 verfügt über gewaltige 48 GB VRAM, die optimal für große Modelle wie `qwen3-next-80b` oder `hermes3-70b` genutzt werden.
* Das empfohlene Modell **`whisper-large-v3-turbo`** benötigt via CTranslate2 (INT8) auf einer modernen CPU **weniger als 0,4–0,8 Sekunden** für einen normalen Satz.
* **Vorteil:** Die GPU bleibt zu 100 % für parallele LLM-Inferenz frei. Es gibt keine VRAM-Fragmentierung oder Ladekonflikte mit Ollama.

---

## 📁 Ordner-Inhalt

* [`docker-compose.yml`](file:///home/clemi/Projekte/LLM/llm-optimierungen/llm-optimierungen/spracheingabe-setup/docker-compose.yml): Startet den Whisper-STT-Dienst (und optional Piper-TTS) im existierenden Docker-Netzwerk `ai-network`.
* [`scripts/dictate_wayland.sh`](file:///home/clemi/Projekte/LLM/llm-optimierungen/spracheingabe-setup/scripts/dictate_wayland.sh): Push-to-Talk Skript für systemweites Diktieren per Tastenkombination (z. B. direkt in Cline/VS Code).
* [`scripts/test_stt.sh`](file:///home/clemi/Projekte/LLM/llm-optimierungen/spracheingabe-setup/scripts/test_stt.sh): Diagnose-Skript für Mikrofon und API-Transkription.

---

## 🚀 Schritt 1: Whisper-Dienst starten

Der Dienst läuft als gehärteter Docker-Container im selben Netzwerk wie Open WebUI (`ai-network`) und bindet den Port `8000` nur an `127.0.0.1`.

```bash
# In den Ordner wechseln
cd /home/clemi/Projekte/LLM/llm-optimierungen/spracheingabe-setup

# Container starten
docker compose up -d

# Status und Logs prüfen
docker compose ps
docker compose logs -f whisper-stt
```

Beim ersten Start wird das Modell `Systran/faster-whisper-large-v3-turbo` (~1.6 GB) einmalig in das persistente Docker-Volume `whisper-models` heruntergeladen.

---

## 🌐 Schritt 2: Open WebUI anbinden

Für Open WebUI gibt es zwei hervorragende Möglichkeiten:

### Variante A: Lokaler Whisper-Container (Empfohlen für maximale Genauigkeit & Datenschutz)
Funktioniert browserunabhängig, versteht Fach- und Codebegriffe exzellent und sendet keine Audiodaten ins Internet.

1. Öffne Open WebUI im Browser (`http://localhost:3000` oder über deinen Cloudflare-Tunnel).
2. Gehe auf **Admin-Bereich (Einstellungen)** ➔ **Audio**.
3. Nimm folgende Einstellungen vor:
   * **Sprachausgabe / Speech-to-Text (STT) Engine**: Wähle `OpenAI`.
   * **OpenAI API Base URL**: 
     * Wenn Open WebUI im selben Docker-Netzwerk läuft: `http://whisper-stt:8000/v1`
     * Alternativ über den Host: `http://host.docker.internal:8000/v1`
   * **OpenAI API Key**: Beliebiger Dummy-Wert (z. B. `sk-local-whisper` – der lokale Dienst verlangt keine Auth).
   * **STT Modell**: `Systran/faster-whisper-large-v3-turbo`
4. Klicke auf **Speichern**.
5. **Ergebnis:** Neben dem Texteingabefeld im Chat erscheint ein Mikrofon-Symbol. Ein Klick startet die Aufnahme; nach dem Beenden wird die Aufnahme sofort transkribiert und eingefügt.

> [!TIP]
> **Echtzeit-Sprachmodus (Voice Call):**
> Open WebUI besitzt oben rechts im Chat einen Telefonhörer-Button ("Call"). Damit kannst du mit dem gewählten Modell flüssig sprechen. Wenn du unter Audio auch **Text-to-Speech (TTS)** aktivierst (z. B. Web API oder den mitgelieferten `piper-tts`), liest dir das LLM seine Antworten direkt vor!

### Variante B: Browser Web Speech API (Sofort & ohne Serverlast)
Wenn du keine zusätzliche Rechenleistung nutzen möchtest:
* Admin-Bereich ➔ **Audio** ➔ **STT Engine**: `Web API`.
* **Voraussetzung:** Funktioniert in Chrome/Edge/Brave und erfordert eine sichere Verbindung (**HTTPS** über deinen Cloudflare Zero Trust Tunnel oder **localhost**).

---

## 💻 Schritt 3: Spracheingabe für Cline in VS Code & Terminal (Systemweit)

Um Prompts direkt per Stimme in das Cline-Chatfeld oder VS Code einzusprechen, nutzen wir das bereitgestellte Push-to-Talk-Skript für Ubuntu (GNOME / Wayland).

### 1. Benötigte Hilfstools installieren
```bash
sudo apt update
sudo apt install -y curl jq libnotify-bin wl-clipboard wtype
```
*(Hinweis: `wl-clipboard` verwaltet die Wayland-Zwischenablage, `wtype` tippt das Ergebnis automatisch per Strg+V in das aktive Fenster).*

### 2. Funktion des Skripts testen
```bash
# Diagnosetest ausführen (prüft Mikrofon & API)
/home/clemi/Projekte/LLM/llm-optimierungen/spracheingabe-setup/scripts/test_stt.sh
```

### 3. Globalen Tastatur-Shortcut in Ubuntu GNOME einrichten
Damit kannst du überall (in VS Code, Cline, Terminal, Browser) eine Taste drücken, sprechen und loslassen:

1. Öffne die **Ubuntu-Einstellungen** ➔ **Tastatur** ➔ **Tastenkombinationen anzeigen und anpassen** (Keyboard Shortcuts).
2. Scrolle ganz nach unten und wähle **Eigene Tastenkombinationen** (Custom Shortcuts) ➔ **+**.
3. Trage folgende Werte ein:
   * **Name:** `KI Spracheingabe / Diktat`
   * **Befehl (Command):** `/home/clemi/Projekte/LLM/llm-optimierungen/spracheingabe-setup/scripts/dictate_wayland.sh`
   * **Tastenkombination (Shortcut):** z. B. `Super + V` (Windows-Taste + V) oder `Pause` / `F8`
4. Klicke auf **Hinzufügen**.

### 🎧 Bedienung in Cline (VS Code)
1. Klicke in VS Code in das **Cline Prompt-Eingabefeld**.
2. Drücke `Super + V` ➔ Es erscheint eine Benachrichtigung *"🎙️ Aufnahme läuft..."*.
3. Sprich deinen Prompt, z. B.:
   > *"Refaktoriere diese Funktion in Python, füge Docstrings hinzu und behandle Fehlerfälle sauber."*
4. Drücke erneut `Super + V` ➔ Das Audio wird transkribiert und automatisch in das Eingabefeld eingefügt!

---

## 🧩 Optionale Alternative: VS Code Speech Erweiterung

Falls du eine native Extension direkt in VS Code bevorzugst:
* Installiere die offizielle Microsoft-Erweiterung **`VS Code Speech`** (`ms-vscode.vscode-speech`).
* Sie fügt Mikrofon-Icons direkt in VS Code Chatfenstern hinzu und unterstützt Inline-Diktat mit `Strg + Alt + V`.

---

## ⚙️ Empfohlene Modelle & Konfiguration

In [`docker-compose.yml`](file:///home/clemi/Projekte/LLM/llm-optimierungen/llm-optimierungen/spracheingabe-setup/docker-compose.yml) kannst du über die Variable `WHISPER__MODEL` das gewünschte Modell anpassen:

| Modell | Download-Größe | CPU-RAM | Latenz (ca.) | Empfehlung |
| :--- | :--- | :--- | :--- | :--- |
| **`Systran/faster-whisper-large-v3-turbo`** *(Standard)* | ~1.6 GB | ~2.5 GB | ~0.5s | **Beste Wahl:** Extrem präzise bei Deutsch, Fach- und Codebegriffen, sehr schnell. |
| **`Systran/faster-whisper-medium`** | ~1.5 GB | ~2.0 GB | ~0.7s | Sehr ausgewogen. |
| **`Systran/faster-whisper-small`** | ~500 MB | ~1.0 GB | ~0.2s | Ultra-schnell bei minimalem RAM-Bedarf. |

---

## 🛠️ Fehlerbehebung & Tipps

### Mikrofon wird nicht erkannt
Prüfe in den Ubuntu-Systemeinstellungen unter **Ton** ➔ **Eingang**, ob der richtige Eingangspegel für dein Mikrofon ausschlägt.

### Kein automatisches Einfügen in Wayland
Falls `wtype` auf deiner Desktop-Sitzung blockiert wird:
* Das Skript kopiert den Text immer automatisch in deine Zwischenablage (`wl-copy`).
* Du kannst den Text jederzeit mit `Strg + V` manuell einfügen.
* Desktop-Benachrichtigungen zeigen dir sofort den erkannten Text an.

### Erreichbarkeit aus Open WebUI testen
Falls Open WebUI die Verbindung nicht herstellen kann:
```bash
# Im Host testen:
curl http://127.0.0.1:8000/health

# Aus dem Open WebUI Container testen:
docker exec -it open-webui curl http://whisper-stt:8000/health
```
*(Da beide Container im `ai-network` liegen, ist `whisper-stt:8000` direkt über Docker DNS erreichbar).*
