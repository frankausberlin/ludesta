# AGENTS.md – ludesta

Diese Datei enthält die projektbezogenen Regeln für die Arbeit in ludesta.

## Git-Arbeitsweise

- **Immer auf `main`.** Vor jeder Änderung und spätestens am Ende jeder Aufgabe
  ist `main` ausgecheckt. Der Arbeitsbaum darf nicht auf einem Feature-Branch
  stehen bleiben.
- Feature-Branches nur, wenn ausdrücklich verlangt. Ein fertiger Branch wird
  lokal per Fast-Forward nach `main` gemergt und danach gelöscht; `main` bleibt
  ausgecheckt.
- **Niemals von einem Feature-Branch veröffentlichen.** Vor Commit und Publish
  mit `git status --short --branch` und `git log --oneline -1 --decorate`
  prüfen, dass `main` aktiv ist. Agenten pushen nicht; die Veröffentlichung ist
  ein Schritt des Maintainers.
- Keine destruktiven Git-Befehle: kein Force-Push, kein `reset --hard` auf
  fremde Arbeit, keine ungefragte Worktree-Entfernung.
