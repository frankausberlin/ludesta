# Luxus-Python-Stack — Dokumentation

Der Luxus-Python-Stack ist eine Kombination aus Werkzeugen, Skripten, Aliasen und Regeln für eine effiziente, konfliktfreie Python-Entwicklung, sowie einer DataScience Umgebung (Jupyter, Mamba). Seine Fünf-Ebenen-Architektur trennt Zuständigkeiten in klar abgegrenzte Schichten. ZSH mit Antidote und dem Powerlevel10k-Prompt dient nicht nur der Optik, sondern verankert auch funktionale Erweiterungen.

## Aufbau des Stacks

|Folder|File|Inhalt|
|-|-|-|
|**`/`**|*Luxus-Python-Stack.md*|Stack-Dokumentation (dieses Dokument)|
||*Stack-Setup.md*|Einrichtung des Stacks auf einem neuen System|
|**`lupysta/`**||Stack-Skill für die Arbeit im initialisierten Projekt (siehe unten)|
|**`scripts/`**|*luxuspythonstack.sh*|Stack-Laufzeit mit `pyinit` und Shell-Funktionen|
|**`templates/`**|*AGENTS.md*|Vorlage für die projektbezogene `AGENTS.md`|
||*scripts/design_report.py*|Vorlage für den Design-Report im Projekt|
	  	     
     
## Aufbau des Skills

|Folder|File|Inhalt|
|-|-|-|
|**`lupysta/`**|*SKILL.md*|Skill-Übersicht und Rezeptindex|
|**`lupysta/references`**|*agent-tests.md*|Agent-Tests (vorgesehen, nicht Teil der Basisversion)|
||*documentation.md*|Dokumentationsrezepte für `just docs*`|
||*e2e-tests.md*|E2E-Tests (vorgesehen, nicht Teil der Basisversion)|
||*git-release.md*|Worktree, Merge, Versionierung und Release|
||*quality-gate.md*|Qualitätsgate und Fehlersuche|
||*refactoring-recipes.md*|Konkrete Refactoring-Rezepte|
||*refactoring.md*|Design-Report, Baseline und Refactoring-Ablauf|
||*session-close.md*|Aufgabenabschluss: ADRs, Attention Points und `JOURNAL.md`|

## Installation

1. Repository an einen stabilen Ort klonen:
   ```shell
   mkdir -p ~/gits
   git clone https://github.com/frankausberlin/ludesta ~/gits/ludesta
   ```
2. Die [Setup-Anleitung](Stack-Setup.md) befolgen.
3. Den Skill verlinken und das Script in der Shell einbinden; die [Setup-Anleitung](Stack-Setup.md) beschreibt beide Schritte.

> **Hinweis:** Die Einrichtung in einer VM oder einer frischen Ubuntu-Installation wird
> empfohlen. Andere Distributionen sind nicht getestet. Für ein bereits
> genutztes System sollte ein erfahrener Agent die Setup-Anleitung begleiten.

## Überblick verwendete Werkzeuge

| Werkzeug | Zweck |
| --- | --- |
| `uv` | Python-Versionen und Paketverwaltung|
| `direnv` | Automatische Aktivierung der Projektumgebung|
| `just` | Command-Runner|
| `ruff` | Linting und Formatierung|
| `basedpyright` | Strenge Typprüfung|
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
| 4 | KI-Agenten | `AGENTS.md` + Skill + `JOURNAL.md` | Start der Agentensitzung |

### Ebene 0: Global / System

* Die Standard-Python-Installation (`/usr/bin/python`) liegt hier.
* Systemwerkzeuge: `uv`, `just`, `direnv`, `mamba`.
* Projektwerkzeuge: `ruff`, `basedpyright`, `pytest` (über `uv sync`).
* Mamba ist installiert; ob es beim Shellstart aktiv wird, regelt Ebene 1.
* Diese Ebene ist der Fallback, wenn keine andere Umgebung aktiv ist.

### Ebene 1: Mamba / Jupyter

* Gedacht für Data Science und Experimente.
* Werkzeuge: Jupyter Lab, Scikit-Learn, JAX, Numba und weitere Pakete aus dem Setup.
* Aktivierung beim Shellstart außerhalb eines Verzeichnisses mit `.envrc`; in
  einem Projekt mit `.envrc` überspringt das Startskript die Mamba-Aktivierung,
  direnv übernimmt nach `direnv allow`.
