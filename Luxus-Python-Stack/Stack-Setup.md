# Setup instructions for the Luxus Python Stack

* The code blocks can be inserted into the shell via copy/paste. 
* In between there are instructions ('⚠️') that must be observed.

## Base System
```shell
# I prefer nala
sudo apt update && sudo apt install -y nala
sudo nala update && sudo nala upgrade

# Core System Essentials / CLI Tools & Productivity / Build Essentials & Dev Libraries
sudo nala install -y \
  ca-certificates curl wget gnupg gpg software-properties-common \
  openssh-server fail2ban unattended-upgrades util-linux-extra net-tools \
  snapd 7zip xz-utils aria2 sqlite3 \
  zsh git gh tmux btop htop iotop nvtop fastfetch tree hwinfo s-tui \
  ripgrep fzf zoxide jq tealdeer shellcheck shfmt apt-transport-https \
  build-essential cmake make pkg-config libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev libncurses-dev libffi-dev liblzma-dev \
  libxml2-dev libxmlsec1-dev tk-dev libyaml-dev libfuse2t64 \
  python3 pipx

# enable ssh
sudo systemctl enable --now ssh
# use the ip ('ip a') to connect ('ssh <user>@<ip>') ssh to this machine

# switch to zsh
chsh -s $(which zsh) 
```
> ⚠️ **do re-login and select option 2: Recommended settings**

## ZSH with antidote and p10k
```shell
# insert from LUDESTA
echo 'setopt INTERACTIVE_COMMENTS' >> ~/.zshrc
```
> ⚠️ **reopen zsh (necessary to be able to use comment characters '#')**

```shell
# Fonts (MesloLGS NF)
mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
fc-cache -fv && cd ~

# Antidote
git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote

# Plugin Selection (p10k)
cat << 'EOF' > ~/.zsh_plugins.txt
romkatv/powerlevel10k
zsh-users/zsh-completions
Aloxaf/fzf-tab
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-history-substring-search
hlissner/zsh-autopair
EOF

# Integration into zsh
cat << 'EOF' >> ~/.zshrc
# --- Antidote & Plugins ---
source ~/.antidote/antidote.zsh
antidote load

# --- Completions & Init ---
autoload -Uz compinit && compinit

# Wake up CLI tools from the setup
eval "$(zoxide init zsh)"

# --- Keybindings & Tweaks ---
# Keybindings for history substring search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# fzf-tab configuration (makes Tab autocompletion nice)
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always -- "$realpath"'
EOF
```
> ⚠️ **Restart terminal. Powerlevel10k will guide through the configuration wizard on first startup.**

## Install: Brew, Just, Direnv, UV, Ruff, Bump-my-version, Basedpyright, Nbstripout

```shell
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
> ⚠️ **follow the instructions (copy/paste the command block and execute)**

```shell
# we need brew for just and direnv
brew install just direnv

# UV (The lightning-fast Rust-based manager)
curl -LsSf https://astral.sh/uv/install.sh | sh
source "$HOME/.local/bin/env"

# Base equipment
uv tool install ruff && uv tool install bump-my-version && uv tool install basedpyright && uv tool install nbstripout

# Create the direnv layout for uv.
mkdir -p ~/.config/direnv && cat << 'EOF' > ~/.config/direnv/direnvrc
layout_uv() {
    # If no environment exists yet, uv creates one in a flash.
    [ ! -d ".venv" ] && uv venv
    # Tell direnv where the bin directory is located.
    export VIRTUAL_ENV="$(pwd)/.venv" && PATH_add "$VIRTUAL_ENV/bin"
    # UV also knows this.
    export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
}
EOF

# Enable direnv in zsh
grep -q 'direnv hook zsh' ~/.zshrc || echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
exec zsh # resource zsh
```

## mamba
```shell
# download install script
cd ~/Downloads  && curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"

# Batch mode (-b): Installs silently without interactive queries to ~/miniforge3
bash Miniforge3-$(uname)-$(uname -m).sh -b -p "$HOME/miniforge3"

# Register UV safety net (instead of `conda init zsh` we write the setup directly into ~/.zshrc)
cat << 'EOF' >> ~/.zshrc
# --- UV ---
# Strictly use own/managed Python versions (Protects System-Python!)
export UV_PYTHON_PREFERENCE=only-managed

