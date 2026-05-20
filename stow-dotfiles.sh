#!/usr/bin/env bash

set -euo pipefail

# === Main Script ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
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

# === Ensure parent directory exists ===
mkdir -p "$(dirname "$DOTFILES_DIR")"

# === Clone if not exists ===
if [ ! -d "$DOTFILES_DIR" ]; then
  info "Cloning dotfiles repository into $DOTFILES_DIR..."
  if git clone https://github.com/jhonatanmizu/dotfiles.git "$DOTFILES_DIR"; then
    success "Repository cloned successfully"
  else
    error "Failed to clone dotfiles repository"
    exit 1
  fi
else
  info "Dotfiles directory already exists at $DOTFILES_DIR"
fi

# === Change to dotfiles directory ===
cd "$DOTFILES_DIR" || { error "Failed to access $DOTFILES_DIR"; exit 1; }

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
