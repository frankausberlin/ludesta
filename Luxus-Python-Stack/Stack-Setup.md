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

## Installation: Brew, Just, Direnv, UV, Ruff, Bump-my-version, Basedpyright, Nbstripout

```shell
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
> ⚠️ **Den Anweisungen folgen (Befehlsblock kopieren/einfügen und ausführen)**

```shell
# wir brauchen brew für just und direnv
brew install just direnv

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
code --install-extension kilocode.kilo-code
code --install-extension ms-python.python
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

### VM-Netzwerk

* ⚠️ **SSH vom Host in die VM funktioniert nur, wenn die VM inbound erreichbar ist: bridged, libvirt-Default-NAT (`virbr0`), VMware-NAT oder Hyper-V Default Switch. Bei VirtualBox-NAT und QEMU-User-Networking braucht es ein Portforwarding; dann verbindet man sich vom Host mit `127.0.0.1` und dem forwardeten Port.**

### Basis-Verbindung

```shell
# In der VM: primäre IPv4 über die Default-Route ermitteln (hostname -I ist nicht eindeutig)
VM_IP=$(ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')
echo "ssh-copy-id ${USER}@${VM_IP}"

# Bei NAT mit Portforwarding stattdessen auf dem Host:
# ssh-copy-id -p 2222 "${USER}@127.0.0.1"
```

* ⚠️ **Führe den erzeugten Befehl auf dem Rechner aus, auf dem die VM mit ludesta läuft, nicht in der VM.**

```shell
# Auf dem Host: Key anlegen, falls noch keiner existiert
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519

# VM-Benutzer und IP aus dem oben erzeugten Befehl übernehmen
VM_USER="<vm-user>"
VM_IP="<vm-ip>"
ssh-copy-id -i ~/.ssh/id_ed25519.pub "${VM_USER}@${VM_IP}"

# Erst wenn dieser Test ohne Passwort funktioniert, ist das Hardening sicher
ssh -o PreferredAuthentications=publickey -o PasswordAuthentication=no "${VM_USER}@${VM_IP}" true
```

### SSH Hardening

* ⚠️ **Das Hardening erst ausführen, nachdem der Key-Login vom Host ohne Passwort funktioniert. Die aktuelle Sitzung bleibt beim Reload erhalten; bei Problemen hilft nur die VM-Konsole.**

```shell
# 99-... sortiert nach 50-cloud-init.conf, sonst gewinnt cloud-init mit PasswordAuthentication yes
cat <<EOF | sudo tee /etc/ssh/sshd_config.d/99-custom-hardening.conf > /dev/null
PubkeyAuthentication yes
KbdInteractiveAuthentication no
PasswordAuthentication no
PermitRootLogin no
AllowUsers ${SUDO_USER:-$USER}
PermitEmptyPasswords no
MaxAuthTries 6
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
EOF

# `KbdInteractiveAuthentication` benötigt OpenSSH >= 8.7 (Ubuntu >= 22.04). 
# Auf älteren Images schlägt `sshd -t` fehl; die Datei wird dann automatisch wieder entfernt, 
# damit sshd beim nächsten Start nicht blockiert.

# Validate config before reloading; bei Fehlern die neue Datei wieder entfernen
if sudo sshd -t; then
  sudo systemctl reload-or-restart ssh
  sudo sshd -T | grep -Ei '^(passwordauthentication|permitrootlogin|allowusers|maxauthtries)'
else
  echo "Ungültige sshd-Konfiguration - 99-custom-hardening.conf wird entfernt"
  sudo rm -f /etc/ssh/sshd_config.d/99-custom-hardening.conf
fi
```

### Firewall (UFW)

* ⚠️ **`ufw limit ssh` gilt für Port 22/tcp. Läuft sshd auf einem anderen Port, diesen Port stattdessen freigeben.**

```shell
command -v ufw >/dev/null || sudo nala install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit ssh       # SSH with brute-force protection
sudo ufw --force enable
sudo ufw status verbose
```

### fail2ban

```shell
# Host-IP für ignoreip (bei SSH-Session automatisch gesetzt; sonst leer)
HOST_IP="${SSH_CLIENT%% *}"

# write /etc/fail2ban/jail.local
cat <<EOF | sudo tee /etc/fail2ban/jail.local > /dev/null
[sshd]
enabled = true
backend = systemd
port = ssh
filter = sshd
maxretry = 5
bantime = 3600
findtime = 3600
banaction = ufw
ignoreip = 127.0.0.1/8 ::1 ${HOST_IP}
EOF

# Konfiguration prüfen, dann neu starten
sudo fail2ban-client -t && sudo systemctl restart fail2ban
sudo fail2ban-client status sshd

# comfort link
mkdir -p ~/.shlib
ln -sf /etc/fail2ban/jail.local ~/.shlib/jail.local
```

## Docker (für E2E)

> ⚠️ **Dieser Block ist dafür gedacht, wenn du den Stack in einer VM ohne Docker installierst.**.
> ⚠️ **Den Docker-Installationsblock überspringen, wenn `docker --version` und `docker info` bereits funktionieren. Der UFW-Patch weiter unten bleibt davon unabhängig.**

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

## Docker UFW patch

* ⚠️ **Nur bei aktivierter Firewall ausführen. Dieser Abschnitt gilt auch dann, wenn Docker bereits installiert ist und der Docker-Installationsblock oben übersprungen wurde.**

```shell
# Gepinnte Version statt master: Commit und Prüfsumme schützen vor ungeprüftem Root-Code
UFW_DOCKER_COMMIT="020a8699f95592561f254d8d4ad1bb40d401dfc7"
UFW_DOCKER_SHA256="643e56b080567c567b4aa28650196849b2a2da5dd0473fd3e5216b0886035ab0"

# LC_ALL=C: ufw-docker erkennt sonst auf deutsch lokalisierten Systemen den Status "aktiv" nicht
sudo wget -O /usr/local/bin/ufw-docker \
  "https://raw.githubusercontent.com/chaifeng/ufw-docker/${UFW_DOCKER_COMMIT}/ufw-docker" \
  && echo "${UFW_DOCKER_SHA256}  /usr/local/bin/ufw-docker" | sudo sha256sum -c - \
  && sudo chmod +x /usr/local/bin/ufw-docker \
  && sudo env LC_ALL=C ufw-docker install \
  && sudo systemctl restart ufw \
  && sudo ufw-docker status
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
sudo ufw-docker status                # nur bei aktivem UFW-Patch
systemctl is-active ssh ssh.socket    # mindestens einer muss aktiv sein
sudo ss -tlnp | grep ':22 '           # ssh listening
sudo sshd -T | grep -Ei '^(passwordauthentication|permitrootlogin|allowusers|maxauthtries)'
sudo fail2ban-client status sshd
ls -la ~/.ssh/authorized_keys         # Server-Seite: Host-Key muss hier liegen
```