* **Start:** `act <envname>` aktiviert die Umgebung und speichert den Namen in `~/.startenv`.
* **Wegwerfcharakter:** Die Regel lautet „keine Updates, löschen und neu anlegen“.
* **Namensschema:** `ds12` bedeutet „Data Science mit Python 3.12“.
* **ipywidgets-Dilemma:** Colab benötigt `ipywidgets < 8.0`, aktuelle Jupyter-Versionen benötigen `>= 8.0`. Das Setup legt deshalb `dsXY` mit `ipywidgets==7.7.1` für Colab an; eine separate Umgebung mit `ipywidgets >= 8.0` wird bei Bedarf manuell erstellt.
* In Mamba-Umgebungen wird `uv pip install` für Geschwindigkeit verwendet;  die Pakete stehen bewusst nicht unter Mambas Kontrolle.

### Ebene 2: Projekte

- Standard-Python-Projekte mit `uv` und `direnv`.
- Aktiviert durch den direnv-Hook und `layout uv`; `layout uv` legt bei Bedarf
  `.venv` an und setzt `VIRTUAL_ENV`/`PATH`. Eine vorhandene `.venv` allein
  genügt nicht.
- Initialisiert mit `pyinit` (App), `pyinit --lib` (Bibliothek) oder
  `pyinit --cli` (App mit Typer-CLI-Referenz). `pyinit` schreibt `.envrc`, ruft
  aber kein `direnv allow` auf.
- Qualitätsgate: `just check` → `ruff check`, `ruff format --check`,
  `basedpyright`, bei Bedarf `docs-check` und `pytest` mit Coverage.
- Weitere Befehle: `just fix`, `just test`, `just lint`, `just typecheck`,
  `just audit`, `just clean`, `just rate-design`, `just refactor`,
  `just merge`, `just bump`.

#### Projektstruktur (von `pyinit` erzeugt)

```text
src/<paketname>/
tests/
scripts/design_report.py
docs/                       # Lib: Diátaxis-Gerüst + index.md/api.md; App --cli: reference/cli.md
docs/adr/                   # bei Bedarf, nicht von pyinit angelegt
pyproject.toml
uv.lock
Justfile
AGENTS.md
JOURNAL.md                  # gitignored
.envrc
.pre-commit-config.yaml
.github/workflows/ci.yml    # release.yml bei Bibliotheken
```

Bibliotheken erhalten von `pyinit` ein Diátaxis-Gerüst: `docs/tutorials/`,
`docs/how-to/`, `docs/reference/` und `docs/explanation/` mit je einer
Leitseite und Einträgen in der MkDocs-Navigation. Apps mit `--cli` erhalten nur
`docs/reference/cli.md`; Apps ohne `--cli` kein Docs-Gerüst. `docs/adr/`
entsteht mit der ersten ADR.

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
| Installierter lupysta-Skill | Beschreibt alle möglichen Arbeitsweisen als Rezepte. |
| Projekt-`AGENTS.md` | Enthält Projektprofil, ADR-Konventionen und Attention Points; keine zweite Skill-Kopie. |
| `JOURNAL.md` | Chronologische Historie und aktueller Stand; gitignored. |
| `docs/adr/` | Architekturentscheidungen; der Inhalt ist unveränderlich, Revisionen entstehen als neue ADR. |

Ablauf:

1. `AGENTS.md` lesen: Projektprofil, ADR-Konventionen und Attention Points.
2. Den letzten Eintrag in `JOURNAL.md` lesen, falls vorhanden.
3. `docs/adr/` sichten, falls vorhanden.
4. `uv sync` und `git status` ausführen.
5. Nur die Rezepte laden, die zur Aufgabe passen.
6. Am Ende `just check` grün halten, [`session-close.md`](lupysta/references/session-close.md)
   ausführen und `JOURNAL.md` fortschreiben.
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
| Dokumentation | `just docs`, `just docs-check`, `just docs-serve` | [`lupysta/references/documentation.md`](lupysta/references/documentation.md) |
| Git und Release | `just merge`, `just bump patch\|minor\|major` | [`lupysta/references/git-release.md`](lupysta/references/git-release.md) |
| Refactoring | `just rate-design run\|save\|compare`, `just refactor` | [`lupysta/references/refactoring.md`](lupysta/references/refactoring.md) |
| Projektwissen | `AGENTS.md`, `docs/adr/`, `JOURNAL.md` | [`lupysta/references/session-close.md`](lupysta/references/session-close.md) |

## `pyinit`-Ablauf

