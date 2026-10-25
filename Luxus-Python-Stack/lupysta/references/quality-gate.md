# Quality Gate

Das Qualitätsgate ist der zentrale Prüfpunkt des Projekts. Es gilt für jedes
initialisierte Projekt; zusätzliche Prüfungen ergeben sich aus den vorhandenen
`just`-Rezepten.

## `just check`

`just check` führt die vorhandenen Prüfungen in dieser Reihenfolge aus:

1. `ruff check .`
2. `ruff format --check .`
3. `basedpyright`
4. `just docs-check`, falls das Rezept existiert
5. `pytest --cov=src --cov-report=term-missing`

Das Gate muss vor und nach jeder Änderung grün sein. Ein rotes Gate wird
nicht durch Abschwächen der Prüfungen repariert, sondern durch Beheben der
Ursache.

## Einzelne Befehle

| Befehl | Wirkung |
| --- | --- |
| `just check` | Vollständiges Gate. |
| `just fix` | Ruff automatisch korrigieren und formatieren. |
| `just test` | Unit-/Smoke-Tests mit Coverage-Bericht. |
| `just test-e2e` | Opt-in Docker-Suite; nicht Teil von `just check`. |
| `just test-agent` | Opt-in Provider-Suite; nicht Teil von `just check` und nie in CI. |
| `just lint` | Ruff plus basedpyright. |
| `just typecheck` | Nur basedpyright. |
| `just audit` | Abhängigkeiten auf bekannte Sicherheitslücken prüfen. |
| `just clean` | Caches und generierte Artefakte entfernen; `.refactor/baselines/` bleibt erhalten. |

`just clean` löscht keine Quellen, keine `.venv` und keine `JOURNAL.md`.

## Fehlersuche

1. Fehlermeldung vollständig lesen; nicht nur die letzte Zeile.
2. Prüfen, ob der Fehler in `src/` oder in einer Abhängigkeit entsteht.
3. Fehler reproduzieren: einen Regressionstest schreiben, der ohne den Fix
   fehlschlägt (`uv run pytest -k <name> -s`).
4. `just fix` nur für automatisch behebbare Lint- und Formatfehler verwenden.
5. Die Ursache beheben, nicht das Symptom.
6. `just check` erneut ausführen; der Regressionstest ist mit dem Fix grün.

## Häufige Fehler

| Symptom | Ursache | Vorgehen |
| --- | --- | --- |
| `ModuleNotFoundError` | Umgebung nicht synchron | `uv sync` oder `uv run` verwenden. |
| Ruff-Fehler | Stil oder echte Regelverletzung | `just fix`; verbleibende Fehler manuell beheben. |
| basedpyright-Fehler | Typen unvollständig | Typen ergänzen, keine `# type: ignore` als Standardlösung. |
| Coverage unter 90 % | Tests fehlen | Verhalten testen, nicht die Schwelle senken. |
| `docs-check` rot | Generierte Seite veraltet | [`documentation.md`](documentation.md) befolgen. |
| `just audit` rot | Verwundbare Abhängigkeit | Abhängigkeit aktualisieren oder Risiko dokumentieren. |

## Grenzen

- Das Gate ersetzt keine fachliche Prüfung.
- Ein grünes Gate bedeutet nicht, dass die Änderung fachlich richtig ist.
- E2E- und Agent-Suiten sind nicht Teil von `just check`; sie werden separat
  mit `just test-e2e` bzw. `just test-agent` ausgeführt.
- Bei leerer Suite melden beide Runner einen Hinweis und Exitcode 0. Sobald
  `test_*.py`-Dateien existieren, sind Fehler echte Fehler.

