#!/usr/bin/env python3
"""
Generiert eine native, voll editierbare OpenDocument-Tabelle (.ods) für LibreOffice Calc
sowie eine CSV-Exportdatei aus der Modell-Vergleichsmatrix (LOKALE_TOP5_VS_CLOUD_FLAGGSCHIFFE.md).
"""

import os
import sys
import zipfile
import xml.sax.saxutils as saxutils

def escape_xml(s):
    return saxutils.escape(str(s))

# ------------------------------------------------------------------------------
# 1. Daten-Definitionen
# ------------------------------------------------------------------------------

# Blatt 1: Gesamtranking aller Modelle
SHEET1_HEADERS = [
    "Rang & Modell", "Host / Umgebung", "Kategorie / Architektur", 
    "Primärer Fokus / Spezialisierung", "Coding & Cline (1-10)", 
    "Deep Reasoning (1-10)", "Allround & Agenten (1-10)", 
    "RAG & Kontext (1-10)", "Zensur-Freiheit (1-10)", 
    "Kontext-Fenster", "Speed (Tokens/s)", "Laufende Kosten", "Gesamt Score (100)"
]

SHEET1_ROWS = [
    ["1. Claude 4.5 Opus", "Cloud (Anthropic)", "👑 Next-Gen Frontier", "System-Design, autonome Multi-File Agenten & Nuancen", 10.0, 9.9, 10.0, 9.9, 3.0, "500k – 1M", "35–50 t/s", "Sehr hoch ($$$$$)", 99],
    ["2. Argon 4", "Cloud (OpenAI/Frontier)", "👑 Next-Gen Reasoning", "Neuartige Proof-Synthese, tiefe CoT-Architektur & Mathe", 9.8, 10.0, 9.6, 9.7, 3.5, "256k – 500k", "40–60 t/s", "Sehr hoch ($$$$)", 98],
    ["3. Gemini 3.8 Pro", "Cloud (Google)", "👑 Hyper-Kontext Multimodal", "2M–5M Hyper-RAG, Audio/Video-Archive & Tool-Calling", 9.7, 9.8, 9.8, 10.0, 4.0, "2.000k–5.000k", "70–110 t/s", "Moderat ($$)", 98],
    ["4. qwen2.5-72b-speed", "Lokal (AMD W7800 48GB)", "👑 Stark (Dense 72B)", "Weltweit bestes Open-Source Coding: Syntax, JSON & Math", 9.8, 9.5, 9.4, 9.2, 7.5, "32k (bis 128k)", "11 t/s (Ollama) / 33,6 t/s (Spekulativ)", "0,00 € (Gratis)", 96],
    ["5. Claude 3.5 / 3.7 Sonnet", "Cloud (Anthropic)", "👑 Stark (Dense)", "Coding, Cline & autonome Software-Agenten", 10.0, 9.5, 9.9, 9.6, 4.0, "200k", "60–80 t/s", "Hoch ($$$)", 98],
    ["6. Claude 3 / 3.5 Opus", "Cloud (Anthropic)", "👑 Stark (Dense)", "Literarische Tiefe, Recht & philosophische Nuancen", 9.3, 9.6, 9.8, 9.8, 3.5, "200k", "30–45 t/s", "Extrem hoch ($$$$$)", 97],
    ["7. OpenAI o1", "Cloud (OpenAI)", "👑 Stark (CoT Reasoning)", "Mathematik, formale Beweise & schwere Algorithmen", 9.4, 10.0, 9.0, 9.2, 3.5, "200k", "20–40 t/s", "Sehr hoch ($$$$)", 96],
    ["8. DeepSeek-R1 (671B)", "Cloud (DeepSeek)", "👑 Stark (MoE 37B aktiv)", "Deep Reasoning, CoT & Logik (Open-Weights)", 9.3, 10.0, 9.2, 9.3, 5.5, "128k", "30–50 t/s", "Sehr günstig ($)", 96],
    ["9. deepseek-r1-70b-speed", "Lokal (AMD W7800 48GB)", "👑 Stark (Dense 70B)", "Deep Reasoning & CoT-Denkketten: o1-mini Niveau lokal", 9.2, 9.9, 9.0, 9.0, 7.0, "32k (bis 128k)", "11 t/s (Ollama) / 14,0 t/s (N-Gram)", "0,00 € (Gratis)", 95],
    ["10. llama3.3-70b-speed", "Lokal (AMD W7800 48GB)", "👑 Stark (Dense 70B)", "Weltklasse Allround-Assistenz, Agenten & Tool-Use", 9.1, 9.2, 9.8, 9.4, 7.5, "32k (bis 128k)", "12 t/s (Ollama) / 25,6 t/s (Spekulativ)", "0,00 € (Gratis)", 95],
    ["10b. llama3.3-70b-abliterated", "Lokal (AMD W7800 48GB)", "👑 Stark (Dense 70B)", "100% Unzensiertes Flaggschiff ohne Guardrails & Refusals", 9.1, 9.2, 9.8, 9.4, 9.9, "32k (bis 128k)", "10 t/s (Ollama) / 30,0 t/s (Spekulativ)", "0,00 € (Gratis)", 95],
    ["11. Gemini 1.5 / 2.0 Pro", "Cloud (Google)", "👑 Stark (MoE / Dense)", "2M Hyper-RAG, Monorepos & Multimodal-Archive", 9.1, 9.3, 9.5, 10.0, 4.0, "2.000k (2M)", "50–70 t/s", "Mittel ($$)", 95],
    ["12. GPT-4o", "Cloud (OpenAI)", "👑 Stark (Dense)", "Omnimodaler Allrounder & Text-Audio-Bild-Konsistenz", 9.2, 8.8, 9.6, 9.3, 4.5, "128k", "80–100 t/s", "Mittel ($$)", 94],
    ["12b. mistral-large-123b", "Lokal (Hybrid W7800)", "👑 Stark (Dense 123B)", "Monumentale 123B Parameter-Masse für tiefste Sprachanalysen", 9.3, 9.4, 9.6, 9.5, 8.0, "16k (bis 128k)", "12–15 t/s (Hybrid)", "0,00 € (Gratis)", 94],
    ["13. Grok 3 / Grok 2", "Cloud (xAI)", "👑 Stark (Dense / MoE)", "Real-Time Webdaten, unzensierter Fun-Mode & Logik", 9.0, 9.2, 9.4, 9.2, 7.5, "128k", "50–70 t/s", "Hoch ($$$)", 94],
    ["13b. qwen3-coder-speed", "Lokal (AMD W7800 48GB)", "⚡ MoE (30.5B / 3.3B aktiv)", "Ultra-Speed Coder für Cline & Roo: 0ms Lag, ~80 t/s!", 9.5, 8.5, 8.8, 9.0, 7.5, "128k–256k", "75,4 – 80,6 t/s (gemessen)", "0,00 € (Gratis)", 94],
    ["13c. qwen3-coder-quality", "Lokal (AMD W7800 48GB)", "👑 Stark (MoE 30.5B, Q8)", "Verlustfreie 8-Bit-Präzision: Compiler, Syntax & Algorithmen", 9.6, 8.5, 8.8, 9.0, 7.5, "32k (bis 128k)", "61,6 t/s (gemessen)", "0,00 € (Gratis)", 93],
    ["14. DeepSeek-V3 (671B)", "Cloud (DeepSeek)", "💰 Günstig (MoE 37B aktiv)", "High-Volume API-Pipelines & Code-Allround", 9.1, 9.0, 9.3, 9.4, 6.0, "128k", "60–90 t/s", "Extrem günstig ($)", 93],
    ["15. Gemini 3.8 Flash", "Cloud (Google)", "💰 Günstig (Multimodal Fast)", "Nativer 1M–2M Multimodal-Speed-Champion & Tool-Calling", 9.0, 9.2, 9.2, 9.8, 4.5, "1.000k–2.000k", "130–150 t/s", "Extrem günstig ($)", 92],
    ["15b. mixtral-8x22b", "Lokal (Hybrid W7800)", "👑 MoE (141B / 39B aktiv)", "MoE Gigant im Hybrid-Modus, flüssiges Weltwissen", 8.9, 9.0, 9.2, 9.0, 7.5, "16k (bis 64k)", "18–22 t/s (Hybrid)", "0,00 € (Gratis)", 92],
    ["16. qwen3-next-80b-16k", "Lokal (AMD W7800 48GB)", "👑 Stark (MoE 10/512)", "Deep Logic, transparente CoT-Denkspuren & Mathe", 8.5, 9.7, 8.8, 8.5, 8.0, "16k (bis 64k)", "36,5 t/s", "0,00 € (Gratis)", 92],
    ["17. OpenAI o3-mini", "Cloud (OpenAI)", "💰 Günstig (CoT Reasoning)", "Kompaktes CoT-Reasoning & wettbewerbsnahes Coding", 9.2, 9.6, 8.6, 8.8, 4.0, "200k", "70–90 t/s", "Günstig ($)", 91],
    ["17b. qwen2.5-coder-32b", "Lokal (AMD W7800 48GB)", "👑 Stark (Dense 32B)", "Bewährter robuster High-Speed Coder mit viel VRAM-Puffer", 9.2, 8.4, 8.6, 8.8, 7.5, "32k (bis 64k)", "55–65 t/s", "0,00 € (Gratis)", 91],
    ["18. Gemini 2.0 Flash-Thinking", "Cloud (Google)", "💰 Günstig (CoT Reasoning)", "Multimodales CoT-Reasoning & Diagramm-Verständnis", 8.6, 9.2, 8.8, 9.5, 4.5, "1.000k (1M)", "80–100 t/s", "Günstig ($)", 89],
    ["18b. mixtral-8x7b", "Lokal (AMD W7800 48GB)", "💰 Günstig (MoE 47B / 13B)", "Schneller MoE Allrounder für lockeren Chat & Breitenwissen", 8.2, 8.0, 9.0, 8.5, 7.5, "32k", "35–45 t/s", "0,00 € (Gratis)", 88],
    ["18c. qwen3.8-35b-distill", "Lokal (AMD W7800 48GB)", "💰 Günstig (MoE 8/256 / Q6)", "Schneller analytischer Co-Pilot & ausgewogenes Reasoning", 8.6, 8.8, 8.8, 8.8, 7.5, "64k (bis 128k)", "64,7 t/s (gemessen)", "0,00 € (Gratis)", 88],
    ["19. Gemini 2.0 Flash", "Cloud (Google)", "💰 Günstig (MoE / Dense)", "Ultraschnelle Workflows (120 t/s), 1M Kontext & API", 8.2, 8.2, 8.6, 9.6, 4.5, "1.000k (1M)", "120 t/s", "Fast kostenlos ($)", 85],
    ["20. qwen3.8-27b-q8", "Lokal (AMD W7800 48GB)", "👑 Stark (Dense 27B Q8)", "Verlustfreie 8-Bit-Präzision, Code & 32k VRAM-Kontext", 8.3, 8.0, 8.5, 9.0, 7.5, "32k (bis 65k)", "52 t/s", "0,00 € (Gratis)", 84],
    ["21. qwen3-obliterated", "Lokal (AMD W7800 48GB)", "👑 Stark (Dense 27B)", "100% Unzensiert: Pentesting, Security & neutrale Fakten", 7.8, 7.5, 8.2, 8.8, 9.6, "49k (bis 65k)", "17,7 t/s (gemessen)", "0,00 € (Gratis)", 83],
    ["22. Grok 2 mini", "Cloud (xAI)", "💰 Günstig (Kompakt)", "Kompakte schnelle Abfragen & ungefilterter Chat", 8.0, 7.8, 8.2, 8.5, 7.0, "128k", "100 t/s", "Günstig ($)", 81],
    ["23. Claude 3.5 Haiku", "Cloud (Anthropic)", "💰 Günstig (Kompakt)", "Kompakte Triage, schnelles Coden & strukturierte Daten", 8.0, 7.4, 8.0, 8.2, 4.0, "200k", "100 t/s", "Günstig ($)", 80],
    ["24. GPT-4o-mini", "Cloud (OpenAI)", "💰 Günstig (Kompakt)", "Standard-Alltagsaufgaben & Low-Cost Automation", 7.8, 7.5, 8.2, 8.2, 4.0, "128k", "100 t/s", "Sehr günstig ($)", 80]
]

