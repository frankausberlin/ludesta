# E2E-Tests

Status: wird von `pyinit` erzeugt; die Suite ist opt-in.

`pyinit` legt für App, Bibliothek und CLI-App ein Docker-Gerüst unter
`tests/e2e/` an. Es enthält bewusst keine `test_*.py`-Dateien. Echte
E2E-Tests sind projektspezifisch und werden nicht generiert.

## Wann sinnvoll

- Das Verhalten hängt von echten externen Werkzeugen oder Betriebssystemzustand
  ab, der sich nicht glaubwürdig mocken lässt.
- Die paketierte oder installierte Anwendung soll geprüft werden, nicht nur
  der importierte Quellcode.
- Ein Wegwerf-Container kann alle Seiteneffekte isolieren.

Wenn ein gemockter Test das Verhalten beweisen kann, ist der gemockte Test
vorzuziehen. E2E-Tests sind langsamer, brauchen Docker und Netzwerk und sind
schwieriger deterministisch zu halten.

## Struktur

```text
tests/
├── conftest.py              # Verzeichnis-Gate für e2e und agent
└── e2e/
    ├── README.md
    ├── conftest.py          # Guard vor dem Import, Fail-on-Skips
    ├── Dockerfile
    └── test_*.py            # projektsepezifisch
scripts/test-e2e.sh
```

- `just test-e2e` ruft `scripts/test-e2e.sh` auf.
- Der Runner prüft **zuerst** auf `test_*.py`-Dateien.
- Bei leerer Suite: klare Meldung und Exitcode 0, ohne Docker und ohne `uv`.
- Erst danach folgt der Docker-Preflight.

## Collection-Gate

Die Suite bleibt aus dem normalen `pytest`-Lauf heraus. Das Gate liegt in
`tests/conftest.py` und schließt das Verzeichnis selbst aus, nicht nur seine
Dateien:

```python
import os

collect_ignore: list[str] = []
if os.environ.get("LUPYSTA_E2E") != "1":
    collect_ignore.append("e2e")
if os.environ.get("LUPYSTA_AGENT") != "1":
    collect_ignore.append("agent")
```

- `LUPYSTA_E2E=1` aktiviert die Suite.
- Der Runner setzt die Variable und adressiert `pytest tests/e2e`.
- Marker sind in `pyproject.toml` registriert, ersetzen das Gate aber nicht.
- Keine optionalen Importe auf Modulebene; Importe in Fixtures oder Tests.
- `tests/conftest.py` gehört E2E und Agent gemeinsam und wird erst entfernt,
  wenn keine der beiden Suiten bleibt.

## Guard in der Suite

`tests/e2e/conftest.py` bricht über `pytest_collectstart` ab, bevor pytest ein
Testmodul importiert, wenn die Suite ohne Opt-in, ohne Container-Umgebung oder
ohne `/.dockerenv` gesammelt wird. Der Abbruch ist ein echter Fehler, kein
Skip. Ein Skip ist kein Ersatz: Im Container werden Skips bei der Ausführung
und beim Sammeln zu Fehlern. So bleibt ein Bypass laut.

## Null-Test-Semantik

| Zustand | Verhalten |
| --- | --- |
| Keine `test_*.py`-Dateien | Meldung, Exitcode 0, kein Docker. |
| Dateien vorhanden, Docker fehlt | Laute Fehlermeldung, Exitcode 1. |
| Dateien vorhanden, Collection fehlerhaft | Fehler, Exitcode ungleich 0. |
| Dateien vorhanden, Ausführung fehlerhaft | Fehler, Exitcode ungleich 0. |
| Test wird bei der Ausführung übersprungen | Fehler im Container. |
| Modul wird beim Sammeln übersprungen | Fehler im Container. |

## Runner-Ablauf

1. Testdateien prüfen; leere Suite erfolgreich melden.
2. Docker-Preflight: `docker` vorhanden und `docker info` erfolgreich.
3. `tests/e2e/Dockerfile` prüfen.
4. Python-Version aus `.python-version` lesen und auf `X.Y` normalisieren.
5. Image mit `--file tests/e2e/Dockerfile` bauen; Abhängigkeiten werden vor dem
   Quellcode installiert.
6. Container ohne Netzwerk starten, Tests ausführen, Artefakte einsammeln.
7. Container und temporäre Daten auch im Fehlerfall aufräumen.

Kein Sharding, kein Attach-Modus und keine vorgefertigten Szenarien: Das Gerüst
ist bewusst minimal.

## Erster Test

1. Docker und BuildKit bereitstellen (`docker info`, `docker buildx version`).
2. `tests/e2e/test_demo.py` mit einer normalen `test_`-Funktion anlegen.
3. `just test-e2e` ausführen.
4. Log und JUnit-Bericht unter `e2e-artifacts.*` auswerten.

## Isolation

- Wegwerf-Container ohne Host-Mounts für veränderbare Daten.
- Kein privilegierter Modus und kein Host-Netzwerk ohne ausdrücklichen Bedarf.
- Unprivilegierter Testnutzer `e2e` (uid 10001), Arbeitsverzeichnis `/app`.
- JUnit-Bericht und Logs unter `/artifacts` sammeln.
- Container und temporäre Daten auch im Fehlerfall aufräumen.

## CI

`pyinit` erzeugt `.github/workflows/e2e.yml`. Der Job führt `just test-e2e`
aus. Solange die Suite leer ist, endet er in Sekunden ohne Docker-Build.
Sobald echte Tests existieren, steigen Build-Zeit und Netzwerkbedarf.

## Grenzen

- E2E-Tests sind nicht Teil von `just check`/`just test`.
- `just check` sammelt sie dank `collect_ignore` nicht.
- Die Suite ist kein Ersatz für schnelle deterministische Tests.
