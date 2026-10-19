# Luxus-Python-Stack — Dokumentation

Der Luxus-Python-Stack ist eine Kombination aus Werkzeugen, Skripten, Aliasen
und Regeln für eine effiziente, konfliktfreie Python-Entwicklung. Seine
Fünf-Ebenen-Architektur trennt Zuständigkeiten in klar abgegrenzte Schichten.
ZSH mit Antidote und dem Powerlevel10k-Prompt dient nicht nur der Optik,
sondern verankert auch funktionale Erweiterungen aus dem Data-Science-Umfeld
(Jupyter, Mamba).

## Komponenten

Ein Luxus-Stack besteht aus drei Komponenten:

| Komponente | Beschreibung |
| --- | --- |
| Stack-Dokumentation (diese Datei) | Beschreibung des Stacks, seiner Ebenen und des `pyinit`-Ablaufs. |
| [Stack-Skill](lupysta/SKILL.md) | Arbeitsweisen für Agenten in bereits initialisierten Projekten; Rezepte werden bei Bedarf geladen. |
| [Stack-Script](luxuspythonstack.sh) | `pyinit` und weitere Shell-Funktionen; wird vom Menschen in der Shell eingebunden. |

Die englischen Fassungen `Luxus-Python-Stack.md`, `Stack-Setup.md` und
`lupysta/SKILL_en.md` bleiben als Referenz erhalten. Während der Entwicklung
ist die deutsche Fassung die Arbeitsgrundlage.

## Installation

1. Repository an einen stabilen Ort klonen:
   ```shell
   mkdir -p ~/gits
   git clone https://github.com/frankausberlin/luxus-skills ~/gits/luxus-skills
   ```
2. Die [Setup-Anleitung](Stack-Setup_de.md) befolgen.
3. Den Skill verlinken und das Script in der Shell einbinden; die
   [Setup-Anleitung](Stack-Setup_de.md) beschreibt beide Schritte.

> **Hinweis:** Die Einrichtung in einer VM oder einer frischen Ubuntu-Installation wird
> empfohlen. Andere Distributionen sind nicht getestet. Für ein bereits
> genutztes System sollte ein erfahrener Agent die Setup-Anleitung begleiten.

## Voraussetzungen

| Werkzeug | Zweck | Installation |
| --- | --- | --- |
| `uv` | Python-Versionen und Paketverwaltung | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| `direnv` | Automatische Aktivierung der Projektumgebung | `sudo apt install direnv` oder Homebrew |
| `just` | Command-Runner | `sudo apt install just` oder Homebrew/Cargo |
| `ruff` | Linting und Formatierung | `uv tool install ruff` |
| `basedpyright` | Strenge Typprüfung | `uv tool install basedpyright` |
| `mamba` | Data-Science-Umgebungen (Ebene 1) | Miniforge-Installer |

## direnv

Der direnv-Hook gehört an das **absolute Ende** der Shell-Konfiguration:

```shell
# In ~/.zshrc oder ~/.bashrc (muss die letzte Zeile sein)
eval "$(direnv hook zsh)"   # oder: eval "$(direnv hook bash)"
```

Die Funktion `layout_uv` liegt in `~/.config/direnv/direnvrc`:

```bash
layout_uv() {
    [ ! -d ".venv" ] && uv venv
    export VIRTUAL_ENV="$(pwd)/.venv" && PATH_add "$VIRTUAL_ENV/bin"
    export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
}
```

## Shell-Einbindung

Das Script wird über einen symbolischen Link oder direkt per `source`
eingebunden. Der Repository-Checkout bleibt die Quelle der Wahrheit;
Aktualisierungen erfolgen mit `git pull`.

```shell
source /pfad/zu/luxus-skills/Luxus-Python-Stack/luxuspythonstack.sh
```

Die Datei behält den Namen `luxuspythonstack.sh`. Der Skill-Name ist
`lupysta`. Beides sind getrennte Schritte: das Script stellt Shell-Funktionen
bereit, der Skill steuert die agentische Arbeit.

