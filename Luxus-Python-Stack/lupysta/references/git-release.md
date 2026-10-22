# Git und Release

Dieses Rezept beschreibt Branch-, Merge- und Release-Abläufe. Es gilt für
jedes initialisierte Projekt. Prüfe vor der Verwendung, welche Rezepte das
`Justfile` tatsächlich anbietet.

## Branch und Worktree

- Auf einem Branch arbeiten: `feat/...`, `fix/...`, `docs/...`,
  `refactor/...` oder `chore/...`.
- Für längere Arbeiten einen separaten Worktree verwenden:
  ```shell
  git worktree add ../<projekt>-feature -b feat/my-feature
  ```
- Im Worktree `uv sync` und `just check` ausführen.
- Änderungen im Worktree committen.
- Den Worktree erst entfernen, wenn keine lokalen `JOURNAL.md`-Inhalte
  verloren gehen.

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

1. Es ermittelt den Worktree, in dem `main` ausgecheckt ist.
2. Es führt dort `git merge --ff-only <branch>` aus.
3. Es entfernt den Quell-Worktree nur, wenn dieser sauber ist und keine
   lokalen `JOURNAL.md`-Inhalte enthält.
4. Andernfalls bleibt der Worktree stehen; der Pfad wird genannt.
5. Es pusht nie.
6. Nach dem Merge nur die Eindeutigkeit der ADR- und AP-Nummern als Kontrolle
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

Pro Harness einen stabilen Branch-Namen und einen Worktree verwenden, zum
Beispiel `vskilo` und `opcode`. Weil parameterloses `just merge` bei
mehreren Worktrees mehrere Kandidaten sieht, den Branch explizit übergeben:
`just merge vskilo`.

## Sicherheitsregeln

- Kein Force-Push.
- Kein `git reset --hard` auf fremde Arbeit.
- Kein Entfernen eines Worktrees mit lokalen `JOURNAL.md`-Inhalten.
- Keine manuellen Tags und keine manuellen Versionsnummern.
