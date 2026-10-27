# Git und Release

Dieses Rezept beschreibt Branch-, Merge- und Release-Abläufe. Es gilt für
jedes initialisierte Projekt. Prüfe vor der Verwendung, welche Rezepte das
`Justfile` tatsächlich anbietet.

## Branch und Worktree

- Ein Aufgaben-Branch ist temporär: Er dient der Arbeit und wird nach dem
  Merge nach `main` gelöscht. Ein stabiler Harness-Branch (`vskilo`,
  `opcode`) ist kein Aufgaben-Branch; er bleibt für die nächste Aufgabe
  bestehen. Den Abschluss regelt [`session-close.md`](session-close.md)
  (Abschnitt 8).
- Der Hauptcheckout ist der Worktree, in dem `main` ausgecheckt ist; in der
  Regel der ursprüngliche Clone. Weitere Worktrees gehören zu demselben
  Repository.
- Auf einem Branch arbeiten: `feat/...`, `fix/...`, `docs/...`,
  `refactor/...` oder `chore/...`.
- Commit-Nachrichten beschreiben die Änderung, zum Beispiel
  `feat: add CSV export`.
- Vor dem Commit `git status` und `git branch --show-current` prüfen.
- Für längere Arbeiten einen separaten Worktree verwenden:
  ```shell
  git worktree add ../<projekt>-feature -b feat/my-feature
  ```
- Im Worktree `uv sync` und `just check` ausführen.
- Änderungen im Worktree committen.
- Den Worktree erst entfernen, wenn er sauber ist; Journal-Einträge sind
  mitcommittet.

## `just merge`

Vor dem Merge:

1. Den Branch auf den aktuellen `main`-Stand rebasen (`git fetch`, falls ein
   Remote existiert).
2. Noch nicht veröffentlichte ADR- und AP-Nummern gegen `main` abgleichen und
   bei Kollisionen umnummerieren; alle Referenzen im selben Commit
   aktualisieren. Revidierte ADRs mit `_`-Präfix behalten ihre Nummer (siehe
   [`session-close.md`](session-close.md)).
3. `just check` ausführen.

`just merge [branch]` ist aus jedem Checkout bedienbar:

1. Es ermittelt den Worktree, in dem `main` ausgecheckt ist. Ist `main` in
   keinem Worktree ausgecheckt, wechselt es im aktuellen, sauberen Checkout
   nach `main` und mergt dort.
2. Es führt dort `git merge --ff-only <branch>` aus.
3. Ist der Quell-Branch in einem anderen Worktree als dem Ziel und dem
   aktuellen Checkout ausgecheckt und ist dieser sauber, entfernt es ihn und
   löscht den Branch.
4. Läuft der Befehl im Quell-Worktree selbst, bleibt dieser auf seinem Branch
   stehen; der Zielpfad wird genannt. Ein `git switch main` ist dort nicht
   möglich, solange `main` im Hauptcheckout ausgecheckt ist – in den
   Hauptcheckout wechseln. Für einen temporären Aufgaben-Branch dort
   `git worktree remove <pfad>` und `git branch -d <branch>` ausführen; ein
   stabiler Harness-Branch bleibt.
5. Ist der Quell-Worktree schmutzig, bleibt er stehen; der Pfad wird genannt.
6. Existiert der Quell-Branch nur als lokaler Branch ohne Worktree, wird er
   gelöscht.
7. Es pusht nie.
8. Nach dem Merge nur die Eindeutigkeit der ADR- und AP-Nummern als Kontrolle
   erneut prüfen.

Ohne Argument sucht das Rezept einen eindeutigen Kandidaten: zuerst einen
Branch in einem anderen Worktree, sonst den einzigen lokalen Branch, der
noch nicht in `main` gemergt ist. Bei keinem oder mehreren Kandidaten
bricht es verständlich ab; dann den Branch explizit übergeben.

Bei Divergenz:

```shell
git rebase main
# ADR-/AP-Nummern gegen main abgleichen und ggf. umnummerieren
just check
just merge <branch>
```

Der Merge ist der letzte Schritt der Pflicht-Checkliste in
[`session-close.md`](session-close.md). Danach ist `main` im Hauptcheckout
ausgecheckt; ein Harness-Worktree darf auf seinem stabilen Branch bleiben.

## Version und Tag

Versionen niemals manuell in `pyproject.toml` oder `__init__.py` ändern und
niemals manuell taggen. Immer `bump-my-version` über `just bump` verwenden:

```shell
just bump patch   # 0.1.0 → 0.1.1
just bump minor   # 0.1.1 → 0.2.0
just bump major   # 0.2.0 → 1.0.0
```

`just bump` verlangt einen sauberen Arbeitsbaum. Es committet die
Versionsänderung und erzeugt den Tag.

## CI

- `.github/workflows/ci.yml` läuft bei Push und Pull Request.
- Der Job synchronisiert die Umgebung und führt `just check` sowie
  `pip-audit` aus.
- Bibliotheken haben zusätzlich `.github/workflows/release.yml`.
- Der Release-Workflow läuft bei Tags `v*`, prüft das Gate und veröffentlicht
  per PyPI Trusted Publishing (OIDC).
- Vor dem ersten Release muss ein Trusted Publisher bei PyPI eingerichtet
  sein.

## Veröffentlichung

Agenten pushen nie. Der Maintainer prüft lokal:

```shell
git log --oneline origin/main..main
git diff origin/main..main
git push origin main
git push origin --tags   # nur wenn der Release-Workflow Tags benötigt
```

## Branch-Namen für mehrere Harnesses

Pro Harness einen stabilen Branch-Namen und einen eigenen Worktree verwenden,
zum Beispiel `vskilo` und `opcode`. Ein stabiler Harness-Branch ist kein
Aufgaben-Branch: Er wird nach dem Merge nicht gelöscht und sein Worktree
bleibt stehen. Deshalb `just merge` aus dem Harness-Worktree ausführen und
danach in den Hauptcheckout wechseln:

```shell
just merge vskilo
main_path="$(git worktree list --porcelain | awk -v ref="refs/heads/main" '
    /^worktree / { path = substr($0, 10) }
    /^branch / && $2 == ref { print path; exit }
')"
cd "$main_path"
```

Der Merge landet im Hauptcheckout; der Harness-Worktree bleibt auf `vskilo`
und wird für die nächste Aufgabe wiederverwendet. Ein `git switch main` im
Harness-Worktree scheitert, solange `main` im Hauptcheckout ausgecheckt ist –
deshalb der Wechsel in den Hauptcheckout.

Wird `just merge vskilo` dagegen aus dem Hauptcheckout ausgeführt, entfernt es
den sauberen Harness-Worktree und löscht `vskilo`. Das ist für einen stabilen
Harness-Branch nicht gewollt; dann aus dem Harness-Worktree mergen oder im
Hauptcheckout manuell `git merge --ff-only vskilo` ausführen.

Weil parameterloses `just merge` bei mehreren Worktrees mehrere Kandidaten
sieht, den Branch explizit übergeben: `just merge vskilo`.

## Sicherheitsregeln

- Kein Force-Push.
- Kein `git reset --hard` auf fremde Arbeit.
- Kein Entfernen eines Worktrees mit uncommitteten Änderungen.
- Keine manuellen Tags und keine manuellen Versionsnummern.
