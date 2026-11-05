# Session-Abschluss

Dieses Rezept wird am Ende jeder erfüllten Aufgabe ausgeführt, spätestens am
Sitzungsende. Es entscheidet, ob die Aufgabe einen Attention
Point hinterlässt, und legt einen Eintrag unter `journal/` an. „Keine
Einträge“ ist ein gültiges Ergebnis.

## 1. Aufgabe prüfen

- Diff und Commits der Aufgabe ansehen.
- Die Aufgabe aus Sicht des nächsten Agenten bewerten: Was war nicht
  offensichtlich? Welche Entscheidung könnte später hinterfragt werden?
- Nur projektbezogenes Wissen dokumentieren, nicht die Arbeit nacherzählen.

## 2. Attention-Point-Kandidat?

Ein Attention Point ist sinnvoll, wenn alle folgenden Punkte zutreffen:

- Die Situation ist projektspezifisch und nicht schon im Skill beschrieben.
- Sie tritt wahrscheinlich wieder auf.
- Die Handhabung ist stabil und klar beschreibbar.
- Sie ist nicht aus dem Code oder den Tests offensichtlich.
- Sie ist kein Einmal-Bug und kein persönlicher Workaround.

Ein AP beschreibt **wie** man in einer Situation handelt; eine ADR beschreibt
**warum** entschieden wurde. ADRs gehören allein dem Nutzer: Der Agent liest
vorhandene ADRs und befolgt sie, legt aber keine an, ändert sie nicht und
nummeriert sie nicht um. Eine ADR wird im AP höchstens referenziert; den
ADR-Text nicht im AP duplizieren.

## 3. Attention Point anlegen

Im Abschnitt `## Attention Points` in `AGENTS.md` ergänzen:

```markdown
### Kurztitel

- **Situation**: ...
- **Handhabung**: ...
```

- Die Überschrift nennt das Problem; die `Situation` wiederholt sie nicht und
  ist genau ein Satz.
- Die `Handhabung` ist ein Satz oder ein kurzer Abschnitt; bei mehreren
  Schritten eine kurze Liste. Codebeispiele gehören bei Bedarf in die
  Handhabung.
- Mehrere Prosa-Absätze oder längere Begründungen sind ein Rezept, kein AP.
- APs haben keine Nummern und keine Tombstones. Obsolete APs werden ersatzlos
  gelöscht; die Git-Historie ist das Archiv (`git log -p -- AGENTS.md`).
- Überschriften sind eindeutig und beschreibend; die Identität ist der Titel.
- Umbenennen, Zusammenführen und Entfernen sind erlaubt; nur aktuelle Verweise
  werden angepasst, Journal-Einträge bleiben historisch.
- APs nicht mit Skill-Inhalten oder ADR-Begründungen duplizieren.

## 4. Journal-Eintrag anlegen

