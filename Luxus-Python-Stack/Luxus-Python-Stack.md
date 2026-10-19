# Luxus Python Stack (English reference)

> The German [Luxus-Python-Stack_de.md](Luxus-Python-Stack_de.md) is the
> canonical working version during development. This page is a short English
> reference and may lag behind.

## Components

| Component | Location |
| --- | --- |
| Stack documentation (German) | [Luxus-Python-Stack_de.md](Luxus-Python-Stack_de.md) |
| Stack setup (German) | [Stack-Setup_de.md](Stack-Setup_de.md) |
| Skill (English reference) | [lupysta/SKILL_en.md](lupysta/SKILL_en.md) |
| Skill (German, canonical) | [lupysta/SKILL.md](lupysta/SKILL.md) |
| Shell script | [luxuspythonstack.sh](luxuspythonstack.sh) |

## Model

- `pyinit` initializes a new project. It never updates, repairs, merges, or
  migrates an existing project.
- The generated `AGENTS.md` selects the project features. The installed
  `lupysta` skill describes the working recipes; recipes are loaded on
  demand.
- The quality gate is `just check`. Refactoring uses
  `just rate-design run|save|compare` and `just refactor`.
- Linux is the reference platform. macOS support requires CI and test
  coverage before it can be promised.
- The script keeps the name `luxuspythonstack.sh` for compatibility; the
  skill name is `lupysta`.

## See also

- [Stack setup (English reference)](Stack-Setup.md)
- [Repository README](../README.md)