# --- direnv ---
# Suppress direnv log output to avoid p10k instant-prompt interference
export DIRENV_LOG_FORMAT=""

# --- Mamba Initialization ---
# Mamba 2.0+ requires this variable before initialization
export MAMBA_ROOT_PREFIX="$HOME/miniforge3"
# Here we explicitly load the 'mamba' hook, not 'conda'
__mamba_setup="$("$HOME/miniforge3/bin/mamba" 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    # Miniforge also conveniently creates a mamba.sh
    if [ -f "$HOME/miniforge3/etc/profile.d/mamba.sh" ]; then
        . "$HOME/miniforge3/etc/profile.d/mamba.sh"
    else
        export PATH="$HOME/miniforge3/bin:$PATH"
    fi
fi
unset __mamba_setup

# --- Default Environment Activation ---
# Only activate a Mamba env if no project-level .envrc is present in the CWD.
# In project directories direnv supersedes Mamba anyway — skipping the activation
# keeps shell startup fast.
if [ ! -f "$PWD/.envrc" ]; then
    mamba activate $([[ -f ~/.startenv ]] && echo "$(< ~/.startenv)" || echo base)
fi

# startenv function
act() { [ "$#" -ne 0 ] && echo $1 > ~/.startenv && mamba activate $1; }

# Creates an environment in a folder if it doesn't already exist and places it under the management of direnv.
alias allowuv='echo "layout uv" > .envrc && direnv allow'

# --- Jupyter LSP shims ---
# jupyter_lsp starts language servers in the terminal's process group, so Ctrl-C
# also hits them (basedpyright then dies with a KeyboardInterrupt traceback).
# The shims ignore SIGINT; keep this directory early in PATH.
export PATH="$HOME/.local/libexec/jupyter-lsp-shims:$PATH"
EOF

# --- Global Jupyter fix for Google Colab ---
# Disables the RTC server extensions globally (~/.jupyter) to prevent WebSocket
# crashes with Colab. Survives environment wipe-and-recreate cycles.
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

# --- Disable JupyterLab Collaboration Room polling ---
# The client polls /api/collaboration/room/JupyterLab:globalAwareness every ~3s.
# Even with RTC extensions disabled, the JupyterLab client still fires these
# requests, causing 404 warnings. The user settings below silence them.
mkdir -p ~/.jupyter/lab/user-settings/\@jupyterlab/collaboration-extension/
cat << 'EOF' > ~/.jupyter/lab/user-settings/\@jupyterlab/collaboration-extension/plugin.jupyterlab-settings
{
    "collaborative": false,
    "enableDocs": false
}
EOF

# --- Jupyter LSP fix: Ctrl-C must not kill the language server ---
# jupyter_lsp starts basedpyright-langserver with a plain subprocess.Popen
# (jupyter_lsp/session.py, init_process) and therefore no new session. The
# language server stays in the terminal's foreground process group, so Ctrl-C
# sends SIGINT to Jupyter AND to basedpyright. Jupyter asks "Shut down this
# Jupyter server (y/[n])?", basedpyright's Python wrapper has no
# KeyboardInterrupt handling and dies with a traceback in the middle of the
# prompt ("No answer for 5s").
#
# The shim ignores SIGINT (SIG_IGN survives exec, so the node process inherits
# it) and execs the real binary, resolved via PATH without the shim directory.
# Works for uv-tool and conda basedpyright alike. ~/.zshrc puts the directory
# first on PATH.
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

# reload shell to activate mamba
exec zsh
```

## VSCode
```shell
# 1. Download and set up Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg

# 2. Add package source to package manager
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg

# 3. Update package list and install VS Code
sudo nala update && sudo nala install -y code

# 4. Kilo Code Extension & Python
code --install-extension kilocode.kilo-code
code --install-extension ms-python.python
```

## Github:
```shell
# Create global .gitignore
cat > ~/.gitignore_global << 'EOF'
# Agent folders
.opencode/
.kilocode/
.cursor/
.kilo/

# Environment files
.env
.env.*
!.env.example

# Virtual environments
.venv/
venv/

# Python
__pycache__/
*.pyc
*.pyo

# IDE
.idea/
*.swp
*~

# OS
.DS_Store
Thumbs.db
EOF
git config --global core.excludesfile ~/.gitignore_global

