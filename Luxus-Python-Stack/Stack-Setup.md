# Einrichtungsanweisungen für den Luxus-Python-Stack

* Die Codeblöcke können per Kopieren/Einfügen in die Shell eingefügt werden. 
* Dazwischen gibt es Hinweise („⚠️“), die beachtet werden müssen.
* Dieses Setup setzt das [Basis-System](../Setup.md) voraus.

## Installation: UV, Ruff, Bump-my-version, Basedpyright, Nbstripout, VSCode-Python-Extension

```shell
# UV (der blitzschnelle, in Rust geschriebene Manager)
curl -LsSf https://astral.sh/uv/install.sh | sh
# UV für die aktuelle Shell laden; ~/.local/bin wird bereits im Basis-Setup in den PATH aufgenommen
source "$HOME/.local/bin/env"

# Grundausstattung
uv tool install ruff && uv tool install bump-my-version && uv tool install basedpyright && uv tool install nbstripout

# Das direnv-Layout für uv erstellen.
mkdir -p ~/.config/direnv && cat << 'EOF' > ~/.config/direnv/direnvrc
layout_uv() {
    # Falls noch keine Umgebung existiert, erstellt uv in Windeseile eine.
    [ ! -d ".venv" ] && uv venv .venv
    # direnv mitteilen, wo sich das bin-Verzeichnis befindet.
    export VIRTUAL_ENV="$(pwd)/.venv" && PATH_add "$VIRTUAL_ENV/bin"
    # UV kennt das ebenfalls.
    export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
}
EOF
exec zsh # zsh neu laden
```

