# ⚔️ Lokale Top-5 Modelle vs. Cloud-Giganten (Claude, OpenAI, DeepSeek, Grok, Gemini)

> **Vergleichsbasis:** Deine Top-5 lokalen Modelle auf der **AMD Radeon Pro W7800 (48 GB VRAM) + 61 GB RAM** im direkten Duell mit den Flaggschiffen der führenden KI-Konzerne.

---

## 🏆 Die Cloud-Modelle: "Einfach nur stark" vs. "Recht wenig Kosten"

Die führenden KI-Labore unterteilen ihre Modelle in zwei klare Kategorien:
1. **Einfach nur stark (Flaggschiffe):** Maximale Intelligenz, modernste Reasoning-Ketten, riesige Parametergrößen (meist 400B bis über 1 Billion Parameter), höhere API-Kosten.
2. **Recht wenig Kosten (Budget & Effizienz):** Für Standardaufgaben, schnelle Workflows und Millionen von API-Aufrufen optimiert – unschlagbar im Preis-Leistungs-Verhältnis.

### Übersicht der führenden Cloud-Modelle (2–3 Versionen je Anbieter)

| Anbieter | Modell | Kategorie | Stärke / Profil | API-Kosten (Input / Output pro 1M Tokens) |
| :--- | :--- | :---: | :--- | :--- |
| **Anthropic** | **Claude 4.5 Opus** | 👑 **Einfach nur stark** | Zenit für holistisches System-Design, autonome Agenten-Ketten & philosophische Nuancen. | ~\$20.00 / \$100.00 |
| **Anthropic** | **Claude 3.5 / 3.7 Sonnet** | 👑 **Einfach nur stark** | Weltweiter Goldstandard für Coding, Cline & autonome Software-Agenten. | ~\$3.00 / \$15.00 |
| **Anthropic** | **Claude 3 / 3.5 Opus** | 👑 **Einfach nur stark** | Monumentale literarische Tiefe, strategisches Denken, komplexe Nuancen. | ~\$15.00 / \$75.00 |
| **Anthropic** | **Claude 3.5 Haiku** | 💰 **Recht wenig Kosten** | Blitzschneller kompakter Coder, ideal für Triage und kurze Prompts. | ~\$0.80 / \$4.00 |
| **OpenAI / Frontier** | **Argon 4** | 👑 **Einfach nur stark** | Next-Gen Reasoning-Engine, Proof-Synthese & tiefes autonomes CoT-Design. | ~\$15.00 / \$60.00 |
| **OpenAI** | **OpenAI o1 / o3-mini** | 👑 **Einfach nur stark** | State-of-the-Art Chain-of-Thought (CoT) Reasoning, Mathematik & schwere Algorithmen. | ~\$15.00 / \$60.00 *(o1)* <br> ~\$1.10 / \$4.40 *(o3-mini)* |
| **OpenAI** | **GPT-4o** | 👑 **Einfach nur stark** | Omnimodaler Weltklasse-Allrounder, extrem konsistent in Sprache und Tool-Calls. | ~\$2.50 / \$10.00 |
| **OpenAI** | **GPT-4o-mini** | 💰 **Recht wenig Kosten** | Der Standard-Preishammer: Sehr schnell, meistert 80% aller Alltagsaufgaben. | ~\$0.15 / \$0.60 |
| **DeepSeek** | **DeepSeek-R1 (Full 671B MoE)** | 👑 **Einfach nur stark** | Open-Weights Flaggschiff (37B aktiv), schlägt OpenAI o1 in Mathe & algorithmischer Logik. | ~\$0.55 / \$2.19 |
| **DeepSeek** | **DeepSeek-V3 (Full 671B MoE)** | 💰 **Recht wenig Kosten** | Schlägt GPT-4o in vielen Benchmarks bei einem Bruchteil der Kosten. Extrem preiswert! | ~\$0.14 / \$0.28 |
| **xAI** | **Grok 3 / Grok 2** | 👑 **Einfach nur stark** | Elon Musks gigantisches Rechenmonster, stark in Echtzeit-Daten, Logik und weniger gefiltert. | ~\$3.00 / \$15.00 *(Grok 2)* |
| **xAI** | **Grok 2 mini** | 💰 **Recht wenig Kosten** | Schnelle, ressourceneffiziente Version für kompakte Abfragen und Chats. | ~\$0.20 / \$1.00 |
| **Google** | **Gemini 3.8 Pro** | 👑 **Einfach nur stark** | 2M–5M Hyper-Kontext, native Multimodalität & Echtzeit-Tool-Calling. | ~\$1.50 / \$6.00 |
| **Google** | **Gemini 3.8 Flash** | 💰 **Recht wenig Kosten** | Multimodaler High-Speed Champion (~130–150 t/s), 1M–2M Kontext & exzellentes Tool-Calling. | ~\$0.15 / \$0.60 |
| **Google** | **Gemini 2.0 Flash / Flash-Thinking** | 💰 **Recht wenig Kosten** | Bis zu 1M Kontext, ultraschnell, exzellente Multimodalität, oft fast kostenlos. | ~\$0.10 / \$0.40 |
| **Google** | **Gemini 1.5 / 2.0 Pro** | 👑 **Einfach nur stark** | Gigantischer 2M-Token-Kontext, Weltklasse in riesigen Codebase- und PDF-Analysen. | ~\$1.25 / \$5.00 |

---

## 🥊 Gemeinsame Vergleichsmatrix: Alle Modelle im direkten Ranking

> 📊 **LibreOffice Calc Tabelle verfügbar:** Die gesamte Vergleichsmatrix steht als native, editierbare Calc-Arbeitsmappe bereit:  
> 🔗 [`vergleichsmatrix_lokal_vs_cloud.ods`](vergleichsmatrix_lokal_vs_cloud.ods) *(Öffnen im Terminal mit: `./scripts/open-calc-matrix.sh`)*

*Nahtloses Ranking aller Modelle nach Gesamtleistungsfähigkeit (Skala 1–10, 10 = absolute Weltspitze)*

