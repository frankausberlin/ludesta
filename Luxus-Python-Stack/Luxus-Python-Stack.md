# Luxus-Python-Stack — Dokumentation

Der Luxus-Python-Stack ist eine Kombination aus Werkzeugen, Skripten, Aliasen und Regeln für eine effiziente, konfliktfreie Python-Entwicklung, sowie einer DataScience Umgebung (Jupyter, Mamba). Seine Fünf-Ebenen-Architektur trennt Zuständigkeiten in klar abgegrenzte Schichten. ZSH mit Antidote und dem Powerlevel10k-Prompt dient nicht nur der Optik, sondern verankert auch funktionale Erweiterungen.

## Aufbau des Stacks

|Folder|File|Inhalt|
|-|-|-|
|**`/`**|*Luxus-Python-Stack.md*|Stack-Dokumentation (dieses Dokument)|
||*Stack-Setup.md*|Stack-spezifische Einrichtung (setzt das [Basis-System](../Setup.md) voraus)|
||*Projekt-Migration.md*|Eigenständiger, ausdrücklich zu beauftragender Agentenauftrag|
|**`lupysta/`**||Stack-Skill für die Arbeit im initialisierten Projekt (siehe unten)|
|**`scripts/`**|*luxuspythonstack.sh*|Shell-Funktionen (`jupyter-launcher`, `prompt_my_jupyter`, Alias `jl`)|
|**extern**|*pyinit*|Projekt-Init in eigenem Repository (`~/gits/pyinit`), per `uv tool` installiert|
	  	     
     
## Aufbau des Skills

|Folder|File|Inhalt|
|-|-|-|
|**`lupysta/`**|*SKILL.md*|Skill-Übersicht und Rezeptindex|
|**`lupysta/references`**|*agent-tests.md*|Opt-in Agent-Tests (Harness projektspezifisch; nicht Teil von `just check`)|
||*documentation.md*|Dokumentationsrezepte für `just docs*`|
||*e2e-tests.md*|Opt-in E2E-Tests (Tests projektspezifisch; nicht Teil von `just check`)|
||*git-release.md*|Worktree, Merge, Versionierung und Release|
||*quality-gate.md*|Qualitätsgate und Fehlersuche|
||*refactoring-recipes.md*|Konkrete Refactoring-Rezepte|
||*refactoring.md*|Design-Report, Baseline und Refactoring-Ablauf|
||*session-close.md*|Aufgabenabschluss: ADRs, Attention Points und `journal/`|

## Projekt-Migration

[`Projekt-Migration.md`](Projekt-Migration.md) ist ein eigenständiger
Agentenauftrag auf Ebene der Stack-Dokumentation, kein Rezept des
Lupysta-Skills und kein zusätzlicher Skill. Er wird nur nach ausdrücklicher
Beauftragung ausgeführt; die normale Projektarbeit mit Lupysta führt nicht in
diesen Ablauf. `pyinit` dient darin als festgelegte Zielreferenz und erhält
keinen Update- oder Merge-Modus. Nach erfolgreicher Migration wird an den
normalen [Lupysta-Sitzungsstart](lupysta/SKILL.md) übergeben.

## Installation

**Zuerst das [Basis-System](../Setup.md) einrichten, danach die [Stack-Einrichtung](Stack-Setup.md) befolgen.**

Kleiner Test
```shell
# zuerst ein kleines python-projekt anlegen
mkdir ~/gits/myproject && cd ~/gits/myproject

# projekt initialisieren und environment automatik aktivieren
pyinit new app
direnv allow

# Du siehst nun im p10k-prompt rechts ein gelbes dreieck, das bedeutet, dass dieser folder 
# automatisch das python-environment wechselt von ds12 zu dem projektenvironment

# jetzt zurück ins home und das ds12 ist wieder aktiv (unser default-environment)
cd ~

# dann starten wir ein jupyter (sein arbeitsfolder ist standardmäßig ~/labor)
jl

# dann öffne ein zweites terminal-fenster 
# Hier nochmal die Situation: 
# 1. du hast ein standard-python-environment ds12 das normalerweise in der shell aktiv ist
# 2. du hast einen Jupyer-Server am laufen auf http://127.0.0.1:8888/lab
# 3. du hast ein Python-Projekt mit aktiviertem (direnv allow) Environment in ~/gits/myproject (ersetzt ds12)

# jetzt wechsel in den labor Folder und achte auf den p10k-prompt, er zeigt an, das ein jupyter 
# läuft und diesen folder als arbeitsverzeichnis verwendet.
cd ~/labor

# und jetzt nochmal den wechsel in den projekt-folder und der prompt ändert sich wieder
cd ~/gits/myproject

# und wenn wir schon mal hier sind, starten wir doch direkt mal code mit einem
# OpenRouter-Key, der nur für den gestarteten VS-Code-Prozess gilt.
# ocode liest das Token verdeckt ein; einfach einfügen. Die Kilo-Erweiterung erkennt es.
ocode .

# dannach öffne die kilo-extension in code und prüfe ob der skill vorhanden ist


```


