# Session-Abschluss

Dieses Rezept wird am Ende jeder erfüllten Aufgabe ausgeführt, spätestens am
Sitzungsende. Es entscheidet, ob die Aufgabe eine ADR oder einen Attention
Point hinterlässt, und legt einen Eintrag unter `journal/` an. „Keine
Einträge“ ist ein gültiges Ergebnis.

## 1. Aufgabe prüfen

- Diff und Commits der Aufgabe ansehen.
- Die Aufgabe aus Sicht des nächsten Agenten bewerten: Was war nicht
  offensichtlich? Welche Entscheidung könnte später hinterfragt werden?
- Nur projektbezogenes Wissen dokumentieren, nicht die Arbeit nacherzählen.

## 2. ADR-Kandidat?

Eine ADR ist sinnvoll, wenn mindestens zwei der folgenden Punkte zutreffen:

- Es gab eine echte Entscheidung zwischen Alternativen.
- Die Entscheidung ist architekturrelevant oder wirkt quer durch das Projekt.
- Sie ist später schwer rückgängig zu machen.
- Der nächste Agent braucht die Begründung, nicht nur das Ergebnis.
- Die Entscheidung betrifft Schnittstellen, Datenmodell, Abhängigkeiten,
  Sicherheit oder Betrieb.

Keine ADR für Routineentscheidungen, Namensgebung, Formatierung oder
Implementierungsdetails, die der Code selbst erklärt.

## 3. Attention-Point-Kandidat?

Ein Attention Point ist sinnvoll, wenn alle folgenden Punkte zutreffen:

- Die Situation ist projektspezifisch und nicht schon im Skill beschrieben.
- Sie tritt wahrscheinlich wieder auf.
- Die Handhabung ist stabil und klar beschreibbar.
- Sie ist nicht aus dem Code oder den Tests offensichtlich.
- Sie ist kein Einmal-Bug und kein persönlicher Workaround.

Ein AP beschreibt **wie** man in einer Situation handelt; eine ADR beschreibt
**warum** entschieden wurde. Beides kann zusammengehören: Die ADR trägt die
Begründung, der AP die Handhabung. Den ADR-Text nicht im AP duplizieren.

## 4. ADR anlegen

Dateiname: `docs/adr/NNNN-entscheidung.md` (vierstellige Nummer, danach die
Entscheidung als kleingeschriebene Wörter mit Bindestrichen). `docs/adr/` bei
Bedarf anlegen.

```markdown
# ADR-NNNN: Titel

- Status: accepted
- Datum: YYYY-MM-DD

## Kontext

...

## Entscheidung

...

## Konsequenzen

...

## Alternativen

...
```

* Die nächste freie Nummer verwenden, beginnend mit `0001`.
* Veröffentlichte ADRs niemals löschen oder umnummerieren. Sobald eine ADR auf
  `main` gemergt ist, gilt ihre Nummer als vergeben – auch dann, wenn die
  Entscheidung später revidiert wird.
* Der Dateiname nennt die Entscheidung selbst, nicht nur das Thema:
  * `0003-auswahl-der-shell.md` ist falsch; der Name sagt dem Agenten nichts,
    er muss die Datei lesen.
  * `0003-wir-verwenden-zsh.md` ist richtig; der Name ist die Entscheidung.
* Ein `ADR`-Präfix im Dateinamen ist nicht nötig. Das Verzeichnis `docs/adr/`
  benennt die Dokumentart; der Standard (MADR, adr-tools) verwendet
  `NNNN-titel.md`.
* `_`-Dateien zählen bei der Nummernvergabe mit. Werkzeuge, die nur nach
  führenden Ziffern suchen (z. B. `adr-tools`), übersehen sie; die nächste
  Nummer daher immer über alle Dateien in `docs/adr/` bestimmen.
* Wird eine Entscheidung revidiert, passiert Folgendes:
  1. Eine neue ADR mit der nächsten Nummer anlegen.
  2. Die alte auf `Status: superseded by ADR-MMMM` setzen.
  3. In beiden Dateien aufeinander verweisen: Die neue ADR verlinkt
     `_NNNN-...md`, die alte verlinkt `MMMM-...md`.
  4. Vor dem Umbenennen eingehende Verweise auf den alten Namen ermitteln und
     im selben Changeset anpassen. Beispiel für
     `0003-wir-verwenden-zsh.md`:

     ```shell
     git grep -nE '(^|[^_])0003-wir-verwenden-zsh\.md' -- '*.md'
     ```

     Der Ausschluss `[^_]` verhindert Treffer auf den neuen `_`-Dateinamen.
     Journal-Einträge unter `journal/` sind historisch und werden nicht
     umgeschrieben; ADR- und AP-Referenzen nennen dort nur die Nummer
     (`ADR-0001`, `AP-3`), nicht den Dateinamen.
  5. Die alte ADR-Datei umbenennen: `<filename>` wird zu `_<filename>`.
     Beispiel: `0003-wir-verwenden-zsh.md` wird zu
     `_0003-wir-verwenden-zsh.md`.

  Nach dem Umbenennen zeigt `ls -1 docs/adr` zuerst alle aktiven und danach
  alle revidierten Entscheidungen. Das `_` ist eine lokale Konvention; der
  Status im Dokument bleibt die inhaltliche Wahrheit.

## 5. Attention Point anlegen

Im Abschnitt `## Attention Points` in `AGENTS.md` ergänzen:

