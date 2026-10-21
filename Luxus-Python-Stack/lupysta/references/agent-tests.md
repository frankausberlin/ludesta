# Agent-Tests

Status: vorgesehen — nicht Teil der Basisversion.

Dieses Rezept ist ein Überblick. Die vollständige Umsetzung ist eine spätere
Stufe nach einem Go/No-Go; im Kern erzeugt die Projektinitialisierung keine
Agent-Suite. Lade
dieses Rezept nur, wenn `AGENTS.md` `agent` als verwendet nennt und das
Projekt die zugehörigen Dateien tatsächlich enthält.

## Wann sinnvoll

- Das Projekt enthält einen Agenten oder eine agentische Schnittstelle, deren
  Verhalten sich nur mit einem Modell oder Provider realistisch prüfen lässt.
- Deterministische Tests und das Quality Gate sind bereits grün.
- Ein begrenzter, reproduzierbarer Lauf mit klaren Kosten- und Zeitlimits ist
  möglich.

Agent-Tests ergänzen das deterministische Gate; sie ersetzen es nicht.
Modellabhängige Qualität ist keine stabile Release-Bedingung.

## Geplanter Aufbau

```text
tests/agent/
├── conftest.py
├── agent.toml
└── test_*.py
```

- `just test-agent` ruft den Runner auf.
- Der Runner prüft **zuerst** auf `test_*.py`-Dateien.
- Bei leerer Suite: klare Meldung und Exitcode 0, ohne Provider.
- Erst danach folgt der Provider-Preflight.

## Collection-Gate

Das Gate liegt in `tests/conftest.py` und schließt `agent` nur aus, wenn
`LUPYSTA_AGENT` nicht auf `1` gesetzt ist. Einzelheiten stehen in
[`e2e-tests.md`](e2e-tests.md).

## Provider-Preflight

Vor einem Lauf mit echten Tests prüfen:

- Endpoint und Modell sind konfiguriert.
- Zugangsdaten sind vorhanden.
- Zeit-, Schritt- und Kostenlimits sind gesetzt.
- Ein fehlender Provider ist ein lauter Fehler, kein stiller Skip.

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

## Status

Die Umsetzung erfolgt in einer späteren Stufe nach einem Go/No-Go. Bis dahin
gilt: keine Agent-Befehle erfinden und keine Suite anlegen, wenn `AGENTS.md`
`agent` nicht nennt.