## mamba
```shell
# Installationsskript herunterladen
cd ~/Downloads  && curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"

# Batch-Modus (-b): Installiert still ohne interaktive Abfragen nach ~/miniforge3
bash Miniforge3-$(uname)-$(uname -m).sh -b -p "$HOME/miniforge3"

# UV-Sicherheitsnetz registrieren (statt `conda init zsh` schreiben wir das Setup direkt in ~/.zshrc)
cat << 'EOF' >> ~/.zshrc
# --- UV ---
# Ausschließlich eigene/verwaltete Python-Versionen verwenden (schützt das System-Python!)
export UV_PYTHON_PREFERENCE=only-managed

# --- direnv ---
# direnv-Logausgabe unterdrücken, um Störungen des p10k-Instant-Prompt zu vermeiden
export DIRENV_LOG_FORMAT=""

# --- Mamba-Initialisierung ---
# Mamba 2.0+ benötigt diese Variable vor der Initialisierung
export MAMBA_ROOT_PREFIX="$HOME/miniforge3"
# Hier laden wir explizit den 'mamba'-Hook, nicht 'conda'
__mamba_setup="$("$HOME/miniforge3/bin/mamba" 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    # Miniforge erstellt praktischerweise auch eine mamba.sh
    if [ -f "$HOME/miniforge3/etc/profile.d/mamba.sh" ]; then
        . "$HOME/miniforge3/etc/profile.d/mamba.sh"
    else
        export PATH="$HOME/miniforge3/bin:$PATH"
    fi
fi
unset __mamba_setup

# --- Standard-Umgebungsaktivierung ---
# Eine Mamba-Umgebung nur aktivieren, wenn im aktuellen Verzeichnis keine
# projektspezifische .envrc vorhanden ist. In Projektverzeichnissen hat direnv
# ohnehin Vorrang vor Mamba — das Überspringen der Aktivierung hält den
# Shell-Start schnell.
if [ ! -f "$PWD/.envrc" ]; then
    mamba activate $([[ -f ~/.startenv ]] && echo "$(< ~/.startenv)" || echo base)
fi

# startenv-Funktion
act() { [ "$#" -ne 0 ] && echo $1 > ~/.startenv && mamba activate $1; }

# Erstellt eine Umgebung in einem Ordner, falls sie noch nicht existiert, und stellt sie unter die Verwaltung von direnv.
alias allowuv='echo "layout uv" > .envrc && direnv allow'

# --- Jupyter-LSP-Shims ---
# jupyter_lsp startet Language-Server in der Prozessgruppe des Terminals, sodass
# Strg-C auch sie trifft (basedpyright stirbt dann mit einem KeyboardInterrupt-Traceback).
# Die Shims ignorieren SIGINT; dieses Verzeichnis muss früh im PATH stehen.
export PATH="$HOME/.local/libexec/jupyter-lsp-shims:$PATH"
EOF

# --- Globaler Jupyter-Fix für Google Colab ---
# Deaktiviert die RTC-Server-Erweiterungen global (~/.jupyter), um WebSocket-
# Abstürze mit Colab zu verhindern. Übersteht das Löschen und Neuerstellen von Umgebungen.
mkdir -p ~/.jupyter && cat << 'EOF' > ~/.jupyter/jupyter_server_config.json
{
  "ServerApp": {
    "jpserver_extensions": {
      "jupyter_server_documents": false,
      "jupyter_server_ydoc": false
    }
  }
}
EOF

# --- JupyterLab-Polling des Collaboration Room deaktivieren ---
# Der Client fragt etwa alle 3 s /api/collaboration/room/JupyterLab:globalAwareness ab.
# Selbst mit deaktivierten RTC-Erweiterungen sendet der JupyterLab-Client diese
# Anfragen weiter und verursacht 404-Warnungen. Die folgenden Benutzereinstellungen
# unterdrücken sie.
mkdir -p ~/.jupyter/lab/user-settings/\@jupyterlab/collaboration-extension/
cat << 'EOF' > ~/.jupyter/lab/user-settings/\@jupyterlab/collaboration-extension/plugin.jupyterlab-settings
{
    "collaborative": false,
    "enableDocs": false
}
EOF

# --- Jupyter-LSP-Fix: Strg-C darf den Language-Server nicht beenden ---
# jupyter_lsp startet basedpyright-langserver mit einem einfachen subprocess.Popen
# (jupyter_lsp/session.py, init_process) und damit ohne neue Session. Der
# Language-Server bleibt in der Vordergrund-Prozessgruppe des Terminals, sodass
# Strg-C SIGINT an Jupyter UND an basedpyright sendet. Jupyter fragt
# "Shut down this Jupyter server (y/[n])?", während der Python-Wrapper von
# basedpyright keine KeyboardInterrupt-Behandlung hat und mitten in der
# Abfrage mit einem Traceback stirbt ("No answer for 5s").
#
# Der Shim ignoriert SIGINT (SIG_IGN überlebt exec, sodass der node-Prozess es
# erbt) und startet die echte Binärdatei per exec, aufgelöst über den PATH ohne
# das Shim-Verzeichnis. Funktioniert sowohl für basedpyright aus uv-Tools als
# auch aus conda. ~/.zshrc stellt das Verzeichnis an den Anfang des PATH.
mkdir -p ~/.local/libexec/jupyter-lsp-shims
cat << 'EOF' > ~/.local/libexec/jupyter-lsp-shims/basedpyright-langserver
#!/bin/sh
trap '' INT

self_dir=$(dirname "$0")
search_path=$(printf '%s' "$PATH" | tr ':' '\n' | grep -vxF "$self_dir" | paste -sd:)

real=$(PATH=$search_path command -v basedpyright-langserver) || {
    echo "basedpyright-langserver shim: no real basedpyright-langserver on PATH" >&2
    exit 127
}

exec "$real" "$@"
EOF
chmod +x ~/.local/libexec/jupyter-lsp-shims/basedpyright-langserver

# Shell neu laden, um mamba zu aktivieren
exec zsh
```

## Data-Science-Mamba-Umgebung
>* ⚠️ **Für Kompatibilität mit der Colab-Runtime wird ipywidgets 7.7.1 verwendet.**
>* ⚠️ **Um das Speichern von Notebook-Ausgaben in GitHub zu unterdrücken, im Repository-Ordner `nbstripout --install` ausführen.**
```shell
#                     (Neu-)Erstellen einer Data-Science-Umgebung mit allem Drum und Dran und aktivieren
# _________________________________________________________________________________________________________________________________
py=3.12 && ENV_NAME="ds${py: -2}" && mamba deactivate && mamba remove -y -n $ENV_NAME --all 2>/dev/null # Python 3.XY --> 'dsXY'
mamba   create -y -n $ENV_NAME python=$py google-colab && mamba activate $ENV_NAME # getestet mit Python 3.11/12/13
uv pip  install  -U jupyterlab jupyter_http_over_ws jupyter-ai jupyterlab-github xeus-python huggingface-hub ipywidgets==7.7.1
jupyter labextension enable jupyter_http_over_ws && echo $ENV_NAME > ~/.startenv
python  -m ipykernel install --user --name $ENV_NAME --display-name $ENV_NAME
# _______________________________________'act'_statt_'mamba_activate'_verwenden_____________________________________________________
# mamba activate $(cat ~/.startenv) # in die Shell-rc-Datei einfügen
# act() { [ "$#" -ne 0 ] && echo $1 > ~/.startenv && mamba activate $1; } # Umgebung wechseln und merken
```