## Überblick verwendete Werkzeuge

| Werkzeug | Zweck |
| --- | --- |
| `uv` | Python-Versionen und Paketverwaltung|
| `direnv` | Automatische Aktivierung der Projektumgebung|
| `just` | Command-Runner|
| `ruff` | Linting und Formatierung|
| `basedpyright` | Strenge Typprüfung|
| `vulture` | Dead-Code-Analyse |
| `pytest` | Durchführung Unittests|
| `coverage` | Testabdeckung|
| `mamba` | Bereitstellung Data-Science-Umgebungen|
| `bump-my-version` | Versionierung / Deployment|
| `radon` | Metriken fürs Refactoring|


## Architektur — Fünf-Ebenen-Konzept

| Ebene | Name | Werkzeug | Aktivierung |
| --- | --- | --- | --- |
| 0 | Global / System | `/usr/bin/python` | Immer verfügbar (Fallback) |
| 1 | Mamba / Jupyter | Mamba + UV | `act <envname>` oder beim Shellstart `~/.startenv`/`base`, solange keine `.envrc` im CWD liegt |
| 2 | Projekte | UV + direnv | `.envrc` mit `layout uv` nach `direnv allow`; eine vorhandene `.venv` allein genügt nicht |
| 3 | CI/CD | GitHub Actions + UV | Bei Push/PR oder manuell |
| 4 | KI-Agenten | `AGENTS.md` + Skill + `journal/` | Start der Agentensitzung |

### Ebene 0: Global / System

* Die Standard-Python-Installation (`/usr/bin/python`) liegt hier.
* Systemwerkzeuge: `uv`, `just`, `direnv`, `mamba`.
* Projektwerkzeuge: `ruff`, `basedpyright`, `pytest` (über `uv sync`).
* Mamba ist installiert; ob es beim Shellstart aktiv wird, regelt Ebene 1.
* Diese Ebene ist der Fallback, wenn keine andere Umgebung aktiv ist.

### Ebene 1: Mamba / Jupyter

* Gedacht für Data Science und Experimente.
* Aktivierung beim Shellstart außerhalb eines Verzeichnisses mit `.envrc`; in einem Projekt mit `.envrc` überspringt das Startskript die Mamba-Aktivierung, direnv übernimmt nach `direnv allow`.
* **Start:** `act <envname>` aktiviert die Umgebung und speichert den Namen in `~/.startenv`.
* **Wegwerfcharakter:** Die Regel lautet „keine Updates, löschen und neu anlegen“.
* **Namensschema:** `ds12` bedeutet „Data Science mit Python 3.12“.
* **ipywidgets-Dilemma:** Colab benötigt `ipywidgets < 8.0`, aktuelle Jupyter-Versionen benötigen `>= 8.0`. Das Setup legt deshalb `dsXY` mit `ipywidgets==7.7.1` für Colab an; eine separate Umgebung mit `ipywidgets >= 8.0` wird bei Bedarf manuell erstellt.
* In Mamba-Umgebungen wird `uv pip install` für Geschwindigkeit verwendet;  die Pakete stehen bewusst nicht unter Mambas Kontrolle.

  > Anmerkung<br>
  > Es wird im Allgemeinen nicht empfohlen, „uv“ in einer Mamba-Umgebung zu verwenden, da auf diese Weise installierte Pakete nicht unter der Kontrolle von Mamba stehen. Dies kann zu Konflikten beim Aktualisieren führen.<br>
  > Ich nutze die Data-Science-Umgebung auf eine Weise, die dieses Problem irrelevant macht. Ich installiere ständig neue Bibliotheken, lösche alte und experimentiere. Genauso häufig (manchmal zweimal am Tag) lösche ich die Umgebung vollständig und installiere sie neu.<br>
  > Deshalb verwende ich „uv“; es ist so unglaublich schnell.



