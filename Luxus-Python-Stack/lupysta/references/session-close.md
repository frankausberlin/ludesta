# Session-Abschluss

Dieses Rezept wird am Ende jeder erfüllten Aufgabe ausgeführt, spätestens am
Sitzungsende. Es entscheidet, ob die Aufgabe eine ADR oder einen Attention
Point hinterlässt, und schreibt `JOURNAL.md` fort. „Keine Einträge“ ist ein
gültiges Ergebnis.

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

Dateiname: `docs/adr/NNNN-kurz-titel.md` (vierstellige Nummer, Kleinbuchstaben,
Bindestriche). `docs/adr/` bei Bedarf anlegen.

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

- Die nächste freie Nummer verwenden, beginnend mit `0001`.
- Veröffentlichte ADRs niemals löschen oder umnummerieren. Sobald eine ADR
  auf `main` gemergt ist, gilt ihre Nummer als vergeben.
- Wird eine Entscheidung revidiert, eine neue ADR mit der nächsten Nummer
  anlegen, die alte auf `Status: superseded by ADR-MMMM` setzen und in beiden
  Dateien aufeinander verweisen.
- Die ADR im ADR-Index in `AGENTS.md` verlinken:

  ```markdown
  | [ADR-NNNN](docs/adr/NNNN-kurz-titel.md) | Titel | accepted |
  ```

## 5. Attention Point anlegen

Im Abschnitt `## Attention Points` in `AGENTS.md` ergänzen:

```markdown

AP-N: Kurztitel
---
* **Situation**: ...
* **Handhabung**: ...
* **Involvierte ADRs**: ...
* **Kontext**: ...
---
```

- Die nächste freie Nummer verwenden; Nummern bleiben stabil, Lücken sind ok.
- APs dürfen präzisiert oder entfernt werden, wenn sie nicht mehr gelten.
- APs nicht mit Skill-Inhalten oder ADR-Begründungen duplizieren.

## 6. JOURNAL fortschreiben

Am Ende von `JOURNAL.md` einen datierten Eintrag anhängen:

```markdown
## YYYY-MM-DD — Kurztitel

* **Stand**: ...
* **Änderungen**: ...
* **ADRs**: ADR-NNNN (neu) / keine
* **Attention Points**: AP-N (neu) / keine
* **Offen**: ...
```

## 7. Konsistenz prüfen

- Alle im ADR-Index verlinkten Dateien existieren.
- ADR-Nummern sind eindeutig; AP-Nummern sind eindeutig.
- `just check` ist grün.
- ADRs und APs sind mit der Aufgabe committet; `JOURNAL.md` bleibt lokal.

Nach einem Merge prüfen, ob zwei Branches dieselbe Nummer vergeben haben:

```shell
ls docs/adr 2>/dev/null | grep -E '^[0-9]{4}-' | cut -c1-4 | sort | uniq -d
grep -oE '^### AP-[0-9]+' AGENTS.md | sort | uniq -d
```

Der später gemergte Branch nummeriert seine noch nicht auf `main` gemergten
ADRs und APs auf die nächsten freien Nummern um und aktualisiert alle
Referenzen im selben Commit. Auf `main` gemergte Nummern bleiben unverändert.

## 8. Bei Unsicherheit

Wenn unklar ist, ob eine Entscheidung eine ADR oder eine Situation einen AP
verdient, den Nutzer fragen. Lieber kein Eintrag als ein spekulativer.
