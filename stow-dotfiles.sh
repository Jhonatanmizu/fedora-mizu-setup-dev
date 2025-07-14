#!/bin/bash

set -euo pipefail

# === Colors ===
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
NC="\033[0m"

echo -e "${CYAN}📦 Loading dotfiles with GNU Stow...${NC}"

# === Prerequisite Check ===
REQUIRED_CMDS=(git stow)
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}✖ Required command '$cmd' not found. Please install it first.${NC}"
    exit 1
  fi
done

# === Set dotfiles directory ===
DOTFILES_DIR="$HOME/.dotfiles"

# === Clone if not exists ===
if [ ! -d "$DOTFILES_DIR" ]; then
  echo -e "${YELLOW}🔄 Cloning dotfiles repository...${NC}"
  git clone https://github.com/jhonatanmizu/dotfiles.git "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR" || {
  echo -e "${RED}✖ Failed to access $DOTFILES_DIR${NC}"
  exit 1
}

# === List of stow modules ===
MODULES=("zsh" "git" "nvim" "alacritty" "mise" "starship" "ulauncher")

for module in "${MODULES[@]}"; do
  if [ -d "$module" ]; then
    echo -e "${GREEN}🔗 Stowing module: $module${NC}"
    stow "$module"
  else
    echo -e "${YELLOW}⚠️  Module '$module' not found in $DOTFILES_DIR${NC}"
  fi
done

echo -e "${GREEN}✅ Dotfiles successfully stowed!${NC}"