# Blatt 2: Frontier Next-Gen vs. Lokal
SHEET2_HEADERS = [
    "Rang & Modell", "Generation & Anbieter", "Architektur / Cluster", 
    "Primärer Fokus / Spezialisierung", "Coding & Cline (1-10)", "Reasoning (1-10)", 
    "Agenten (1-10)", "Kontext-Fenster", "Betrieb & Kosten", "Gesamt Score (100)", 
    "Wann lohnt sich der Sprung im Alltag?"
]

SHEET2_ROWS = [
    ["🪐 GPT-6 / Orion Ultra", "Next-Gen (OpenAI)", "Multi-Cluster Supercomputer", "Autonome AGI-Entwicklung & wissenschaftliche Durchbrüche", 10.0, 10.0, 10.0, "1.000k–5.000k", "Extrem teuer ($$$$$)", 100, "Autonome Entwicklung ganzer Großprojekte ohne Menschen, bahnbrechende Wissenschaft."],
    ["👑 Claude 5.5 Opus", "Next-Gen (Anthropic)", "Next-Gen Frontier MoE", "Perfekte Reflexion, philosophische Nuancen & Code-Design", 10.0, 10.0, 9.9, "500k–1.000k", "Extrem teuer ($$$$$)", 100, "Perfekte philosophische Nuancen, fehlerfreie juristische Analysen, unübertroffenes Code-Design."],
    ["🎭 Claude 4.5 Opus", "Next-Gen (Anthropic)", "Frontier Dense / MoE", "Komplexe Großsystem-Entwicklung, autonome Agenten & Nuancen", 10.0, 9.9, 10.0, "500k–1.000k", "Sehr hoch ($$$$$)", 99, "System-Design, fehlerfreie Multi-File Refactorings & tiefes Textverständnis."],
    ["🧠 Argon 4", "Next-Gen (OpenAI/Frontier)", "Nativ CoT Reasoning", "Neuartige Proof-Synthese, tiefe CoT-Architektur & Algorithmen", 9.8, 10.0, 9.6, "256k–500k", "Sehr hoch ($$$$)", 98, "Höchste mathematische Beweisführung, formale Logik & tiefe Denkketten."],
    ["🌐 Gemini 3.8 Pro", "Next-Gen (Google)", "TPU v5p Mega-MoE", "2M–5M Token Hyper-RAG & multimodale Echtzeit-Workflows", 9.7, 9.8, 9.8, "2.000k–5.000k", "Moderat ($$)", 98, "Gigantische Archive, ganze Repositories oder Stunden an Video/Audio auf einmal."],
    ["🚀 GPT-5 (Orion)", "Next-Gen (OpenAI)", "Nativ CoT + Omnimodal", "Nativ verschmolzenes CoT-Reasoning & selbstkorrigierende Systeme", 9.9, 9.9, 9.8, "500k–1.000k", "Sehr hoch ($$$$)", 99, "Verschmilzt o1-Denktiefe nativ mit der Geschwindigkeit von GPT-4o. Selbstkorrigierender Code."],
    ["🇨🇳 DeepSeek-R2 / R3", "Next-Gen (DeepSeek)", "1T+ Parameter MoE (~50B aktiv)", "Open-Weights Reasoning zu Spottpreisen (1–2 $ / MTok)", 9.6, 9.9, 9.5, "256k", "Günstig ($)", 98, "Bringt GPT-5 Niveau zu Open-Source-Preisen. Der Preis-Leistungs-König der Cloud."],
    ["⚡ Grok 3 (Colossus)", "Flaggschiff (xAI)", "100k+ H100 GPU Cluster", "100k+ GPU Mega-Cluster Weltwissen & Echtzeit-Recherche", 9.5, 9.5, 9.6, "256k", "Hoch ($$$)", 97, "Riesiges Echtzeit-Weltwissen über X/Web, aggressive Logik, minimale Zensurfilter."],
    ["🏆 Claude 3.5 / 3.7 Sonnet", "Aktuelles Flaggschiff (Anthropic)", "Dense", "Der weltbeste Programmierer für VS Code & autonome Agenten", 10.0, 9.5, 9.9, "200k", "Mittel ($$)", 98, "Der aktuelle Best-in-Class Programmierer für VS Code & Cline."],
    ["🧠 OpenAI o1", "Aktuelles Flaggschiff (OpenAI)", "CoT Reasoning", "Schwere mathematische Beweise, Algorithmen & Logikrätsel", 9.4, 9.9, 9.0, "200k", "Sehr hoch ($$$$)", 96, "Komplexe Algorithmen, mathematische Beweise, harte Logikrätsel."],
    ["👑 qwen2.5-72b-speed", "Lokales Top-Modell (W7800)", "100% VRAM (72B Dense)", "Weltweit bestes Open-Source Coding: Syntax & Math (11 t/s Ollama / 33,6 t/s Spekulativ)", 9.8, 9.5, 9.4, "32k (bis 128k)", "0,00 € (Free / Lokal)", 96, "Dein Coding-König: Nahezu auf Sonnet-Niveau, tippt mit bis zu 33,6 t/s spekulativ (0.5B Draft), 100% privat & kostenlos."],
    ["🧠 deepseek-r1-70b-speed", "Lokales Top-Modell (W7800)", "100% VRAM (70B Dense)", "Deep Reasoning & CoT-Denkketten: o1-Niveau lokal (11 t/s Ollama / 14 t/s N-Gram)", 9.2, 9.9, 9.0, "32k (bis 128k)", "0,00 € (Free / Lokal)", 95, "Dein Denk-Meister: Transparente <think>-Kette, löst härteste Mathe- & Logikrätsel."],
    ["🌐 llama3.3-70b-speed", "Lokales Top-Modell (W7800)", "100% VRAM (70B Dense)", "Weltklasse Allround, Tool-Use & Agenten (12 t/s Ollama / 25,6 t/s Spekulativ)", 9.1, 9.2, 9.8, "32k (bis 128k)", "0,00 € (Free / Lokal)", 95, "Dein täglicher Allrounder: Schlägt 90% der Cloud-Anfragen, 0ms Lag, 100% privat, bis zu 25,6 t/s spekulativ."],
    ["🔓 llama3.3-70b-abliterated", "Lokales Top-Modell (W7800)", "100% VRAM (70B Dense)", "Stärkstes unzensiertes Modell ohne Refusals (10 t/s Ollama / 30,0 t/s Spekulativ)", 9.1, 9.2, 9.8, "32k (bis 128k)", "0,00 € (Free / Lokal)", 95, "100% Unzensiert: Pentesting, Exploit-Analysen, freie Recherche, 0 Weigerungen, bis zu 30 t/s spekulativ."],
    ["🐘 Mistral Large (123B)", "Lokales Max-Modell (Hybrid)", "123B Hybrid (GPU+RAM)", "Monumentales 123B Hybrid-Modell für tiefes Textverständnis (12–15 t/s)", 9.3, 9.4, 9.6, "16k (bis 128k)", "0,00 € (Free / Lokal)", 94, "Maximale Modellgröße: 123 Milliarden Parameter lokal, echte GPT-4-Klasse auf deinem System!"],
    ["💻 qwen3-coder-speed", "Lokales Top-Modell (W7800)", "MoE 30.5B (~3.3B aktiv)", "High-Speed Coding für Cline & Roo Code (gemessene 75,4 – 80,6 t/s)", 9.5, 8.5, 8.8, "128k–256k", "0,00 € (Free / Lokal)", 94, "Cline Durchsatz-König: ~80 t/s nativer Durchsatz ohne Draft-Bedarf, sofortiger Code-Fluss, 20 GB VRAM, 0ms Lag!"],
    ["💻 qwen3-coder-quality", "Lokales Top-Modell (W7800)", "MoE 30.5B (~3.3B aktiv, Q8)", "Verlustfreie 8-Bit-Präzision & formale Code-Syntax (gemessene 61,6 t/s)", 9.6, 8.5, 8.8, "32k (bis 128k)", "0,00 € (Free / Lokal)", 93, "Verlustfreier Code-Präzisions-König: 99,9% FP16, keine Rundungsfehler bei Syntax & Compilerbau."],
    ["🔀 mixtral-8x22b", "Lokales Max-Modell (Hybrid)", "MoE 141B (~39B aktiv)", "141B MoE Gigant im Hybrid-Modus, flüssiges Weltwissen (~20 t/s)", 8.9, 9.0, 9.2, "16k (bis 64k)", "0,00 € (Free / Lokal)", 92, "MoE-Schwergewicht: Riesige Parameter-Basis bei flüssigem Vorwärtsschritt."],
    ["⚡ qwen3-next-80b-16k", "Lokales Top-Modell (W7800)", "80B MoE (10/512 aktiv)", "Deep Logic, transparente CoT-Denkspuren & Mathe (36,5 t/s)", 8.5, 9.7, 8.8, "16k (bis 64k)", "0,00 € (Free / Lokal)", 92, "Dein lokales Denkmodell: Reicht an 92% von OpenAI o1 heran, transparente <think>-Kette."],
    ["⚡ Gemini 3.8 Flash", "Next-Gen (Google)", "TPU v5e Native Multimodal", "Ultra-Low-Latency Tool-Calling & 1M-2M Multimodal-Streaming", 9.0, 9.2, 9.2, "1.000k–2.000k", "Fast kostenlos ($)", 92, "Ultraschnelle API-Agenten, 150 t/s, Live-Video/Audio und Millionen Kontext zu Spottpreisen."],
    ["💻 qwen2.5-coder-32b", "Lokales Top-Modell (W7800)", "100% VRAM (32B Dense)", "Bewährter Dense High-Speed Coder mit viel VRAM-Puffer (55–65 t/s)", 9.2, 8.4, 8.6, "32k (bis 64k)", "0,00 € (Free / Lokal)", 91, "Klassischer Coder: Extrem solide Syntax, 24 GB freier VRAM für lange Sitzungen."],
    ["⚡ qwen3.8-35b-distill", "Lokales Top-Modell (W7800)", "100% VRAM (35B Dense Q6)", "Alltags-Sweet-Spot für W7800: Schnell (gemessene 64,7 t/s) & 64k Kontext", 8.6, 8.8, 8.8, "64k (bis 128k)", "0,00 € (Free / Lokal)", 88, "Bester Alltags-Allrounder: Gemessene 64.7 t/s, sofort flüssige Antworten."],
    ["🔀 mixtral-8x7b", "Lokales Top-Modell (W7800)", "100% VRAM (MoE 47B/13B)", "Schneller MoE Allrounder für lockeren Chat (~35–45 t/s)", 8.2, 8.0, 9.0, "32k", "0,00 € (Free / Lokal)", 88, "Flüssiger MoE Chat: Breites Allgemeinwissen, niedrige Latenz."],
    ["🚀 qwen3.8-27b-q8", "Lokales Top-Modell (W7800)", "100% VRAM (27B Dense Q8)", "Verlustfreie 8-Bit-Präzision, Code & 32k VRAM-Kontext (52 t/s)", 8.3, 8.0, 8.5, "32k (bis 65k)", "0,00 € (Free / Lokal)", 84, "Verlustfreier Präzisions-Champion: 99,9% FP16-Qualität, ~52 t/s, 14 GB VRAM frei für 32k Kontext!"]
]

