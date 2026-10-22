---
name: lupysta
description: >
  Arbeitsweise für bereits initialisierte Python-Projekte des
  Luxus-Python-Stacks: Qualitätsgate, Dokumentation, Git und Release,
  Refactoring, Projektjournal, ADRs und Attention Points. E2E- und
  Agent-Tests sind vorgesehen, aber nicht Teil der Basisversion.
version: 0.8.0
platforms: [linux]
metadata:
  tags: [python, uv, quality-gate, refactoring, adr]
---

# lupysta

## Zweck und Grenzen

Dieser Skill beschreibt, **wie** in einem bereits initialisierten Projekt
gearbeitet wird. Er erzeugt keine Projekte und richtet keine Umgebung ein:
Projektinitialisierung, Shell-Funktionen und Systemeinrichtung sind nicht
Teil dieses Skills.

Die dauerhaft relevanten Projektdateien sind `AGENTS.md` (Profil, ADRs,
Attention Points), `JOURNAL.md` (Sitzungsgedächtnis) und `docs/adr/`
(Architekturentscheidungen). Alles Weitere wird nur bei Bedarf geladen.

## Sitzungsstart

1. `AGENTS.md` lesen: Projektprofil, ADR-Konventionen und Attention Points.
2. Den letzten Eintrag in `JOURNAL.md` lesen, falls vorhanden.
3. `docs/adr/` sichten, falls vorhanden; die Dateinamen genügen für den
   Überblick.
4. `uv sync` ausführen.
5. `git status` prüfen und den aktuellen Branch verstehen.
6. Nur die Rezepte laden, die zur Aufgabe passen.

## Grundregeln

- **`AGENTS.md` ist die Projektquelle.** Sie enthält die projektbezogenen
  Regeln, die ADR-Konventionen und die Attention Points.
- **`just check` grün halten.** Vor und nach jeder Änderung gilt das
  Qualitätsgate des Projekts.
- **Tests, Lint und Typen nicht abschwächen**, um Fehler zu verstecken.
- **Generierte Dokumentation nicht von Hand ändern.** Stattdessen den
  Generator ausführen und das Ergebnis committen.
- **Agenten pushen nie.** Der Maintainer prüft und veröffentlicht.
- **Keine destruktiven Git-Befehle.** Kein Force-Push, kein `reset --hard` auf
  fremde Arbeit, keine ungefragte Worktree-Entfernung.
- **Am Ende jeder erfüllten Aufgabe** den Abschnitt
  [Sitzungsende](#sitzungsende) ausführen.

## Sitzungsende

1. `just check` ausführen; das Gate muss grün sein.
2. [`references/session-close.md`](references/session-close.md) ausführen:
   `JOURNAL.md` fortschreiben, ADR- und Attention-Point-Kandidaten prüfen und
   bei Bedarf anlegen.
3. Alle beabsichtigten Änderungen auf dem Branch committen; ADRs und Attention
   Points gehören in denselben Commit. `JOURNAL.md` bleibt lokal.
4. Den fertigen Branch lokal mit `just merge [branch]` mergen; Einzelheiten
   stehen in [`references/git-release.md`](references/git-release.md).

## Rezeptindex

| Rezept | Inhalt |
| --- | --- |
| [`references/session-close.md`](references/session-close.md) | Aufgabenabschluss: ADR- und Attention-Point-Kandidaten prüfen, `JOURNAL.md` fortschreiben. |
| [`references/quality-gate.md`](references/quality-gate.md) | `just check`, `fix`, `test`, `lint`, `typecheck`, `audit`, `clean` und Fehlersuche. |
| [`references/documentation.md`](references/documentation.md) | `docs`, `docs-check`, `docs-serve` und generierte Seiten. |
| [`references/git-release.md`](references/git-release.md) | Worktree, `just merge`, `bump`, CI und Veröffentlichung. |
| [`references/refactoring.md`](references/refactoring.md) | `rate-design run\|save\|compare`, `refactor`, Baseline und ein Rezept pro Schritt. |
| [`references/refactoring-recipes.md`](references/refactoring-recipes.md) | Extract Function, Rename Internal Symbol und Remove Confirmed Dead Code. |
| [`references/e2e-tests.md`](references/e2e-tests.md) | Vorgesehene Docker-Suite; nur laden, wenn das Projekt `tests/e2e/` enthält. |
| [`references/agent-tests.md`](references/agent-tests.md) | Vorgesehene Provider-Suite; nur laden, wenn das Projekt `tests/agent/` enthält. |

## Laden auf Bedarf

Lade ein Rezept erst, wenn die Aufgabe es verlangt. Prüfe vor der Verwendung
die tatsächlich vorhandenen Befehle im `Justfile` und die Projektdateien.
Weicht der Projektzustand von `AGENTS.md` ab, melde die Abweichung, statt sie
stillschweigend zu reparieren oder neu anzulegen.

E2E- und Agent-Tests sind nicht Teil der Basisversion. Ihre Einrichtung ist
ein eigener Auftrag; der Skill beschreibt nur die Arbeit mit einer bereits
vorhandenen Suite.

## Tägliche Entwicklungsbefehle

```shell
uv add <package>          # Laufzeitabhängigkeit
uv add --dev <package>    # Abhängigkeit nur für die Entwicklung
uv sync                   # Umgebung synchronisieren
just run                  # Hauptskript ausführen (nur Apps)
just test                 # pytest mit Coverage
just lint                 # ruff + basedpyright
just typecheck            # nur Typprüfung
just check                # vollständiges Qualitätsgate (Lint + Typecheck + Docs + Tests)
just fix                  # automatische Korrektur
just clean                # Caches und generierte Artefakte entfernen
just audit                # Sicherheitsscan
just rate-design          # Design-Metriken → .refactor/ (nur Bericht)
just refactor             # Refactoring-Sitzung vorbereiten (Preflight, Baseline, Branch)
just merge                # main per Fast-Forward auf einen Branch ziehen und dessen Worktree/Branch aufräumen (kein Push)
```

## Dokumentation generieren

```shell
just docs                 # MkDocs bauen (Lib) / docs/reference/cli.md neu erzeugen (App --cli)
just docs-check           # prüfen, ob die generierte Dokumentation aktuell ist (Teil von `just check`)
just docs-serve           # Live-Vorschau (nur Bibliotheken)
```

## Release & Deployment

Versionen niemals manuell bearbeiten oder Tags erstellen. Immer `bump-my-version` verwenden:

```shell
just bump patch           # 0.2.0 → 0.2.1
just bump minor           # 0.2.1 → 0.3.0
just bump major           # 0.3.0 → 1.0.0
```

Agenten pushen nie; der Maintainer veröffentlicht mit `git push origin main --tags`.

## Refactoring

```shell
just rate-design run            # Design-Metriken → .refactor/ (nur Bericht)
just rate-design save <name>    # Bericht sichern → .refactor/<name>.json
just rate-design compare <name> # Bericht mit Baseline vergleichen
just refactor                   # Refactoring-Sitzung vorbereiten (Preflight, Baseline, Branch)
```