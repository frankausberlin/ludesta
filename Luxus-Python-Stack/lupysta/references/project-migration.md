# Projekt-Migration

Dieses Rezept überführt ein bestehendes Python-Projekt in den aktuellen
Luxus-Python-Stack. Es gilt sowohl für ein älteres `pyinit`-Projekt als auch für
ein fremdes Projekt ohne `pyinit.toml`. Nicht-Python-Projekte und die reguläre
Neuanlage sind kein Anwendungsfall dieses Rezepts.

`pyinit` bleibt die Quelle für Profile, Artefakte und den Zielzustand. Das Rezept
beschreibt die bewusste, agentengeführte Migration und erweitert `pyinit` nicht
um einen Update- oder Merge-Modus.

## Ziel und Grundregeln

Das Ziel ist kein bytegleiches frisch erzeugtes Gerüst. Das migrierte Projekt
soll stack-kompatibel, nachvollziehbar verankert und vollständig geprüft sein.
Sein fachliches Verhalten und begründete projektspezifische Abweichungen bleiben
erhalten.

- Vor dem ersten Schreibzugriff Bestand, Baseline, Zielstand und Vorgehen
  erfassen.
- Strukturmigration nicht mit fachlichen Änderungen oder großflächiger
  Sanierung vermischen.
- Referenzdateien niemals pauschal über das Bestandsprojekt kopieren.
- Keine Tests, Lint-Regeln, Typprüfungen oder Coverage-Anforderungen abschwächen,
  um den Migrationsaufwand zu verstecken.
- Keine ursprünglichen Herkunftsdaten erfinden und keine neuen Felder des
  `pyinit.toml`-Schemas durch dieses Rezept einführen.
- Branch-, Commit-, Merge- und Publish-Regeln des Projekts einhalten. Agenten
  pushen nicht.

## 1. Fall bestimmen und Preflight ausführen

Ordne den Bestand einem der folgenden Fälle zu:

1. **Upgrade:** Ein `pyinit`-Projekt mit nachvollziehbarer Herkunft soll auf
   einen neueren Contract- oder Skill-Stand.
2. **Adoption:** Ein fremdes Python-Projekt ohne `pyinit.toml` wird erstmalig in
   den Stack aufgenommen.
3. **Teilmigration:** Das Projekt enthält bereits Stack-Dateien, aber Herkunft,
   Artefakte oder Dateizustände sind widersprüchlich. Zuerst den tatsächlichen
   Stand rekonstruieren, keine Herkunft annehmen.

Vor Änderungen:

- `git status --short --branch` prüfen und einen separaten Migrationsbranch
  verwenden. Vorhandene Projektregeln haben Vorrang.
- Uncommittete, unversionierte und ignorierte Dateien berücksichtigen. Keine
  fremden Änderungen verschieben oder überschreiben; Secrets nicht auslesen.
- Die bisherigen Test-, Build-, Start- und Dokumentationsbefehle bestimmen und
  ausführen. Bei einem älteren Stack-Projekt gehört auch das vorhandene
  `just check` dazu.
- Ergebnisse als Baseline festhalten, einschließlich bereits vorhandener
  Fehler. Diese weder als neue Regressionsfehler behandeln noch still beheben.
- Ist keine ausreichende Verhaltens-Baseline feststellbar oder ist unklar,
  welche bestehenden Fehler vor der Migration behandelt werden sollen, vor dem
  Schreiben Rücksprache halten.

Monorepos, Mehr-Paket-Projekte, native Build-Komponenten oder unklare
Release-Prozesse sind nicht mechanisch nach dem Standardprofil zu migrieren.
Dafür zuerst einen gesonderten Migrationsplan und die nötigen Entscheidungen
einholen.

## 2. Bestand inventarisieren

Mindestens folgende Bereiche erfassen:

