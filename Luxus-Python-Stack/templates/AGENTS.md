# AGENTS.md – @PROJECT_NAME@

Diese Datei wurde einmalig bei der Projektinitialisierung erzeugt. Sie
beschreibt die Projektauswahl für den lupysta-Skill. Die Arbeitsweisen selbst
stehen im installierten lupysta-Skill; hier steht nur, was in diesem Projekt
gilt.

## Projektprofil

- Projektname: `@PROJECT_NAME@`
- Paketname: `@PACKAGE_NAME@`
- Projekttyp: @PROJECT_TYPE@
- Python-Version: `@PYTHON_VERSION@`
- Quellpfad: `@SOURCE_PATH@`
- Testpfad: `tests/`
- @ENTRY_KIND@: `@ENTRY_PATH@` — @ENTRY_NOTE@

## Projektfeatures

Verwendet: @FEATURES_USED@

Nicht verwendet: @FEATURES_UNUSED@

<!-- `e2e` und `agent` sind vorgesehen, werden in der Basisversion aber nicht erzeugt. -->

Die Feature-Liste ist die einzige Auswahl. Fehlende Features werden nicht
vorausgesetzt und nicht ungefragt nachgebaut. Vor der Verwendung eines
Befehls prüfen, ob er im `Justfile` tatsächlich vorhanden ist.

## Wichtige Befehle

- Qualitätsgate: `just check`
- Design-Report: `just rate-design run`, `just rate-design save <name>`,
  `just rate-design compare <name>`

## Lokale Regeln

<!-- Projektlokale Regeln hier ergänzen. -->

## Herkunft

- lupysta_version: `@LUPYSTA_VERSION@`
- contract_version: `@CONTRACT_VERSION@`