| Schritt | Inhalt | Details |
| ---: | --- | --- |
| 01 | Argumente | `while`/`case`-Parser; `--lib`, `--cli`, `--python X.Y`, `--no-check`, `--help`; höchstens ein Verzeichnis; unbekannte Optionen und ungültige Kombinationen werden vor jeder Änderung abgelehnt. |
| 02 | Python-Version | Format `X.Y`, mindestens `3.11` (z. B. `3.12`), sonst Abbruch. |
| 03 | Name ableiten | Projektname aus dem Zielverzeichnis; Paketname kleingeschrieben und `-` → `_`; ungültige Identifier und Keywords werden abgelehnt. |
| 04 | Ziel prüfen | Nicht vorhandenes oder leeres Ziel ist erlaubt; ein Ziel, das nur `.git` enthält, ebenfalls; Dateien und sonstige Inhalte werden abgelehnt. |
| 05 | Werkzeuge und Vorlagen | `uv`, `just`, `git`, `awk` und die Vorlagen `templates/AGENTS.md` sowie `templates/scripts/design_report.py` werden vor dem ersten Schreibzugriff geprüft. |
| 06 | Ziel betreten, `uv init` | In einer Subshell; `UV_PYTHON_PREFERENCE=only-managed`; App: `uv init --app --package`; Lib: `uv init --lib`. |
| 07 | Dev-Abhängigkeiten | `ruff`, `pytest`, `pytest-cov`, `basedpyright`, `colorlog`, `bump-my-version`, `pre-commit`, `pip-audit`, `radon`, `vulture`; Lib zusätzlich MkDocs; CLI zusätzlich `typer`. |
| 08 | `pyproject.toml` patchen | Einstiegspunkt für Apps; Versionsmarker für `bump-my-version`. |
| 09 | Paketquelle | `__init__.py` mit Docstring und Version; App: `main.py`; Lib: `py.typed`. |
| 10 | Tests | `tests/test_smoke.py` mit echtem Smoke-Test; kein `assert True`. |
| 10b | Design-Report | `scripts/design_report.py` aus der Vorlage kopieren. |
| 11 | Tool-Konfiguration | Ruff, basedpyright, pytest, Coverage, bump-my-version. |
| 12 | `.gitignore` | Python, Umgebungen, Caches, Docs-Ausgabe, `JOURNAL.md`, `ignore/`, `.refactor/`, `.kilo/`; `.vscode/` bleibt versionierbar. |
| 13 | VS Code | `settings.json`, `launch.json`, `extensions.json`. |
| 14 | direnv | `.envrc` mit Conda-Schutz, `watch_file uv.lock`, `layout uv`; kein automatisches `direnv allow`. |
| 15 | Justfile | `test`, `lint`, `typecheck`, `check`, `fix`, `clean`, `audit`, `bump`, `rate-design`, `refactor`, `merge`; `run` nur für Apps; `check` ruft `docs-check` auf, wenn vorhanden. |
| 16 | GitHub Actions | `ci.yml` immer; `release.yml` nur für Bibliotheken. |
| 17 | `AGENTS.md` | Aus `templates/AGENTS.md` gerendert: Projektprofil, ADR-Konventionen, Attention Points, Herkunft. |
| 18 | Journal und Projektdokumente | `JOURNAL.md`, `README.md`, `.editorconfig`, `CONTRIBUTING.md`, `LICENSE`. |
| 19 | pre-commit | Standard-Hooks plus lokale Ruff-Hooks; basedpyright läuft im Gate und in CI. |
| 20 | Dokumentation | Lib: `mkdocs.yml`, `docs/index.md`, `docs/api.md`, Diátaxis-Gerüst (`tutorials/`, `how-to/`, `reference/`, `explanation/`), `just docs*`; App mit `--cli`: `scripts/gen_cli_docs.py`, `docs/reference/cli.md`, `just docs*`; sonst kein Docs-Gerüst. |
| 21 | Git | `git init -q -b main`. |
| 22 | Sync, Hooks, Gate | `uv sync`, `uv run pre-commit install`, ggf. `just docs`, dann `just check`; mit `--no-check` entfällt nur das Gate. |

## Unterstützte Umgebung

Ubuntu 26.04 ist die Referenzplattform. 

## Uninstall

- Zum Deinstallieren den Skill-Link entfernen und die `source`-Zeile aus der
  Shell-Konfiguration löschen. 
- Systemlinks in Harnesses auf den Skill-Folder sind zu entfernen.


