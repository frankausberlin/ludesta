# Stack-Setup — Luxus-Python-Stack einrichten

Diese Anleitung richtet den Luxus-Python-Stack auf einer frischen
Ubuntu-Installation ein. Sie ist für eine VM oder ein neues System gedacht.
Für ein bereits genutztes System sollte ein erfahrener Agent die Schritte
begleiten, weil Paket- und Shell-Änderungen bestehende Konfigurationen
beeinflussen können.

## 1. Basissystem aktualisieren

```shell
sudo apt update
sudo apt upgrade -y
sudo apt install -y software-properties-common curl wget git build-essential \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libffi-dev liblzma-dev libncursesw5-dev tk-dev xz-utils \
    gnupg ca-certificates apt-transport-https
```

Zusätzliche Werkzeuge:

```shell
sudo apt install -y nala zsh fzf btop neofetch gh shellcheck shfmt ripgrep
```

```shell
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.12 python3.12-venv python3.12-dev
```

## 2. ZSH

```shell
chsh -s "$(which zsh)"
```

Nach dem Neuanmelden:

```shell
mkdir -p ~/.local/share/zsh
```

### 2.1 Plugins

```shell
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting \
    ~/.local/share/zsh/fast-syntax-highlighting

mkdir -p ~/.local/share/zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions \
    ~/.local/share/zsh/zsh-autosuggestions

mkdir -p ~/.local/share/zsh/zsh-completions
git clone https://github.com/zsh-users/zsh-completions \
    ~/.local/share/zsh/zsh-completions
```

### 2.2 Antidote

```shell
mkdir -p ~/.antidote
git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote

cat > ~/.zsh_plugins.txt <<'EOF'
romkatv/powerlevel10k
zdharma-continuum/fast-syntax-highlighting
zsh-users/zsh-autosuggestions
zsh-users/zsh-completions
EOF
```

### 2.3 `.zshrc`

Falls bereits eine `.zshrc` existiert, vorher sichern:

```shell
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak
```

```shell
cat > ~/.zshrc <<'EOF'
setopt INTERACTIVE_COMMENTS

# --- Basic ZSH settings ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory incappendhistory

# --- Antidote plugin manager ---
source ~/.antidote/antidote.zsh
antidote load ~/.zsh_plugins.txt

# --- Powerlevel10k prompt ---
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# --- Mamba ---
[ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ] && source "$HOME/miniforge3/etc/profile.d/conda.sh"
[ -f "$HOME/miniforge3/etc/profile.d/mamba.sh" ] && source "$HOME/miniforge3/etc/profile.d/mamba.sh"

# --- Mamba startenv ---
act() { [ "$#" -ne 0 ] && echo "$1" > ~/.startenv && mamba activate "$1"; }
if [ -f ~/.startenv ]; then
    mamba activate "$(cat ~/.startenv)"
fi

# --- direnv (must be the last line) ---
eval "$(direnv hook zsh)"
EOF
```

Der `direnv`-Hook gehört ans **absolute Ende** der Shell-Konfiguration.

### 2.4 `INTERACTIVE_COMMENTS`

Der alte Setup-Block schrieb versehentlich eine `echo`-Zeile in `.zshrc`.
Diese Zeile wird bei jeder neuen Shell ausgeführt und erzeugt Duplikate.
Richtig ist, die Option genau einmal zu setzen:

```shell
if ! grep -qxF 'setopt INTERACTIVE_COMMENTS' ~/.zshrc; then
    if grep -qxF 'eval "$(direnv hook zsh)"' ~/.zshrc; then
        sed -i '0,/^eval "$(direnv hook zsh)"$/s//setopt INTERACTIVE_COMMENTS\n&/' ~/.zshrc
    else
        printf '%s\n' 'setopt INTERACTIVE_COMMENTS' >> ~/.zshrc
    fi
fi
```

Bestehende Duplikate und die literale `echo`-Zeile gezielt entfernen:

```shell
cp ~/.zshrc ~/.zshrc.bak
grep -vxF "echo 'setopt INTERACTIVE_COMMENTS' >> ~/.zshrc" ~/.zshrc.bak \
    | awk '$0 == "setopt INTERACTIVE_COMMENTS" { if (seen++) next } { print }' \
    > ~/.zshrc
```

Danach prüfen:

```shell
grep -c '^setopt INTERACTIVE_COMMENTS$' ~/.zshrc   # expected: 1
! grep -qF "echo 'setopt INTERACTIVE_COMMENTS' >> ~/.zshrc" ~/.zshrc
```

### 2.5 Powerlevel10k

```shell
p10k configure
```

Konfiguration sichern:

```shell
test -f ~/.p10k.zsh && echo "p10k configuration present"
```

## 3. Just

```shell
sudo apt install -y just
```

Falls das Paket fehlt:

```shell
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
    | bash -s -- --to ~/.local/bin
```

## 4. UV

```shell
curl -LsSf https://astral.sh/uv/install.sh | sh
```

`uv` installiert und verwaltet Python-Versionen; das System-Python bleibt
unverändert.

## 5. direnv

```shell
sudo apt install -y direnv
```

`layout_uv` in `~/.config/direnv/direnvrc` ergänzen:

```shell
mkdir -p ~/.config/direnv
cat >> ~/.config/direnv/direnvrc <<'EOF'

layout_uv() {
    [ ! -d ".venv" ] && uv venv
    export VIRTUAL_ENV="$(pwd)/.venv" && PATH_add "$VIRTUAL_ENV/bin"
    export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
}
EOF
```

## 6. Mamba

```shell
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash "Miniforge3-$(uname)-$(uname -m).sh" -b -p "$HOME/miniforge3"
source "$HOME/miniforge3/etc/profile.d/conda.sh"
source "$HOME/miniforge3/etc/profile.d/mamba.sh"
```

Die Mamba-Profile werden bereits über den `.zshrc`-Block aus Abschnitt 2.3
geladen. Prüfen:

```shell
grep -q 'miniforge3/etc/profile.d/mamba.sh' ~/.zshrc && echo "mamba profile present"
```

Mamba bleibt inaktiv, bis eine Umgebung ausdrücklich aktiviert wird.

## 7. Data-Science-Umgebung

Die Umgebung `ds12` ist eine bewusst **abgespeckte** Data-Science-Umgebung
mit Python 3.12. Sie enthält Google Colab, JupyterLab, Scikit-Learn, JAX,
Numba und verwandte Werkzeuge, aber **keine CUDA-, PyTorch- oder
TensorFlow-Zusage**. Wer diese Pakete braucht, ergänzt sie ausdrücklich.

```shell
mamba create -n ds12 python=3.12 -y
mamba activate ds12
conda install -c conda-forge google-colab jupyterlab scikit-learn jax \
    matplotlib pandas seaborn ipywidgets -y
pip install uv
```

Jupyter-Konfiguration:

```shell
mkdir -p ~/labor
jupyter lab --generate-config
cat > ~/.jupyter/jupyter_server_config.json <<'EOF'
{
  "ServerApp": {
    "jpserver_extensions": {
      "jupyter_server_ydoc": false,
      "jupyter_server_documents": false
    }
  }
}
EOF
```

`~/labor` ist das Standard-Notebook-Verzeichnis. `jupyter-launcher` aus dem
Stack-Script startet Jupyter Lab mit sicheren Standardwerten.

## 8. VS Code

```shell
sudo snap install code --classic
code --install-extension ms-python.python
code --install-extension charliermarsh.ruff
code --install-extension detachhead.basedpyright
```

## 9. Luxus-Python-Stack installieren

Repo-Pfad einmal festlegen; die folgenden Blöcke verwenden diese Variable:

```shell
export LUXUS_REPO="${LUXUS_REPO:-$HOME/gits/luxus-skills}"
```

Repository klonen, falls es noch nicht existiert:

```shell
if [ ! -d "$LUXUS_REPO" ]; then
    mkdir -p "$(dirname "$LUXUS_REPO")"
    git clone https://github.com/frankausberlin/luxus-skills "$LUXUS_REPO"
fi
```

Das Script in `.zshrc` einbinden:

```shell
if ! grep -qF 'Luxus-Python-Stack/luxuspythonstack.sh' ~/.zshrc; then
    cat >> ~/.zshrc <<'EOF'

# --- Luxus-Python-Stack ---
export LUXUS_REPO="${LUXUS_REPO:-$HOME/gits/luxus-skills}"
source "$LUXUS_REPO/Luxus-Python-Stack/luxuspythonstack.sh"
EOF
    # Keep the direnv hook as the last line.
    grep -vxF 'eval "$(direnv hook zsh)"' ~/.zshrc > ~/.zshrc.tmp || true
    printf '%s\n' 'eval "$(direnv hook zsh)"' >> ~/.zshrc.tmp
    mv ~/.zshrc.tmp ~/.zshrc
fi
```