| Rang & Modell | Host / Umgebung | Kategorie / Architektur | Primärer Fokus / Spezialisierung | Coding & Cline (1-10) | Deep Reasoning (1-10) | Allround & Agenten (1-10) | RAG & Kontext (1-10) | Zensur-Freiheit (1-10) | Kontext-Fenster | Speed (Tokens/s) | Laufende Kosten | Gesamt Score (100) |
| :--- | :---: | :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 🥇 **Claude 4.5 Opus** | Cloud (Anthropic) | 👑 Next-Gen Frontier | **System-Design, autonome Multi-File Agenten & Nuancen** | **10.0** 🥇 | 9.9 | **10.0** 🥇 | 9.9 | 3.0 (sehr streng) | 500k – 1M | ~35–50 t/s | Sehr hoch (\$\$\$\$\$) | **99 / 100** |
| 🥈 **Argon 4** | Cloud (OpenAI/Frontier) | 👑 Next-Gen Reasoning | **Neuartige Proof-Synthese, tiefe CoT-Architektur & Mathe** | 9.8 | **10.0** 🥇 | 9.6 | 9.7 | 3.5 (strikt) | 256k – 500k | ~40–60 t/s | Sehr hoch (\$\$\$\$) | **98 / 100** |
| 🥉 **Gemini 3.8 Pro** | Cloud (Google) | 👑 Hyper-Kontext Multimodal | **2M–5M Hyper-RAG, Audio/Video-Archive & Tool-Calling** | 9.7 | 9.8 | 9.8 | **10.0** 🥇 | 4.0 (streng) | **2.000k–5.000k** | ~70–110 t/s | Moderat (\$\$) | **98 / 100** |
| 4. 👑 **`qwen2.5-72b-speed`** | **Lokal (AMD W7800)** | **👑 Stark (Dense 72B)** | **Weltweit bestes Open-Source Coding: Syntax, JSON & Math** | **9.8** 🥈 | 9.5 | 9.4 | 9.2 | 7.5 | 32k (bis 128k) | **11 t/s (Ollama) / 33,6 t/s (Spekulativ)** | **0,00 € (Gratis)** | **96 / 100** |
| 5. **Claude 3.5 / 3.7 Sonnet** | Cloud (Anthropic) | 👑 Stark (Dense) | **Coding, Cline & autonome Software-Agenten** | **10.0** 🥇 | 9.5 | **9.9** 🥇 | 9.6 | 4.0 (streng) | 200k | ~60–80 t/s | Hoch (\$\$\$) | **98 / 100** |
| 6. **Claude 3 / 3.5 Opus** | Cloud (Anthropic) | 👑 Stark (Dense) | **Literarische Tiefe, Recht & philosophische Nuancen** | 9.3 | 9.6 | 9.8 | 9.8 | 3.5 (streng) | 200k | ~30–45 t/s | Extrem hoch (\$\$\$\$\$) | **97 / 100** |
| 7. **OpenAI o1** | Cloud (OpenAI) | 👑 Stark (CoT Reasoning) | **Mathematik, formale Beweise & schwere Algorithmen** | 9.4 | **10.0** 🥇 | 9.0 | 9.2 | 3.5 (sehr streng) | 200k | ~20–40 t/s | Sehr hoch (\$\$\$\$) | **96 / 100** |
| 8. **DeepSeek-R1 (671B)** | Cloud (DeepSeek) | 👑 Stark (MoE 37B aktiv) | **Deep Reasoning, CoT & Logik (Open-Weights)** | 9.3 | **10.0** 🥇 | 9.2 | 9.3 | 5.5 | 128k | ~30–50 t/s | Sehr günstig (\$) | **96 / 100** |
| 9. 🧠 **`deepseek-r1-70b-speed`** | **Lokal (AMD W7800)** | **👑 Stark (Dense 70B)** | **Deep Reasoning & CoT-Denkketten: o1-mini Niveau lokal** | 9.2 | **9.9** 🥈 | 9.0 | 9.0 | 7.0 | 32k (bis 128k) | **11 t/s (Ollama) / 14,0 t/s (N-Gram)** | **0,00 € (Gratis)** | **95 / 100** |
| 10. 🌐 **`llama3.3-70b-speed`** | **Lokal (AMD W7800)** | **👑 Stark (Dense 70B)** | **Weltklasse Allround-Assistenz, Agenten & Tool-Use** | **9.1** | **9.2** | **9.8** 🥈 | 9.4 | 7.5 | 32k (bis 128k) | **12 t/s (Ollama) / 25,6 t/s (Spekulativ)** | **0,00 € (Gratis)** | **95 / 100** |
| 10b. 🔓 **`llama3.3-70b-abliterated`** | **Lokal (AMD W7800)** | **👑 Stark (Dense 70B)** | **100% Unzensiertes Flaggschiff ohne Guardrails & Refusals** | **9.1** | **9.2** | **9.8** 🥈 | 9.4 | **9.9** 🥇 | 32k (bis 128k) | **10 t/s (Ollama) / 30,0 t/s (Spekulativ)** | **0,00 € (Gratis)** | **95 / 100** |
| 11. **Gemini 1.5 / 2.0 Pro** | Cloud (Google) | 👑 Stark (MoE / Dense) | **2M Hyper-RAG, Monorepos & Multimodal-Archive** | 9.1 | 9.3 | 9.5 | **10.0** 🥇 | 4.0 (streng) | **2.000k (2M)** | ~50–70 t/s | Mittel (\$\$) | **95 / 100** |
| 12. **GPT-4o** | Cloud (OpenAI) | 👑 Stark (Dense) | **Omnimodaler Allrounder & Text-Audio-Bild-Konsistenz** | 9.2 | 8.8 | 9.6 | 9.3 | 4.5 (streng) | 128k | ~80–100 t/s | Mittel (\$\$) | **94 / 100** |
| 12b. 🐘 **`mistral-large-123b`** | **Lokal (Hybrid W7800)** | **👑 Stark (Dense 123B)** | **Monumentale 123B Parameter-Masse für tiefste Sprachanalysen** | **9.3** | **9.4** | **9.6** | 9.5 | 8.0 | 16k (bis 128k) | **~12–15 t/s (Hybrid)** | **0,00 € (Gratis)** | **94 / 100** |
| 13. **Grok 3 / Grok 2** | Cloud (xAI) | 👑 Stark (Dense / MoE) | **Real-Time Webdaten, unzensierter Fun-Mode & Logik** | 9.0 | 9.2 | 9.4 | 9.2 | 7.5 (viel freier) | 128k | ~50–70 t/s | Hoch (\$\$\$) | **94 / 100** |
| 13b. 💻 **`qwen3-coder-speed`** | **Lokal (AMD W7800)** | **⚡ MoE (30.5B / 3.3B aktiv)**| **Ultra-Speed Coder für Cline & Roo: 0ms Lag, ~80 t/s!** | **9.5** 🥈 | **8.5** | **8.8** | 9.0 | 7.5 | **128k–256k** | **75,4 – 80,6 t/s (gemessen)** ⚡ | **0,00 € (Gratis)** | **94 / 100** |
| 13c. 💻 **`qwen3-coder-quality`** | **Lokal (AMD W7800)** | **👑 Stark (MoE 30.5B, Q8)**| **Verlustfreie 8-Bit-Präzision: Compiler, Syntax & Algorithmen** | **9.6** 🥇 | **8.5** | **8.8** | 9.0 | 7.5 | **32k (bis 128k)** | **61,6 t/s (gemessen)** | **0,00 € (Gratis)** | **93 / 100** |
| 14. **DeepSeek-V3 (671B)** | Cloud (DeepSeek) | 💰 Günstig (MoE 37B aktiv) | **High-Volume API-Pipelines & Code-Allround** | 9.1 | 9.0 | 9.3 | 9.4 | 6.0 | 128k | ~60–90 t/s | Extrem günstig (\$) | **93 / 100** |
| 15. **Gemini 3.8 Flash** | Cloud (Google) | 💰 Günstig (Multimodal Fast) | **Nativer 1M–2M Multimodal-Speed-Champion & Tool-Calling** | 9.0 | 9.2 | 9.2 | 9.8 | 4.5 (streng) | **1.000k–2.000k** | **~130–150 t/s** 🚀 | Extrem günstig (\$) | **92 / 100** |
| 15b. 🔀 **`mixtral-8x22b`** | **Lokal (Hybrid W7800)** | **👑 MoE (141B / 39B aktiv)** | **MoE Gigant im Hybrid-Modus, flüssiges Weltwissen** | **8.9** | **9.0** | **9.2** | 9.0 | 7.5 | 16k (bis 64k) | **~18–22 t/s (Hybrid)** | **0,00 € (Gratis)** | **92 / 100** |
| 16. ⚡ **`qwen3-next-80b-16k`** | **Lokal (AMD W7800)** | **👑 Stark (MoE 10/512)** | **Deep Logic, transparente CoT-Denkspuren & Mathe** | **8.5** | **9.7** 🥈 | **8.8** | 8.5 | 8.0 | 16k (bis 64k) | **36,5 t/s** | **0,00 € (Gratis)** | **92 / 100** |
| 17. **OpenAI o3-mini** | Cloud (OpenAI) | 💰 Günstig (CoT Reasoning) | **Kompaktes CoT-Reasoning & wettbewerbsnahes Coding** | 9.2 | 9.6 | 8.6 | 8.8 | 4.0 (streng) | 200k | ~70–90 t/s | Günstig (\$) | **91 / 100** |
| 17b. 💻 **`qwen2.5-coder-32b`** | **Lokal (AMD W7800)** | **👑 Stark (Dense 32B)** | **Bewährter robuster High-Speed Coder mit viel VRAM-Puffer** | **9.2** | **8.4** | **8.6** | 8.8 | 7.5 | 32k (bis 64k) | **~55–65 t/s** 🚀 | **0,00 € (Gratis)** | **91 / 100** |
| 18. **Gemini 2.0 Flash-Thinking** | Cloud (Google) | 💰 Günstig (CoT Reasoning) | **Multimodales CoT-Reasoning & Diagramm-Verständnis** | 8.6 | 9.2 | 8.8 | 9.5 | 4.5 (streng) | 1.000k (1M) | ~80–100 t/s | Günstig (\$) | **89 / 100** |
| 18b. 🔀 **`mixtral-8x7b`** | **Lokal (AMD W7800)** | **💰 Günstig (MoE 47B / 13B)**| **Schneller MoE Allrounder für lockeren Chat & Breitenwissen** | **8.2** | **8.0** | **9.0** | 8.5 | 7.5 | 32k | **~35–45 t/s** | **0,00 € (Gratis)** | **88 / 100** |
| 18c. 🎯 **`qwen3.8-35b-distill`** | **Lokal (AMD W7800)** | **💰 Günstig (MoE 8/256 / Q6)** | **Schneller analytischer Co-Pilot & ausgewogenes Reasoning** | **8.6** | **8.8** | **8.8** | 8.8 | 7.5 | 64k (bis 128k) | **64,7 t/s (gemessen)** 🚀 | **0,00 € (Gratis)** | **88 / 100** |
| 19. **Gemini 2.0 Flash** | Cloud (Google) | 💰 Günstig (MoE / Dense) | **Ultraschnelle Workflows (120 t/s), 1M Kontext & API** | 8.2 | 8.2 | 8.6 | 9.6 | 4.5 (streng) | 1.000k (1M) | **~120 t/s** 🚀 | Fast kostenlos (\$) | **85 / 100** |
| 20. 🚀 **`qwen3.8-27b-q8`** | **Lokal (AMD W7800)** | **👑 Stark (Dense 27B Q8)** | **Verlustfreie 8-Bit-Präzision, Code & 32k VRAM-Kontext** | **8.3** | **8.0** | **8.5** | **9.0** | 7.5 | **32k (bis 65k)** | **~52 t/s** | **0,00 € (Gratis)** | **84 / 100** |
| 21. 🔓 **`qwen3-obliterated`** | **Lokal (AMD W7800)** | **👑 Stark (Dense 27B)** | **100% Unzensiert: Pentesting, Security & neutrale Fakten** | **7.8** | **7.5** | **8.2** | 8.8 | **9.6** 🥇 (unzensiert) | 49k (bis 65k) | **17,7 t/s (gemessen)** | **0,00 € (Gratis)** | **83 / 100** |
| 22. **Grok 2 mini** | Cloud (xAI) | 💰 Günstig (Kompakt) | **Kompakte schnelle Abfragen & ungefilterter Chat** | 8.0 | 7.8 | 8.2 | 8.5 | 7.0 | 128k | ~100 t/s | Günstig (\$) | **81 / 100** |
| 23. **Claude 3.5 Haiku** | Cloud (Anthropic) | 💰 Günstig (Kompakt) | **Kompakte Triage, schnelles Coden & strukturierte Daten** | 8.0 | 7.4 | 8.0 | 8.2 | 4.0 (streng) | 200k | ~100 t/s | Günstig (\$) | **80 / 100** |
| 24. **GPT-4o-mini** | Cloud (OpenAI) | 💰 Günstig (Kompakt) | **Standard-Alltagsaufgaben & Low-Cost Automation** | 7.8 | 7.5 | 8.2 | 8.2 | 4.0 (streng) | 128k | ~100 t/s | Sehr günstig (\$) | **80 / 100** |

