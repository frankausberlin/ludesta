---
name: lupysta
description: >
  Arbeitsweise für bereits eingerichtete Python-Projekte des
  Luxus-Python-Stacks: Qualitätsgate, Dokumentation, Git und Release,
  Refactoring, Projektjournal, ADRs und Attention Points. E2E- und
  Agent-Tests sind opt-in und nicht Teil von `just check`.
version: 0.14.0
platforms: [linux]
metadata:
  tags: [python, uv, quality-gate, refactoring, adr]
---

# lupysta

## Zweck und Grenzen

Dieser Skill beschreibt, **wie** in einem bereits eingerichteten Projekt
gearbeitet wird. Er erzeugt keine Projekte und richtet keine Umgebung ein:
Projektinitialisierung, Shell-Funktionen und Systemeinrichtung sind nicht
Teil dieses Skills.

Das eingerichtete Projekt und seine `AGENTS.md` bilden den Vertrag für die
Arbeit. Maßgeblich sind die tatsächlich vorhandenen Projektdateien, Befehle
und Regeln; die Kenntnis eines ursprünglichen Generators ist nicht erforderlich.

Die dauerhaft relevanten Projektdateien sind `AGENTS.md` (Projektregeln, ADRs,
Attention Points), `journal/` (Sitzungsgedächtnis) und `docs/adr/`
(Architekturentscheidungen). Alles Weitere wird nur bei Bedarf geladen.

## Sitzungsstart

1. `AGENTS.md` lesen: Projektprofil, ADR-Konventionen und Attention Points.
2. Die neuesten Einträge unter `journal/` lesen
   (`ls -1 journal | grep -v '^README\.md$' | sort | tail -n 3`).
   Existiert nur `JOURNAL.md`, ist das die Legacy-Quelle; der Umgang damit
   steht in [`references/session-close.md`](references/session-close.md).
3. `docs/adr/` sichten, falls vorhanden; die Dateinamen genügen für den
   Überblick.
4. `uv sync` ausführen.
5. `git status` prüfen und den aktuellen Branch verstehen.
6. Nur die Rezepte laden, die zur Aufgabe passen.

## Grundregeln

- **`AGENTS.md` ist die Projektquelle.** Sie enthält die projektbezogenen
  Regeln, die ADR-Konventionen und die Attention Points; bei Branch-,
  Merge- und Publish-Fragen schlägt sie Rezepte und Pläne.
- **`just check` grün halten.** Vor und nach jeder Änderung gilt das
  Qualitätsgate des Projekts.
- **Tests, Lint und Typen nicht abschwächen**, um Fehler zu verstecken.
- **Generierte Dokumentation nicht von Hand ändern.** Stattdessen den
  Generator ausführen und das Ergebnis committen.
- **Agenten pushen nie; der Hauptcheckout bleibt auf `main`.** Der fertige
  Aufgaben-Branch wird lokal nach `main` gemergt und gelöscht; ein stabiler
  Harness-Branch und sein Worktree bleiben bestehen. `main` ist im
  Hauptcheckout ausgecheckt. Der Maintainer prüft und veröffentlicht.
- **Keine destruktiven Git-Befehle.** Kein Force-Push, kein `reset --hard` auf
  fremde Arbeit, keine ungefragte Worktree-Entfernung.
