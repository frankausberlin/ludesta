# Einrichtungsanweisungen für den Luxus-Python-Stack

* Die Codeblöcke können per Kopieren/Einfügen in die Shell eingefügt werden. 
* Dazwischen gibt es Hinweise („⚠️“), die beachtet werden müssen.

## Basissystem
> ⚠️ **Der Standard-Darkmode der bash zeigt Kommentare schlecht an, ich empfehle die Pallete 'VS Code' (dark)**

```shell
# Ich bevorzuge nala
sudo apt update && sudo apt install -y nala
sudo nala update && sudo nala upgrade

# gits Folder und labor Folder (für jupyter) anlegen und Repository klonen
sudo nala install -y git && mkdir -p ~/gits ~/labor
git clone https://github.com/frankausberlin/ludesta ~/gits/ludesta

# Systemgrundlagen / CLI-Tools & Produktivität / Build-Grundlagen & Entwicklerbibliotheken
sudo nala install -y \
  ca-certificates curl wget gnupg gpg software-properties-common \
  openssh-server fail2ban ufw unattended-upgrades util-linux-extra net-tools \
  util-linux-extra snapd 7zip xz-utils aria2 sqlite3 \
  zsh gh tmux btop htop iotop nvtop fastfetch tree hwinfo s-tui \
  ripgrep fzf zoxide jq tealdeer shellcheck shfmt apt-transport-https \
  build-essential cmake make pkg-config libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev libncurses-dev libffi-dev liblzma-dev \
  libxml2-dev libxmlsec1-dev tk-dev libyaml-dev libfuse2t64 \
  python3 pipx

# SSH aktivieren
sudo systemctl enable --now ssh
# IP mit 'ip a' ermitteln und per 'ssh <user>@<ip>' mit dieser Maschine verbinden

# zu zsh wechseln
chsh -s $(which zsh) 
```
> ⚠️ **Neu anmelden und Option 2: Recommended settings wählen**

## ZSH mit antidote und p10k
```shell
echo 'setopt INTERACTIVE_COMMENTS' >> ~/.zshrc
```
> ⚠️ **zsh neu öffnen (notwendig, um das Kommentarzeichen '#' verwenden zu können)**

```shell
# Schriftarten (MesloLGS NF)
mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
fc-cache -fv && cd ~

# Antidote
git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote

# Plugin-Auswahl (p10k)
cat << 'EOF' > ~/.zsh_plugins.txt
romkatv/powerlevel10k
zsh-users/zsh-completions
Aloxaf/fzf-tab
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-history-substring-search
hlissner/zsh-autopair
EOF

# Integration in zsh
cat << 'EOF' >> ~/.zshrc
# --- Antidote & Plugins ---
source ~/.antidote/antidote.zsh
antidote load

# --- Completions & Init ---
autoload -Uz compinit && compinit

# CLI-Tools aus dem Setup aktivieren
eval "$(zoxide init zsh)"

# --- Tastenbelegung & Feinschliff ---
# Tastenbelegung für die History-Substring-Suche
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# fzf-tab-Konfiguration (macht die Tab-Autovervollständigung komfortabel)
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always -- "$realpath"'
EOF
```
> ⚠️ **Terminal neu starten. Powerlevel10k führt beim ersten Start durch den Konfigurationsassistenten. (fav: yyy1n2122125222221n1y)**

## Installation: Just, Direnv, UV, Ruff, Bump-my-version, Basedpyright, Nbstripout

```shell
# just und direnv aus der Paketquelle
sudo nala install -y just direnv

# UV (der blitzschnelle, in Rust geschriebene Manager)
curl -LsSf https://astral.sh/uv/install.sh | sh
source "$HOME/.local/bin/env"

# Grundausstattung
uv tool install ruff && uv tool install bump-my-version && uv tool install basedpyright && uv tool install nbstripout

# Das direnv-Layout für uv erstellen.
mkdir -p ~/.config/direnv && cat << 'EOF' > ~/.config/direnv/direnvrc
layout_uv() {
    # Falls noch keine Umgebung existiert, erstellt uv in Windeseile eine.
    [ ! -d ".venv" ] && uv venv
    # direnv mitteilen, wo sich das bin-Verzeichnis befindet.
    export VIRTUAL_ENV="$(pwd)/.venv" && PATH_add "$VIRTUAL_ENV/bin"
    # UV kennt das ebenfalls.
    export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
}
EOF

# direnv in zsh aktivieren
grep -q 'direnv hook zsh' ~/.zshrc || echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
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

## VSCode
```shell
# Microsoft-GPG-Schlüssel herunterladen und einrichten
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg

# Paketquelle zum Paketmanager hinzufügen
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg

# Paketliste aktualisieren und VS Code installieren
sudo nala update && sudo nala install -y code

# alias startet code und fragt vorher openrouter-key ab, kilo erkennt den dann
cat << 'EOF' >> ~/.zshrc
alias ocode='read -s "OPENROUTER_API_KEY?API-Key eingeben: " && echo && export OPENROUTER_API_KEY && code'
EOF