Existiert im Projekt nur `JOURNAL.md` und wurde die Übernahme (Abschnitt 8)
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
* **ADRs**: keine / vom Nutzer angelegt: ADR-0001
* **Attention Points**: keine / "Kurztitel" (neu)
* **Offen**: ...
```

Ein Eintrag unter `journal/` wird mit der Aufgabe committet und ist ab dem
Merge nach `main` unveränderlich. Er ist Teil des Repos: keine Secrets und keine
Rohprompts aufnehmen. Vorhandene ADRs als Nummer nennen (`ADR-0001`); APs mit
ihrem Titel nennen, nicht als Nummer. Spätere Umbenennungen oder das Löschen
eines APs ändern den historischen Eintrag nicht.
Ein Eintrag in der Legacy-`JOURNAL.md` wird nicht committet und bleibt lokal.
Wenn die Session nichts Dauerhaftes hinterlässt, entfällt der Eintrag.

## 5. Konsistenz prüfen

Vor dem Merge:

- Den eigenen Branch gegen den aktuellen `main`-Stand abgleichen (nach
  `git fetch`, falls ein Remote existiert) und rebasen.
- Vorhandene ADR-Verweise nur lesen. ADR-Dateien und ihre Nummern sind
  Nutzer-Sache und werden vom Agenten nicht geprüft.
- `just check` ist grün.
- APs und der Journal-Eintrag sind mit der Aufgabe committet; das gilt nur für
  Einträge unter `journal/`, die Legacy-`JOURNAL.md` bleibt lokal.
- AP-Überschriften in `AGENTS.md` sind eindeutig; eine Nummern- oder
  Duplikatprüfung gibt es nicht.

## 6. Arbeitsbaum

Eine Aufgabe ist erst abgeschlossen, wenn der Merge nach `main` erfolgt ist
und `main` im Hauptcheckout ausgecheckt und sauber ist.

```shell
git worktree list            # Hauptcheckout mit [main] identifizieren
git status --short --branch  # im Hauptcheckout: ## main
git branch --show-current    # im Hauptcheckout: main
```

- Den fertigen Aufgaben-Branch lokal nach `main` mergen. Bevorzugt mit
  `just merge [branch]`; ohne `just` im Hauptcheckout manuell per
  Fast-Forward:
  `git switch main && git merge --ff-only <branch> && git branch -d <branch>`.
- `just merge` mergt in dem Worktree, in dem `main` ausgecheckt ist. Läuft der
  Befehl in einem anderen Worktree, bleibt dieser nach dem Merge auf seinem
  Branch stehen; `just merge` nennt den Zielpfad. Danach in den Hauptcheckout
  wechseln: Ein `git switch main` im Quell-Worktree scheitert, solange `main`
  im Hauptcheckout ausgecheckt ist.
- Ein temporärer Aufgaben-Branch wird gelöscht. Sein sauberer Quell-Worktree
  wird von `just merge` entfernt, sofern er nicht der aktuelle Checkout ist.
  War er der aktuelle Checkout, nach dem Wechsel in den Hauptcheckout
  `git worktree remove <pfad>` und `git branch -d <branch>` ausführen.
  Einen Harness-Worktree nicht ungefragt entfernen.
- Ein stabiler Harness-Branch (zum Beispiel `vskilo`) ist kein
  Aufgaben-Branch. Er und sein Worktree bleiben nach dem Merge bestehen und
  werden für die nächste Aufgabe wiederverwendet. Solche Branches aus dem
  Harness-Worktree mergen, damit `just merge` den Worktree nicht entfernt
  (siehe [`git-release.md`](git-release.md)).
- Abschlusskontrolle im Hauptcheckout (oder mit `git -C <pfad>`):
  `git branch --show-current` gibt `main` aus und `git status --short` ist
  leer. In einem Harness-Worktree zeigt `git worktree list` den Hauptcheckout
  mit `main`; der Worktree selbst darf auf seinem stabilen Branch bleiben.
- Kein Push. Veröffentlichen ist ein Schritt des Maintainers und nur von
  `main` aus zulässig.
- Ein Plan oder Rezept darf einen Branch verlangen; der Endzustand folgt
  aus `AGENTS.md`. Der Hauptcheckout bleibt auf `main`. Details in
  [`git-release.md`](git-release.md).

## 7. Bei Unsicherheit

Wenn unklar ist, ob eine Situation einen AP verdient, den Nutzer fragen. 
Lieber kein Eintrag als ein spekulativer.

## 8. Übernahme von `JOURNAL.md`

Für bestehende Projekte, nur nach Zustimmung des Nutzers:

```shell
mkdir -p journal
mv JOURNAL.md "journal/$(date -u +%Y-%m-%d-%H%M)-import.md"
# JOURNAL.md aus .gitignore entfernen
git add journal .gitignore
git commit -m "docs: migrate journal to journal/"
```

Die lokale Historie wird als eine Import-Datei übernommen; nicht automatisch
nach Sessions aufsplitten. Bis zur Übernahme bleibt `JOURNAL.md` die
Legacy-Quelle. Existieren beide, gilt `journal/`.