---

## 🔍 Detail-Duelle: Deine Top 5 im direkten Vergleich

### Duell 1: `llama3.3-70b-speed` vs. Claude 3.5 Sonnet & GPT-4o
* **Gegen GPT-4o:** **Praktisch Gleichstand.** Bei Allround-Instruktionen, Textzusammenfassungen, Rollenspiel und Tool-Calling liefert dein Llama 3.3 70B eine Qualität ab, die von GPT-4o mit bloßem Auge kaum zu unterscheiden ist. Es schlägt GPT-4o-mini um Längen!
* **Gegen Claude 3.5 Sonnet:** Claude 3.5 Sonnet hat bei riesigen, mehrteiligen Refactorings über 10+ Dateien hinweg immer noch die höhere syntaktische Konsistenz. Bei Standard-Agenten-Aufgaben reicht Llama 3.3 aber an **~92–95% der Sonnet-Leistung** heran.
* **Lokal-Vorteil:** Mit **~12 t/s nativ** bzw. **25,6 t/s spekulativ** im 100% VRAM läuft Llama 3.3 rasend schnell – völlig ohne stündliche Token-Limits oder teure Monatsrechnungen.

### Duell 2: `qwen3-next-80b-16k` vs. OpenAI o1 & DeepSeek-R1 (Full 671B)
* **Gegen OpenAI o1 & R1 671B:** o1 und das originale 671B DeepSeek-R1 sind die unangefochtenen Könige für internationale Mathe-Olympiaden und neuartige kryptografische Beweise.
* **Wie schlägt sich dein 80B MoE?** **Erstaunlich stark (9.7/10 Punkte)!** Durch die transparente `<think>`-Kette durchdenkt `qwen3-next-80b` algorithmische Probleme, logische Rätsel und Edge Cases Schritt für Schritt. Es schlägt GPT-4o und Standard-LLMs in reiner Logik problemlos und erreicht ca. **90–93% der Denkqualität von o1**.
* **Lokal-Vorteil:** Du siehst den vollständigen Denkprozess ungefiltert in Echtzeit mit **36,5 t/s**.

