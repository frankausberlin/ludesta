# Tests

Diese Tests prüfen das Stack-Script `Luxus-Python-Stack/scripts/luxuspythonstack.sh`, dessen `pyinit`-Funktion und die daraus generierten Projektgerüste.

## Was wird getestet?

### `test-pyinit.sh --fast`

Schnelle Prüfungen ohne Netzwerk und ohne erzeugte Projekte:

- `pyinit --help` liefert die Usage und beendet sich mit 0, ohne Dateien anzulegen.
- Argument-Validierung: unbekannte Optionen, fehlende Werte, ungültige Python-Versionen (< 3.11), unzulässige Kombinationen (`--lib --cli`), zu viele Verzeichnisse, ungültige Paketnamen und Python-Keywords werden abgelehnt. Keywords werden nach der Normalisierung geprüft, sodass auch `Class` und `IMPORT` abgelehnt werden.
- Zielpfad-Prüfung: Dateien, nicht-leere Verzeichnisse und ein fehlendes Template führen zu einem Abbruch, bevor etwas geschrieben wird.
- Beide Template-Runner sind syntaktisch gültig.
- Leerlauf-Semantik: `scripts/test-e2e.sh` und `scripts/test-agent.sh` beenden sich in einem Projekt ohne `test_*.py` mit Exit 0 und einem Hinweis. Ein Fake-`docker` bzw. Fake-`uv` im `PATH` protokolliert Aufrufe und beendet sich mit 99; bei leerer Suite darf keine Markerdatei entstehen.
- Rekursive Suche: Eine Testdatei unter `tests/e2e/cli/` bzw. `tests/agent/providers/` startet den jeweiligen Runner, obwohl direkt im Suite-Verzeichnis keine `test_*.py` liegt. Die Preflight-Suche importiert das Testmodul nicht (Markerdatei bleibt aus).
- Suchfehler: Ein Fake-`find`, der mit Exit 2 scheitert, muss beide Runner mit einer lauten Fehlermeldung und Exit 1 beenden, statt eine leere Suite zu melden.
- Build-Aufruf: In einem Projekt mit `test_*.py` und `tests/e2e/Dockerfile` beantwortet der Fake-`docker` nur `info` mit 0. Der Runner muss `build --file tests/e2e/Dockerfile` aufrufen; der Test prüft das Argument im Aufrufprotokoll, ohne Docker zu benötigen.
- Kopierfehler: Ein Fake-`docker`, der Build und Testlauf erfolgreich simuliert, aber `docker cp` scheitern lässt, muss den Runner mit einer sichtbaren Meldung und Exitcode 1 beenden.
- `pyinit --help` nennt `test-e2e` und `test-agent` sowie den MIT-Lizenzhinweis mit Autor-Fallback `Project Author`.
- Versionsgleichheit: `_LUPYSTA_VERSION` aus dem Stack-Script muss dem `version:`-Feld im Frontmatter von `lupysta/SKILL.md` entsprechen.
- ZSH-Prompt: Wenn `zsh` installiert ist, übersteht `prompt_my_jupyter` ein leeres Runtime-Verzeichnis und ein einzelnes Runtime-Dateimuster ohne `NOMATCH`-Abbruch.

### `test-pyinit.sh` (vollständig)

Zusätzlich Integrationstests mit temporären Projekten (werden am Ende gelöscht):

