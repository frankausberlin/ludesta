# Tests

Diese Tests prüfen das Stack-Script `Luxus-Python-Stack/scripts/luxuspythonstack.sh`, dessen `pyinit`-Funktion und die daraus generierten Projektgerüste.

## Was wird getestet?

### `test-pyinit.sh --fast`

Schnelle Prüfungen ohne Netzwerk und ohne erzeugte Projekte:

- `pyinit --help` liefert die Usage und beendet sich mit 0, ohne Dateien anzulegen.
- Argument-Validierung: unbekannte Optionen, fehlende Werte, ungültige Python-Versionen (< 3.11), unzulässige Kombinationen (`--lib --cli`), zu viele Verzeichnisse, ungültige Paketnamen und Python-Keywords werden abgelehnt. Keywords werden nach der Normalisierung geprüft, sodass auch `Class` und `IMPORT` abgelehnt werden.
- Zielpfad-Prüfung: Dateien, nicht-leere Verzeichnisse und ein fehlendes Template führen zu einem Abbruch, bevor etwas geschrieben wird.
- Beide Template-Runner sind syntaktisch gültig.
- Leerlauf-Semantik: `scripts/test-e2e.sh` und `scripts/test-agent.sh` beenden sich in einem Projekt ohne `test_*.py` mit Exit 0 und einem Hinweis. Ein Fake-`docker` bzw. Fake-`uv` im `PATH` schreibt eine Markerdatei und beendet sich mit 99; die Markerdatei darf nicht entstehen.
- `pyinit --help` nennt `test-e2e` und `test-agent`.
- ZSH-Prompt: Wenn `zsh` installiert ist, übersteht `prompt_my_jupyter` ein leeres Runtime-Verzeichnis und ein einzelnes Runtime-Dateimuster ohne `NOMATCH`-Abbruch.

### `test-pyinit.sh` (vollständig)

Zusätzlich Integrationstests mit temporären Projekten (werden am Ende gelöscht):

- **App** (`pyinit <dir> --python 3.12`): erzeugt `AGENTS.md` mit Projektprofil, Testing, ADR-Konventionen und Attention Points (Contract-Version 3); kein `SESSION.md`, keine alten Managed-Blocks. `just check`, `just rate-design run/save/compare` und `just clean` funktionieren; Baselines werden nicht überschrieben und von `clean` erhalten.
- **Opt-in-Gerüste**: `tests/conftest.py`, `tests/e2e/` (README, conftest, Dockerfile), `tests/agent/` (README, conftest), `scripts/test-e2e.sh`, `scripts/test-agent.sh` und `.dockerignore` existieren. `Justfile`, `pyproject.toml` (Marker, `e2e`-Gruppe), `.gitignore`, `README.md`, `CONTRIBUTING.md` und `.github/workflows/e2e.yml` enthalten die neuen Einträge. Beide Runner laufen im leeren Gerüst mit Exit 0; Fake-`docker`/`uv` beweisen, dass nichts aufgerufen wird.
- **Gate-Probe**: Eine `tests/e2e/test_gate_probe.py` bzw. `tests/agent/test_gate_probe.py` mit absichtlichem `AssertionError` verändert `just check` nicht; anschließend wird die Probe entfernt. Wenn Docker verfügbar ist, führt `just test-e2e` die E2E-Probe wirklich aus und muss fehlschlagen; sonst wird dieser Teil übersprungen.
- **Refactoring-Workflow**: `just refactor demo` legt Branch `refactor/demo` und Baseline an; `just merge` erkennt den Branch, wechselt zurück nach `main` und löscht den gemergten Branch. Worktrees mit Journal-Dateien bleiben geschützt.
- **Bibliothek** (`--lib`): korrekter Projekttyp in `AGENTS.md`, vollständiges Diátaxis-Gerüst (`tutorials/`, `how-to/`, `reference/`, `explanation/`) inklusive MkDocs-Navigation, `just check` und `just docs-check` sind grün.
- **CLI-App** (`--cli`): korrekter Projekttyp in `AGENTS.md`, generierte CLI-Referenz, `just check` und `just docs-check` sind grün. Apps ohne `--cli` erhalten kein Docs-Gerüst.
- **Bibliotheks-Bump**: `just bump patch` aktualisiert `uv.lock` im selben Commit, `uv sync --locked --dev` und `just check` bleiben grün, und der Tag `v0.1.1` wird erzeugt.
- **`.git-only`-Ziel**: ein bereits initialisiertes Repo wird akzeptiert, `.git` bleibt erhalten und der Branch wird auf `main` gesetzt.

Die Skripte geben pro Prüfung `ok - ...` bzw. `not ok - ...` aus und am Ende eine Zusammenfassung. Der Exit-Code ist 0, wenn alle Prüfungen bestanden wurden.

### `fresh-clone.sh`

Klont den letzten Commit in ein temporäres Verzeichnis und stellt sicher, dass ein frischer Clone ohne lokalen Zustand (z. B. `ignore/`) funktioniert. Danach laufen die Fast-Checks, ein Beispielprojekt wird angelegt und `just check` ausgeführt.

### `scripts/check-links.sh`

Prüft relative Markdown-Links in allen getrackten Markdown-Dateien. Externe URLs, Anker und absolute Pfade werden ignoriert; Codeblöcke und Inline-Code werden übersprungen. Gemeldet wird jede Datei mit Zeilennummer und defektem Ziel.

## Tests ausführen

Alle Befehle im Repository-Wurzelverzeichnis ausführen.

```shell
bash tests/test-pyinit.sh --fast          # schnelle Prüfungen, keine Projekte
bash tests/test-pyinit.sh                 # zusätzlich Integration mit generierten Projekten
bash tests/fresh-clone.sh                 # frischer Clone des letzten Commits
bash tests/scripts/check-links.sh         # relative Markdown-Links prüfen
```

## Voraussetzungen

- `bash`, `git`, `python3` (für `check-links.sh`)
- `uv` und `just` für die Integrationstests
- Docker ist optional. Nur wenn `docker info` erfolgreich ist, prüft der volle Lauf zusätzlich, dass `just test-e2e` einen echten E2E-Test im Container ausführt; sonst wird dieser Teil übersprungen.
- `zsh` ist optional und aktiviert zusätzlich den Jupyter-Prompt-Test
- Netzwerkzugriff kann für das Auflösen der Abhängigkeiten mit `uv` nötig sein
- `fresh-clone.sh` testet den **letzten Commit**; nicht committete Änderungen werden nicht geprüft.