- **Am Ende jeder erfüllten Aufgabe** den Abschnitt
  [Sitzungsende](#sitzungsende) ausführen; er ist erst abgeschlossen, wenn
  `main` im Hauptcheckout ausgecheckt ist.

## Sitzungsende

1. `just check` ausführen; das Gate muss grün sein.
2. [`references/session-close.md`](references/session-close.md) ausführen:
   einen Eintrag unter `journal/` anlegen (in Legacy-Projekten ohne freigegebene
   Journal-Übernahme weiterhin in `JOURNAL.md`), ADR- und
   Attention-Point-Kandidaten prüfen und bei Bedarf anlegen.
3. Alle beabsichtigten Änderungen auf dem Branch committen; ADRs, Attention
   Points und der Journal-Eintrag unter `journal/` gehören in denselben Commit.
   `JOURNAL.md` bleibt bis zur freigegebenen Journal-Übernahme lokal und wird
   nicht committet (in bestehenden Projekten ist sie gitignored).
4. Den fertigen Aufgaben-Branch lokal nach `main` mergen – bevorzugt mit
   `just merge [branch]`, ohne `just` manuell per Fast-Forward. Den
   Hauptcheckout auf `main` bringen und einen temporären Branch löschen; ein
   stabiler Harness-Branch bleibt bestehen. Einzelheiten in
   [`references/session-close.md`](references/session-close.md)
   (Abschnitt 8) und [`references/git-release.md`](references/git-release.md).

## Rezeptindex

| Rezept | Inhalt |
| --- | --- |
| [`references/session-close.md`](references/session-close.md) | Aufgabenabschluss: ADR-/AP-Kandidaten, Journal-Eintrag, Merge nach `main` und ausgecheckter Hauptcheckout. |
| [`references/quality-gate.md`](references/quality-gate.md) | `just check`, `fix`, `test`, `lint`, `typecheck`, `audit`, `clean` und Fehlersuche. |
| [`references/documentation.md`](references/documentation.md) | `docs`, `docs-check`, `docs-serve` und generierte Seiten. |
| [`references/git-release.md`](references/git-release.md) | Worktree, `just merge`, `bump`, CI und Veröffentlichung. |
| [`references/refactoring.md`](references/refactoring.md) | `rate-design run\|save\|compare`, `refactor`, Baseline und ein Rezept pro Schritt. |
| [`references/refactoring-recipes.md`](references/refactoring-recipes.md) | Extract Function, Rename Internal Symbol und Remove Confirmed Dead Code. |
| [`references/e2e-tests.md`](references/e2e-tests.md) | Opt-in Docker-Suite; Tests projektspezifisch. |
| [`references/agent-tests.md`](references/agent-tests.md) | Opt-in Provider-Suite; Harness projektspezifisch. |

## Laden auf Bedarf

Lade ein Rezept erst, wenn die Aufgabe es verlangt. Prüfe vor der Verwendung
die tatsächlich vorhandenen Befehle im `Justfile` und die Projektdateien.
Weicht der Projektzustand von `AGENTS.md` ab, melde die Abweichung, statt sie
stillschweigend zu reparieren oder neu anzulegen. Fehlende oder
widersprüchliche Projektvoraussetzungen werden nicht durch Gerüstgenerierung,
einen Migrationsablauf oder Recherche nach Generatorprofilen ersetzt; kläre
sie mit dem Nutzer.

E2E- und Agent-Tests sind nicht Teil von `just check`. E2E ist lokal nur über
`just test-e2e` aufrufbar und läuft in CI automatisch, sobald Testdateien
existieren; Agent-Tests laufen nur manuell über `just test-agent` und nie in
der CI. Die vorhandenen Runner, Suiten und CI-Workflows sind maßgeblich; echte
Tests und der Agent-Harness bleiben projektspezifisch. Lade die Rezepte, wenn
das Projekt Testdateien in `tests/e2e/` oder `tests/agent/` enthält oder die
Aufgabe sie berührt.

## Tägliche Entwicklungsbefehle

```shell
uv add <package>          # Laufzeitabhängigkeit
uv add --dev <package>    # Abhängigkeit nur für die Entwicklung
uv sync                   # Umgebung synchronisieren
just run                  # Hauptskript ausführen (nur Apps)
just test                 # pytest mit Coverage
just test-e2e             # Docker-E2E-Suite lokal (CI: automatisch ab vorhandenen Tests)
just test-agent           # Provider-Suite manuell (Leerlauf: Hinweis + Exit 0)
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
just docs                 # MkDocs bauen (Bibliothek) / docs/reference/cli.md neu erzeugen (CLI-App)
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