## Luxus-Python-Stack: pyinit (Projekt-Init)

>* ⚠️ **`pyinit` ist ein eigenständiges Tool mit eigenem Repository. Es wird geklont und als editierbares uv-Tool installiert, damit lokale Änderungen sofort wirken.**

```shell
# Projekt-Init klonen und als uv-Tool installieren
git clone https://github.com/frankausberlin/pyinit ~/gits/pyinit
uv tool install --editable ~/gits/pyinit

# ~/.local/bin muss im PATH liegen; dort legt uv tool install die Entrypoints ab
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc ;;
esac

# Installation prüfen
pyinit --help
pyinit list
```

**Updates**

```shell
git -C ~/gits/pyinit pull --ff-only
# nach Änderungen an pyproject.toml oder am Entrypoint erneut installieren:
uv tool install --editable --force ~/gits/pyinit
```

**Uninstall und Neuinstallation**

```shell
uv tool uninstall pyinit
```

Wird der Clone verschoben oder neu geklont, zeigt die editable Installation auf
den alten Pfad. Dann mit `uv tool install --editable --force ~/gits/pyinit` neu
installieren; bei einem zweiten Clone den neuen Pfad verwenden.

## Luxus-Python-Stack: Shell-Funktionen (jl, p10k)

```shell
# Funktionen laden
cat << 'EOF' >> ~/.zshrc
# aus LUDESTA einfügen
source ~/gits/ludesta/Luxus-Python-Stack/scripts/luxuspythonstack.sh
EOF

# das Jupyter-Prompt-Element in .p10k.zsh einfügen
sed -i '/^[[:space:]]*anaconda/a \    my_jupyter              # benutzerdefiniertes Jupyter-Segment (siehe prompt_my_jupyter-Funktion in luxuspythonstack.sh)' ~/.p10k.zsh

# Skill zugänglich machen
mkdir -p ~/.agents/skills/
ln -s ~/gits/ludesta/Luxus-Python-Stack/lupysta ~/.agents/skills/lupysta

# python extension in vscode installieren
n=0; until [ "$n" -ge 5 ] || code --install-extension ms-python.python; do n=$((n+1)); echo "Fehlgeschlagen ($n/5). Warte 5s..."; sleep 5; done
n=0; until [ "$n" -ge 5 ] || code --install-extension charliermarsh.ruff; do n=$((n+1)); echo "Fehlgeschlagen ($n/5). Warte 5s..."; sleep 5; done
n=0; until [ "$n" -ge 5 ] || code --install-extension detachhead.basedpyright; do n=$((n+1)); echo "Fehlgeschlagen ($n/5). Warte 5s..."; sleep 5; done

exec zsh
```

## Überprüfung

