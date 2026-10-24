# Einrichtungsanweisungen für das Basis-System für alle Luxus-Stacks

* Die Codeblöcke können per Kopieren/Einfügen in die Shell eingefügt werden. 
* Dazwischen gibt es Hinweise („⚠️“), die beachtet werden müssen.
* Dieses Dokument richtet das gemeinsame Basis-System ein. Danach den stack-spezifischen Teil befolgen.

## Basissystem
>* ⚠️ **Der Standard-Darkmode der bash zeigt Kommentare schlecht an, ich empfehle die Pallete 'VS Code' (dark)**

```shell
# Ich bevorzuge nala
sudo apt update && sudo apt install -y nala
sudo nala update && sudo nala upgrade -y

# gits- und labor-Folder (für jupyter) sowie ~/.local/bin anlegen und Repository klonen
sudo nala install -y git && mkdir -p ~/gits ~/labor ~/.local/bin
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

# just und direnv
sudo nala install -y just direnv

# SSH aktivieren
sudo systemctl enable --now ssh
# IP mit 'ip a' ermitteln und per 'ssh <user>@<ip>' mit dieser Maschine verbinden

# zu zsh wechseln
sudo chsh -s $(which zsh) $USER
```
>* ⚠️ **Neu anmelden, Terminal starten und Option 2: Recommended settings wählen**

## ZSH mit antidote und p10k
```shell
echo 'setopt INTERACTIVE_COMMENTS' >> ~/.zshrc
```
>* ⚠️ **zsh neu öffnen (notwendig, um das Kommentarzeichen '#' verwenden zu können)**

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

# --- Lokale Binaries ---
export PATH="$HOME/.local/bin:$PATH"

# --- Tastenbelegung & Feinschliff ---
# Tastenbelegung für die History-Substring-Suche
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# fzf-tab-Konfiguration (macht die Tab-Autovervollständigung komfortabel)
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always -- "$realpath"'

# --- direnv ---
eval "$(direnv hook zsh)"
EOF
```
>* ⚠️ **Terminal neu starten. Powerlevel10k führt beim ersten Start durch den Konfigurationsassistenten. (fav: yyy1n2122125222221n1y)**

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

# Kilo-Code-Erweiterung
n=0; until [ "$n" -ge 5 ] || code --install-extension kilocode.kilo-code; do n=$((n+1)); echo "Fehlgeschlagen ($n/5). Warte 5s..."; sleep 5; done
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

>* ⚠️ **optional Daten eingeben, no-reply-email gibts hier: https://github.com/settings/emails**
```shell
#git config --global user.name "Your Name"
#git config --global user.email "noreply-email" 
# GitHub-Login („SSH“ wählen und den id_ed25519.pub-Schlüssel hochladen!)
#gh auth login
# Legt den Credential-Helper für HTTPS-Remotes fest
#gh auth setup-git
```

## Network & Security

>* ⚠️ **Die Network & Security Einstellungen sind optional. Ich biete hier lediglich eine Variante an.**

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
# copy-paste-freundliche ausgabe von user und ip
printf 'VM_USER="%s"\nVM_IP="%s"\n' "$USER" "$(hostname -I | awk '{print $1}')"
```

```shell
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

>* ⚠️ **Dieser Block ist dafür gedacht, wenn du den Stack in einer VM ohne Docker installierst.**
>* ⚠️ **Den Docker-Installationsblock überspringen, wenn `docker --version` und `docker info` bereits funktionieren.**

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


## Überprüfung

> ⚠️ **Die stack-spezifischen Prüfungen stehen in der Setup-Anleitung des jeweiligen Stacks.**

```shell
mkdir -p ~/.local/bin
cat << 'EOF' > ~/.local/bin/test-ludesta
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

# ── System & Basis ───────────────────────────────────────────────────────────
if command -v nala >/dev/null; then nala --version | head -1 || fail=1; else missing nala; fi
zsh_clean 'echo "zsh $ZSH_VERSION"' || missing zsh
[ "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)" ] && ok "login shell zsh" || missing "login shell zsh (neu anmelden)"
python3 --version || missing python3
for c in gcc make git awk; do
    command -v "$c" >/dev/null && ok "$c" || missing "$c"
done

# ── Globale Werkzeuge in frischer interaktiver Shell ─────────────────────────
# Nicht die Setup-Shell prüfen: sie hat ~/.local/bin nur geerbt. Der Test startet
# zsh mit einem kontrollierten PATH, damit nur ~/.zshrc zählt.
zsh_clean 'r=0; for t in just direnv zoxide fzf rg jq gh; do if command -v "$t" >/dev/null; then echo "ok $t"; else echo "MISSING $t"; r=1; fi; done; exit $r' || fail=1
zsh_clean 'just --version; direnv --version; gh --version | head -1' || fail=1