## Skill-Installation

Den Skill-Ordner in das Skills-Verzeichnis der Harness verlinken:

```shell
mkdir -p ~/.agents/skills
ln -s /pfad/zu/luxus-skills/Luxus-Python-Stack/lupysta \
      ~/.agents/skills/lupysta
```

Wenn die Harness `~/.agents/skills` nicht automatisch lädt, den Pfad in ihrer
Konfiguration ergänzen, zum Beispiel über `skills.paths` in
`~/.config/kilo/kilo.jsonc`. Danach die Harness neu starten.

Es gibt **keine zweite Skill-Kopie** in generierten Projekten. Der zentral
installierte Skill beschreibt alle Arbeitsweisen; die `AGENTS.md` des Projekts
wählt aus, welche davon gelten.

## Installation prüfen

```shell
type pyinit act jl
pyinit --help
```

`pyinit --help` zeigt die Nutzung ohne Nebenwirkungen.

## Architektur — Fünf-Ebenen-Konzept

| Ebene | Name | Werkzeug | Aktivierung |
| --- | --- | --- | --- |
| 0 | Global / System | `/usr/bin/python` | Immer aktiv (Fallback) |
| 1 | Mamba / Jupyter | Mamba + UV | `act <envname>` oder Start über `~/.startenv` |
| 2 | Projekte | UV + direnv | Automatisch über `direnv`, wenn `.venv` existiert |
| 3 | CI/CD | GitHub Actions + UV | Bei Push/PR oder manuell |
| 4 | KI-Agenten | `AGENTS.md` + Skill + `SESSION.md` | Start der Agentensitzung |

### Ebene 0: Global / System

- Die Standard-Python-Installation (`/usr/bin/python`) liegt hier.
- Systemwerkzeuge: `uv`, `just`, `direnv`, `mamba`.
- Projektwerkzeuge: `ruff`, `basedpyright`, `pytest` (über `uv sync`).
- Mamba ist installiert, aber inaktiv, bis es ausdrücklich aktiviert wird.
- Diese Ebene ist der Fallback, wenn keine andere Umgebung aktiv ist.

### Ebene 1: Mamba / Jupyter

- Gedacht für Data Science und Experimente.
- Werkzeuge: Jupyter Lab, Scikit-Learn, JAX, Numba und weitere Pakete aus
  dem Setup.
- Aktiv, solange kein `.venv` im aktuellen Verzeichnis existiert; direnv hat
  Vorrang.
- **Start:** `act <envname>` aktiviert die Umgebung und speichert den Namen in
  `~/.startenv`.
- **Wegwerfcharakter:** Die Regel lautet „keine Updates, löschen und neu
  anlegen“.
- **Namensschema:** `ds12` bedeutet „Data Science mit Python 3.12“; `_ds12`
  ist die Variante mit normalem `ipywidgets >= 8.0`.
- **ipywidgets-Dilemma:** Colab benötigt `ipywidgets < 8.0`, aktuelle
  Jupyter-Versionen benötigen `>= 8.0`. Deshalb existieren zwei Varianten je
  Python-Version.
- In Mamba-Umgebungen wird `uv pip install` für Geschwindigkeit verwendet;
  die Pakete stehen bewusst nicht unter Mambas Kontrolle.

Die im Setup angelegte `ds12`-Umgebung ist bewusst **abgespeckt**: Sie enthält
Google Colab, Scikit-Learn, JAX, JupyterLab und verwandte Werkzeuge, aber
**keine CUDA-, PyTorch- oder TensorFlow-Zusage**. Wer diese Pakete braucht,
ergänzt sie ausdrücklich in der eigenen Umgebung.

### Ebene 2: Projekte

