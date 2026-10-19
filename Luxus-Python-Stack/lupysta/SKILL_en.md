---
name: lupysta
description: >
  Working agreements for already initialized Python projects
  from the Luxurious Python Stack: quality gate, documentation, Git and
  release, refactoring, and optional E2E and agent tests. Load it only when
  AGENTS.md selects the relevant capability for the project; older projects
  without a feature list use the migration recipe.
version: 0.5.0
platforms: [linux]
metadata:
  tags: [python, uv, quality-gate, refactoring, e2e, agent-tests]
---

# lupysta

## Purpose and limits

This skill describes **how** to work in an already initialized project. It
does not create projects and does not set up an environment: project
initialization, shell functions, and system configuration are not part of this skill.

The only permanently relevant files are this overview and the project's
`AGENTS.md`. Everything else is loaded on demand. The detailed recipes are
kept in German during development; the German files are canonical.

## Start

1. Read `AGENTS.md`: project profile, feature selection, and local rules.
2. Read `SESSION.md` if it exists.
3. Run `uv sync`.
4. Check `git status` and understand the current branch.
5. Load only the recipes that match the task and the selected features.

## Ground rules

- **`AGENTS.md` is the project source.** It decides which features and
  working agreements apply.
- **Use only selected features.** A feature missing from `AGENTS.md` is not
  assumed and must not be recreated without being asked.
- **Keep `just check` green.** The project quality gate applies before and
  after every change.
- **Do not weaken tests, lint, or typing** to hide failures.
- **Never edit generated documentation by hand.** Run the generator and
  commit the result.
- **Agents never push.** The maintainer reviews and publishes.
- **No destructive Git commands.** No force-push, no `reset --hard` on
  someone else's work, no unrequested worktree removal.

## Recipe index

| Recipe | Contents |
| --- | --- |
| [`references/workflow.md`](references/workflow.md) | Session start and end, `SESSION.md`/`JOURNAL.md`, branch and commit. |
| [`references/quality-gate.md`](references/quality-gate.md) | `just check`, `fix`, `test`, `lint`, `typecheck`, `audit`, `clean`, and debugging. |
| [`references/documentation.md`](references/documentation.md) | `docs`, `docs-check`, `docs-serve`, and generated pages. |
| [`references/git-release.md`](references/git-release.md) | Worktree, `just merge`, `bump`, CI, and publishing. |
| [`references/refactoring.md`](references/refactoring.md) | `rate-design run\|save\|compare`, `refactor`, baseline, and one recipe per step. |
| [`references/refactoring-recipes.md`](references/refactoring-recipes.md) | Extract Function, Rename Internal Symbol, and Remove Confirmed Dead Code. |
| [`references/e2e-tests.md`](references/e2e-tests.md) | Optional Docker suite; load only when `AGENTS.md` selects `e2e`. |
| [`references/agent-tests.md`](references/agent-tests.md) | Optional provider suite; load only when `AGENTS.md` selects `agent`. |
| [`references/migration.md`](references/migration.md) | Older projects without a feature list; check the actual commands. |

## Load on demand

Load a recipe only when the task requires it **and** the project selects the
corresponding capability in `AGENTS.md`. Before using a command, check the
actual recipes in the `Justfile` and the project files. If the project state
differs from `AGENTS.md`, report the difference instead of silently repairing
or recreating features.

For older projects without a feature list, use
[`references/migration.md`](references/migration.md).