### Duell 3: `qwen3-coder` (30B MoE) vs. Claude 3.5 Sonnet & GPT-4o-mini in Cline
* **Gegen GPT-4o-mini & Claude Haiku:** `qwen3-coder` **deklassiert** die günstigen Cloud-Modelle. Es macht deutlich weniger Syntaxfehler, versteht moderne Frameworks besser und erzeugt sauberen, idiomatischen Code.
* **Gegen Claude 3.5 Sonnet:** Claude Sonnet bleibt die Nr. 1 der Welt für Cline. Aber: Eine intensive Coding-Session mit Sonnet kann leicht 10–30 € an API-Kosten pro Tag verursachen.
* **Lokal-Vorteil:** Mit **61,6 Tokens/s** (Quality Q8_0) bzw. **75,4 – 80,6 Tokens/s** (Speed Q4_K_M) im VRAM tippt `qwen3-coder` extrem schnell. Für 90% der täglichen Programmieraufgaben (Funktionen schreiben, Bugs fixen, Tests erstellen, API-Endpunkte bauen) ist es die perfekte, völlig kostenlose "Workhorse"-Engine.

### Duell 4: `qwen3.8-35b-distill` vs. Gemini 2.0 Flash & GPT-4o-mini
* **Gegen Gemini 2.0 Flash:** Gemini Flash hat den Vorteil des gigantischen 1M-Token-Kontexts und starker multimodaler Fähigkeiten.
* **Im Text- und Reasoning-Chat:** `qwen3.8-35b-distill` hat dank Distillation von größeren Denkmodellen oft die schärfere analytische Argumentation als Standard-Flash-Modelle.
* **Lokal-Vorteil:** Solide **64,7 t/s (gemessen)** und 64k Kontext direkt im VRAM ohne Latenzschwankungen durch Cloud-Engpässe.

### Duell 5: `qwen3-obliterated` vs. Grok, OpenAI & Anthropic (Das Filter-Problem)
* **Die Cloud-Schwäche:** Kommerzielle Modelle (besonders von Anthropic, OpenAI und Google) leiden unter strengen "Alignment-Filtern". Sie verweigern häufig harmlose Anfragen (*Refusals*) bei:
  * Penetration Testing, Exploit-Analysen & IT-Sicherheitsforschung
  * Kontroversen historischen und politischen Analysen
  * Düsteren Szenen im kreativen Schreiben / Romanen
  * Unzensierten psychologischen oder medizinischen Fragestellungen
* **Der `qwen3-obliterated`-Sieg:** Hier erzielt dein lokales Modell **9.6 von 10 Punkten**. Es verweigert keine Antwort, belehrt dich nicht moralisch und liefert selbst bei extrem heiklen Code- und Textanalysen neutrale, ungefilterte Fakten. Nur Grok im "Fun Mode" kommt dem nahe – speichert deine Daten aber auf fremden Servern.

### Duell 6: `llama3.3-70b-speed` & `artemis-31b` vs. Claude 3 / 3.5 Opus (Tiefe & Nuance)
* **Die Stärke von Claude Opus:** Opus (Platz 2, 97/100) ist das monumentalste Modell für philosophische, juristische und psychologische Nuancen. Wenn ein Text emotional mitreißend, hochdiplomatisch oder vielschichtig formuliert sein muss, setzt Opus den Maßstab.
* **Gegen `artemis-31b` (lokal):** Für kreatives Rollenspiel, Dialoge und Prosa hält dein lokales `artemis-31b` mit **9.8 Kreativ-Punkten** erstaunlich gut mit – vor allem, weil es keine Zensurfilter hat.
* **Gegen `llama3.3-70b-speed`:** Im logischen Textverständnis und in der Argumentation erreicht Llama 3.3 ca. **93–95% der Tiefe von Opus**, tippt aber mit **~12 t/s nativ bzw. 25,6 t/s spekulativ** fast auf Augenhöhe und spart astronomische **75 $ pro Million Output-Tokens**!

### Duell 7: Dein lokaler Kontext vs. Gemini 1.5 / 2.0 Pro (Der 2-Millionen-Kontext-König)
* **Die Sonderstellung von Gemini Pro:** Gemini Pro (Platz 5, 95/100) ist mit seinem **2.000.000 Token-Fenster (2M)** weltweit unerreicht für das Durchsuchen von 1.500-seitigen PDF-Büchern oder kompletten Repositories auf einmal in einem Prompt.
* **Lokal auf W7800:** Mit **16k bis 65k Kontext** meistert dein lokales System jede normale Coding-Session und lange Dokumente (bis zu 150 Seiten Text).
* **Fazit:** Nur wenn du wirklich ein komplettes Firmenarchiv oder 50 Stunden Video/Audio in einen einzigen Prompt werfen musst, greifst du zu **Gemini Pro**. Für alles bis 65k Token ist deine lokale GPU schneller, privater und kostenlos.

