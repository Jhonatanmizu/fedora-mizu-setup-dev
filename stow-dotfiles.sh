#!/usr/bin/env bash

set -euo pipefail

# === Color Variables ===
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
BLUE="\033[1;34m"
NC="\033[0m"

# === Utility Functions ===
info() { echo -e "${BLUE}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✖ $1${NC}" >&2; }

# === Main Script ===
echo -e "${CYAN}📦 Loading dotfiles with GNU Stow...${NC}"

# === Prerequisite Check ===
REQUIRED_CMDS=(git stow)
missing_cmds=()

for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    missing_cmds+=("$cmd")
  fi
done

if [ ${#missing_cmds[@]} -gt 0 ]; then
  error "Missing required commands: ${missing_cmds[*]}"
  info "Install them with:"
  echo "  sudo dnf install -y ${missing_cmds[*]}"
  exit 1
fi

# === Set dotfiles directory ===
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# === Clone if not exists ===
if [ ! -d "$DOTFILES_DIR" ]; then
  info "Cloning dotfiles repository..."
  if ! git clone --quiet https://github.com/jhonatanmizu/dotfiles.git "$DOTFILES_DIR"; then
    error "Failed to clone dotfiles repository"
    exit 1
  fi
  success "Repository cloned successfully"
fi

# === Change to dotfiles directory ===
if ! cd "$DOTFILES_DIR"; then
  error "Failed to access $DOTFILES_DIR"
  exit 1
fi

# === Update repository if it exists ===
if [ -d ".git" ]; then
  info "Updating dotfiles repository..."
  if ! git pull --quiet --rebase; then
    warning "Failed to update dotfiles repository (continuing with existing version)"
  fi
fi

# === List of stow modules ===
MODULES=("zsh" "git" "nvim" "alacritty" "mise" "starship" "ulauncher")
stowed_modules=()
skipped_modules=()

# === Process each module ===
for module in "${MODULES[@]}"; do
  if [ ! -d "$module" ]; then
    warning "Module '$module' not found - skipping"
    skipped_modules+=("$module")
    continue
  fi

  info "Stowing module: $module"
  if stow --restow --target="$HOME" "$module" 2>/dev/null; then
    success "Successfully stowed $module"
    stowed_modules+=("$module")
  else
    warning "Failed to stow $module (conflicts may exist)"
    skipped_modules+=("$module")
  fi
done

# === Summary Report ===
echo -e "\n${CYAN}📋 Stow Summary:${NC}"
echo -e "${GREEN}✅ Successfully stowed: ${#stowed_modules[@]} modules${NC}"
printf ' - %s\n' "${stowed_modules[@]}"

if [ ${#skipped_modules[@]} -gt 0 ]; then
  echo -e "${YELLOW}⚠  Skipped: ${#skipped_modules[@]} modules${NC}"
  printf ' - %s\n' "${skipped_modules[@]}"
fi

# === Final Message ===
if [ ${#stowed_modules[@]} -gt 0 ]; then
  success "✅ Dotfiles successfully stowed!"
else
  warning "No modules were stowed - check for errors above"
  exit 1
fi