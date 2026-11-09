# Handbuch: Git-Hooks & Systemweite Nutzung (cabumtain-hook Standard)

Dieses Handbuch dokumentiert alle im Ökosystem integrierten Git-Hooks, erklärt die erzwungenen Standards (Conventional Commits, Sicherheits- und Dateiprüfungen) und beschreibt, wie diese **systemweit auf allen Git-Repositories** aktiviert und genutzt werden.

---

## 🧭 Inhaltsverzeichnis
- [Handbuch: Git-Hooks \& Systemweite Nutzung (cabumtain-hook Standard)](#handbuch-git-hooks--systemweite-nutzung-cabumtain-hook-standard)
  - [🧭 Inhaltsverzeichnis](#-inhaltsverzeichnis)
  - [🔍 Übersicht \& Funktionsweise](#-übersicht--funktionsweise)
  - [📦 Die einzelnen Hooks im Detail](#-die-einzelnen-hooks-im-detail)
    - [1. `commit-msg`: Conventional Commits](#1-commit-msg-conventional-commits)
      - [Format:](#format)
      - [Erlaubte Typen:](#erlaubte-typen)
      - [Wichtige Regeln:](#wichtige-regeln)
    - [2. `pre-commit`: Schutz vor Modell- \& Großdateien](#2-pre-commit-schutz-vor-modell---großdateien)
    - [3. `pre-commit`: Secrets \& Credential-Scanner](#3-pre-commit-secrets--credential-scanner)
    - [4. `pre-commit`: Linter für Shell \& YAML](#4-pre-commit-linter-für-shell--yaml)
    - [5. `pre-push`: Tag Immutability Guard](#5-pre-push-tag-immutability-guard)
  - [🌐 Systemweite (Globale) Nutzung](#-systemweite-globale-nutzung)
    - [Einrichtung in 1 Schritt:](#einrichtung-in-1-schritt)
    - [Was passiert dabei?](#was-passiert-dabei)
  - [🚀 Tägliche Arbeitsabläufe \& Cheatsheet](#-tägliche-arbeitsabläufe--cheatsheet)
    - [Normaler Commit-Workflow:](#normaler-commit-workflow)
    - [Was tun, wenn ein Hook den Commit abbricht?](#was-tun-wenn-ein-hook-den-commit-abbricht)
      - [Fall A: Nachricht war falsch formatiert](#fall-a-nachricht-war-falsch-formatiert)
      - [Fall B: Eine Datei ist zu groß (\> 2 MB)](#fall-b-eine-datei-ist-zu-groß--2-mb)
      - [Fall C: Whitespace- oder Einrückungsfehler](#fall-c-whitespace--oder-einrückungsfehler)
  - [🚨 Notfall-Bypass \& Fehlerbehebung](#-notfall-bypass--fehlerbehebung)
    - [Notfall-Bypass (Hooks einmalig überspringen):](#notfall-bypass-hooks-einmalig-überspringen)
    - [Nachträgliches Korrigieren einer abgelehnten Nachricht:](#nachträgliches-korrigieren-einer-abgelehnten-nachricht)
    - [Globale Hooks wieder deaktivieren:](#globale-hooks-wieder-deaktivieren)

---

## 🔍 Übersicht & Funktionsweise

Git-Hooks sind Skripte, die bei bestimmten Git-Ereignissen automatisch ausgeführt werden:

```
[git commit] ──► 1. pre-commit (Prüft staged Dateien: Größe, Secrets, Syntax)
                     │ (Erfolg)
                     ▼
                 2. commit-msg (Prüft Commit-Nachricht: Conventional Commits, max 72 Zeichen)
                     │ (Erfolg)
                     ▼
                 [Commit erfolgreich angelegt]

[git push]   ──► 3. pre-push (Prüft Release-Tags: Schutz vor Überschreibung/Löschen)
                     │ (Erfolg)
                     ▼
                 [Push zum Remote-Server]
```

Wenn eine Prüfung fehlschlägt, wird die Git-Aktion **vor dem Speichern** mit einer verständlichen Fehlermeldung abgebrochen.

---

## 📦 Die einzelnen Hooks im Detail

### 1. `commit-msg`: Conventional Commits
Stellt sicher, dass jede Commit-Nachricht dem Industriestandard **Conventional Commits v1.0.0** entspricht.

#### Format:
```text
<typ>(<optionaler scope>): <kurze beschreibung>
```

#### Erlaubte Typen:
| Typ | Bedeutung | Beispiel |
|:---|:---|:---|
| **`feat`** | Neues Feature / neue Konfiguration | `feat: add qwen3 model routing in llama-swap` |
| **`fix`** | Behebung eines Fehlers | `fix: correct port binding in compose` |
| **`docs`** | Reine Dokumentationsänderungen | `docs: add hardware tuning guide` |
| **`chore`** | Wartung, Hilfsskripte, Paket-Updates | `chore: clean up obsolete cache files` |
| **`refactor`**| Code-Restrukturierung ohne Funktionsänderung | `refactor: simplify model loader logic` |
| **`perf`** | Performance-Optimierung | `perf: tune flash attention batch size` |
| **`test`** | Tests hinzufügen oder anpassen | `test: add healthcheck verification script` |
| **`ci`** | CI/CD-Pipelines und GitHub Actions | `ci: add automated linting workflow` |
| **`style`** | Formatierung, Semikolons, Leerzeichen | `style: fix indentation in config.yaml` |

#### Wichtige Regeln:
1. **72-Zeichen-Limit:** Die erste Zeile darf maximal **72 Zeichen** lang sein.
2. **Kleinbuchstaben:** Typ und Beschreibung beginnen klein (`feat: add...`, nicht `Feat: Add...`).
3. **Kein Punkt am Ende:** Kein abschließender Punkt in der ersten Zeile.
4. **Breaking Changes:** Werden durch ein `!` vor dem Doppelpunkt gekennzeichnet:  
   `feat!: drop legacy rocm 5.x support`

---

### 2. `pre-commit`: Schutz vor Modell- & Großdateien
Verhindert das größte Risiko bei lokalen KI-Projekten: Das versehentliche Committen von Multi-Gigabyte Modelldateien (`.gguf`, `.safetensors`, `.bin`, `.pt`, `.onnx`).

* **Dateigrößen-Limit:** Maximal **2 MB** pro Datei.
* **Blockierte Formate:** `*.gguf`, `*.safetensors`, `*.bin`, `*.pt`, `*.pth`, `*.onnx`.
* **Warum das kritisch ist:** Einmal versehentlich eine 20 GB GGUF-Datei committet, bleibt sie dauerhaft in der Git-History hängen und führt zu `remote rejected: file exceeds 100 MB` auf GitHub.

---

### 3. `pre-commit`: Secrets & Credential-Scanner
Scannt alle zum Commit vorbereiteten Änderungen (`staged files`) auf sensible Daten:
* Private SSH-Schlüssel (`BEGIN OPENSSH PRIVATE KEY`, `BEGIN RSA PRIVATE KEY`)
* Cloudflare Tunnel Tokens (`TUNNEL_TOKEN=ey...`)
* API-Keys und Passwörter

Wird ein Secret gefunden, stoppt der Commit sofort.

---

### 4. `pre-commit`: Linter für Shell & YAML
* **`shellcheck`**: Prüft Bash-Skripte (`.sh`) auf typische Fehler, unquotierte Variablen, Syntaxfehler und Portabilität.
* **`yamllint`**: Prüft `docker-compose.yml`, `config.yaml` und Kubernetes-Manifeste auf korrekte Einrückung, doppelte Schlüssel und Syntax.

---

### 5. `pre-push`: Tag Immutability Guard
Schützt veröffentlichte Versionen vor versehentlicher Manipulation:
* Verhindert `git push --force` auf Tags im SemVer-Format (`v1.0.0`, `v2.1.3`).
* Verhindert das Löschen von Tags auf dem Remote-Server (`git push origin :refs/tags/v1.0.0`).

---

## 🌐 Systemweite (Globale) Nutzung

Anstatt Hooks mühsam in jedes einzelne Git-Repository zu kopieren, kannst du sie **einmalig systemweit für alle Repositories** auf deinem Rechner aktivieren.

Git bietet dafür die Direktive `core.hooksPath`. Wenn dieser Pfad gesetzt ist, führt Git die Hooks **immer und überall** aus – egal in welchem Ordner du dich befindest.

### Einrichtung in 1 Schritt:
```bash
/home/clemi/Projekte/LLM/llm-optimierungen/scripts/setup-global-hooks.sh
```

### Was passiert dabei?
1. Die Hook-Skripte werden in `~/.config/git/hooks/` installiert:
   * `~/.config/git/hooks/commit-msg`
   * `~/.config/git/hooks/pre-commit`
   * `~/.config/git/hooks/pre-push`
2. Git wird global konfiguriert:
   ```bash
   git config --global core.hooksPath ~/.config/git/hooks
   ```
3. **Koexistenz:** Befindet sich in einem Unterprojekt (wie `llm-optimierungen`) zusätzlich eine projekt-spezifische `.pre-commit-config.yaml`, delegiert der globale Hook automatisch auch die projektspezifischen Linter (`yamllint`, `shellcheck`, etc.).

---

## 🚀 Tägliche Arbeitsabläufe & Cheatsheet

### Normaler Commit-Workflow:
```bash
# 1. Änderungen stagen
git add configs/llama-swap/config.yaml

# 2. Committen mit Conventional Commit Header
git commit -m "feat(llama-swap): update context length for 80b model"
```
*Die Hooks laufen im Hintergrund durch. Ist alles in Ordnung, wird der Commit sofort gespeichert.*

---

### Was tun, wenn ein Hook den Commit abbricht?

#### Fall A: Nachricht war falsch formatiert
```text
❌ FEHLER: Commit-Nachricht entspricht nicht dem Conventional-Commit-Standard!
   Format:   <typ>(<scope>): <kurze beschreibung>
   Deine Nachricht: "update configs"
```
**Lösung:** Einfach den Commit-Befehl mit gültigem Präfix wiederholen:
```bash
git commit -m "feat(configs): update model parameters"
```

#### Fall B: Eine Datei ist zu groß (> 2 MB)
```text
❌ FEHLER: Folgende Dateien überschreiten das Limit von 2 MB oder sind Modelldateien:
   • models/qwen3.gguf (Modell-Tensorformat)
```
**Lösung:** Datei aus dem Staging entfernen und in `.gitignore` eintragen:
```bash
git reset HEAD models/qwen3.gguf
echo "*.gguf" >> .gitignore
git add .gitignore
git commit -m "chore: ignore local model weights in git"
```

#### Fall C: Whitespace- oder Einrückungsfehler
Die `pre-commit-hooks` entfernen oft trailing whitespaces automatisch. Wenn das passiert:
```bash
git add .
git commit -m "fix: your original commit message"
```

---

## 🚨 Notfall-Bypass & Fehlerbehebung

### Notfall-Bypass (Hooks einmalig überspringen):
Wenn du in einer Notfallsituation eine Prüfung überspringen musst (z. B. WIP-Commit oder Sonderformat):
```bash
git commit --no-verify -m "wip: urgent backup before reboot"
```
*`--no-verify` (oder `-n`) deaktiviert alle Pre-Commit und Commit-Msg Hooks für diesen einen Befehl.*

### Nachträgliches Korrigieren einer abgelehnten Nachricht:
Falls der Commit abgebrochen wurde, ist noch nichts im Git-Log gespeichert. Falls du den letzten bereits existierenden Commit korrigieren willst:
```bash
git commit --amend -m "fix(typo): corrected commit header"
```

### Globale Hooks wieder deaktivieren:
Falls du die globalen Hooks jemals wieder entfernen möchtest:
```bash
git config --global --unset core.hooksPath
```
Danach gelten wieder nur die lokalen `.git/hooks` in den einzelnen Repositories.
