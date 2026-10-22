# E2E-Tests (Docker)

Dieses Verzeichnis ist das Gerüst für die opt-in Docker-Suite. Es enthält
bewusst noch keine `test_*.py`-Dateien. `just test-e2e` meldet in diesem
Zustand einen Hinweis und beendet sich mit Exitcode 0, ohne Docker aufzurufen.

## Zweck

E2E-Tests prüfen die Anwendung in einem Wegwerf-Container: das installierte
Paket, echte externe Werkzeuge und Seiteneffekte, die sich nicht glaubwürdig
mocken lassen. Der Container liefert Isolation und reproduzierbare
Abhängigkeiten aus `uv.lock`.

## Abgrenzung

- Unit- und Smoke-Tests liegen unter `tests/` und laufen in `just check`.
- `tests/e2e/` wird von `tests/conftest.py` aus dem normalen pytest-Lauf
  ausgeschlossen, solange `LUPYSTA_E2E` nicht `1` ist.
- E2E-Tests sind langsam und brauchen Docker. Sie sind kein Ersatz für schnelle
  deterministische Tests.

## Aufbau

```text
tests/e2e/
├── README.md
├── conftest.py
├── Dockerfile
└── test_*.py        # fügst du hinzu
scripts/test-e2e.sh
```

- `Dockerfile` baut das Image aus `pyproject.toml`, `uv.lock`, `src/` und
  `tests/`. Die Abhängigkeiten werden vor dem Quellcode installiert.
- `conftest.py` bricht ab, bevor pytest die Testmodule importiert, wenn die
  Suite ohne Opt-in, außerhalb des Containers oder ohne `/.dockerenv` läuft.
  Skips – auch Collection-Skips – werden im Container zu Fehlern.
- `scripts/test-e2e.sh` prüft zuerst die Testdateien, dann Docker, baut das
  Image mit `--file tests/e2e/Dockerfile`, startet den Container und sammelt
  die Artefakte ein.
- `scripts/test-e2e.sh` verwendet BuildKit (`--mount=type=cache`).

## Leerlauf-Semantik

| Zustand | Verhalten |
| --- | --- |
| Keine `test_*.py`-Dateien | Hinweis, Exitcode 0, kein Docker. |
| Dateien vorhanden, Docker fehlt | Laute Fehlermeldung, Exitcode 1. |
| Dateien vorhanden, Test schlägt fehl | Exitcode 1 mit Log-Auszug. |
| Test oder Modul wird übersprungen | Fehler im Container, kein stiller grüner Lauf. |

## Erster Test

1. Docker und BuildKit bereitstellen: `docker info`, `docker buildx version`.
2. Eine Datei `tests/e2e/test_demo.py` mit einer normalen `test_`-Funktion
   anlegen. Der Collection-Hook in `conftest.py` schützt den Lauf, bevor
   Testmodule importiert werden.
3. `just test-e2e` ausführen. Der Runner setzt `LUPYSTA_E2E=1` und
   `LUPYSTA_E2E_CONTAINER=1`, baut das Image und startet den Container.
4. Fehler zuerst im Log unter `e2e-artifacts.*/run.log` suchen.

## Isolation und Artefakte

- Kein Host-Netzwerk (`--network none`), keine Host-Mounts für veränderbare
  Daten.
- Unprivilegierter Nutzer `e2e` (uid 10001), Arbeitsverzeichnis `/app`.
- JUnit-Bericht und Logs landen unter `/artifacts` und werden nach
  `e2e-artifacts.*` kopiert; der Pfad wird am Ende ausgegeben.
- `just clean` entfernt diese Artefakte.

## Grenzen

- Kein Sharding, kein Attach-Modus und keine vorgefertigten Szenarien.
- Das Gerüst ist minimal; projekt- und werkzeugspezifische Fixtures gehören in
  dieses Verzeichnis.
- `just check` führt keine E2E-Tests aus. Details stehen in `AGENTS.md` und im
  lupysta-Rezept `e2e-tests`.
