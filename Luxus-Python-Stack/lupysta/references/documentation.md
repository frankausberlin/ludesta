# Dokumentation

Dokumentationsrezepte gelten nur, wenn `AGENTS.md` `docs-lib` oder `docs-cli`
nennt. Prüfe vor der Verwendung, ob die genannten `just`-Rezepte im Projekt
tatsächlich existieren.

## Varianten

| Feature | Projekttyp | Quelle | Ausgabe |
| --- | --- | --- | --- |
| `docs-lib` | Bibliothek | `mkdocs.yml`, `docs/`, Docstrings | Statische MkDocs-Seite. |
| `docs-cli` | App mit `--cli` | Typer-App in `src/<paket>/cli.py` | `docs/reference/cli.md`. |

Beide Varianten können in einem Projekt nicht gleichzeitig entstehen:
`docs-lib` gehört zur Bibliothek, `docs-cli` zur CLI-App.

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
