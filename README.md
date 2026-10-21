# LUDESTA - Luxus Development Stack

Wiederverwendbare Agent-Skills für einen komfortablen, konsistenten Entwicklungsworkflow.

Das *luxoriös* steht für die verwendung komfortabler Mechanismen und Werkzeuge im Entwicklungsprozess. Die Idee ist, einem Agenten (Skill + Harness) eine umfangreiche, komfortable Projektstruktur vorzugeben und ihn anzuleiten, diese effektiv einzusetzen. Automatismen in der CI/CD erhöhen die Stabilität der agentischen Arbeit.

> **⚠️ Im Moment gibt es nur den Luxus-Python-Stack**

## Komponenten

Ein **Luxus Stack** (z.b. Python) befindet sich im **gleichnamigen Folder** (*Luxus-&lt;domain>-Stack/*) und besteht aus der **Dokumentation** (*Luxus-&lt;domain>-Stack.md, Stack-Setup.md*), dem **Skill** (*&lt;skill-folder>/*) und dem **Stack-Script** (&lt;stack-script>.sh) mit der Stack-Init-Funktion.



```shell
Luxus-Stack  
├── Stack-Dokumentation - Beschreibt das Arbeiten mit dem Stack
│   ├── Setupanleitung der benötigten Software
│   ├── Beschreibung der Verwendung von dem Stack-Init
│   ├── Beschreibung der Anpassung des generierten Projektgerüstes
│   └── Beschreibung des Aufbau des Skills
├── Stack-Skill  - Beschreibt das Arbeiten in einem Projekt
│   ├── Beschreibungen von Standard Workflows
│   ├── Rezepte zur Verwendung des Stacks
│   ├── Beschreibung der Verwendung von Tools
│   └── Anleitung zur Pflege von Dokumenten
├── Stack-Scripte - Beinhaltet die Stack-Init-Funktion und beliebige andere Stack-Funktionen
│   ├── Stack-Init generiert das vorkonfigurierte Projektgerüst
│   ├── Stackspezifische Funktionen (z.b. jupyter-launcher)
│   ├── Funktionen zur Systemintegration (z.b. zsh-prompt)
│   └── Hilfsfunktionen, Einrichtungsunterstützung, Aliase
```

* Das Init ist hochgradig stackabhängig. Lediglich Grundanforderungen sind daran gestellt:
   > 1. es muss ein '--help' vorhanden sein mit einer ausführlichen beschreibung.
   > 2. durch aufruf ohne einen parameter wird in dem aktuellen folder eine default projektstruktur angelet.
   > 3. das Init informiert darüber, was es getan hat.


## Verwendung

### Projekt anlegen mit Stack Init

Das Herz des Stacks ist das Stack-Init. Es ist ein Script das ein vorkonfiguriertes Projektgerüst erzeugt und es wird vom Benutzer des Stacks verwendet. Dem Agenten-Skill ist das Script unbekannt, er weiß nicht, ob es sich um eine vorgefertigte Schablone handelt oder ein individuell angelegtes Projekt.

* Es wird ein neuer Folder mit dem Projektnamen angelegt, 
* da hinein wechseln
* das Stackinit-Kommndo ausführen.

### Projekt individualiesieren

Der Agent-Skill beschreibt im vollen Umfang das Arbeiten mit allen unterstützten Features, basierende auf dem Stack-Init. Dafür ist er modular aufgebaut und lädt komplexe Rezepte nur bei Bedarf.

In der AGENTS.md befindet sich in der generierten version eine kurze Anleitung wie die AGENTS.md individuell an das Projekt angepasst werden kann.



## Installation

1. ⚠️ Empfohlen: VM aufsetzen 
   > Probiere es erstmal in einer VM aus bevor du einen Agenten anweißt es in dein System einzubauen oder du das selbst machst.

2. Repository klonen:
   ```shell
   mkdir -p ~/gits
   git clone https://github.com/frankausberlin/ludesta ~/gits/ludesta
   ```
3. Stack-Setup befolgen.

## Die Luxus Stacks

### Luxus Python Stack

Das [Stack-Dokument](Luxus-Python-Stack/Luxus-Python-Stack.md) befindet sich im Stackfolder. Zum Appetit machen hier einige Highlights:

* Alles wird zusammengehalten von einem **5-Stuffigen Konezpt** mit klaren Zuständigkeiten, um immer den Überblick über *dein* Python zu haben.
* Du hast eine komplette **CI/CD** basierend auf **Github Actions** und **Bump-my-version**.
* Die Sichererung der **Codequalität** wird durch die Verwendung moderner Tools erreicht: **Ruff, Basedpyright, Pytest, Coverage**.
* Ein echter **Stabilitätsbooster** ist das **dreistuffiges Testkonzept** mit automatischen **Unittests** und auf Abruf **e2e-tests** und **e2e-agent-tests** (mit autonom arbeitenden **Testagenten**). 
* Bewertung der **Codestruktur** mit **just rate-design** dient dem Skill mit seinem **Refactoring-Rezept** Vorschläge für ein Refactoring zu machen und **dieses dann umzusetzen**.
* Auch **Agenten** bekommen Unterstützung mit **AGENTS.md** und **JOURNAL.md** und ihrem **Agenten-Skill**.
* Das **Sahnehäubchen** ist dann noch eine **DataScience Umgebung** mit **Jupyter und Colab**.


