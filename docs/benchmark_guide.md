# Fortgeschrittenes LLM-Benchmarking (inkl. MTP, DFlash2 & Ollama-Integration)

Um Large Language Models (LLMs) auf Inferenz-Geschwindigkeit zu testen, reicht ein simpler Test oft nicht aus. Besonders auf leistungsstarker Hardware (wie einer AMD W7800 mit ROCm) sind fortgeschrittene Techniken wie **Speculative Decoding (MTP / DFlash2)** und die korrekte Verwaltung des **KV-Caches** entscheidend.

Diese Anleitung zeigt, wie Sie `llama.cpp` für professionelle Benchmarks nutzen und dabei bereits vorhandene **Ollama-Modelle wiederverwenden**.

---

## 1. Ollama-Modelle für llama.cpp wiederverwenden

Um Speicherplatz (und Zeit für Downloads) zu sparen sowie identische Bedingungen zu garantieren, testen wir dieselben GGUF-Dateien, die Ollama bereits heruntergeladen hat.

**Ollama-Blobs finden:**
```bash
# Suche nach großen Modell-Dateien in Ollamas Speicher
find ~/.ollama/blobs -type f -size +5G -printf '%s %p\n' | sort -n | tail -20
```

**Symlinks erstellen (für bessere Lesbarkeit):**
Ollama speichert Dateien unter Namen wie `sha256-ABC...`. Wir verlinken diese für unsere Tests, damit wir im Terminal nicht mit langen Hashes hantieren müssen:
```bash
mkdir -p ~/models/ollama
ln -s ~/.ollama/blobs/sha256-ABC... ~/models/ollama/Qwen3.8-27B-Q6_K.gguf
```

---

## 2. Advanced Parameter für den Benchmark

Beim Testen von großen Modellen (wie Qwen 27B) und viel Kontext (z.B. 32k - 128k) müssen wir die Ausführung optimieren. Diese Parameter sind kritisch für reale Performance-Werte auf Systemen wie der W7800:

* `-fa on`: Aktiviert **Flash Attention** (Pflicht für große Kontextfenster und effiziente ROCm-Nutzung).
* `-c 32768`: Setzt den Kontext auf 32k. *(Tipp: Messen Sie 32k und 128k separat, um den Einfluss der Cache-Größe zu sehen).*
* `-ctk q8_0` & `-ctv q8_0`: Quantisiert den KV-Cache auf 8-Bit. Das spart enorm VRAM bei langen Kontexten und erhöht oft die Bandbreite.
* `-b 8192` & `-ub 2048`: Optimierte Batch-Größen.

---

## 3. Benchmarking: Normal vs. Speculative Decoding

Der größte Geschwindigkeitssprung entsteht heutzutage durch Speculative Decoding. 

### Test A: Standard (Normales Decoding)
Die Referenz-Messung ohne spekulative Beschleunigung.
```bash
./build-rocm/bin/llama-bench -m ~/models/ollama/Qwen3.8-27B-Q6_K.gguf -n 512 -ngl 99 -fa on -c 32768 -ctk q8_0 -ctv q8_0
```

### Test B: Multi-Token Prediction (MTP)
Wenn das GGUF-Modell MTP-Tensoren enthält (nativ integriert), generiert das Modell mehrere Tokens gleichzeitig.
Da `llama-bench` Draft-Models unterschiedlich handhabt, misst man dies oft am besten über den `llama-server` und jagt Anfragen per `curl` dagegen, um die echten "Tokens pro Sekunde" der API auszulesen:
```bash
./build-rocm/bin/llama-server -m ~/models/ollama/Qwen3.8-27B-Q6_K.gguf \
  --spec-type draft-mtp \
  --spec-draft-n-max 3 \
  -ngl 99 -fa on -c 32768 -ctk q8_0 -ctv q8_0
```

### Test C: DFlash2 (Separater Drafter)
Nutzt ein separates, kleineres Modell (Drafter), um Tokens vorzuschlagen, die das große Zielmodell nur noch verifizieren muss.
```bash
./build-rocm/bin/llama-server -m ~/models/ollama/Qwen3.8-27B-Q6_K.gguf \
  --model-draft /pfad/zum/DFlash2-Drafter.gguf \
  --spec-type draft-dflash \
  -ngl 99 -fa on -c 32768 -ctk q8_0 -ctv q8_0
```

---

## 4. Test-Matrix für strukturierte Auswertung

Um den Überblick zu behalten, sollte die Benchmarking-Matrix priorisiert abgearbeitet werden. 

| Priorität | Test-Setup | Umsetzung | Erwartung (Beispiel W7800) |
| :--- | :--- | :--- | :--- |
| **1 (Referenz)** | Qwen3.8-27B (Q6) | llama.cpp normal (ROCm) | Basiswert (z.B. ~30 tok/s) |
| **2 (Hoch)** | Qwen3.8-27B (Q6) | llama.cpp + **MTP** | Deutlicher Boost (z.B. ~55 tok/s) |
| **3 (Sehr hoch)**| Qwen3.8-27B (Q6) | llama.cpp + **DFlash2** | Maximaler Boost (z.B. ~70 tok/s) |
| **4 (Kontrolle)**| Qwen3.8-27B (Q6) | Ollama normal | Vergleich Ollama Backend vs. llama.cpp |

**Wichtiges Fazit für den Test:**
Trennen Sie Tests strikt nach Kontextlänge! Ein KV-Cache von 128k drückt die reale Decode-Rate im Vergleich zu 32k massiv (da mehr Speicher hin- und hergeschoben werden muss). Messen Sie zuerst 32k oder 64k, um die reine Hardwaregeschwindigkeit der Speculation (MTP/DFlash2) zu isolieren.
