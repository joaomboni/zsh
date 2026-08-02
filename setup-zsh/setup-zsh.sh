#!/bin/bash
#
# Fedora zsh bootstrap
# Based on https://github.com/radleylewis/zsh

set -euo pipefail

echo "Installing dependencies..."
sudo dnf install -y zsh vim-X11  eza bat fd-find fzf ripgrep zoxide

echo "Installing Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

echo "Configuring ZDOTDIR in /etc/zsh/zshenv..."
# Ensure the directory exists before creating the file
sudo mkdir -p /etc/zsh
if grep -q "ZDOTDIR" /etc/zsh/zshenv 2>/dev/null; then
    echo "ZDOTDIR already set in /etc/zsh/zshenv. Skipping..."
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

echo "Cloning repository..."
if [ -d "$HOME/.config/zsh" ]; then
    echo "~/.config/zsh already exists. Skipping clone."
else
    git clone https://github.com/joaomboni/zsh "$HOME/.config/zsh"
fi

echo "Writing ~/.zshenv bootstrap..."
cat > "$HOME/.zshenv" << 'EOF'
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
EOF
ln -sf "$HOME/.config/zsh/.zshrc" "$HOME/.zshrc"

echo "Creating history and cache directories..."
mkdir -p "$HOME/.cache/zsh"
mkdir -p "$HOME/.local/state/zsh"
mkdir -p "$HOME/.config/lf" && touch "$HOME/.config/lf/icons" # avoid cat error when icons file is missing

echo "Setting zsh as default shell..."
ZSH_PATH="$(command -v zsh)"
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    echo "Running: chsh -s $ZSH_PATH"
    echo "You may be prompted for your password."
    chsh -s "$ZSH_PATH" < /dev/tty
else
    echo "zsh is already the default shell."
fi

echo "Setup complete. Restart your terminal."