| Bereich | Festzuhalten |
| --- | --- |
| Projekt | Zweck, App oder Bibliothek, Paket- und Quelllayout, Python-Version |
| Paketierung | Distributions- und Importnamen, Version, Build-System, Metadaten |
| Verhalten | Entrypoints, öffentliche APIs, Laufzeit- und optionale Abhängigkeiten |
| Qualität | Tests und Coverage, Lint, Formatierung, Typprüfung, Pre-commit |
| Dokumentation | README, MkDocs oder andere Dokumentation, ADRs und Journal |
| Betrieb | CI, Release, Tags, Trusted Publishing und projektspezifische Runner |
| Agenten | `AGENTS.md`, Attention Points, Journals und besondere Harness-Regeln |
| Herkunft | `pyinit.toml`, Skill-/Contract-Version und frühere Abweichungen |

Die Projektversion, Lizenz, Autoren, Abhängigkeiten, Entrypoints,
Release-Konfiguration und öffentlichen Schnittstellen gehören zum Bestand und
dürfen nicht durch Template-Standardwerte ersetzt werden.

## 3. Zielstand festlegen und Referenz erzeugen

Eine Migration läuft gegen genau einen `pyinit`-Stand, nicht gegen ein während
der Arbeit wechselndes „aktuell“.

1. Die verwendete `pyinit`-Version beziehungsweise den Commit sowie die
   Zielwerte für `contract_version` und `lupysta_version` notieren.
2. Mit `pyinit list` die verfügbaren Profile und mit `pyinit describe <id>` den
   gewählten Modus, die Artefakte und ihre Beziehungen prüfen.
3. Mit `pyinit new <profil> <ziel> --dry-run` den aktuellen Dateiplan ermitteln.
   Der Zielname dient nur der Referenz und liegt nicht im Bestandsprojekt.
4. Werden die gerenderten Dateiinhalte benötigt, ein temporäres Referenzprojekt
   außerhalb des Bestandsprojekts erzeugen. Seine Dateien einzeln bewerten,
   nicht als Ganzes übernehmen.

Das Profil beschreibt die nächstliegende Stack-Basis, nicht zwingend jede
Projektfähigkeit. Zusätzliche fachliche Entrypoints oder eine Kombination wie
CLI plus projektspezifischem MCP können bewusst außerhalb des Profils bleiben.
Profilregeln oder Resolver-Invarianten werden dafür nicht aufgeweicht.

## 4. Migrationsplan erstellen

Für jede relevante Bestands- und Referenzdatei eine Entscheidung festhalten:

| Entscheidung | Bedeutung und Beispiele |
| --- | --- |
| **Übernehmen** | Eine fehlende, konfliktfreie Stack-Datei neu anlegen, etwa Runner oder Leitdateien. |
| **Zusammenführen** | Bestand und Ziel bewusst verbinden, etwa bei `pyproject.toml`, `Justfile`, CI und `AGENTS.md`. |
| **Behalten** | Fachcode, Tests oder Produktdokumentation unverändert lassen. |
| **Abweichen** | Eine projektspezifische Abweichung samt Begründung dauerhaft dokumentieren. |
| **Auslassen** | Demo-Quellen, Hello-Tests oder Template-Texte nicht übernehmen. |

Der Plan ordnet jeder Änderung einen Grund und eine spätere Prüfung zu.
Unklare Profil-, Verhaltens- oder Release-Entscheidungen vor der Umsetzung
klären. Eine Abweichung ist zulässig; eine stillschweigend veränderte
Schnittstelle ist es nicht.

## 5. Schrittweise migrieren

- In kleinen, getrennt prüfbaren Schritten arbeiten, beispielsweise Paketierung
  und Quality Gate, optionale Suiten, Dokumentation und Agentenstruktur.
- `pyproject.toml` zusammenführen: Paketierung, Version, Abhängigkeiten und
  Entrypoints erhalten. Build-System oder Tool-Konfiguration nur bewusst
  ändern und die Folgen prüfen. Die Lock-Datei kontrolliert neu erzeugen.
- Bestehenden Fachcode und bestehende Tests nie durch Demo-Dateien ersetzen.
  Einen zusätzlichen Smoke-Test nur ergänzen, wenn er für das Projekt sinnvoll
  ist und keinen vorhandenen Test verdrängt.