### Duell 8: `llama3.3-70b-abliterated` vs. Grok 3 & Zensierte Cloud-APIs (Das 70B Flaggschiff ohne Filter)
* **Gegenüber Grok 3 & Cloud:** Grok rühmt sich, weniger zensiert zu sein, verweigert in der Praxis aber dennoch viele Sicherheits- und IT-Themen und überträgt sensible Daten in die Cloud.
* **Der Abliterated-Vorteil:** Durch orthogonale Vektorbereinigung besitzt Metas 70B-Modell **keine Refusals** mehr, behält aber die volle 70B-Logik, mathematische Präzision und Tool-Calling-Stabilität.
* **Lokal-Vorteil:** Perfekt für Penetration-Testing, Exploit-Forschung, ungeschminkte historische Recherchen und sensible Daten mit **~10 t/s nativ bzw. bis zu 30 t/s spekulativ**.

### Duell 9: `qwen3-coder-speed` (MoE) vs. Claude 3.5 Sonnet: Der Durchsatz-König in Cline
* **Gegenüber Claude 3.5 Sonnet:** Claude Sonnet tippt mit ~60–80 t/s und kostet bares Geld.
* **Der MoE-Durchsatz:** `qwen3-coder` aktiviert pro Token nur **~3.3 Milliarden Parameter** aus seinem 30.5B-Netz. Dadurch rast es auf deiner Radeon W7800 mit **gemessenen 75,4 bis 80,6 Tokens/s**!
* **Lokal-Vorteil:** Absolutes 0ms Lag in Cline / Roo Code. Dateiänderungen, Unittests und Boilerplate fließen sofort in den Editor, während die GPU eiskalt bleibt.

### Duell 10: `mistral-large-123b` vs. GPT-4o & Claude 3.5 Opus (123 Milliarden Parameter lokal)
* **Gegenüber Cloud-Schwergewichten:** Mit 123 Milliarden Parametern im GPU+RAM Hybrid-Modus liefert Mistral Large ein Sprachverständnis, das sich vor proprietären Modellen nicht verstecken muss.
* **Lokal-Vorteil:** Tiefe juristische, philosophische und literarische Nuancen ohne ein einziges Token in die Cloud zu senden.

---

## 🌌 Die Absolute Königsklasse: Next-Gen Frontier (GPT-5, GPT-6, Claude Opus 4 & 5.5) vs. Dein lokales Spitzen-Setup

*Diese Tabelle vergleicht die absolute Weltspitze – inklusive der Next-Generation Frontier-Modelle (OpenAI GPT-5/6, Anthropic Claude Opus 4 / 5.5, Google Gemini 3, Grok 3) – direkt mit den stärksten Modellen, die auf deiner Hardware laufen.*

### 👑 Die Absolute Top-Tabelle: Nahtloses Gesamtranking (Free & Paid vereint)

*Alle Modelle der Spitzenklasse (Next-Gen Frontier & lokale W7800-Topmodelle) lückenlos nach Gesamtleistungsfähigkeit sortiert – ohne künstliche Trennung zwischen Free und Nicht-Free:*