# Blatt 3: Qwen Coder Deep-Dive
SHEET3_HEADERS = [
    "Modell-Name", "Architektur", "Quantisierung", "Größe auf SSD / VRAM", 
    "Freier VRAM auf W7800 (48GB)", "Max. VRAM-Kontext", "Reale Speed (W7800)", 
    "Coding Score (1-10)", "Gesamt Score (100)", "Empfohlener Einsatzzweck"
]

SHEET3_ROWS = [
    ["qwen2.5-72b-speed", "Dense (72.7B aktiv)", "IQ4_XS", "~39,7 GB", "~4,5 GB frei", "32k (bis 128k)", "9,1–12,0 t/s (Ollama) / 33,6 t/s (Spekulativ)", 9.8, 96, "Der absolute Qualitäts-König: 33,6 t/s mit 0.5B Draft (3,7x Speedup!), 97% Draft-Trefferquote."],
    ["qwen3-coder-quality", "MoE (30.5B / ~3.3B aktiv)", "Q8_0", "~32,0 GB", "~14,5 GB frei", "32k stabil", "61,6 t/s (gemessen)", 9.6, 93, "Verlustfreie 8-Bit-Präzision für Compilerbau, formale Syntax & wissenschaftliche Algorithmen."],
    ["qwen3-coder-speed", "MoE (30.5B / ~3.3B aktiv)", "Q4_K_M", "~18,5 GB", "~27,4 GB frei (Riesig)", "128k+ nativ im VRAM", "75,4–80,6 t/s (gemessen)", 9.5, 94, "Der Durchsatz-König: Cline, Roo Code & VS Code. 0ms Lag, tippt doppelt so schnell, schluckt ganze Codebasen."],
    ["qwen2.5-coder-32b", "Dense (32.5B aktiv)", "Q4_K_M", "~19,5 GB", "~24,5 GB frei", "32k (bis 64k)", "55–65 t/s", 9.2, 91, "Klassischer Coder der 2.5-Generation: Extrem solide Syntax, kompakter VRAM-Bedarf für Offline-Entwicklung."]
]

