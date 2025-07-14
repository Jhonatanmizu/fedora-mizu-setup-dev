#!/bin/bash

set -e
echo "📦 Loading dotfiles with GNU Stow..."

# Set dotfiles directory
DOTFILES_DIR="$HOME/.dotfiles"
# TODO: Replace with your actual dotfiles repository
# Clone your dotfiles repository if it's not already present
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "🔄 Cloning dotfiles repository..."
  git clone https://github.com/jhonatanmizu/dotfiles.git "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# List of dotfile folders to stow (adjust to your structure)
MODULES=("zsh" "git" "nvim" "alacritty" "tmux")

for module in "${MODULES[@]}"; do
  if [ -d "$module" ]; then
    echo "🔗 Stowing $module"
    stow "$module"
  else
    echo "⚠️  Module '$module' not found in $DOTFILES_DIR"
  fi
done

echo "✅ Dotfiles successfully stowed!"