- `AGENTS.md` zusammenführen. Vorhandene ADRs, Attention Points und
  Journal-Einträge samt Nummern und Historie erhalten. Eine Migration von
  Legacy-`JOURNAL.md` folgt ausschließlich
  [`session-close.md`](session-close.md) und setzt Zustimmung voraus.
- CI und Release vorsichtig übernehmen. Bestehende Environments, Secrets,
  Trusted Publisher und Tag-Verträge nicht still verändern oder aktivieren.
- Neue Lint-, Typ- oder Coverage-Probleme nicht durch Abschwächen des Gates
  beseitigen. Umfangreiche Sanierung vom Struktur-Changeset trennen. Reicht der
  freigegebene Auftrag dafür nicht aus, die Migration nicht als abgeschlossen
  melden und den weiteren Umgang klären.
- Die aktualisierte Herkunft erst eintragen, nachdem der jeweilige Zielstand
  tatsächlich erreicht und geprüft wurde.

## 6. Herkunft und Abweichungen dokumentieren

`pyinit.toml` beschreibt die ursprüngliche Generierung, nicht den Migrationszeitpunkt.

- Bekannte ursprüngliche Werte für `version` und `generated_at` erhalten.
  Unbekannte Werte bleiben nach bisheriger Konvention ausdrücklich `unknown`;
  kein Generierungsdatum rekonstruieren und das Migrationsdatum nicht
  einsetzen.
- `contract_version` in `pyinit.toml` und `lupysta_version` in `AGENTS.md`
  bezeichnen den erreichten Zielstand, nicht nur die verwendete
  Werkzeugversion.
- Migrationsbasis, Migrationsdatum und dauerhafte Abweichungen in der
  Herkunftsdokumentation beziehungsweise im Journal festhalten.
- Keine neuen Metadatenfelder einführen. Eine Erweiterung des Schemas, etwa um
  generierte und migrierte Herkunft maschinenlesbar zu unterscheiden, ist eine
  separate `pyinit`-Aufgabe.
- Aus der Migration folgt kein automatischer Update-Pfad für spätere
  `pyinit`-Versionen.

## 7. Migration verifizieren

Die alte Verhaltens-Baseline und das neue Stack-Gate sind beide relevant:

1. Die bisherigen Tests sowie relevante Build-, Start- und
   Dokumentationsbefehle erneut ausführen und mit der Baseline vergleichen.
2. Die Umgebung reproduzierbar synchronisieren, bei vorhandener Lock-Datei
   einschließlich `uv sync --locked --dev`.
3. `just check` ausführen; es muss für eine abgeschlossene Migration grün sein.
4. Das Paket bauen und relevante Entrypoints oder Importe aus dem gebauten
   Ergebnis prüfen, soweit das für das Projekt zutreffend ist.
5. Vorhandene E2E-Suiten nach ihren Regeln ausführen. Agent-Live-Tests bleiben
   manuell und werden nicht allein für die Migration gestartet.
6. Diff und Arbeitsbaum prüfen: keine Demo-Überschreibungen, unbeabsichtigten
   Löschungen, Secrets oder unerklärten Lock-/Konfigurationsänderungen.
7. `pyinit.toml`, Herkunft und bewusste Abweichungen gegen den tatsächlichen
   Endzustand prüfen.

Ein unverändert grünes altes Kommando ersetzt `just check` nicht; ein grünes
neues Gate ersetzt den Vergleich mit dem bisherigen Verhalten nicht.

## 8. Abschluss

- [`session-close.md`](session-close.md) ausführen und die Migrationsbasis,
  wesentlichen Entscheidungen, Abweichungen und verbleibenden Risiken im
  Journal festhalten.
- Eine ADR nur für eine echte Projektentscheidung anlegen; das allgemeine
  Migrationsverfahren nicht projektbezogen duplizieren. Attention Points nur
  für wiederkehrende projektspezifische Stolpersteine aufnehmen.
- Die regulären Prüfungen, den lokalen Merge und die Endzustandskontrolle nach
  den Projektregeln durchführen. Nicht pushen.
- Nach abgeschlossener Migration gilt wieder der normale Sitzungsstart des
  lupysta-Skills.