```markdown
### AP-N: Kurztitel

- **Situation**: ...
- **Handhabung**: ...
- **Involvierte ADRs**: ...
- **Kontext**: ...
```

- Die nächste freie Nummer ist die höchste in `AGENTS.md` verwendete
  AP-Nummer plus eins; Tombstones zählen mit.
- Wird ein AP nicht mehr gültig, den aktiven Text durch einen einzeiligen
  Tombstone ersetzen:
  `### AP-N: entfernt (YYYY-MM-DD)`
  Die Nummer bleibt dauerhaft vergeben und wird nicht neu verwendet. Ein
  Tombstone ist kein aktiver AP.
- APs dürfen präzisiert werden; ihre Identität bleibt stabil.
- APs nicht mit Skill-Inhalten oder ADR-Begründungen duplizieren.

## 6. Journal-Eintrag anlegen

Existiert im Projekt nur `JOURNAL.md` und wurde die Migration (Abschnitt 9)
nicht freigegeben, dort einen datierten Eintrag anhängen. Sonst am Ende der
Session eine neue Datei unter `journal/` anlegen:

`journal/YYYY-MM-DD-HHMM-<slug>.md` (UTC). Den Slug kleingeschrieben mit
Bindestrichen bilden; existiert die Datei bereits, einen Suffix ergänzen.

```shell
stamp="$(date -u +%Y-%m-%d-%H%M)"
```

```markdown
## YYYY-MM-DD — Kurztitel

* **Stand**: ...
* **Änderungen**: ...
* **ADRs**: ADR-0001 (neu) / keine
* **Attention Points**: AP-N (neu) / keine
* **Offen**: ...
```

Ein Eintrag unter `journal/` wird mit der Aufgabe committet und ist ab dem
Merge nach `main` unveränderlich. Er ist Teil des Repos: keine Secrets und keine
Rohprompts aufnehmen. ADR- und AP-Referenzen als Nummern nennen (`ADR-0001`,
`AP-3`), nicht als Dateilinks. Vor dem Merge dürfen solche Referenzen berichtigt
werden, wenn eine noch nicht gemergte ADR oder ein AP umnummeriert wurde
(Abschnitt 7); der dokumentierte Inhalt der Session bleibt dabei unverändert.
Ein Eintrag in der Legacy-`JOURNAL.md` wird nicht committet und bleibt lokal.
Wenn die Session nichts Dauerhaftes hinterlässt, entfällt der Eintrag.

## 7. Konsistenz prüfen

Vor dem Merge:

- Den eigenen Branch gegen den aktuellen `main`-Stand abgleichen (nach
  `git fetch`, falls ein Remote existiert) und rebasen.
- Noch nicht auf `main` gemergte ADRs und APs umnummerieren, wenn ihre Nummer
  dort bereits vergeben ist; alle Referenzen im selben Commit aktualisieren,
  einschließlich der Journal-Einträge aus Abschnitt 6. Diese Berichtigung ist
  vor dem Merge zulässig und verletzt die Unveränderlichkeit nicht.
  Auf `main` gemergte Nummern bleiben unverändert, auch bei revidierten ADRs
  mit `_`-Präfix.
- Verweise auf `docs/adr/` müssen auf existierende Dateien zeigen; nach einer
  Revision darf kein Verweis mehr den alten Namen (ohne `_`) nennen.
- `just check` ist grün.
- Jede Datei in `docs/adr/` folgt dem Muster `_?NNNN-entscheidung.md`.
- ADRs, APs und der Journal-Eintrag sind mit der Aufgabe committet; das gilt
  nur für Einträge unter `journal/`, die Legacy-`JOURNAL.md` bleibt lokal.

Nach dem Merge die bisherige Duplikatprüfung als Nachkontrolle wiederholen:

```shell
ls docs/adr 2>/dev/null | sed 's/^_//' | grep -E '^[0-9]{4}-' | cut -c1-4 | sort | uniq -d
grep -oE '^### AP-[0-9]+' AGENTS.md | sort | uniq -d
```

Das erste Kommando ignoriert das `_`-Präfix revidierter ADRs. Die AP-Prüfung
erfasst auch Tombstones, weil ihre Überschrift mit `### AP-N` beginnt. Zusätzlich
prüfen, dass keine Datei die Konvention verletzt (die Ausgabe muss leer sein):

```shell
ls docs/adr 2>/dev/null | grep -Ev '^_?[0-9]{4}-[a-z0-9-]+\.md$'
```

Weicht der Branch von `main` ab, nummeriert er seine noch nicht gemergten
ADRs und APs auf die nächsten freien Nummern um und aktualisiert alle
Referenzen im selben Commit.

## 8. Bei Unsicherheit

Wenn unklar ist, ob eine Entscheidung eine ADR oder eine Situation einen AP
verdient, den Nutzer fragen. Lieber kein Eintrag als ein spekulativer.

## 9. Migration von `JOURNAL.md`

Für bestehende Projekte, nur nach Zustimmung des Nutzers:

```shell
mkdir -p journal
mv JOURNAL.md "journal/$(date -u +%Y-%m-%d-%H%M)-import.md"
# JOURNAL.md aus .gitignore entfernen
git add journal .gitignore
git commit -m "docs: migrate journal to journal/"
```

Die lokale Historie wird als eine Import-Datei übernommen; nicht automatisch
nach Sessions aufsplitten. Bis zur Migration bleibt `JOURNAL.md` die
Legacy-Quelle. Existieren beide, gilt `journal/`.