`pyinit` ist eine Shell-Funktion und wird über `source` geladen, nicht als
eigenständige Datei aufgerufen. Ein Symlink in `~/.local/bin` ersetzt das
Sourcen nicht. Nicht-interaktive Shells können bei Bedarf einen kleinen
Wrapper verwenden, der das Script sourct und `pyinit` aufruft.

## 10. Skill verlinken

```shell
export LUXUS_REPO="${LUXUS_REPO:-$HOME/gits/luxus-skills}"
mkdir -p ~/.agents/skills
ln -sfn "$LUXUS_REPO/Luxus-Python-Stack/lupysta" ~/.agents/skills/lupysta
```

Wenn die Harness `~/.agents/skills` nicht automatisch lädt, den Pfad in ihrer
Konfiguration ergänzen, zum Beispiel über `skills.paths` in
`~/.config/kilo/kilo.jsonc`.

## 11. Kilo / Harness

```shell
code --install-extension kilocode.kilo-code
```

## 12. Installation prüfen

```shell
type pyinit act jl
pyinit --help
```

Werkzeuge prüfen:

```shell
for c in git just direnv uv mamba rg fzf btop gh shellcheck shfmt code python3.12; do
    command -v "$c" >/dev/null 2>&1 \
        && printf 'ok   %s\n' "$c" \
        || printf 'MISS %s\n' "$c"
done
```

Konfiguration prüfen:

```shell
export LUXUS_REPO="${LUXUS_REPO:-$HOME/gits/luxus-skills}"
grep -q "direnv hook zsh" ~/.zshrc && echo "direnv hook present"
grep -q "layout_uv" ~/.config/direnv/direnvrc && echo "layout_uv present"
test -f ~/.antidote/antidote.zsh && echo "antidote present"
test -f ~/.p10k.zsh && echo "p10k present"
test -f "$LUXUS_REPO/Luxus-Python-Stack/luxuspythonstack.sh" && echo "stack script present"
test -L ~/.agents/skills/lupysta && echo "lupysta skill link present"
test "$(grep -c '^setopt INTERACTIVE_COMMENTS$' ~/.zshrc)" -eq 1 \
    && echo "INTERACTIVE_COMMENTS present once"
tail -n 1 ~/.zshrc | grep -q 'direnv hook zsh' \
    && echo "direnv hook is the last line"
```

## 13. Erstes Projekt

```shell
pyinit mein-projekt
cd mein-projekt
direnv allow
just check
```

Für eine Bibliothek:

```shell
pyinit meine-lib --lib
```

Für eine CLI-App:

```shell
pyinit meine-cli --cli
```

## 14. Migration und Uninstall

- Den alten `luxuspythonstack`-Skill und `lupysta` nicht parallel installieren.
- Alte Projekte werden nicht automatisch aktualisiert.
- Skill-Link entfernen: `rm ~/.agents/skills/lupysta`.
- `source`-Zeile aus `.zshrc` entfernen.
- Generierte Projekte bleiben unabhängig vom installierten Skill nutzbar.

## Bekannte Stolpersteine

| Problem | Ursache | Lösung |
| --- | --- | --- |
| `direnv: command not found` | Hook fehlt oder steht nicht am Ende | Hook als letzte Zeile in `.zshrc` eintragen. |
| `.venv` wird nicht aktiviert | `direnv allow` fehlt | Im Projekt `direnv allow` ausführen. |
| `layout_uv: command not found` | Funktion fehlt in `direnvrc` | `layout_uv` ergänzen und Shell neu starten. |
| `pyinit: command not found` | Script nicht gesourct | `source "$LUXUS_REPO/Luxus-Python-Stack/luxuspythonstack.sh"`. |
| Doppelte `INTERACTIVE_COMMENTS` | Alter `echo`-Block | Duplikate mit dem Cleanup-Block entfernen. |
| Mamba/Python-Konflikt | Beide Umgebungen aktiv | `conda deactivate`, dann `direnv allow`. |