- **App** (`pyinit <dir> --python 3.12`): erzeugt `AGENTS.md` mit Projektprofil, Testing, ADR-Konventionen und Attention Points (Contract-Version 3); kein `SESSION.md`, keine alten Managed-Blocks. `just check`, `just rate-design run/save/compare` und `just clean` funktionieren; Baselines werden nicht überschrieben und von `clean` erhalten.
- **Opt-in-Gerüste**: `tests/conftest.py`, `tests/e2e/` (README, conftest, Dockerfile), `tests/agent/` (README, conftest), `scripts/test-e2e.sh`, `scripts/test-agent.sh` und `.dockerignore` existieren. `Justfile`, `pyproject.toml` (Marker, `e2e`-Gruppe), `.gitignore`, `README.md`, `CONTRIBUTING.md` und `.github/workflows/e2e.yml` enthalten die neuen Einträge. Das E2E-Dockerfile installiert das Projekt mit `--no-editable`; der Workflow lädt `e2e-artifacts.*/**` mit `actions/upload-artifact@v7` und `if: always()` hoch und schließt pytest-Tempdaten unter `work/**` aus. Beide Runner laufen im leeren Gerüst mit Exit 0; Fake-`docker`/`uv` beweisen, dass nichts aufgerufen wird.
- **Workflows**: Apps erhalten `ci.yml` und `e2e.yml`, aber kein `release.yml`. Beide Workflows laufen auf `main` und per Pull Request, lassen sich manuell starten, fordern `contents: read` und brechen veraltete Läufe ab (`cancel-in-progress: true`). `ci.yml` nutzt `actions/checkout@v7`, `astral-sh/setup-uv@v10`, `extractions/setup-just@v4` und ruft `just audit` auf. Bibliotheken erhalten zusätzlich `release.yml` mit Tag-Trigger, `environment: pypi`, `contents: read`, `id-token: write` und einer Prüfung, dass `v<version>` aus `pyproject.toml` zum Git-Tag passt. `.pre-commit-config.yaml` nutzt `rev: v6.0.0`.
- **LICENSE**: `LICENSE` wird als MIT erzeugt; die Next-Steps-Ausgabe weist auf die Prüfung von Lizenz und Autor hin.
- **Gate-Probe**: Eine `tests/e2e/test_gate_probe.py` bzw. `tests/agent/test_gate_probe.py` mit absichtlichem `AssertionError` verändert `just check` nicht; anschließend wird die Probe entfernt.
- **Import-Guard**: Ein temporäres Testmodul schreibt beim Import eine Markerdatei. Ein direktes `uv run pytest tests/e2e` bzw. `tests/agent` ohne Opt-in muss mit der Runner-Meldung (`use just test-e2e`/`use just test-agent`) fehlschlagen; die Markerdatei darf nicht entstehen. Das beweist, dass der Guard vor dem Modulimport greift.
- **Collection-Skips**: Ein Modul mit `pytest.skip(..., allow_module_level=True)` und ein bestandener Test lassen den opt-in-Lauf fehlschlagen. Beim Agenten wird die Skip-Meldung im Log nachgewiesen; mit Docker gilt dasselbe für die E2E-Suite. Anschließend werden die Proben entfernt.
- **E2E-Ausführung**: Wenn Docker verfügbar ist, führt `just test-e2e` die E2E-Probe wirklich aus und muss fehlschlagen. Der Log und der JUnit-Bericht unter `e2e-artifacts.*` müssen die Probemeldung enthalten; sonst wird dieser Teil übersprungen.
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

### `scripts/check-workflows.sh`

Prüft die Workflows unter `.github/workflows/` und `Luxus-Python-Stack/templates/workflows/` mit `actionlint`. Ist `actionlint` nicht im `PATH`, wird das offizielle Image `rhysd/actionlint:latest` per Docker verwendet. Fehlen beide, bricht das Skript mit einer klaren Meldung ab.

## Tests ausführen

Alle Befehle im Repository-Wurzelverzeichnis ausführen.

```shell
bash tests/test-pyinit.sh --fast          # schnelle Prüfungen, keine Projekte
bash tests/test-pyinit.sh                 # zusätzlich Integration mit generierten Projekten
bash tests/fresh-clone.sh                 # frischer Clone des letzten Commits
bash tests/scripts/check-links.sh         # relative Markdown-Links prüfen
bash tests/scripts/check-workflows.sh     # GitHub-Actions-Workflows linten
```

## Voraussetzungen

- `bash`, `git`, `python3` (für `check-links.sh`)
- `actionlint` oder Docker (für `check-workflows.sh`)
- `uv` und `just` für die Integrationstests
- Docker ist optional. Nur wenn `docker info` erfolgreich ist, prüft der volle Lauf zusätzlich, dass `just test-e2e` echte Tests im Container ausführt, Fehlschläge samt Probemeldung in Log und JUnit-Bericht festhält und Collection-Skips als Fehler behandelt; sonst werden diese Teile übersprungen.
- `zsh` ist optional und aktiviert zusätzlich den Jupyter-Prompt-Test
- Netzwerkzugriff kann für das Auflösen der Abhängigkeiten mit `uv` nötig sein
- `fresh-clone.sh` testet den **letzten Commit**; nicht committete Änderungen werden nicht geprüft.
