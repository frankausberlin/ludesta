# LUDESTA — Luxus Development Stack

Wiederverwendbare Agent-Skills für einen komfortablen, konsistenten
Entwicklungsworkflow.

„Luxuriös“ bedeutet hier: komfortable Mechanismen und Werkzeuge im
Entwicklungsprozess. Die Idee ist, einem Agenten (Skill + Harness) eine
umfangreiche, komfortable Projektstruktur vorzugeben und ihn anzuleiten,
diese effektiv einzusetzen. Automatismen in der CI/CD erhöhen die Stabilität
der agentischen Arbeit.

> Das Repository heißt derzeit noch `luxus-skills` und wird in `ludesta`
> umbenannt. Pfade in dieser Dokumentation verwenden bereits den neuen Namen,
> wo es möglich ist.

## Komponenten

Ein Luxus-Stack (z. B. Python) besteht aus drei Komponenten:

| Komponente | Beschreibung |
| --- | --- |
| [Stack-Dokumentation](Luxus-Python-Stack/Luxus-Python-Stack_de.md) | Beschreibung des Stacks, seiner Ebenen und des `pyinit`-Ablaufs. Die [Setup-Anleitung](Luxus-Python-Stack/Stack-Setup_de.md) gehört zur Dokumentation. |
| [Stack-Skill](Luxus-Python-Stack/lupysta/SKILL.md) | Arbeitsweisen für Agenten in bereits initialisierten Projekten. Rezepte werden bei Bedarf geladen. |
| [Stack-Script](Luxus-Python-Stack/luxuspythonstack.sh) | `pyinit` und weitere Shell-Funktionen; wird in der Shell eingebunden. |

Die englischen Fassungen `Luxus-Python-Stack.md`, `Stack-Setup.md` und
`lupysta/SKILL_en.md` bleiben als Referenz erhalten. Während der Entwicklung
ist die deutsche Fassung die Arbeitsgrundlage.

## Installation

1. Repository klonen:
   ```shell
   mkdir -p ~/gits
   git clone https://github.com/frankausberlin/luxus-skills ~/gits/luxus-skills
   ```
2. [Stack-Setup](Luxus-Python-Stack/Stack-Setup_de.md) befolgen.
3. Das Script in der Shell einbinden:
   ```shell
   export LUXUS_REPO="${LUXUS_REPO:-$HOME/gits/luxus-skills}"
   source "$LUXUS_REPO/Luxus-Python-Stack/luxuspythonstack.sh"
   ```
4. Den Skill verlinken:
   ```shell
   mkdir -p ~/.agents/skills
   ln -s "$LUXUS_REPO/Luxus-Python-Stack/lupysta" ~/.agents/skills/lupysta
   ```

Der Skill wird **nicht** in generierte Projekte kopiert. Ein zentral
installierter Skill beschreibt alle Arbeitsweisen; die `AGENTS.md` des
Projekts wählt aus, welche davon gelten.

### Nicht-interaktive Shells

`pyinit` ist eine Shell-Funktion. In Skripten und nicht-interaktiven Shells
das Script zuerst sourcen; bei Bedarf einen kleinen Wrapper verwenden, der
das Script sourct und `pyinit` aufruft.

### Migration und Koexistenz

- Den alten `luxuspythonstack`-Skill und `lupysta` nicht parallel installieren.
- Bestehende Projekte werden nicht automatisch aktualisiert; ihre vorhandenen
  Befehle bleiben gültig.
- Zum Deinstallieren den Skill-Link entfernen und die `source`-Zeile aus der
  Shell-Konfiguration löschen. Generierte Projekte bleiben unabhängig vom
  installierten Skill nutzbar.

## Projektmodell

`pyinit` erzeugt ein Projekt mit:

- `AGENTS.md` mit Projektprofil, Feature-Auswahl und lokalen Regeln,
- `Justfile` mit dem Qualitätsgate und den Projektbefehlen,
- `scripts/design_report.py` für designbezogene Messungen,
- optionaler Dokumentation für Bibliotheken und CLI-Apps,
- CI-Workflows und einem Smoke-Test.

Die Feature-Auswahl in `AGENTS.md` ist die einzige Quelle für die Frage,
welche Arbeitsweisen in einem Projekt gelten. Fehlende Features werden nicht
vorausgesetzt und nicht ungefragt nachgebaut.

| Feature | Standard | Einstieg |
| --- | --- | --- |
| `core` | immer | `just check` |
| `refactor` | immer | `just rate-design`, `just refactor` |
| `docs-lib` | Bibliothek | `just docs`, `just docs-check` |
| `docs-cli` | App mit `--cli` | `just docs`, `just docs-check` |
| `e2e` | nicht erzeugt | `just test-e2e` (später) |
| `agent` | nicht erzeugt | `just test-agent` (später) |

## Unterstützte Umgebung

Linux ist die Referenzplattform. macOS ist derzeit keine unterstützte Zusage;
mehrere Werkzeuge im Script und in den erzeugten Projekten setzen
GNU-Werkzeuge voraus. macOS-Unterstützung kommt erst mit CI- und
Testabdeckung zurück.

## Entwicklung

```shell
bash tests/test-pyinit.sh --fast   # Argumente, Guards, Template-Preflight
bash tests/test-pyinit.sh          # zusätzlich generierte Projekte und just check
bash tests/fresh-clone.sh          # letzter Commit als frischer Clone
bash scripts/check-links.sh        # relative Markdown-Links prüfen
shellcheck -s bash Luxus-Python-Stack/luxuspythonstack.sh tests/*.sh scripts/*.sh
```

Die CI führt den schnellen Test, den Integrationstest, den Fresh-Clone-Test,
den Link-Check und Shellcheck aus. Der Fresh-Clone-Test stellt sicher, dass
das Repository ohne `ignore/` und ohne lokale Altlasten funktioniert.

## Repository-Layout

```text
Luxus-Python-Stack/
├── Luxus-Python-Stack_de.md     # deutsche Arbeitsfassung
├── Luxus-Python-Stack.md        # englische Referenz
├── Stack-Setup_de.md            # deutsche Setup-Anleitung
├── Stack-Setup.md               # englische Referenz
├── luxuspythonstack.sh          # pyinit und Shell-Funktionen
├── lupysta/                     # Skill (SKILL.md deutsch, SKILL_en.md englisch)
│   └── references/              # Rezepte, nur bei Bedarf geladen
└── templates/pyinit/            # AGENTS.md-Vorlage und design_report.py
tests/                           # Skill-Repository-Tests
scripts/                         # Link-Checker
.github/workflows/               # CI
```

`ignore/` ist lokal, nicht versioniert und für den Betrieb nicht erforderlich.