>* ⚠️ **Die allgemeinen Prüfungen stehen in der [Basis-Überprüfung](../Setup.md#überprüfung).**

```shell
mkdir -p ~/.local/bin
cat << 'EOF' > ~/.local/bin/test-lupysta
#!/bin/bash
set -o pipefail

fail=0
ok() { echo "ok $*"; }
missing() { echo "MISSING $*"; fail=1; }

base_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
zsh_clean() {
    env -u ZDOTDIR -u VIRTUAL_ENV -u UV_PYTHON_PREFERENCE -u MAMBA_ROOT_PREFIX \
        PATH="$base_path" zsh -ic "$1"
}

# ── UV / Python-Werkzeuge ────────────────────────────────────────────────────
# Nicht die Setup-Shell prüfen: sie hat ~/.local/bin nur geerbt. Der Test startet
# zsh mit einem kontrollierten PATH, damit nur ~/.zshrc zählt.
zsh_clean 'r=0; for t in uv ruff basedpyright bump-my-version nbstripout pyinit; do if command -v "$t" >/dev/null; then echo "ok $t"; else echo "MISSING $t"; r=1; fi; done; exit $r' || fail=1
uv --version || fail=1
uv tool list || fail=1                                # Versionen der globalen uv-Tools

# ── Shell-Integration ────────────────────────────────────────────────────────
grep -q 'layout_uv' ~/.config/direnv/direnvrc 2>/dev/null && ok layout_uv || missing layout_uv
grep -q 'my_jupyter' ~/.p10k.zsh 2>/dev/null && ok "p10k segment" || missing "p10k segment"
grep -q 'luxuspythonstack.sh' ~/.zshrc && ok "stack functions" || missing "stack functions"
[ -f ~/.agents/skills/lupysta/SKILL.md ] && ok "lupysta skill" || missing "lupysta skill"
[ -x ~/.local/bin/test-lupysta ] && ok "test-lupysta" || missing "test-lupysta"
zsh_clean 'command -v test-lupysta >/dev/null' && ok "$HOME/.local/bin im PATH" || missing "$HOME/.local/bin im PATH"
zsh_clean 'pyinit list | grep -q mcp' && ok "pyinit profile mcp" || missing "pyinit profile mcp"
zsh_clean 'command -v jupyter-launcher >/dev/null' && ok jupyter-launcher || missing jupyter-launcher
zsh_clean 'alias jl' >/dev/null 2>&1 && ok "alias jl" || missing "alias jl"
zsh_clean '
if [ "$UV_PYTHON_PREFERENCE" = "only-managed" ]; then
    echo "ok UV_PYTHON_PREFERENCE=$UV_PYTHON_PREFERENCE"
else
    echo "MISSING UV_PYTHON_PREFERENCE (erwartet: only-managed, ist: ${UV_PYTHON_PREFERENCE:-nicht gesetzt})"
    exit 1
fi' || fail=1
zsh_clean '
if [ -n "$MAMBA_ROOT_PREFIX" ]; then
    echo "ok MAMBA_ROOT_PREFIX=$MAMBA_ROOT_PREFIX"
else
    echo "MISSING MAMBA_ROOT_PREFIX"
    exit 1
fi' || fail=1

# ── Mamba / Data Science ─────────────────────────────────────────────────────
mamba --version | head -1 || fail=1
zsh_clean 'mamba activate base' && ok "mamba hook" || missing "mamba hook"
env_name="$(cat ~/.startenv 2>/dev/null || echo base)"
echo "startenv: $env_name"
mamba env list | grep -qE "^[[:space:]]*${env_name}[[:space:]]" && ok "env $env_name" || missing "env $env_name"
mamba run -n "$env_name" jupyter lab --version || fail=1
mamba run -n "$env_name" python -c 'import importlib.util as u; raise SystemExit(0 if u.find_spec("jupyter_http_over_ws") else 1)' \
    >/dev/null 2>&1 && ok jupyter_http_over_ws || missing jupyter_http_over_ws

# Der Jupyter-LSP-Shim muss Vorrang vor dem echten basedpyright-langserver haben
shim="$HOME/.local/libexec/jupyter-lsp-shims/basedpyright-langserver"
resolved="$(zsh_clean 'command -v basedpyright-langserver')"
[ "$resolved" = "$shim" ] && ok "basedpyright-langserver shim" || missing "basedpyright-langserver shim (got: ${resolved:-nothing})"

# ── VS Code: Python-Stack ────────────────────────────────────────────────────
extensions="$(code --list-extensions)" || fail=1
printf '%s\n' "$extensions" | grep -qix ms-python.python && ok ms-python.python || missing ms-python.python
for e in charliermarsh.ruff detachhead.basedpyright; do
    printf '%s\n' "$extensions" | grep -qix "$e" && echo "ok $e" || echo "HINWEIS: $e optional (wird pro Projekt empfohlen)"
done

exit "$fail"
EOF

# Das Skript wird nur erzeugt. Ausführen mit `test-lupysta` oder `~/.local/bin/test-lupysta`
chmod +x ~/.local/bin/test-lupysta

# und direkt mal testen
test-lupysta
```