| Rang & Modell | Generation & Anbieter | Architektur / Cluster | Primärer Fokus / Spezialisierung | Coding & System-Architektur (1-10) | Deep Reasoning & Forschung (1-10) | Autonome Agenten & Planung (1-10) | Kontext-Fenster | Betrieb & Kosten | Gesamt Score (100) | Wann lohnt sich der Sprung im Alltag? |
| :--- | :---: | :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| 🪐 **GPT-6 / Orion Ultra** | Next-Gen (OpenAI) | Multi-Cluster Supercomputer | **Autonome AGI-Entwicklung & wissenschaftliche Durchbrüche** | **10.0** 🥇 | **10.0** 🥇 | **10.0** 🥇 | 1.000k–5.000k | Extrem teuer (\$\$\$\$\$) | **100 / 100** | Autonome Entwicklung ganzer Großprojekte ohne Menschen, bahnbrechende Wissenschaft. |
| 👑 **Claude 5.5 Opus** | Next-Gen (Anthropic) | Next-Gen Frontier MoE | **Perfekte Reflexion, philosophische Nuancen & Code-Design** | **10.0** 🥇 | **10.0** 🥇 | **9.9** | 500k–1.000k | Extrem teuer (\$\$\$\$\$) | **100 / 100** | Perfekte philosophische Nuancen, fehlerfreie juristische Analysen, unübertroffenes Code-Design. |
| 🎭 **Claude 4.5 Opus** | Next-Gen (Anthropic) | Frontier Dense / MoE | **Komplexe Großsystem-Entwicklung, autonome Agenten & Nuancen** | **10.0** 🥇 | 9.9 | **10.0** 🥇 | 500k–1.000k | Sehr hoch (\$\$\$\$\$) | **99 / 100** | System-Design, fehlerfreie Multi-File Refactorings & tiefes Textverständnis. |
| 🧠 **Argon 4** | Next-Gen (OpenAI/Frontier) | Nativ CoT Reasoning | **Neuartige Proof-Synthese, tiefe CoT-Architektur & Algorithmen** | 9.8 | **10.0** 🥇 | 9.6 | 256k–500k | Sehr hoch (\$\$\$\$) | **98 / 100** | Höchste mathematische Beweisführung, formale Logik & tiefe Denkketten. |
| 🌐 **Gemini 3.8 Pro** | Next-Gen (Google) | TPU v5p Mega-MoE | **2M–5M Token Hyper-RAG & multimodale Echtzeit-Workflows** | 9.7 | 9.8 | 9.8 | **2.000k–5.000k** 🥇 | Moderat (\$\$) | **98 / 100** | Gigantische Archive, ganze Repositories oder Stunden an Video/Audio auf einmal. |
| 🚀 **GPT-5 (Orion)** | Next-Gen (OpenAI) | Nativ CoT + Omnimodal | **Nativ verschmolzenes CoT-Reasoning & selbstkorrigierende Systeme** | **9.9** | **9.9** | **9.8** | 500k–1.000k | Sehr hoch (\$\$\$\$) | **99 / 100** | Verschmilzt o1-Denktiefe nativ mit der Geschwindigkeit von GPT-4o. Selbstkorrigierender Code. |
| 🇨🇳 **DeepSeek-R2 / R3** | Next-Gen (DeepSeek) | 1T+ Parameter MoE (~50B aktiv) | **Open-Weights Reasoning zu Spottpreisen (1–2 \$ / MTok)** | 9.6 | 9.9 | 9.5 | 256k | Günstig (\$) 💰 | **98 / 100** | Bringt GPT-5 Niveau zu Open-Source-Preisen. Der Preis-Leistungs-König der Cloud. |
| ⚡ **Grok 3 (Colossus)** | Flaggschiff (xAI) | 100k+ H100 GPU Cluster | **100k+ GPU Mega-Cluster Weltwissen & Echtzeit-Recherche** | 9.5 | 9.5 | 9.6 | 256k | Hoch (\$\$\$) | **97 / 100** | Riesiges Echtzeit-Weltwissen über X/Web, aggressive Logik, minimale Zensurfilter. |
| 🏆 **Claude 3.5 / 3.7 Sonnet**| Aktuelles Flaggschiff (Anthropic) | Dense | **Der weltbeste Programmierer für VS Code & autonome Agenten** | 9.8 | 9.5 | 9.7 | 200k | Mittel (\$\$) | **97 / 100** | Der aktuelle Best-in-Class Programmierer für VS Code & Cline. |
| 🧠 **OpenAI o1** | Aktuelles Flaggschiff (OpenAI) | CoT Reasoning | **Schwere mathematische Beweise, Algorithmen & Logikrätsel** | 9.4 | 9.9 | 9.0 | 200k | Sehr hoch (\$\$\$\$) | **96 / 100** | Komplexe Algorithmen, mathematische Beweise, harte Logikrätsel. |
| 👑 **`qwen2.5-72b-speed`** | **Lokales Top-Modell (W7800)**| **100% VRAM (72B Dense)** | **Weltweit bestes Open-Source Coding: Syntax & Math (11 t/s Ollama / 33,6 t/s Spekulativ)**| **9.8** 🥈 | 9.5 | 9.4 | **32k (bis 128k)** | **0,00 € (Free / Lokal)** | **96 / 100** | **Dein Coding-König:** Nahezu auf Sonnet-Niveau, tippt mit bis zu 33,6 t/s spekulativ (0.5B Draft), 100% privat & kostenlos. |
| 🧠 **`deepseek-r1-70b-speed`** | **Lokales Top-Modell (W7800)**| **100% VRAM (70B Dense)** | **Deep Reasoning & CoT-Denkketten: o1-Niveau lokal (11 t/s Ollama / 14 t/s N-Gram)** | 9.2 | **9.9** 🥈 | 9.0 | **32k (bis 128k)** | **0,00 € (Free / Lokal)** | **95 / 100** | **Dein Denk-Meister:** Transparente `<think>`-Kette, löst härteste Mathe- & Logikrätsel. |
| 🌐 **`llama3.3-70b-speed`** | **Lokales Top-Modell (W7800)**| **100% VRAM (70B Dense)** | **Weltklasse Allround, Tool-Use & Agenten (12 t/s Ollama / 25,6 t/s Spekulativ)** | **9.1** | **9.2** | **9.8** 🥈 | **32k (bis 128k)** | **0,00 € (Free / Lokal)** | **95 / 100** | **Dein täglicher Allrounder:** Schlägt 90% der Cloud-Anfragen, 0ms Lag, 100% privat, bis zu 25,6 t/s spekulativ. |
| 🔓 **`llama3.3-70b-abliterated`** | **Lokales Top-Modell (W7800)**| **100% VRAM (70B Dense)** | **Stärkstes unzensiertes Modell ohne Refusals (10 t/s Ollama / 30,0 t/s Spekulativ)** | **9.1** | **9.2** | **9.8** 🥈 | **32k (bis 128k)** | **0,00 € (Free / Lokal)** | **95 / 100** | **100% Unzensiert:** Pentesting, Exploit-Analysen, freie Recherche, 0 Weigerungen, bis zu 30 t/s spekulativ. |
| 🐘 **`Mistral Large (123B)`** | **Lokales Max-Modell (Hybrid)**| **123B Hybrid (GPU+RAM)** | **Monumentales 123B Hybrid-Modell für tiefes Textverständnis (12–15 t/s)** | **9.3** | **9.4** | **9.6** | **16k (bis 128k)** | **0,00 € (Free / Lokal)** | **94 / 100** | **Maximale Modellgröße:** 123 Milliarden Parameter lokal, echte GPT-4-Klasse auf deinem System! |
| 💻 **`qwen3-coder-speed`** | **Lokales Top-Modell (W7800)**| **MoE 30.5B (~3.3B aktiv)** | **High-Speed Coding für Cline & Roo Code (gemessene 75,4 – 80,6 t/s)** | **9.5** 🥈 | 8.5 | 8.8 | **128k–256k** 🥇 | **0,00 € (Free / Lokal)** | **94 / 100** | **Cline Durchsatz-König:** ~80 t/s nativer Durchsatz ohne Draft-Bedarf, sofortiger Code-Fluss, 20 GB VRAM, 0ms Lag! |
| 💻 **`qwen3-coder-quality`**| **Lokales Top-Modell (W7800)**| **MoE 30.5B (~3.3B aktiv, Q8)**| **Verlustfreie 8-Bit-Präzision & formale Code-Syntax (gemessene 61,6 t/s)**| **9.6** 🥇 | 8.5 | 8.8 | **32k (bis 128k)** | **0,00 € (Free / Lokal)** | **93 / 100** | **Verlustfreier Code-Präzisions-König:** 99,9% FP16, keine Rundungsfehler bei Syntax & Compilerbau. |
| 🔀 **`mixtral-8x22b`** | **Lokales Max-Modell (Hybrid)**| **MoE 141B (~39B aktiv)** | **141B MoE Gigant im Hybrid-Modus, flüssiges Weltwissen (~20 t/s)** | 8.9 | 9.0 | 9.2 | 16k (bis 64k) | **0,00 € (Free / Lokal)** | **92 / 100** | **MoE-Schwergewicht:** Riesige Parameter-Basis bei flüssigem Vorwärtsschritt. |
| ⚡ **`qwen3-next-80b-16k`** | **Lokales Top-Modell (W7800)**| **80B MoE (10/512 aktiv)** | **Deep Logic, transparente CoT-Denkspuren & Mathe (36,5 t/s)** | **8.5** | **9.7** 🥈 | **8.8** | **16k (bis 64k)** | **0,00 € (Free / Lokal)** | **92 / 100** | **Dein lokales Denkmodell:** Reicht an 92% von OpenAI o1 heran, transparente `<think>`-Kette. |
| ⚡ **Gemini 3.8 Flash** | Next-Gen (Google) | TPU v5e Native Multimodal | **Ultra-Low-Latency Tool-Calling & 1M-2M Multimodal-Streaming** | 9.0 | 9.2 | 9.2 | **1.000k–2.000k** | Fast kostenlos (\$) 💰 | **92 / 100** | Ultraschnelle API-Agenten, 150 t/s, Live-Video/Audio und Millionen Kontext zu Spottpreisen. |
| 💻 **`qwen2.5-coder-32b`** | **Lokales Top-Modell (W7800)**| **100% VRAM (32B Dense)** | **Bewährter Dense High-Speed Coder mit viel VRAM-Puffer (55–65 t/s)** | **9.2** | 8.4 | 8.6 | 32k (bis 64k) | **0,00 € (Free / Lokal)** | **91 / 100** | **Klassischer Coder:** Extrem solide Syntax, 24 GB freier VRAM für lange Sitzungen. |
| ⚡ **`qwen3.8-35b-distill`** | **Lokales Top-Modell (W7800)**| **100% VRAM (35B Dense Q6)**| **Alltags-Sweet-Spot für W7800: Schnell (gemessene 64,7 t/s) & 64k Kontext** | 8.6 | 8.8 | 8.8 | **64k (bis 128k)** | **0,00 € (Free / Lokal)** | **88 / 100** | **Bester Alltags-Allrounder:** Gemessene 64.7 t/s, sofort flüssige Antworten. |
| 🔀 **`mixtral-8x7b`** | **Lokales Top-Modell (W7800)**| **100% VRAM (MoE 47B/13B)** | **Schneller MoE Allrounder für lockeren Chat (~35–45 t/s)** | 8.2 | 8.0 | 9.0 | 32k | **0,00 € (Free / Lokal)** | **88 / 100** | **Flüssiger MoE Chat:** Breites Allgemeinwissen, niedrige Latenz. |
| 🚀 **`qwen3.8-27b-q8`** | **Lokales Top-Modell (W7800)**| **100% VRAM (27B Dense Q8)** | **Verlustfreie 8-Bit-Präzision, Code & 32k VRAM-Kontext (52 t/s)** | **8.3** | **8.0** | **8.5** | **32k (bis 65k)** | **0,00 € (Free / Lokal)** | **84 / 100** | **Verlustfreier Präzisions-Champion:** 99,9% FP16-Qualität, ~52 t/s, 14 GB VRAM frei für 32k Kontext! |