- Standard-Python-Projekte mit `uv` und `direnv`.
- Automatisch aktiviert, wenn ein Verzeichnis eine `.venv` enthält.
- Initialisiert mit `pyinit` (App), `pyinit --lib` (Bibliothek) oder
  `pyinit --cli` (App mit Typer-CLI-Referenz).
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
docs/                       # optional (Lib oder --cli)
pyproject.toml
uv.lock
Justfile
AGENTS.md
SESSION.md / JOURNAL.md     # gitignored
.envrc
.pre-commit-config.yaml
.github/workflows/ci.yml    # release.yml bei Bibliotheken
```

`AGENTS.md` enthält das Projektprofil, die Feature-Auswahl und lokale Regeln.
Der Skill beschreibt die Arbeitsweisen; die Projektdateien bleiben die
ausführbare Quelle.

### Ebene 3: CI/CD

- Automatisches Gate zwischen lokaler Entwicklung und Veröffentlichung.
- Umgebungsparität über `uv.lock`.
- Bei jedem Push/PR: `uv sync --locked --dev` und `just check`.
- Release: `bump-my-version` und Git-Tags.
- Veröffentlichung auf PyPI über GitHub Actions mit OIDC Trusted Publishing.

### Ebene 4: KI-Agenten

Die vierte Ebene besteht aus drei Teilen:

| Teil | Verantwortung |
| --- | --- |
| Installierter lupysta-Skill | Beschreibt alle möglichen Arbeitsweisen als Rezepte. |
| Projekt-`AGENTS.md` | Wählt die Features und nennt lokale Regeln; enthält keine zweite Skill-Kopie. |
| `SESSION.md` / `JOURNAL.md` | Flüchtiger Sitzungszustand bzw. chronologische Historie; gitignored. |

Ablauf:

1. `AGENTS.md` lesen und die Feature-Auswahl prüfen.
2. `SESSION.md` lesen, falls vorhanden.
3. `uv sync` und `git status` ausführen.
4. Nur die Rezepte laden, die zur Aufgabe und zur Feature-Auswahl passen.
5. Am Ende `just check` grün halten, `SESSION.md` überschreiben und
   `JOURNAL.md` ergänzen.
6. Lokal mit `just merge` mergen; Agenten pushen nie.

Die Feature-Auswahl in `AGENTS.md` ist die einzige Quelle für die Frage,
welche Arbeitsweisen in einem Projekt gelten. Fehlende Features werden nicht
vorausgesetzt und nicht ungefragt nachgebaut.

## Tägliche Befehle

Die ausführlichen Rezepte stehen im Skill. Diese Übersicht dient nur der
Orientierung:

| Bereich | Befehle | Rezept |
| --- | --- | --- |
| Qualität | `just check`, `just fix`, `just test`, `just lint`, `just typecheck`, `just audit`, `just clean` | [`lupysta/references/quality-gate.md`](lupysta/references/quality-gate.md) |
| Dokumentation | `just docs`, `just docs-check`, `just docs-serve` | [`lupysta/references/documentation.md`](lupysta/references/documentation.md) |
| Git und Release | `just merge`, `just bump patch\|minor\|major` | [`lupysta/references/git-release.md`](lupysta/references/git-release.md) |
| Refactoring | `just rate-design run\|save\|compare`, `just refactor` | [`lupysta/references/refactoring.md`](lupysta/references/refactoring.md) |

## `pyinit`-Ablauf

| Schritt | Inhalt | Details |
| ---: | --- | --- |
| 01 | Argumente | `while`/`case`-Parser; `--lib`, `--cli`, `--python X.Y`, `--no-check`, `--help`; höchstens ein Verzeichnis; unbekannte Optionen und ungültige Kombinationen werden vor jeder Änderung abgelehnt. |
| 02 | Python-Version | Format `X.Y`, mindestens `3.11` (z. B. `3.12`), sonst Abbruch. |
| 03 | Name ableiten | Projektname aus dem Zielverzeichnis; Paketname kleingeschrieben und `-` → `_`; ungültige Identifier und Keywords werden abgelehnt. |
| 04 | Ziel prüfen | Nicht vorhandenes oder leeres Ziel ist erlaubt; ein Ziel, das nur `.git` enthält, ebenfalls; Dateien und sonstige Inhalte werden abgelehnt. |
| 05 | Werkzeuge und Vorlagen | `uv`, `just`, `git`, `awk` und die Vorlagen `templates/pyinit/AGENTS.md` sowie `templates/pyinit/scripts/design_report.py` werden vor dem ersten Schreibzugriff geprüft. |
| 06 | Ziel betreten, `uv init` | In einer Subshell; `UV_PYTHON_PREFERENCE=only-managed`; App: `uv init --app --package`; Lib: `uv init --lib`. |
| 07 | Dev-Abhängigkeiten | `ruff`, `pytest`, `pytest-cov`, `basedpyright`, `colorlog`, `bump-my-version`, `pre-commit`, `pip-audit`, `radon`, `vulture`; Lib zusätzlich MkDocs; CLI zusätzlich `typer`. |
| 08 | `pyproject.toml` patchen | Einstiegspunkt für Apps; Versionsmarker für `bump-my-version`. |
| 09 | Paketquelle | `__init__.py` mit Docstring und Version; App: `main.py`; Lib: `py.typed`. |
| 10 | Tests | `tests/test_smoke.py` mit echtem Smoke-Test; kein `assert True`. |
| 10b | Design-Report | `scripts/design_report.py` aus der Vorlage kopieren. |
| 11 | Tool-Konfiguration | Ruff, basedpyright, pytest, Coverage, bump-my-version. |
| 12 | `.gitignore` | Python, Umgebungen, Caches, Docs-Ausgabe, Session-Dateien, `ignore/`, `.refactor/`, `.kilo/`; `.vscode/` bleibt versionierbar. |
| 13 | VS Code | `settings.json`, `launch.json`, `extensions.json`. |
| 14 | direnv | `.envrc` mit Conda-Schutz, `watch_file uv.lock`, `layout uv`; kein automatisches `direnv allow`. |
| 15 | Justfile | `test`, `lint`, `typecheck`, `check`, `fix`, `clean`, `audit`, `bump`, `rate-design`, `refactor`, `merge`; `check` ruft `docs-check` auf, wenn vorhanden. |
| 16 | GitHub Actions | `ci.yml` immer; `release.yml` nur für Bibliotheken. |
| 17 | `AGENTS.md` | Aus `templates/pyinit/AGENTS.md` gerendert: Projektprofil, Feature-Liste, lokale Regeln, Herkunft. |
| 18 | Session und Projektdokumente | `SESSION.md`, `JOURNAL.md`, `README.md`, `.editorconfig`, `CONTRIBUTING.md`, `LICENSE`. |
| 19 | pre-commit | Standard-Hooks plus lokale Ruff-Hooks; basedpyright läuft im Gate und in CI. |
| 20 | Dokumentation | Lib: MkDocs; App mit `--cli`: generierte CLI-Referenz. Generierte Seiten nie von Hand ändern. |
| 21 | Git | `git init -q -b main`. |
| 22 | Sync, Hooks, Gate | `uv sync`, `uv run pre-commit install`, ggf. `just docs`, dann `just check`; mit `--no-check` entfällt nur das Gate. |

## Unterstützte Umgebung

Linux ist die Referenzplattform. macOS ist derzeit keine unterstützte Zusage;
mehrere Werkzeuge im Script und in den erzeugten Projekten setzen
GNU-Werkzeuge voraus. macOS-Unterstützung kommt erst mit CI- und
Testabdeckung zurück.

## Migration und Uninstall

- Den alten `luxuspythonstack`-Skill und `lupysta` nicht parallel installieren.
- Bestehende Projekte werden nicht automatisch aktualisiert; ihre vorhandenen
  Befehle bleiben gültig.
- Zum Deinstallieren den Skill-Link entfernen und die `source`-Zeile aus der
  Shell-Konfiguration löschen. Generierte Projekte bleiben unabhängig vom
  installierten Skill.

## Nicht im Scope

- Automatische Migration bestehender Projekte.
- Ein vollständiger Lion-Port.
- macOS-Unterstützung ohne CI.
- Setup-, `pyinit`- oder Shell-Funktionen im Skill.
