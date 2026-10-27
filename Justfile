set shell := ["bash", "-uc"]

# Shell scripts checked by the local gate
scripts := "Luxus-Python-Stack/scripts/luxuspythonstack.sh tests/test-shell.sh tests/scripts/check-links.sh tests/scripts/check-workflows.sh"

# Everything the fast CI job runs, locally.
# Keep the recipe list in sync with the 'fast' job in .github/workflows/ci.yml.
check: syntax shellcheck shell-tests links workflows

# Bash syntax check of every shell script
syntax:
    bash -n {{scripts}}

# ShellCheck at warning level
shellcheck:
    shellcheck -S warning {{scripts}}

# Shell tests; the zsh prompt checks run only when zsh is installed
shell-tests:
    bash tests/test-shell.sh

# Relative Markdown links in tracked files
links:
    bash tests/scripts/check-links.sh

# Workflow lint (needs Docker)
workflows:
    bash tests/scripts/check-workflows.sh
