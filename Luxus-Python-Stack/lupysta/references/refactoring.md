# Refactoring

Refactoring ist messbar und schrittweise. Dieses Rezept gilt, wenn das Projekt
`rate-design`- und `refactor`-Rezepte im `Justfile` anbietet. Prüfe vor der
Verwendung die tatsächlich vorhandenen Befehle.

## Zuerst messen

```shell
just rate-design run              # aktuellen Bericht schreiben
just rate-design save <name>      # Baseline unveränderlich sichern
just rate-design compare <name>   # aktuellen Lauf mit der Baseline vergleichen
```

- `run` schreibt `.refactor/report.json` und `.refactor/report.md`.
- `save <name>` legt `.refactor/baselines/<name>/` an und überschreibt eine
  vorhandene Baseline nie.
- `compare <name>` vergleicht Messwerte und meldet Regressionen. Es ändert
  keinen Anwendungscode.
- Ein `incomplete`-Marker zeigt an, dass eine Messung abgebrochen wurde.
  In diesem Zustand nicht refaktorieren; zuerst die Messung reparieren.
- Metriken sind Hinweise, keine Beweise. Ein hoher Komplexitätswert ist ein
  Prüfauftrag, keine automatische Freigabe für Umbauten.

## Sitzung vorbereiten

```shell
just refactor <slug>
```

Das Rezept:

1. verlangt einen sauberen Arbeitsbaum,
2. führt `just check` aus,
3. sichert eine Baseline unter `.refactor/baselines/<slug>/`,
4. erstellt den Branch `refactor/<slug>`,
5. ändert keinen Anwendungscode.

Ohne Slug wird ein Zeitstempel verwendet. Der Branch ist der Arbeitsbereich
für die folgenden Schritte; ein separater Worktree ist optional.

## Ein Rezept pro Schritt

1. Ein Refactoring-Rezept aus [`refactoring-recipes.md`](refactoring-recipes.md)
   auswählen.
2. Preconditions prüfen.
3. Den kleinsten sinnvollen Schritt umsetzen.
4. `just check` ausführen.
5. Bei grünem Gate committen.
6. Bei rotem Gate den Schritt korrigieren oder zurücknehmen; nicht das Gate
   abschwächen.
7. Nach jedem Schritt `just rate-design compare <slug>` ausführen, wenn eine
   Baseline vorhanden ist.

## Grenzen

- Keine Verhaltensänderung ohne eigenen Test und eigene Freigabe.
- Keine Tests löschen oder abschwächen, um ein Refactoring zu ermöglichen.
- Keine öffentlichen APIs ohne ausdrückliche Entscheidung umbenennen.
- Keine großflächigen Umformatierungen mit inhaltlichen Änderungen mischen.
- Keine destruktiven Git-Befehle.
- Kein Refactoring auf rotem Gate oder mit `incomplete`-Messung.

## Abschluss

- `just check` ist grün.
- Die Änderungen sind in kleinen Commits dokumentiert.
- Ein Journal-Eintrag unter `journal/` ist angelegt und
  [`session-close.md`](session-close.md) wurde ausgeführt.
- Der Branch wird über [`git-release.md`](git-release.md) gemergt.
