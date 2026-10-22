# LUDESTA - Luxus Development Stack

<table><tr><td align=right><img src="https://lh3.googleusercontent.com/d/1qn2q-d_y_NP3lxD8gzCh7vnRi_qImnvd" width=1000><font size=-2><br>for agents, for humans, for the whole damned world<a href=https://suno.com/playlist/dea7acde-5886-407a-8193-db889a2af569>...</a></td></tr></table>




Wiederverwendbare Agent-Skills für einen komfortablen, konsistenten Entwicklungsworkflow.

Das *luxuriös* steht für die Verwendung komfortabler Mechanismen und Werkzeuge im Entwicklungsprozess. Die Idee ist, einem Agenten (Skill + Harness) eine umfangreiche, komfortable Projektstruktur vorzugeben und ihn anzuleiten, diese effektiv einzusetzen. Automatismen in der CI/CD erhöhen die Stabilität der agentischen Arbeit.

> **⚠️ Im Moment gibt es nur den Luxus-Python-Stack**

## Komponenten

Ein **Luxus Stack** (z.B. Python) befindet sich im **gleichnamigen Folder** (*Luxus-&lt;domain>-Stack/*) und besteht aus der **Dokumentation** (*Luxus-&lt;domain>-Stack.md, Stack-Setup.md*), dem **Skill** (*&lt;skill-folder>/*), dem **Stack-Script** (*&lt;stack-script>.sh*) mit der Stack-Init-Funktion und den **Templates** (*templates/*) für das Init.

```shell
Luxus-Stack  
├── Stack-Dokumentation - Beschreibt das Arbeiten mit dem Stack
│   ├── Setup-Anleitung der benötigten Software
│   ├── Beschreibung der Verwendung von dem Stack-Init
│   ├── Beschreibung der Anpassung des generierten Projektgerüstes
│   └── Beschreibung des Aufbaus des Skills
├── Stack-Skill  - Beschreibt das Arbeiten in einem Projekt
│   ├── Beschreibungen von Standard Workflows
│   ├── Rezepte zur Verwendung des Stacks
│   ├── Beschreibung der Verwendung von Tools
│   └── Anleitung zur Pflege von Dokumenten
├── Stack-Skripte - Beinhaltet die Stack-Init-Funktion und beliebige andere Stack-Funktionen
│   ├── Stack-Init generiert das vorkonfigurierte Projektgerüst
│   ├── Stackspezifische Funktionen (z.b. jupyter-launcher)
│   ├── Funktionen zur Systemintegration (z.b. zsh-prompt)
│   └── Hilfsfunktionen, Einrichtungsunterstützung, Aliase
├── Stack-Templates - Vorlagen für das generierte Projektgerüst
│   ├── Vorlage AGENTS.md - wird vom Init verwendet
│   └── scripts/design_report.py - 
```

* Das Init ist hochgradig stackabhängig. Lediglich Grundanforderungen sind daran gestellt:
   > 1. es muss ein '--help' vorhanden sein mit einer ausführlichen beschreibung.
   > 2. durch aufruf ohne einen parameter wird in dem aktuellen folder eine default projektstruktur angelegt.
   > 3. das Init informiert darüber, was es getan hat und welche Schritte noch vom Anwender zu erledigen sind.


## Verwendung

### Projekt anlegen mit Stack Init

Das Herz des Stacks ist das Stack-Init. Es ist ein Script das ein vorkonfiguriertes Projektgerüst erzeugt und es wird vom Benutzer des Stacks verwendet. Dem Agenten-Skill ist das Script unbekannt, er weiß nicht, ob es sich um eine vorgefertigte Schablone handelt oder ein individuell angelegtes Projekt.

* Es wird ein neuer Folder mit dem Projektnamen angelegt, 
* da hinein wechseln
* das Stackinit-Kommando ausführen.

### Projekt individualisieren

Der Agent-Skill beschreibt im vollen Umfang das Arbeiten mit allen unterstützten Arbeitsweisen, basierend auf dem Stack-Init. Dafür ist er modular aufgebaut und lädt komplexe Rezepte nur bei Bedarf.

Die `AGENTS.md` enthält das Projektprofil, die **ADR**-Konventionen und die Attention Points. **Attention Points** sind projektbezogene Stolpersteine und Eigenheiten, die Agent und Nutzer gemeinsam pflegen; ADRs halten Architekturentscheidungen in `docs/adr/` fest.


## Installation

1. ⚠️ Empfohlen: VM aufsetzen 
   > Probiere es erstmal in einer VM aus bevor du einen Agenten anweißt es in dein System einzubauen oder du das selbst machst.

2. Repository klonen:
   ```shell
   sudo apt update && sudo apt update -y && sudo apt install -y git
   mkdir -p ~/gits
   git clone https://github.com/frankausberlin/ludesta ~/gits/ludesta
   ```
3. Die [Setup-Anleitung](Luxus-Python-Stack/Stack-Setup.md) befolgen.

## Die Luxus Stacks

### Luxus Python Stack

Das [Stack-Dokument](Luxus-Python-Stack/Luxus-Python-Stack.md) befindet sich im Stackfolder. Zum Appetit machen hier einige Highlights:

* Alles wird zusammengehalten von einem **5-stufigen Konzept** mit klaren Zuständigkeiten, um immer den Überblick über *dein* Python zu haben.
* Du hast eine komplette **CI/CD** basierend auf **Github Actions** und **Bump-my-version**.
* Die Sicherung der **Codequalität** wird durch die Verwendung moderner Tools erreicht: **Ruff, Basedpyright, Pytest, Coverage**.
* Ein echter **Stabilitätsbooster** ist das **dreistufige Testkonzept** mit automatischen **Unittests**; **e2e-tests** und **e2e-agent-tests** (mit autonom arbeitenden **Testagenten**) sind vorgesehen, nicht Teil der Basisversion.
* **Projektdokumentation** mit MkDocs und **Diátaxis-Gerüst** (Bibliothek) oder generierter CLI-Referenz; **ADRs** (Architectural Decision Records).
* Bewertung der **Codestruktur** mit **just rate-design** dient dem Skill mit seinem **Refactoring-Rezept** Vorschläge zur Codeverbesserung zu machen und **diese dann umzusetzen**.
* Auch **Agenten** bekommen Unterstützung mit **AGENTS.md** und **JOURNAL.md** und ihrem **Agenten-Skill**.
* Das **Sahnehäubchen** ist dann noch eine **DataScience Umgebung** mit **Jupyter und Colab**.


