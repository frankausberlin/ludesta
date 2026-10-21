# Dokumentation

Dokumentationsrezepte gelten, wenn das Projekt `docs`-Rezepte im `Justfile`
anbietet. Bibliotheken nutzen MkDocs, CLI-Apps eine generierte Referenz.
Prüfe vor der Verwendung die tatsächlich vorhandenen Befehle.

## Varianten

| Variante | Projekttyp | Quelle | Ausgabe |
| --- | --- | --- | --- |
| MkDocs | Bibliothek | `mkdocs.yml`, `docs/`, Docstrings | Statische MkDocs-Seite. |
| CLI-Referenz | App mit `--cli` | Typer-App in `src/<paket>/cli.py` | `docs/reference/cli.md`. |

Eine Bibliothek nutzt MkDocs, eine CLI-App die generierte Referenz; beide
Varianten entstehen im selben Projekt nicht gleichzeitig.

## Befehle

```shell
just docs         # Dokumentation bauen bzw. generierte Seite neu erzeugen
just docs-check   # prüfen, ob die Dokumentation aktuell ist (Teil von `just check`)
just docs-serve   # Live-Vorschau (nur Bibliotheken)
```

`just docs-check` ist bei vorhandener Dokumentation Teil von `just check`.
Ein veralteter Generatorstand lässt das Gate fehlschlagen.

## Generierte Seiten

- `docs/reference/cli.md` wird aus der Typer-App erzeugt.
- Generierte Seiten tragen einen Hinweis am Dateianfang.
- Generierte Seiten niemals von Hand bearbeiten.
- Stattdessen `just docs` ausführen und das Ergebnis committen.
- Bei Änderungen an CLI-Befehlen, Hilfetexten oder Docstrings die
  Dokumentation neu erzeugen.

## Bibliotheken

- `mkdocs.yml` und `docs/` gehören zum Projekt.
- `mkdocstrings` liest die öffentliche API aus den Docstrings.
- Öffentliche Funktionen und Klassen brauchen Google-Style-Docstrings.
- `just docs-serve` startet eine lokale Vorschau mit Live-Reload.
- ADRs unter `docs/adr/` sind absichtlich nicht Teil der Navigation. Wenn
  `docs-check` sie beanstandet, in `mkdocs.yml` über `not_in_nav` ausschließen
  oder in die Navigation aufnehmen.

## CLI-Apps

- `scripts/gen_cli_docs.py` ist der Generator.
- Die Quelle der Wahrheit ist die Typer-App, nicht die Markdown-Seite.
- `just docs` schreibt die Seite, `just docs-check` prüft sie ohne Schreiben.
- Nach dem Hinzufügen oder Ändern eines Befehls `just docs` ausführen.

## Fehlerbilder

| Symptom | Vorgehen |
| --- | --- |
| `docs-check` meldet eine veraltete Seite | `just docs` ausführen und die Änderung committen. |
| MkDocs bricht ab | Fehlermeldung lesen; fehlende Dateien oder ungültige `mkdocs.yml` prüfen. |
| Typer-Generator scheitert | Importfehler in `cli.py` beheben; danach `just docs` erneut ausführen. |
| `docs-serve` fehlt | Nur Bibliotheken haben dieses Rezept. |
