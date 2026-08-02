
#!/bin/bash
#
# Setup de preparação do zsh para utilização no fedora
# Baseado no https://github.com/radleylewis/zsh

set -euo pipefail

echo "Instalando dependencias..."
sudo dnf install -y zsh vim-X11  eza bat fd-find fzf ripgrep zoxide

echo "Instalando o starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

echo "Configurando o ZDOTDIR em /etc/zsh/zshenv..."
# Garante que a pasta existe antes de criar o arquivo
sudo mkdir -p /etc/zsh
if grep -q "ZDOTDIR" /etc/zsh/zshenv 2>/dev/null; then
    echo "ZDOTDIR já está configurado em /etc/zsh/zshenv. Pulando..."
else
    sudo tee -a /etc/zsh/zshenv > /dev/null << 'EOF'
if [[ -z "$XDG_CONFIG_HOME" ]]
then
    export XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ -d "$XDG_CONFIG_HOME/zsh" ]]
then
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi
EOF
fi

echo "Download do repositorio.."
if [ -d "$HOME/.config/zsh" ]; then
    echo "A pasta ~/.config/zshenv já existe. Pulando clone."
else
    git clone https://github.com/joaomboni/zsh "$HOME/.config/zsh"
fi

echo "Criando links simbolicos na Home..."
echo 'export ZDOTDIR="$HOME/.config/zsh"' "$HOME/.zshenv"
ln -sf "$HOME/.config/zsh/.zshrc" "$HOME/.zshrc"

echo "Criando diretorios de hitorico e cache..."
mkdir -p "$HOME/.cache/zsh"
mkdir -p "$HOME/.local/state/zsh"
mkdir -p "$HOME/.config/lf" && touch "$HOME/.config/lf/icons" # <--- Evita o erro do cat!

echo "Atualizando SHELL padrão para o zsh.."
ZSH_PATH="$(command -v zsh)"
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    echo "Executando: chsh -s $ZSH_PATH"
    echo "Pode ser necessário digitar sua senha."
    chsh -s "$ZSH_PATH" < /dev/tty
else
    echo "Zsh já é o shell padrão."
fi

echo "Corrigindo o icone do Fedora no starship.toml..."
STARTSHIP_FILE="$HOME/.config/zsh/starship.toml"
if [[ -f "$STARSHIP_FILE" ]]; then
    python3 << 'PY'
from pathlib import Path

path = Path.home() / ".config/zsh/starship.toml"
text = path.read_text(encoding="utf-8")

# substitui a string literal "uf30a" pelo caractere Unicode real
text = text.replace("uf30a", "\uf30a")

path.write_text(text, encoding="utf-8")
print("Icone do Fedora corrigido.")
PY
fi

echo " Setup concluido com sucesso! Reinicie a sessão do terminal."