# ── Shell-Integration ────────────────────────────────────────────────────────
[ -d ~/.antidote ] && ok antidote || missing antidote
[ -f ~/.zsh_plugins.txt ] && ok .zsh_plugins.txt || missing .zsh_plugins.txt
[ -f ~/.p10k.zsh ] && ok "p10k configured" || missing "p10k configured"
grep -q 'setopt INTERACTIVE_COMMENTS' ~/.zshrc && ok INTERACTIVE_COMMENTS || missing INTERACTIVE_COMMENTS
grep -q 'zoxide init zsh' ~/.zshrc && ok "zoxide init" || missing "zoxide init"
grep -q 'direnv hook zsh' ~/.zshrc && ok "direnv hook" || missing "direnv hook"
[ -x ~/.local/bin/test-ludesta ] && ok "test-ludesta" || missing "test-ludesta"
zsh_clean 'command -v test-ludesta >/dev/null' && ok "$HOME/.local/bin im PATH" || missing "$HOME/.local/bin im PATH"

# ── Git / GitHub ─────────────────────────────────────────────────────────────
expected_ignore="$HOME/.gitignore_global"
[ -f "$expected_ignore" ] && ok .gitignore_global || missing .gitignore_global
value="$(git config --global --path --get core.excludesfile)"
if [ "$value" = "$expected_ignore" ] && [ -f "$value" ]; then
    ok "core.excludesfile=$value"
else
    missing "core.excludesfile (erwartet: $expected_ignore, ist: ${value:-nicht gesetzt})"
fi
value="$(git config --global --get init.defaultBranch)"
[ "$value" = "main" ] && ok "init.defaultBranch=$value" || missing "init.defaultBranch (erwartet: main, ist: ${value:-nicht gesetzt})"
value="$(git config --global --bool --get pull.rebase)"
[ "$value" = "true" ] && ok "pull.rebase=$value" || missing "pull.rebase (erwartet: true, ist: ${value:-nicht gesetzt})"
value="$(git config --global --get user.name)" && echo "user.name=$value" || echo "HINWEIS: user.name nicht gesetzt"
value="$(git config --global --get user.email)" && echo "user.email=$value" || echo "HINWEIS: user.email nicht gesetzt"

# ── VS Code ──────────────────────────────────────────────────────────────────
code --version || missing code
extensions="$(code --list-extensions)" || fail=1
printf '%s\n' "$extensions" | grep -qix kilocode.kilo-code && ok kilocode.kilo-code || missing kilocode.kilo-code
zsh_clean 'alias ocode' >/dev/null 2>&1 && ok "alias ocode" || missing "alias ocode"

# ── Docker (optional) ────────────────────────────────────────────────────────
if command -v docker >/dev/null; then
    docker --version || fail=1
    docker buildx version || fail=1                      # BuildKit wird vom E2E-Dockerfile benötigt
    docker compose version || fail=1                     # Compose-Plugin ist installiert
    if docker info --format '{{.ServerVersion}}'; then   # muss die Serverversion ausgeben, nicht nur die des Clients
        id -nG | grep -qw docker && ok "docker group" || echo "HINWEIS: Benutzer nicht in Gruppe docker (bei Rootless Docker normal; sonst ggf. neu einloggen)"
    else
        fail=1
        id -nG | grep -qw docker && echo "HINWEIS: docker info fehlgeschlagen, obwohl die Gruppe docker vorhanden ist" || echo "HINWEIS: docker info fehlgeschlagen und Gruppe docker fehlt (nach usermod neu einloggen?)"
    fi
else
    echo "HINWEIS: Docker nicht installiert (optional für E2E)"
fi

# Network & Security
systemctl is-active --quiet ssh || systemctl is-active --quiet ssh.socket && ok "ssh aktiv" || echo "HINWEIS: ssh nicht aktiv"
ss -tln 2>/dev/null | grep -q ':22 ' && ok "ssh auf Port 22" || echo "HINWEIS: kein Listener auf 22"
[ -s ~/.ssh/authorized_keys ] && ok authorized_keys || echo "HINWEIS: authorized_keys fehlt"
{ grep -qx 'ENABLED=yes' /etc/ufw/ufw.conf && grep -qx 'DEFAULT_INPUT_POLICY="DROP"' /etc/default/ufw && grep -qx 'DEFAULT_OUTPUT_POLICY="ACCEPT"' /etc/default/ufw; } 2>/dev/null && ok "ufw enabled + policies" || echo "HINWEIS: ufw-Status/Policies prüfen"
t="$(mktemp -d)"; [ -d "$t" ] || t="${TMPDIR:-/tmp}"; ssh-keygen -q -t ed25519 -N '' -f "$t/k" 2>/dev/null; sshd -T -h "$t/k" 2>/dev/null > "$t/c"
r=0; for c in "passwordauthentication no" "kbdinteractiveauthentication no" "permitrootlogin no" "permitemptypasswords no"; do grep -qx "$c" "$t/c" || r=1; done; grep -Eq "^allowusers( .*)? $USER( .*)?$" "$t/c" || r=1
rm -rf "$t"; [ "$r" = 0 ] && ok "sshd hardening" || echo "HINWEIS: sshd-Config prüfen"

exit "$fail"
EOF

# Das Skript wird nur erzeugt. Ausführen mit `test-ludesta` oder `~/.local/bin/test-ludesta`
chmod +x ~/.local/bin/test-ludesta
```