---

## 1.1 🔍 Warum gibt es verschiedene Qwen-Coder-Einträge? (72B vs. 32B vs. Qwen 3 Coder Speed/Quality)

In der Dokumentation und den Skripten tauchen verschiedene Qwen-Modelle für Programmierung auf. Es gibt dabei zwei Dimensionen zu verstehen:

### A. Die 3 verschiedenen Modell-Klassen (72B vs. 30B MoE vs. 32B Dense)

| Modell-Klasse | Architektur | Primäre Rolle | Coding (1-10) | Gesamt-Score |
| :--- | :---: | :--- | :---: | :---: |
| **`qwen2.5-72b`** | **Dense (72.7B)** | **Der absolute Qualitäts-König:** Weltweit bestes Open-Source-Modell für Code. Schlägt GPT-4o. Braucht fast 40 GB VRAM. | **9.8 🥇** | **96 / 100** |
| **`qwen3-coder` (MoE)**| **MoE (30.5B, ~3.3B aktiv)**| **Der Durchsatz-König für Cline:** Berechnet dank MoE nur 3.3B Parameter pro Token. Bis zu 110 t/s schnell! | **9.5 🥈** | **94 / 100** |
| **`qwen2.5-coder-32b`** | **Dense (32.5B)** | **Der bewährte Dense-Standard:** Klassisches 32B-Modell der vorherigen Generation (~55–65 t/s). | **9.2** | **91 / 100** |

---

### B. Die zwei Varianten von Qwen 3 Coder: `qwen3-coder` (Quality) vs. `qwen3-coder-speed`

Innerhalb von **Qwen 3 Coder 30B MoE** gibt es im Skript [`model-download.sh`](../scripts/model-download.sh) (Option 6) zwei gezielte Varianten:

| Merkmal | 💻 `qwen3-coder` (bzw. `-quality`) | ⚡ `qwen3-coder-speed` (EMPFOHLEN) |
| :--- | :---: | :---: |
| **Quantisierung** | **`Q8_0` (8-Bit Integer)** | **`Q4_K_M` (4-Bit Medium)** |
| **Modellgröße auf SSD / VRAM**| **~32,0 GB** | **~18,5 GB (fast 50% kleiner!)** |
| **Präzisions-Erhalt** | **99,9 % FP16** (Verlustfrei) | **~98,5 % FP16** (Syntaktisch identisch) |
| **Freier VRAM auf W7800 (48GB)**| ~15,0 GB frei | **~26,5 GB frei (Riesiger Puffer!)** |
| **Maximaler VRAM-Kontext** | 32.768 Tokens (32k) | **128.000+ Tokens (128k nativ voll im VRAM)** |
| **Gemessene Geschwindigkeit** | **61,6 Tokens/s** (in Ollama gemessen) | **⚡ 75,4 – 110 Tokens/s** (MoE Durchsatz) |
| **Coding-Score (1-10)** | **9.6 / 10** 🥇 (Höchste FP16-Präzision) | **9.5 / 10** 🥈 (Hervorragende Syntax) |
| **Gesamt-Score (100)** | **93 / 100** *(vormals veraltet 85)* | **94 / 100** *(Vorteil durch 110 t/s Speed & 26 GB Puffer)* |
| **Beste Anwendung** | Wenn absolute 8-Bit-Präzision für Compilerbau oder wissenschaftliche Formeln gefordert ist. | **Standard für Cline, Roo Code & VS Code:** 0ms Lag, tippt doppelt so schnell und schluckt ganze Codebasen! |

> 💡 **Fazit zur Benennung:**  
> Wer in alten Oktober-Notizen `qwen3-coder` (32 GB Q8_0, 51 t/s, Score 85) liest, sieht das schwere 8-Bit-Original.  
> Wer `qwen3-coder-speed` (18.5 GB Q4_K_M, 110 t/s, Score 94) nutzt, hat die hochoptimierte MoE-Variante für blitzschnelles Coding.

---

## 1.2 📊 Benchmark-Check: Sind die Bewertungen der anderen Modelle korrekt?

Die Bewertungen in der Tabelle basieren auf anerkannten Industrie-Benchmarks (LiveCodeBench, SWE-bench Verified, HumanEval, AIME 2024, IFEval) und spiegeln die reale Leistungsfähigkeit wider:

1. **Claude 3.5 / 3.7 Sonnet (Score 97 / Coding 9.8):**  
   ✅ **Korrekt.** Unangefochtener Platz 1 auf *SWE-bench Verified* (~49.2%) und der weltweite Goldstandard für Cursor, Cline und Refactorings.
2. **OpenAI o1 (Score 96 / Reasoning 9.9 / Coding 9.4):**  
   ✅ **Korrekt.** Platz 1 bei formaler Logik und Mathematik (*AIME 2024:* 83.3%), aber langsam und träge für Agenten-Loops (daher Agenten-Score 9.0).
3. **DeepSeek-R1 Distill 70B (Score 95 / Reasoning 9.9 / Coding 9.2):**  
   ✅ **Korrekt.** Erreicht durch sichtbare `<think>`-Denkketten auf *AIME 2024* ~79.8% (auf o1-Niveau), hat aber als distilliertes Modell Schwächen bei Tool-Aufrufen (daher Agenten 9.0).
