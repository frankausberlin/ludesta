# LUDESTA - Luxus Development Stack

<table><tr><td align=right><img src="https://lh3.googleusercontent.com/d/1qn2q-d_y_NP3lxD8gzCh7vnRi_qImnvd" width=1000><font size=-2><br><a href=https://suno.com/album/db368c0a-9a4d-484e-9ea6-6725b85b135a>&nbsp;</a></td></tr></table>


*Das Hogwarts für Coding Agents*

Das *luxuriös* steht für die Verwendung komfortabler Mechanismen und Werkzeuge im Entwicklungsprozess. Die Idee ist, einem Agenten (Skill + Harness + llm) eine umfangreiche, komfortable Projektstruktur vorzugeben und ihn anzuleiten, diese effektiv einzusetzen. Automatismen in der CI/CD erhöhen die Stabilität der agentischen Arbeit.

> **⚠️ Im Moment gibt es nur den Luxus-Python-Stack**

## Komponenten

Ein **Luxus Stack** (z.B. Python) befindet sich im **gleichnamigen Folder** (*Luxus-&lt;domain>-Stack/*) und besteht aus der **Dokumentation** (*Luxus-&lt;domain>-Stack.md, Stack-Setup.md*), dem **Skill** (*&lt;skill-folder>/*) und den **Stack-Skripten** (*&lt;stack-script>.sh*) mit den Stack-Funktionen.

Das Projektgerüst erzeugt **pyinit**, ein eigenständiges Tool mit eigenem Repository (`~/gits/pyinit`). ludesta dokumentiert Installation und Verwendung, bettet den Generator aber nicht ein.

```shell
Luxus-Stack  
├── Stack-Dokumentation - Beschreibt das Arbeiten mit dem Stack
│   ├── Setup-Anleitung der benötigten Software
│   ├── Beschreibung der Verwendung des Projekt-Init
│   ├── Beschreibung der Anpassung des generierten Projektgerüstes
│   └── Beschreibung des Aufbaus des Skills
├── Stack-Skill  - Beschreibt das Arbeiten in einem Projekt
│   ├── Beschreibungen von Standard Workflows
│   ├── Rezepte zur Verwendung des Stacks
│   ├── Beschreibung der Verwendung von Tools
│   └── Anleitung zur Pflege von Dokumenten
└── Stack-Skripte - Beinhaltet die Shell-Funktionen des Stacks
    ├── Stackspezifische Funktionen (z.b. jupyter-launcher)
    ├── Funktionen zur Systemintegration (z.b. zsh-prompt)
    └── Hilfsfunktionen, Einrichtungsunterstützung, Aliase
```

Das Projekt-Init selbst ist stackabhängig und liegt außerhalb dieses Repos. Lediglich Grundanforderungen sind daran gestellt:
   > 1. es muss ein '--help' vorhanden sein mit einer ausführlichen beschreibung.
   > 2. `new <profil>` ohne verzeichnis legt im aktuellen folder eine default projektstruktur an.
   > 3. das Init informiert darüber, was es getan hat und welche Schritte noch vom Anwender zu erledigen sind.


## Verwendung

### Projekt anlegen mit pyinit

Das Herz des Stacks ist das Projekt-Init `pyinit`. Es erzeugt ein vorkonfiguriertes Projektgerüst aus einem Profil. Dem Agenten-Skill ist das Tool unbekannt, er weiß nicht, ob es sich um eine vorgefertigte Schablone handelt oder ein individuell angelegtes Projekt.

```shell
pyinit list                       # Profile anzeigen: app, app-cli, lib, mcp
pyinit describe app-cli           # Profil oder Artefakt im Detail
pyinit new app my-project         # Anwendung im neuen Ordner my-project
pyinit new lib my-lib             # Bibliothek mit MkDocs
pyinit new mcp arithmetic-mcp     # Anwendung mit MCP-Server
pyinit new app-cli .              # im aktuellen Ordner anlegen
```

Ohne Verzeichnis legt `new <profil>` im aktuellen Ordner an; das Ziel muss fehlen, leer sein oder nur `.git` enthalten. `pyinit` erzeugt nur neue Projekte und aktualisiert keine bestehenden.

### Projekt individualisieren

Der Agent-Skill beschreibt im vollen Umfang das Arbeiten mit allen unterstützten Arbeitsweisen, basierend auf dem Stack-Init. Dafür ist er modular aufgebaut und lädt komplexe Rezepte nur bei Bedarf.

Die `AGENTS.md` enthält das Projektprofil, die **ADR**-Konventionen und die Attention Points. **Attention Points** sind projektbezogene Stolpersteine und Eigenheiten, die Agent und Nutzer gemeinsam pflegen; ADRs halten Architekturentscheidungen in `docs/adr/` fest.


## Installation

1. ⚠️ Dringend Empfohlen: VM aufsetzen 
   > Probiere es erstmal in einer VM aus bevor du einen Agenten anweißt es in dein System einzubauen oder du das selbst machst.

2. In der VM eine bash öffnen und die [Setup-Anleitung für das Basis-System](Setup.md) befolgen.
3. Danach den stack-spezifischen Teil der [Python-Stack-Einrichtung](Luxus-Python-Stack/Stack-Setup.md) befolgen. Er klont `pyinit` aus `https://github.com/frankausberlin/pyinit` und installiert es mit `uv tool install --editable`.


## Die Luxus Stacks

### Luxus Python Stack

Das [Stack-Dokument](Luxus-Python-Stack/Luxus-Python-Stack.md) befindet sich im Stackfolder. Zum Appetit machen hier einige Highlights:

* Alles wird zusammengehalten von einem **5-stufigen Konzept** mit klaren Zuständigkeiten, um immer den Überblick über *dein* Python zu haben.
* Du hast eine komplette **CI/CD** basierend auf **Github Actions** und **Bump-my-version**.
* Die Sicherung der **Codequalität** wird durch die Verwendung moderner Tools erreicht: **Ruff, Basedpyright, Pytest, Coverage, Vulture**.
* Ein echter **Stabilitätsbooster** ist das **dreistufige Testkonzept**: automatische **Unittests** als Gate; **e2e-tests** und **e2e-agent-tests** werden als Gerüste standardmäßig erzeugt und bleiben projektspezifisch. Die E2E-Suite läuft lokal nur über `just test-e2e` und in CI automatisch, sobald Tests vorhanden sind; Agent-Tests laufen nur manuell.
* **Projektdokumentation** mit MkDocs und **Diátaxis-Gerüst** (Bibliothek) oder generierter CLI-Referenz; **ADRs** (Architectural Decision Records).
* Bewertung der **Codestruktur** mit **just rate-design** dient dem Skill mit seinem **Refactoring-Rezept** Vorschläge zur Codeverbesserung zu machen und **diese dann umzusetzen**.
* Auch **Agenten** bekommen Unterstützung mit **AGENTS.md** und **journal/** und ihrem **Agenten-Skill**.
* Das **Sahnehäubchen** ist dann noch eine **DataScience Umgebung** mit **Jupyter und Colab**.