# Blatt 4: Cloud-Modelle Kosten & Kategorien
SHEET4_HEADERS = [
    "Anbieter", "Modell", "Kategorie", "Stärke / Profil", 
    "Input-Preis ($ pro 1M)", "Output-Preis ($ pro 1M)"
]

SHEET4_ROWS = [
    ["Anthropic", "Claude 4.5 Opus", "👑 Einfach nur stark", "Zenit für holistisches System-Design, autonome Agenten-Ketten & philosophische Nuancen", 20.00, 100.00],
    ["Anthropic", "Claude 3.5 / 3.7 Sonnet", "👑 Einfach nur stark", "Weltweiter Goldstandard für Coding, Cline & autonome Software-Agenten", 3.00, 15.00],
    ["Anthropic", "Claude 3 / 3.5 Opus", "👑 Einfach nur stark", "Monumentale literarische Tiefe, strategisches Denken, komplexe Nuancen", 15.00, 75.00],
    ["Anthropic", "Claude 3.5 Haiku", "💰 Recht wenig Kosten", "Blitzschneller kompakter Coder, ideal für Triage und kurze Prompts", 0.80, 4.00],
    ["OpenAI / Frontier", "Argon 4", "👑 Einfach nur stark", "Next-Gen Reasoning-Engine, Proof-Synthese & tiefes autonomes CoT-Design", 15.00, 60.00],
    ["OpenAI", "OpenAI o1", "👑 Einfach nur stark", "State-of-the-Art Chain-of-Thought (CoT) Reasoning, Mathematik & schwere Algorithmen", 15.00, 60.00],
    ["OpenAI", "OpenAI o3-mini", "💰 Recht wenig Kosten", "Kompaktes CoT-Reasoning & wettbewerbsnahes Coding zum Spottpreis", 1.10, 4.40],
    ["OpenAI", "GPT-4o", "👑 Einfach nur stark", "Omnimodaler Weltklasse-Allrounder, extrem konsistent in Sprache und Tool-Calls", 2.50, 10.00],
    ["OpenAI", "GPT-4o-mini", "💰 Recht wenig Kosten", "Der Standard-Preishammer: Sehr schnell, meistert 80% aller Alltagsaufgaben", 0.15, 0.60],
    ["DeepSeek", "DeepSeek-R1 (Full 671B MoE)", "👑 Einfach nur stark", "Open-Weights Flaggschiff (37B aktiv), schlägt OpenAI o1 in Mathe & algorithmischer Logik", 0.55, 2.19],
    ["DeepSeek", "DeepSeek-V3 (Full 671B MoE)", "💰 Recht wenig Kosten", "Schlägt GPT-4o in vielen Benchmarks bei einem Bruchteil der Kosten. Extrem preiswert!", 0.14, 0.28],
    ["xAI", "Grok 3 / Grok 2", "👑 Einfach nur stark", "Elon Musks gigantisches Rechenmonster, stark in Echtzeit-Daten, Logik und weniger gefiltert", 3.00, 15.00],
    ["xAI", "Grok 2 mini", "💰 Recht wenig Kosten", "Schnelle, ressourceneffiziente Version für kompakte Abfragen und Chats", 0.20, 1.00],
    ["Google", "Gemini 3.8 Pro", "👑 Einfach nur stark", "2M–5M Hyper-Kontext, native Multimodalität & Echtzeit-Tool-Calling", 1.50, 6.00],
    ["Google", "Gemini 3.8 Flash", "💰 Recht wenig Kosten", "Multimodaler High-Speed Champion (~130–150 t/s), 1M–2M Kontext & exzellentes Tool-Calling", 0.15, 0.60],
    ["Google", "Gemini 2.0 Flash / Flash-Thinking", "💰 Recht wenig Kosten", "Bis zu 1M Kontext, ultraschnell, exzellente Multimodalität, oft fast kostenlos", 0.10, 0.40],
    ["Google", "Gemini 1.5 / 2.0 Pro", "👑 Einfach nur stark", "Gigantischer 2M-Token-Kontext, Weltklasse in riesigen Codebase- und PDF-Analysen", 1.25, 5.00]
]

