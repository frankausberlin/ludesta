# Workflow

Dieses Rezept beschreibt den Sitzungsablauf in einem initialisierten Projekt.
Es gilt, wenn `AGENTS.md` `core` nennt. `core` ist in jedem initialisierten
Projekt vorhanden.

## Sitzungsstart

1. `AGENTS.md` lesen: Projektprofil, Feature-Auswahl und lokale Regeln.
2. `SESSION.md` lesen, falls vorhanden.
3. Bei Bedarf die letzten Einträge in `JOURNAL.md` lesen.
4. `uv sync` ausführen, damit die Umgebung zum Lockfile passt.
5. `git status` und den aktuellen Branch prüfen.
6. Prüfen, ob die für die Aufgabe nötigen `just`-Rezepte tatsächlich
   existieren. Fehlende Features werden nicht vorausgesetzt.

## Arbeiten

- Kleine, überprüfbare Änderungen machen.
- Vor und nach jeder Änderung `just check` ausführen.
- Keine Tests, Lint-Regeln oder Typprüfungen abschwächen, um Fehler zu
  verstecken.
- Generierte Dokumentation nur über den Generator aktualisieren.
- Bei Unklarheiten den Projektzustand prüfen, nicht raten.

## Branch und Commit

- Auf einem Branch arbeiten: `feat/...`, `fix/...`, `docs/...`,
  `refactor/...` oder `chore/...`.
- Ein separater Worktree ist optional, aber für längere Arbeiten sinnvoll.
- Vor dem Commit `just check` grün haben.
- Commit-Nachrichten beschreiben die Änderung, zum Beispiel
  `feat: add CSV export`.
- Agenten pushen nie. Der Maintainer prüft und veröffentlicht.

## Sitzungsende

1. `just check` ausführen; das Gate muss grün sein.
2. `SESSION.md` mit dem aktuellen Stand **überschreiben** (flüchtig).
3. Einen datierten Eintrag an `JOURNAL.md` **anhängen**; die Historie wird
   niemals überschrieben.
4. Alle beabsichtigten Änderungen auf dem Branch committen.
5. Lokal mit `just merge [branch]` mergen, wenn der Branch fertig ist.
   Einzelheiten stehen in [`git-release.md`](git-release.md).

## SESSION.md und JOURNAL.md

| Datei | Zweck | Regel |
| --- | --- | --- |
| `SESSION.md` | Zustand der letzten Sitzung | Bei jedem Sitzungsende überschreiben. |
| `JOURNAL.md` | Chronik der Sitzungen | Nur anhängen, nie überschreiben. |

Beide Dateien sind in erzeugten Projekten gitignored und gehören zum lokalen
Arbeitszustand. Sie werden nicht committed.

## Typische Fehler

| Symptom | Ursache | Vorgehen |
| --- | --- | --- |
| `ModuleNotFoundError` | Umgebung nicht synchron | `uv sync` ausführen oder `uv run` verwenden. |
| `just check` schlägt fehl | Änderung oder Umgebung | Fehler lesen, `just fix`, Rest manuell beheben. |
| Falscher Branch | Vor dem Commit nicht geprüft | `git status` und `git branch --show-current` prüfen. |
| `just merge` findet keinen Branch | Kein oder mehrere Kandidaten | Branch explizit übergeben: `just merge <branch>`. |