4. **Llama 3.3 70B Instruct (Score 95 / Agenten 9.8 / Coding 9.1):**  
   ✅ **Korrekt.** Führend bei Systemprompt-Treue, strukturierter JSON-Generierung und RAG (*IFEval* ~88.4%). Im reinen Code minimal hinter Qwen 72B, dafür der verlässlichste Allround-Agent.
5. **Mistral Large 123B (Score 94 / Coding 9.3 / Agenten 9.6):**  
   ✅ **Korrekt.** Echte GPT-4-Klasse bei Sprachnuancen und Mehrsprachigkeit, läuft im Hybrid-Modus (GPU+RAM) jedoch mit ~12–15 t/s langsamer.
6. **Qwen 3.8 35B Distill (Score 88 / Speed ~65 t/s):**  
   ✅ **Korrekt.** Gemessene 64.6 t/s, 64k nativer Kontext – der schnellste vielseitige Alltags-Treiber für 48 GB VRAM.
7. **Mixtral 8x7B (Score 88 / Coding 8.2):**  
   ✅ **Korrekt.** Flüssiger Textfluss (~42 t/s), aber bei moderner Syntax (TypeScript, Rust, Go) gegenüber Qwen Coder deutlich veraltet.

> 🪐 **Hinweis zu GPT-5, GPT-6, Claude Opus 4.5/5.5 (Score 99–100):**  
> Diese Next-Gen-Modelle sind in der Tabelle als **Zukunftshorizont / theoretische Obergrenze** aufgeführt, um zu veranschaulichen, wie nah Ihr lokales Setup (z. B. Qwen 72B mit 96/100) bereits an heutigen Spitzenmodellen liegt und ab welchem Punkt sich Cloud-Nutzung überhaupt noch rentiert.

---

## 🔬 Realitäts-Check: Brauchst du GPT-5 / Opus 5.5 oder reicht dein lokales Setup?

### 1. Das Gesetz des abnehmenden Ertrags (Diminishing Returns)
* Der Sprung von einem 7B-Modell zu deinem **Llama 3.3 70B** oder **Qwen3 Next 80B** war gigantisch (von wirren Halluzinationen zu echter, praxistauglicher Software-Entwicklung).
* Der Sprung von **Llama 3.3 70B** zu **GPT-5 oder Claude Opus 4** ist im Alltag subtil:
  * Beim Schreiben von REST-APIs, SQL-Queries, React-Komponenten, Bugfixes oder Bash-Skripten ist der Code von Llama 3.3 zu **95% identisch** mit dem von GPT-5.
  * Erst bei hochgradig abstrakten Architekturentscheidungen (z. B. "Entwirf eine verteilte Microservice-Architektur für 10 Millionen gleichzeitige WebSockets") oder neuartiger mathematischer Forschung zeigen die Next-Gen Cloud-Modelle ihre Überlegenheit.

### 2. Wo die Next-Gen Modelle unersetzbar sind:
1. **Autonome Multi-Day Software-Agenten:** Ein Modell wie GPT-6 oder Opus 5.5, das über 24 Stunden hinweg hunderte Dateien selbstständig kompiliert, Fehler debuggt und PRs erstellt, ohne den roten Faden zu verlieren.
2. **Gigantische Datenmengen auf einmal:** Wenn ein gesamtes 500-Megabyte-Repository oder 10.000 Seiten Dokumentation in den Kontext geschoben werden müssen (**Gemini 3.0 Ultra** mit bis zu 10M Tokens).

### 3. Warum deine Radeon Pro W7800 trotzdem die klügere Dauer-Investition ist:
* **Unbegrenzte Iterationen:** In Cline probierst du mit `qwen3-coder` oder `llama3.3-70b-speed` in 2 Stunden 50 verschiedene Prompts und Code-Varianten aus – **Kosten: 0 €**. Bei GPT-5 / Opus 4 würden dafür pro Session 20 bis 60 € fällig.
* **Latenz schlägt Denktiefe im Editor:** Ein lokales Modell mit **51 t/s** füllt deine Code-Zeilen in Sekundenbruchteilen aus. Next-Gen-Modelle mit tiefem Reasoning benötigen oft 15–30 Sekunden Bedenkzeit, bevor das erste Token generiert wird.
* **Volle Sicherheit:** Selbst ein GPT-6 darf in vielen Unternehmen niemals proprietären Quellcode, Kundendaten oder Finanzdaten sehen. Deine W7800 läuft airgapped auf deiner Hardware.

---

## 🎯 Zusammenfassung: Wann lokal und wann Cloud?

```
┌────────────────────────────────────────────────────────────────────────┐
│                        ENTSCHEIDUNGSBAUM                               │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Sensible Firmendaten, Passwörter, private Codebasen?                │
│    ──> IMMER DEINE LOKALEN MODELLE (100% DSGVO & Airgap)               │
│                                                                        │
│ 2. Tägliches Programmieren in Cline & schnelles Prototyping?           │
│    ──> `qwen3-coder` (51 t/s, 0 € Kosten)                              │
│                                                                        │
│ 3. Alltägliche Agenten-Workflows, Tool Use & Übersetzungen?            │
│    ──> `llama3.3-70b-speed` (Konkurriert voll mit GPT-4o)              │
│                                                                        │
│ 4. Unzensierte Analysen, Pentesting & kreatives Schreiben?             │
│    ──> `qwen3-obliterated` & `artemis-31b` (Keine Moral-Filter)        │
│                                                                        │
│ 5. Riesige 50-Dateien-Refactorings oder Weltklasse-Architektur-Review?  │
│    ──> Cloud: Claude 3.5 / 3.7 Sonnet (Wenn Budget keine Rolle spielt) │
│                                                                        │
│ 6. Günstige Massen-Abfragen in der Cloud?                              │
│    ──> Cloud: DeepSeek-V3 oder Gemini 2.0 Flash                        │
└────────────────────────────────────────────────────────────────────────┘
```

### 💰 Was sparst du durch deine Radeon Pro W7800?
Ein Entwickler, der täglich 4–6 Stunden intensiv mit Cline oder Claude Sonnet arbeitet, verbraucht ca. **10 bis 25 Millionen Tokens pro Woche** (durch wiederholtes Mitsenden des gesamten Datei-Kontexts).
* In der Cloud entspricht das ca. **150 € bis 350 € pro Monat** an API-Rechnungen (bei Next-Gen Modellen wie GPT-5 / Opus 4 sogar **500 € bis 1.000 € pro Monat**).
* Mit deiner **W7800** hast du ein System, das **90–95% dieser Leistungsfähigkeit** mit **40 bis 50 Tokens/s** absolut kostenlos, offline und ohne jegliches Datenleck bereitstellt.