### Ebene 2: Projekte

- Standard-Python-Projekte mit `uv` und `direnv`.
- Aktiviert durch den direnv-Hook und `layout uv`; `layout uv` legt bei Bedarf
  `.venv` an und setzt `VIRTUAL_ENV`/`PATH`. Eine vorhandene `.venv` allein
  genügt nicht.
- Initialisiert mit `pyinit new app`, `pyinit new lib`, `pyinit new app-cli`
  oder `pyinit new mcp`; ohne Verzeichnis legt der Befehl im aktuellen Ordner
  an. `pyinit` schreibt `.envrc`, ruft aber kein `direnv allow` auf.
- Qualitätsgate: `just check` → `ruff check`, `ruff format --check`,
  `basedpyright`, bei Bedarf `docs-check` und `pytest` mit Coverage.
- Weitere Befehle: `just fix`, `just test`, `just lint`, `just typecheck`,
  `just audit`, `just clean`, `just rate-design`, `just refactor`,
  `just merge`, `just bump`.

#### Projektstruktur (von `pyinit` erzeugt)

```text
src/<paketname>/
├── main.py                 # App: Einstieg; App-CLI: Typer-Delegate; MCP: stdio-Start
└── server.py               # nur MCP: Tool, Resource, Server
tests/
├── conftest.py             # Gate für die opt-in Suiten
├── e2e/                    # Docker-Gerüst, zunächst ohne test_*.py
└── agent/                  # Provider-Skelett, zunächst ohne test_*.py
scripts/design_report.py
scripts/test-e2e.sh
scripts/test-agent.sh
docs/                       # Lib: Diátaxis-Gerüst + index.md/api.md; App-CLI: reference/cli.md
docs/adr/                   # ADR-Konvention (README.md); die erste ADR legt der Nutzer an
pyinit.toml                 # Herkunft: Profil, Artefakte, Versionen
pyproject.toml
uv.lock
Justfile
AGENTS.md
journal/                    # versionierte Session-Chronik (README.md + Einträge)
.envrc
.dockerignore               # nur mit E2E-Artefakt
.pre-commit-config.yaml
.github/workflows/ci.yml    # release.yml bei Bibliotheken
.github/workflows/e2e.yml   # Docker-Suite; CI automatisch ab vorhandenen Tests
```

Testkonzept: Unit- und Smoke-Tests unter `tests/` sind das automatische Gate.
`tests/e2e/` ist lokal nur über `just test-e2e` erreichbar und nicht Teil von
`just check`; der CI-Workflow führt die Suite automatisch aus, sobald
Testdateien existieren. `tests/agent/` ist rein manuell und nie Teil der CI.
Echte Tests bleiben projektspezifisch.

Bibliotheken erhalten von `pyinit` ein Diátaxis-Gerüst: `docs/tutorials/`,
`docs/how-to/`, `docs/reference/` und `docs/explanation/` mit je einer
Leitseite und Einträgen in der MkDocs-Navigation. `app-cli` erhält nur
`docs/reference/cli.md`; `app` und `mcp` erhalten kein Docs-Gerüst. `docs/adr/`
entsteht mit dem ADR-Gerüst; die erste ADR legt der Nutzer an.

* `AGENTS.md` enthält das Projektprofil, die ADR-Konventionen und die Attention Points.
* Der Skill beschreibt die Arbeitsweisen; die Projektdateien bleiben die ausführbare Quelle.

### Ebene 3: CI/CD

- Automatisches Gate zwischen lokaler Entwicklung und Veröffentlichung.
- Umgebungsparität über `uv.lock`.
- Bei jedem Push/PR: `uv sync --locked --dev` und `just check`.
- Release: `bump-my-version` und Git-Tags.
- Veröffentlichung auf PyPI über GitHub Actions mit OIDC Trusted Publishing.

### Ebene 4: KI-Agenten

Die vierte Ebene besteht aus vier Teilen:

| Teil | Verantwortung |
| --- | --- |
| Installierter lupysta-Skill | Beschreibt die reguläre Projektarbeit als Rezepte. |
| Projekt-`AGENTS.md` | Enthält Projektprofil, ADR-Konventionen und Attention Points; keine zweite Skill-Kopie. |
| `journal/` | Versionierte Session-Chronik; ein unveränderlicher Eintrag pro Session. |
| `docs/adr/` | Architekturentscheidungen; der Inhalt ist unveränderlich, Revisionen entstehen als neue ADR. |

