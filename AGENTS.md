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

## Qualitätsgate

- Vor und nach jeder Änderung `just check` ausführen: Bash-Syntax,
  ShellCheck, Shell-Tests, Link-Check und Workflow-Lint. Dieselben Prüfungen
  laufen in der CI; `just check` ist die lokale Entsprechung, kein Ersatz.
- Das Gate braucht `just`, Bash, Git, ShellCheck und Python 3. Der Workflow-Lint
  nutzt `actionlint` im PATH oder ersatzweise einen funktionierenden
  Docker-Daemon. Fehlt beides, den Rest einzeln ausführen
  (`just syntax shellcheck shell-tests links`).
- Markdown-Links relativ halten; der Link-Check prüft nur Dateien im
  Arbeitsbaum, keine externen URLs.
- ludesta ist kein `pyinit`-Projekt: Es gibt kein `journal/` und kein
  `docs/adr/`. Dauerhafte Entscheidungen stehen in den Stack-Dokumenten, die
  zusammen mit dem Skill gepflegt werden.