# Git config
#git config --global user.name "Your Name"
#git config --global user.email "noreply-email" # -> https://github.com/settings/emails
#git config --global init.defaultBranch main
#git config --global pull.rebase true

# GitHub Login (Choose "SSH" and upload your id_ed25519.pub key!)
#gh auth login
# Sets the credential helper for HTTPS remotes
#gh auth setup-git
```

## Data Science Mamba Environment
* ⚠️ Using ipywidgets 7.7.1 for colab runtime compatibility.
* ⚠️ To suppress saving notebook output in github use `nbstripout --install` in the repository folder.
```shell
#                     (re)create a data science environment with all the goodies and activate it
# _________________________________________________________________________________________________________________________________
py=3.12 && ENV_NAME="ds${py: -2}" && mamba deactivate && mamba remove -y -n $ENV_NAME --all 2>/dev/null # python 3.XY --> 'dsXY'
mamba   create -y -n $ENV_NAME python=$py google-colab && mamba activate $ENV_NAME # tested with Python 3.11/12/13
uv pip  install  -U jupyterlab jupyter_http_over_ws jupyter-ai jupyterlab-github xeus-python huggingface-hub ipywidgets==7.7.1
jupyter labextension enable jupyter_http_over_ws && echo $ENV_NAME > ~/.startenv
python  -m ipykernel install --user --name $ENV_NAME --display-name $ENV_NAME
# _______________________________________use_'act'_instead_of_'mamba_activate'_____________________________________________________
# mamba activate $(cat ~/.startenv) # insert in your shell rc file
# act() { [ "$#" -ne 0 ] && echo $1 > ~/.startenv && mamba activate $1; } # switch environment and remember
```

Important notes on the Mamba level:

- It doesn't necessarily have to be data science. Any domain is possible — this just happens to be mine.
- It's generally not recommended to use `uv` in a Mamba environment, as packages installed this way are not under Mamba's control. This can lead to conflicts when updating.
- I use the data science environment in a way that makes this problem irrelevant. I'm constantly installing new libraries, deleting old ones, and experimenting. Just as frequently (sometimes twice a day), I completely wipe the environment and reinstall it.
- That's why I use `uv`; it's so incredibly fast.
- **The rule is: no updates, just delete and recreate.** Only in this way can the dependency conflicts eliminated.


## Luxus Python Stack: pyinit, jupyter-launcher (jl), myprompt_my_jupyter (p10k)
```shell
# load functions
cat << 'EOF' >> ~/.zshrc
# insert from LUDESTA
source ~/gits/ludesta/Luxus-Python-Stack/scripts/luxuspythonstack.sh
EOF

# insert the jupyter-prompt-element in .p10k.zsh
sed -i '/^[[:space:]]*anaconda/a \    my_jupyter              # custom jupyter segment (see prompt_my_jupyter function in luxuspythonstack.sh)' ~/.p10k.zsh

# make skill accessable
mkdir -p ~/.agents/skills/
ln -s ~/gits/ludesta/Luxus-Python-Stack/lupysta ~/.agents/skills/lupysta

exec zsh
```


## Docker (optional, für E2E)

Docker ist keine Voraussetzung für `pyinit` oder `just check`. Es wird nur für
die opt-in E2E-Suite benötigt. Ohne Docker läuft `just test-e2e` im leeren
Gerüst weiterhin mit Hinweis und Exit 0.

```shell
docker --version
docker buildx version
docker info
```

## Verify

```shell
nala --version | head -1
for c in just direnv gcc; do command -v "$c" >/dev/null && echo "ok $c" || echo "MISSING $c"; done

[ -d ~/.antidote ] && echo "antidote present"
[ -f ~/.zsh_plugins.txt ] && echo ".zsh_plugins.txt present"
[ -f ~/.p10k.zsh ] && echo "p10k configured"
zsh -ic 'echo $ZSH_VERSION'

python3 --version
uv --version
for t in ruff bump-my-version basedpyright nbstripout; do command -v "$t" >/dev/null && echo "ok $t" || echo "MISSING $t"; done
direnv --version
mamba --version | head -1
zsh -ic 'mamba activate base && echo "mamba hook ok"'

# Jupyter LSP shim must win over the real basedpyright-langserver
zsh -ic 'command -v basedpyright-langserver'   # -> ~/.local/libexec/jupyter-lsp-shims/basedpyright-langserver

code --version
```