Ablauf:

1. `AGENTS.md` lesen: Projektprofil, ADR-Konventionen und Attention Points.
2. Die neuesten Einträge unter `journal/` lesen, falls vorhanden.
3. `docs/adr/` sichten, falls vorhanden.
4. `uv sync` und `git status` ausführen.
5. Nur die Rezepte laden, die zur Aufgabe passen.
6. Am Ende `just check` grün halten, [`session-close.md`](lupysta/references/session-close.md)
   ausführen und einen Journal-Eintrag unter `journal/` anlegen.
7. Lokal mit `just merge` mergen; Agenten pushen nie.

`AGENTS.md` ist die Quelle für projektbezogene Regeln. Der Skill beschreibt die
Arbeitsweisen; fehlende Befehle werden nicht vorausgesetzt und nicht ungefragt
nachgebaut.

## Tägliche Befehle

Die ausführlichen Rezepte stehen im Skill. Diese Übersicht dient nur der
Orientierung:

| Bereich | Befehle | Rezept |
| --- | --- | --- |
| Qualität | `just check`, `just fix`, `just test`, `just lint`, `just typecheck`, `just audit`, `just clean` | [`lupysta/references/quality-gate.md`](lupysta/references/quality-gate.md) |
| Opt-in-Tests | `just test-e2e`, `just test-agent` | [`lupysta/references/e2e-tests.md`](lupysta/references/e2e-tests.md), [`lupysta/references/agent-tests.md`](lupysta/references/agent-tests.md) |
| Dokumentation | `just docs`, `just docs-check`, `just docs-serve` | [`lupysta/references/documentation.md`](lupysta/references/documentation.md) |
| Git und Release | `just merge`, `just bump patch\|minor\|major` | [`lupysta/references/git-release.md`](lupysta/references/git-release.md) |
| Refactoring | `just rate-design run\|save\|compare`, `just refactor` | [`lupysta/references/refactoring.md`](lupysta/references/refactoring.md) |
| Projektwissen | `AGENTS.md`, `docs/adr/`, `journal/` | [`lupysta/references/session-close.md`](lupysta/references/session-close.md) |

## `pyinit`-Ablauf

`pyinit` löst ein Profil zu einem Artefaktgraphen auf, rendert alle Dateien im
Speicher und schreibt sie atomar über ein Staging-Verzeichnis. Danach folgen
`uv lock`, `git init`, `uv sync`, `pre-commit install`, bei Bedarf `just docs`
und `just check`.

Die Details je Artefakt und Profil stehen im pyinit-Repository:
[`docs/artefakte.md`](https://github.com/frankausberlin/pyinit/blob/main/docs/artefakte.md).
Zur Laufzeit zeigen `pyinit describe <id>`, `pyinit list` und
`pyinit new <profil> --dry-run` dieselben Daten.

Skill und Generator liegen in getrennten Repositories. Bei jeder Änderung von
`version:` in [`lupysta/SKILL.md`](lupysta/SKILL.md) ist die gekoppelte
Konstante `LUPYSTA_VERSION` in `src/pyinit/models.py` in einem separaten
Change im Pyinit-Repository anzugleichen. Dieser Abgleich ist ausdrückliche
repoübergreifende Folgearbeit. `CONTRACT_VERSION` beziehungsweise
`contract_version` ändert sich nur bei einer tatsächlichen Änderung des
Gerüst-Contracts, nicht durch eine reine Skill- oder Dokumentationsänderung.

## Unterstützte Umgebung

Ubuntu 26.04 ist die einzige Referenzplattform. Die Skripte und die generierten
Projekte nutzen GNU-Werkzeuge (`sed -i`, `readlink -f`, `realpath`); macOS wird
nicht unterstützt und nicht portiert.

## Uninstall

- `pyinit` entfernen: `uv tool uninstall pyinit`; den Clone `~/gits/pyinit`
  separat löschen. Existiert ein zweiter Clone, zeigt die editable Installation
  auf den zuerst installierten Pfad – nach dem Löschen mit
  `uv tool install --editable <pfad>` neu installieren.
- Zum Deinstallieren den Skill-Link entfernen und die `source`-Zeile aus der
  Shell-Konfiguration löschen. 
- Systemlinks in Harnesses auf den Skill-Folder sind zu entfernen.


