---
name: lupysta
description: >
  Arbeitsweise für bereits initialisierte Python-Projekte des
  Luxus-Python-Stacks: Qualitätsgate, Dokumentation, Git und Release,
  Refactoring sowie vorgesehene E2E- und Agent-Tests (nicht Teil der
  Basisversion). Nur laden, wenn
  AGENTS.md die jeweilige Arbeitsweise für das Projekt ausweist.
version: 0.5.0
platforms: [linux]
metadata:
  tags: [python, uv, quality-gate, refactoring]
---

# lupysta

## Zweck und Grenzen

Dieser Skill beschreibt, **wie** in einem bereits initialisierten Projekt
gearbeitet wird. Er erzeugt keine Projekte und richtet keine Umgebung ein:
Projektinitialisierung, Shell-Funktionen und Systemeinrichtung sind nicht
Teil dieses Skills.

Die einzigen dauerhaft relevanten Dateien sind diese Übersicht und die
`AGENTS.md` des Projekts. Alles Weitere wird nur bei Bedarf geladen.

## Einstieg

1. `AGENTS.md` lesen: Projektprofil, Feature-Auswahl und lokale Regeln.
2. `SESSION.md` lesen, falls vorhanden.
3. `uv sync` ausführen.
4. `git status` prüfen und den aktuellen Branch verstehen.
5. Nur die Rezepte laden, die zur Aufgabe und zur Feature-Auswahl passen.

## Grundregeln

- **`AGENTS.md` ist die Projektquelle.** Sie entscheidet, welche Features und
  Arbeitsweisen in diesem Projekt gelten.
- **Nur genannte Features verwenden.** Fehlt ein Feature in `AGENTS.md`, wird
  es nicht vorausgesetzt und nicht ungefragt nachgebaut.
- **`just check` grün halten.** Vor und nach jeder Änderung gilt das
  Qualitätsgate des Projekts.
- **Tests, Lint und Typen nicht abschwächen**, um Fehler zu verstecken.
- **Generierte Dokumentation nicht von Hand ändern.** Stattdessen den
  Generator ausführen und das Ergebnis committen.
- **Agenten pushen nie.** Der Maintainer prüft und veröffentlicht.
- **Keine destruktiven Git-Befehle.** Kein Force-Push, kein `reset --hard` auf
  fremde Arbeit, keine ungefragte Worktree-Entfernung.

## Rezeptindex

| Rezept | Inhalt |
| --- | --- |
| [`references/workflow.md`](references/workflow.md) | Sitzungsstart und -ende, `SESSION.md`/`JOURNAL.md`, Branch und Commit. |
| [`references/quality-gate.md`](references/quality-gate.md) | `just check`, `fix`, `test`, `lint`, `typecheck`, `audit`, `clean` und Fehlersuche. |
| [`references/documentation.md`](references/documentation.md) | `docs`, `docs-check`, `docs-serve` und generierte Seiten. |
| [`references/git-release.md`](references/git-release.md) | Worktree, `just merge`, `bump`, CI und Veröffentlichung. |
| [`references/refactoring.md`](references/refactoring.md) | `rate-design run\|save\|compare`, `refactor`, Baseline und ein Rezept pro Schritt. |
| [`references/refactoring-recipes.md`](references/refactoring-recipes.md) | Extract Function, Rename Internal Symbol und Remove Confirmed Dead Code. |
| [`references/e2e-tests.md`](references/e2e-tests.md) | Vorgesehene Docker-Suite (nicht Teil der Basisversion); nur laden, wenn `AGENTS.md` `e2e` nennt. |
| [`references/agent-tests.md`](references/agent-tests.md) | Vorgesehene Provider-Suite (nicht Teil der Basisversion); nur laden, wenn `AGENTS.md` `agent` nennt. |


## Laden auf Bedarf

Lade ein Rezept erst, wenn die Aufgabe es verlangt **und** das Projekt die
zugehörige Arbeitsweise in `AGENTS.md` nennt. Prüfe vor der Verwendung die
tatsächlich vorhandenen Befehle im `Justfile` und in den Projektdateien.
Weicht der Projektzustand von `AGENTS.md` ab, melde die Abweichung, statt
Features stillschweigend zu reparieren oder neu anzulegen.