# ------------------------------------------------------------------------------
# 2. ODS XML-Generierung (OpenDocument Spreadsheet Standard 1.2)
# ------------------------------------------------------------------------------

def make_cell(value, is_local=False):
    if isinstance(value, (int, float)):
        style = "NumberCellLocal" if is_local else "NumberCell"
        return f'<table:table-cell office:value-type="float" office:value="{value}" table:style-name="{style}"><text:p>{value}</text:p></table:table-cell>'
    else:
        text = escape_xml(value)
        style = "TextCellLocal" if is_local else "TextCell"
        return f'<table:table-cell office:value-type="string" table:style-name="{style}"><text:p>{text}</text:p></table:table-cell>'

def make_header_cell(title):
    return f'<table:table-cell office:value-type="string" table:style-name="HeaderCell"><text:p>{escape_xml(title)}</text:p></table:table-cell>'

def make_table(sheet_name, headers, rows):
    out = [f'<table:table table:name="{escape_xml(sheet_name)}">']
    
    # Spalten-Definitionen
    for _ in headers:
        out.append('<table:table-column table:style-name="co1" table:default-cell-style-name="Default"/>')
    
    # Kopfzeile
    out.append('<table:table-header-rows>')
    out.append('<table:table-row table:style-name="ro_header">')
    for h in headers:
        out.append(make_header_cell(h))
    out.append('</table:table-row>')
    out.append('</table:table-header-rows>')
    
    # Datenzeilen
    for row in rows:
        # Prüfen ob lokale W7800 GPU für Hervorhebung
        is_local = any("Lokal" in str(c) or "W7800" in str(c) for c in row)
        row_style = "ro_local" if is_local else "ro_data"
        out.append(f'<table:table-row table:style-name="{row_style}">')
        for cell in row:
            out.append(make_cell(cell, is_local=is_local))
        out.append('</table:table-row>')
        
    out.append('</table:table>')
    return "".join(out)

