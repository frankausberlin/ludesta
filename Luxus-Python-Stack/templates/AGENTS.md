# AGENTS.md – @PROJECT_NAME@

Diese Datei enthält die projektbezogenen Informationen und Regeln. Die
Arbeitsweisen selbst stehen im lupysta-Skill; hier steht nur, was für dieses
Projekt gilt.

Verwende für die Entwicklung immer den lupysta-Skill.

## Projektprofil

- Projektname: `@PROJECT_NAME@`
- Paketname: `@PACKAGE_NAME@`
- Projekttyp: @PROJECT_TYPE@
- Python-Version: `@PYTHON_VERSION@`
- Quellpfad: `@SOURCE_PATH@`
- Testpfad: `tests/`

## ADRs

Architekturentscheidungen liegen als Dateien in `docs/adr/`. Verschaffe dir mit
`ls -1 docs/adr` einen Überblick, falls das Verzeichnis existiert.

* Dateiname: `NNNN-entscheidung.md`, zum Beispiel `0001-wir-verwenden-zsh.md`.
  Der Name nennt die Entscheidung, nicht nur das Thema.
* Ein `ADR`-Präfix im Dateinamen ist nicht nötig; das Verzeichnis benennt die
  Dokumentart.
* Der Name reicht für den Überblick; lies eine aktive ADR, wenn ihre
  Entscheidung die Aufgabe berührt.
* Revidierte Entscheidungen tragen ein `_`-Präfix, zum Beispiel
  `_0001-wir-verwenden-zsh.md`. Ihre Nummer bleibt vergeben.
* Der Status steht im Dokument: `accepted`, `superseded by ADR-NNNN` oder
  `deprecated`.

## Attention Points

<!--
Format eines Eintrags:

### AP-1: Kurztitel

- **Situation**: ...
- **Handhabung**: ...
- **Involvierte ADRs**: ...
- **Kontext**: ...
-->

## Herkunft

- lupysta_version: `@LUPYSTA_VERSION@`
- contract_version: `@CONTRACT_VERSION@`
