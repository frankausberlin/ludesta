# Migration älterer Projekte

Ältere Projekte können ohne Feature-Liste in `AGENTS.md` und ohne die
neueren `just`-Rezepte existieren. Dieses Rezept beschreibt den sicheren
Umgang damit.

## Grundsätze

- Bestehende Projekte werden **nicht automatisch aktualisiert**.
- Fehlende Features werden **nicht nachgebaut**, nur weil der Skill sie kennt.
- Die tatsächlichen Projektbefehle sind maßgeblich, nicht die Erwartung aus
  diesem Skill.
- Änderungen an Projektdateien nur im Rahmen der aktuellen Aufgabe und mit
  Zustimmung der Projektverantwortlichen.

## Projektzustand prüfen

1. `AGENTS.md` lesen.
2. Prüfen, ob `lupysta_version` und `contract_version` vorhanden sind.
3. `Justfile` lesen und die tatsächlich vorhandenen Rezepte notieren:
   - `just check`
   - `just rate-design`
   - `just refactor`
   - `just merge`
   - `just docs` / `just docs-check`
4. Prüfen, ob `docs/`, `scripts/design_report.py` oder optionale
   Testverzeichnisse existieren.
5. Nur die Rezepte verwenden, deren Befehle wirklich vorhanden sind.

## Ältere Verträge

- Ein alter Contract-Block in `AGENTS.md` ist eine historische
  Beschreibung, keine Garantie für aktuelle Befehle.
- Der Skill beschreibt die Arbeitsweise; die Projektdateien beschreiben den
  tatsächlichen Zustand.
- Weicht `AGENTS.md` vom Projektzustand ab, die Abweichung melden und die
  betroffene Arbeit stoppen, bis die Zuständigkeit geklärt ist.

## Fehlende neuere Funktionen

| Fehlt | Vorgehen |
| --- | --- |
| `just rate-design save/compare` | Nur `just rate-design` verwenden, falls vorhanden; keine Baseline erfinden. |
| `just refactor` | Branch manuell anlegen; vorher `just check` ausführen. |
| `just merge` | Branch manuell mergen; Session-Dateien schützen. |
| `docs-check` | Dokumentation nur bauen, wenn `just docs` vorhanden ist. |
| `e2e`/`agent` | Nicht anlegen und nicht ausführen. |

## Empfohlene manuelle Aktualisierung

Wenn das Projekt ohnehin angepasst wird:

1. Projektprofil und Feature-Auswahl in `AGENTS.md` ergänzen.
2. `lupysta_version` und `contract_version` eintragen.
3. Fehlende Rezepte nur mit Zustimmung ergänzen.
4. `just check` ausführen.
5. Änderungen separat committen.

## Grenzen

- Keine automatische Migration.
- Keine rückwirkende Änderung generierter Dokumentation.
- Keine Übernahme von Befehlen aus diesem Skill, wenn das Projekt sie nicht
  anbietet.