CONTENT_XML = f"""<?xml version="1.0" encoding="UTF-8"?>
<office:document-content 
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" 
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" 
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" 
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" 
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" 
  office:version="1.2">
  <office:automatic-styles>
    <style:style style:name="co1" style:family="table-column">
      <style:table-column-properties style:column-width="3.5cm" fo:break-before="auto"/>
    </style:style>
    <style:style style:name="ro_header" style:family="table-row">
      <style:table-row-properties style:row-height="0.8cm" fo:break-before="auto"/>
    </style:style>
    <style:style style:name="ro_data" style:family="table-row">
      <style:table-row-properties fo:break-before="auto"/>
    </style:style>
    <style:style style:name="ro_local" style:family="table-row">
      <style:table-row-properties fo:break-before="auto"/>
    </style:style>
    
    <!-- Header Style: Dunkelblau, Weißer Text, Fett, Zentriert -->
    <style:style style:name="HeaderCell" style:family="table-cell">
      <style:table-cell-properties fo:background-color="#1E3A8A" fo:padding="0.15cm" fo:border="0.05pt solid #FFFFFF"/>
      <style:text-properties fo:color="#FFFFFF" fo:font-weight="bold" fo:font-size="10pt"/>
    </style:style>
    
    <!-- Standard Zelle Text -->
    <style:style style:name="TextCell" style:family="table-cell">
      <style:table-cell-properties fo:padding="0.12cm" fo:border="0.05pt solid #CBD5E1"/>
      <style:text-properties fo:color="#0F172A" fo:font-size="9.5pt"/>
    </style:style>
    
    <!-- Standard Zelle Zahl -->
    <style:style style:name="NumberCell" style:family="table-cell">
      <style:table-cell-properties fo:padding="0.12cm" fo:border="0.05pt solid #CBD5E1"/>
      <style:paragraph-properties fo:text-align="center"/>
      <style:text-properties fo:color="#0F172A" fo:font-size="9.5pt"/>
    </style:style>
    
    <!-- Lokales Modell Text (Dezenter Mint-Grün Hintergrund) -->
    <style:style style:name="TextCellLocal" style:family="table-cell">
      <style:table-cell-properties fo:background-color="#F0FDF4" fo:padding="0.12cm" fo:border="0.05pt solid #86EFAC"/>
      <style:text-properties fo:color="#14532D" fo:font-weight="bold" fo:font-size="9.5pt"/>
    </style:style>
    
    <!-- Lokales Modell Zahl -->
    <style:style style:name="NumberCellLocal" style:family="table-cell">
      <style:table-cell-properties fo:background-color="#F0FDF4" fo:padding="0.12cm" fo:border="0.05pt solid #86EFAC"/>
      <style:paragraph-properties fo:text-align="center"/>
      <style:text-properties fo:color="#14532D" fo:font-weight="bold" fo:font-size="9.5pt"/>
    </style:style>
  </office:automatic-styles>
  
  <office:body>
    <office:spreadsheet>
      {make_table("1_Gesamtranking_Alle_Modelle", SHEET1_HEADERS, SHEET1_ROWS)}
      {make_table("2_Frontier_vs_Lokal", SHEET2_HEADERS, SHEET2_ROWS)}
      {make_table("3_Qwen_Coder_Vergleich", SHEET3_HEADERS, SHEET3_ROWS)}
      {make_table("4_Cloud_Preise_und_Kosten", SHEET4_HEADERS, SHEET4_ROWS)}
    </office:spreadsheet>
  </office:body>
</office:document-content>
"""

