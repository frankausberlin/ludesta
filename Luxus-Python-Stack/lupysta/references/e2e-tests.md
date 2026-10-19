# E2E-Tests

Dieses Rezept ist ein Überblick. Die vollständige Umsetzung ist eine spätere
Stufe; im Kern erzeugt die Projektinitialisierung keine E2E-Suite. Lade dieses Rezept nur, wenn
`AGENTS.md` `e2e` als verwendet nennt und das Projekt die zugehörigen Dateien
tatsächlich enthält.

## Wann sinnvoll

- Das Verhalten hängt von echten externen Werkzeugen oder Betriebssystemzustand
  ab, der sich nicht glaubwürdig mocken lässt.
- Die paketierte oder installierte Anwendung soll geprüft werden, nicht nur
  der importierte Quellcode.
- Ein Wegwerf-Container kann alle Seiteneffekte isolieren.

Wenn ein gemockter Test das Verhalten beweisen kann, ist der gemockte Test
vorzuziehen. E2E-Tests sind langsamer, brauchen Docker und Netzwerk und sind
schwieriger deterministisch zu halten.

## Geplanter Aufbau

```text
tests/e2e/
├── conftest.py
├── Dockerfile
└── test_*.py
scripts/test-e2e.sh
```

- `just test-e2e` ruft den Runner auf.
- Der Runner prüft **zuerst** auf `test_*.py`-Dateien.
- Bei leerer Suite: klare Meldung und Exitcode 0, ohne Docker.
- Erst danach folgt der Docker-Preflight.

## Collection-Gate

Die Suite bleibt aus dem normalen `pytest`-Lauf heraus. Das Gate liegt in
`tests/conftest.py` und schließt das Verzeichnis selbst aus, nicht nur seine
Dateien:

```python
import os

collect_ignore = []
if os.environ.get("LUPYSTA_E2E") != "1":
    collect_ignore.append("e2e")
if os.environ.get("LUPYSTA_AGENT") != "1":
    collect_ignore.append("agent")
```

- `LUPYSTA_E2E=1` aktiviert die Suite.
- Der Runner setzt die Variable und adressiert `pytest tests/e2e`.
- Marker ergänzen das Gate, ersetzen es nicht.
- Keine optionalen Importe auf Modulebene; Importe in Fixtures oder Tests.
- `tests/conftest.py` gehört E2E und Agent gemeinsam und wird erst entfernt,
  wenn keines der beiden Features bleibt.

## Null-Test-Semantik

| Zustand | Verhalten |
| --- | --- |
| Keine `test_*.py`-Dateien | Meldung, Exitcode 0, kein Docker. |
| Dateien vorhanden, Collection fehlerhaft | Fehler, Exitcode ungleich 0. |
| Dateien vorhanden, Ausführung fehlerhaft | Fehler, Exitcode ungleich 0. |
| `pytest`-Exitcode 5 | Nur im echten Leerfall tolerieren. |

## Isolation

- Wegwerf-Container ohne Host-Mounts für veränderbare Daten.
- Kein privilegierter Modus und kein Host-Netzwerk ohne ausdrücklichen Bedarf.
- Temporäres `HOME`, `XDG_*` und Arbeitsverzeichnis im Container.
- Unprivilegierter Testnutzer; Root nur für Paketänderungen im Container.
- JUnit-Bericht und Logs unter einem definierten Artefaktpfad sammeln.
- Container und temporäre Daten auch im Fehlerfall aufräumen.

## Runner-Aufgaben

1. Testdateien prüfen; leere Suite erfolgreich melden.
2. Docker-Preflight mit klarer Fehlermeldung.
3. Image bauen; Abhängigkeiten vor dem Quellcode installieren.
4. Container starten, Tests ausführen, Artefakte einsammeln.
5. Aufräumen und Ergebnis melden.

## Status

Die Umsetzung erfolgt in einer späteren Stufe. Bis dahin gilt: keine
E2E-Befehle erfinden und keine Suite anlegen, wenn `AGENTS.md` `e2e` nicht
nennt.
