# Agent-Tests

Status: Das Skelett wird von `pyinit` erzeugt; der Harness ist
projektspezifisch.

`pyinit` legt für App, Bibliothek und CLI-App ein Gerüst unter `tests/agent/`
an. Es enthält bewusst keine `test_*.py`-Dateien, keinen Provider-Adapter und
keinen Harness. Echte Agent-Tests werden nicht generiert.

## Wann sinnvoll

- Das Projekt enthält einen Agenten oder eine agentische Schnittstelle, deren
  Verhalten sich nur mit einem Modell oder Provider realistisch prüfen lässt.
- Deterministische Tests und das Quality Gate sind bereits grün.
- Ein begrenzter, reproduzierbarer Lauf mit klaren Kosten- und Zeitlimits ist
  möglich.

Agent-Tests ergänzen das deterministische Gate; sie ersetzen es nicht.
Modellabhängige Qualität ist keine stabile Release-Bedingung.

## Struktur

```text
tests/
├── conftest.py              # Verzeichnis-Gate für e2e und agent
└── agent/
    ├── README.md
    ├── conftest.py          # Opt-in-Guard, Fail-on-Skips
    └── test_*.py            # projektseitig ergänzt
scripts/test-agent.sh
```

- `just test-agent` ruft `scripts/test-agent.sh` auf.
- Der Runner prüft **zuerst** auf `test_*.py`-Dateien.
- Bei leerer Suite: klare Meldung und Exitcode 0, ohne `uv` und ohne Provider.
- Erst danach folgt der Lauf mit `LUPYSTA_AGENT=1`.

## Collection-Gate

Das Gate liegt in `tests/conftest.py` und schließt `agent` nur aus, wenn
`LUPYSTA_AGENT` nicht auf `1` gesetzt ist. Einzelheiten stehen in
[`e2e-tests.md`](e2e-tests.md). `tests/agent/conftest.py` schlägt fehl, wenn die
Suite trotzdem ohne Opt-in gesammelt wird; im opt-in-Lauf werden Skips zu
Fehlern.

## Provider-Preflight

Vor einem Lauf mit echten Tests prüfen:

- Endpoint und Modell sind konfiguriert.
- Zugangsdaten sind vorhanden.
- Zeit-, Schritt- und Kostenlimits sind gesetzt.
- Ein fehlender Provider ist ein lauter Fehler, kein stiller Skip.

Der Preflight gehört in den projektspezifischen Harness, nicht in das
generierte Skelett.

## Limits

Jeder Lauf braucht mindestens:

- ein Zeitlimit,
- ein Schrittlimit,
- einen definierten Abbruch bei Limitverletzung,
- eine Aufzeichnung des Abbruchs im Report.

## Report und Transkript

Der Report enthält mindestens:

- Status des Laufs,
- Szenario und Modell,
- Limitverletzungen,
- Verweis auf das Transkript,
- `preflight_error` als eigenen Status, wenn die Voraussetzungen fehlen.

Das Transkript wird unter einem gitignored Artefaktpfad abgelegt.

## Fake-Provider

Fake-Provider-Tests decken ohne Live-Modell ab:

- Limitverletzungen,
- Fehlerpfade,
- Report-Schema,
- Abbruch und Aufräumen.

Ein Live-Lauf wird manuell dokumentiert und ist kein Release-Gate.

## Erster Test

1. Harness und Provider-Preflight implementieren.
2. Ein Szenario unter `tests/agent/test_*.py` ergänzen.
3. `just test-agent` ausführen.
4. Kosten, Laufzeit und Ergebnis dokumentieren.

## Grenzen

- Agent-Tests laufen nie in der CI.
- Das Gerüst ist kein funktionierender Harness; ein grüner Lauf vor der
  Implementierung ist nicht zu erwarten.
- Details zum Gate stehen in [`e2e-tests.md`](e2e-tests.md).