STYLES_XML = """<?xml version="1.0" encoding="UTF-8"?>
<office:document-styles 
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" 
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" 
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" 
  office:version="1.2">
  <office:styles>
    <style:default-style style:family="table-cell">
      <style:paragraph-properties fo:hyphenate="false"/>
      <style:text-properties fo:color="#000000" fo:font-family="Liberation Sans, Arial, sans-serif" fo:font-size="10pt"/>
    </style:default-style>
  </office:styles>
</office:document-styles>
"""

META_XML = """<?xml version="1.0" encoding="UTF-8"?>
<office:document-meta 
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" 
  xmlns:dc="http://purl.org/dc/elements/1.1/" 
  office:version="1.2">
  <office:meta>
    <dc:title>LLM Vergleichsmatrix: Lokale Top-Modelle vs. Cloud-Giganten</dc:title>
    <dc:creator>Antigravity AI</dc:creator>
    <dc:description>Umfassende Vergleichstabelle aller lokalen Modelle auf AMD Radeon PRO W7800 48GB vs. Cloud-Modelle (OpenAI, Anthropic, Google, DeepSeek, xAI)</dc:description>
  </office:meta>
</office:document-meta>
"""

MANIFEST_XML = """<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.2">
 <manifest:file-entry manifest:full-path="/" manifest:version="1.2" manifest:media-type="application/vnd.oasis.opendocument.spreadsheet"/>
 <manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>
 <manifest:file-entry manifest:full-path="styles.xml" manifest:media-type="text/xml"/>
 <manifest:file-entry manifest:full-path="meta.xml" manifest:media-type="text/xml"/>
</manifest:manifest>
"""