# Kilo-Code-Erweiterung & Python
n=0; until [ "$n" -ge 5 ] || code --install-extension kilocode.kilo-code; do n=$((n+1)); echo "Fehlgeschlagen ($n/5). Warte 5s..."; sleep 5; done
n=0; until [ "$n" -ge 5 ] || code --install-extension ms-python.python; do n=$((n+1)); echo "Fehlgeschlagen ($n/5). Warte 5s..."; sleep 5; done
exec zsh
```

## GitHub:
```shell
# Globale .gitignore erstellen
cat > ~/.gitignore_global << 'EOF'
# Agent-Ordner
.opencode/
.kilocode/
.cursor/
.kilo/

# Umgebungsdateien
.env
.env.*
!.env.example

# Virtuelle Umgebungen
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

# Betriebssystem
.DS_Store
Thumbs.db
EOF

# setze globales gitignore, verwende main anstatt master, merge-verhalten
git config --global core.excludesfile ~/.gitignore_global
git config --global init.defaultBranch main
git config --global pull.rebase true
```

* ⚠️ optional Daten eingeben, no-reply-email gibts hier: https://github.com/settings/emails
```shell
#git config --global user.name "Your Name"
#git config --global user.email "noreply-email" 
# GitHub-Login („SSH“ wählen und den id_ed25519.pub-Schlüssel hochladen!)
#gh auth login
# Legt den Credential-Helper für HTTPS-Remotes fest
#gh auth setup-git
```

## Data-Science-Mamba-Umgebung
* ⚠️ Für Kompatibilität mit der Colab-Runtime wird ipywidgets 7.7.1 verwendet.
* ⚠️ Um das Speichern von Notebook-Ausgaben in GitHub zu unterdrücken, im Repository-Ordner `nbstripout --install` ausführen.
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

## Network & Security

* ⚠️ **Die Network & Security Einstellungen sind optional. Ich biete hier lediglich eine Variante an.**

### Ausführen auf dem Host PC
```shell
# AUF DEM HOST: VM_USER/VM_IP einsetzen, dann ausführen
VM_USER="<vm-user>"
VM_IP="<vm-ip>"          # NAT: 127.0.0.1, beide ssh-Befehle zusätzlich mit -p <host-port>

[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519
ssh-copy-id -i ~/.ssh/id_ed25519.pub "${VM_USER}@${VM_IP}"
ssh -o PreferredAuthentications=publickey "${VM_USER}@${VM_IP}" true
```

### Ausführen in der VM
```shell
# ip ermitteln (wird im Host PC benötigt)
ip -br addr

# IN DER VM, nicht als root: erst ausführen, wenn der Login oben ohne Passwort klappt
# 00- gewinnt gegen 50-cloud-init.conf, sshd nimmt den ersten Wert
cat << EOF | sudo tee /etc/ssh/sshd_config.d/00-ludesta.conf > /dev/null
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
AllowUsers ${SUDO_USER:-$USER}
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
EOF
sudo sshd -t && sudo systemctl reload ssh

# Erste drei Werte: no; allowusers: dein VM-Benutzername
# Danach SSH-Login in einem zweiten Terminal prüfen, bisherige Sitzung offen lassen.
sudo sshd -T | grep -E '^(passwordauthentication|kbdinteractiveauthentication|permitrootlogin|allowusers) '

# Firewall: eingehend dicht, SSH gedrosselt, ausgehend offen
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit ssh
sudo ufw --force enable

# Docker: keine Ports veröffentlichen; wenn unvermeidbar, nur an Loopback binden
# docker run -p 127.0.0.1:8080:80 ...
```

## Docker (für E2E)

> ⚠️ **Dieser Block ist dafür gedacht, wenn du den Stack in einer VM ohne Docker installierst.**.
> ⚠️ **Den Docker-Installationsblock überspringen, wenn `docker --version` und `docker info` bereits funktionieren.**

```shell
# Offiziellen GPG-Schlüssel:
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Füge repository hinzu
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# install docker / user in group 
sudo nala update && sudo nala install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker
```
> ⚠️ **Optional: run docker's hello-world**.

```shell
docker run --rm hello-world
```

## Luxus-Python-Stack: pyinit, jupyter-launcher (jl), myprompt_my_jupyter (p10k)
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

exec zsh
```

## Überprüfung

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
# Der Jupyter-LSP-Shim muss Vorrang vor dem echten basedpyright-langserver haben
zsh -ic 'command -v basedpyright-langserver'   # -> ~/.local/libexec/jupyter-lsp-shims/basedpyright-langserver
code --version
docker --version
docker buildx version                      # BuildKit wird vom E2E-Dockerfile benötigt
docker info --format '{{.ServerVersion}}'  # muss die Serverversion ausgeben, nicht nur die des Clients
# Network & Security (optional)
sudo ufw status verbose
systemctl is-active ssh ssh.socket    # mindestens einer muss aktiv sein
sudo ss -tlnp | grep ':22 '           # ssh listening
sudo sshd -T | grep -Ei '^(passwordauthentication|permitrootlogin|allowusers|maxauthtries)'
ls -la ~/.ssh/authorized_keys         # Server-Seite: Host-Key muss hier liegen
```