def build_ods(output_path):
    print(f"* Baue native OpenDocument-Tabelle (.ods): {output_path}...")
    with zipfile.ZipFile(output_path, 'w') as z:
        # mimetype MUSS unkomprimiert als erste Datei im ZIP liegen!
        z.writestr('mimetype', 'application/vnd.oasis.opendocument.spreadsheet', compress_type=zipfile.ZIP_STORED)
        z.writestr('META-INF/manifest.xml', MANIFEST_XML.encode('utf-8'), compress_type=zipfile.ZIP_DEFLATED)
        z.writestr('content.xml', CONTENT_XML.encode('utf-8'), compress_type=zipfile.ZIP_DEFLATED)
        z.writestr('styles.xml', STYLES_XML.encode('utf-8'), compress_type=zipfile.ZIP_DEFLATED)
        z.writestr('meta.xml', META_XML.encode('utf-8'), compress_type=zipfile.ZIP_DEFLATED)
    print(f"  ✅ ODS erfolgreich erstellt ({os.path.getsize(output_path):,} Bytes).")

def build_csv(output_path, headers, rows):
    import csv
    print(f"* Erstelle CSV-Export: {output_path}...")
    with open(output_path, 'w', newline='', encoding='utf-8-sig') as f:
        writer = csv.writer(f, delimiter=';', quoting=csv.QUOTE_MINIMAL)
        writer.writerow(headers)
        for r in rows:
            writer.writerow(r)
    print(f"  ✅ CSV erfolgreich erstellt ({os.path.getsize(output_path):,} Bytes).")

def main():
    base_dir = "/home/clemi/Projekte/LLM"
    docs_dir = os.path.join(base_dir, "docs")
    
    ods_path_main = os.path.join(base_dir, "vergleichsmatrix_lokal_vs_cloud.ods")
    ods_path_docs = os.path.join(docs_dir, "vergleichsmatrix_lokal_vs_cloud.ods")
    
    csv_path_all = os.path.join(docs_dir, "vergleichsmatrix_alle_modelle.csv")
    csv_path_qwen = os.path.join(docs_dir, "vergleichsmatrix_qwen_coder.csv")

    build_ods(ods_path_main)
    
    # Symlink oder Kopie in docs/
    if os.path.exists(ods_path_docs):
        os.remove(ods_path_docs)
    os.link(ods_path_main, ods_path_docs)
    print(f"  ✅ Hardlink in {ods_path_docs} angelegt.")

    build_csv(csv_path_all, SHEET1_HEADERS, SHEET1_ROWS)
    build_csv(csv_path_qwen, SHEET3_HEADERS, SHEET3_ROWS)

    print("\n🎉 Fertig! Die Tabelle kann jetzt direkt in LibreOffice Calc geöffnet und editiert werden:")
    print(f"   localc {ods_path_main} &")

if __name__ == '__main__':
    main()

