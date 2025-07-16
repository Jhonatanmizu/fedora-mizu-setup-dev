#!/usr/bin/env bash

set -euo pipefail

# === Color Variables ===
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

# === Utility Functions ===
info() { echo -e "${BLUE}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✖ $1${NC}" >&2; }

# === Script Setup ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils.sh"

# === Package Installation ===
info "Installing required packages..."
install_packages python-pipx gnome-shell-extensions
success "Packages installed"

# === gnome-extensions-cli Setup ===
GEXT_BIN="$HOME/.local/bin/gext"

if ! command -v "$GEXT_BIN" &>/dev/null; then
  info "gnome-extensions-cli not found, installing via pipx..."
  pipx install gnome-extensions-cli --system-site-packages
  success "gnome-extensions-cli installed"
else
  info "gnome-extensions-cli already installed"
fi

# === Extensions to Install ===
declare -a EXTENSIONS=(
  "tactile@lundal.io"
  "just-perfection-desktop@just-perfection"
  "blur-my-shell@aunetx"
  "space-bar@luchrioh"
  "undecorate@sun.wxg@gmail.com"
  "tophat@fflewddur.github.io"
  "switcher@landau.fi"
)

echo -e "\n${CYAN}=== Installing GNOME Extensions via gext ===${NC}"

INSTALLED=0
SKIPPED=0

for EXT in "${EXTENSIONS[@]}"; do
  if ! "$GEXT_BIN" list | grep -q "$EXT"; then
    info "Installing extension: $EXT"
    if "$GEXT_BIN" install "$EXT"; then
      success "Installed: $EXT"
      ((INSTALLED++))
    else
      error "Failed to install: $EXT"
    fi
  else
    warning "Extension already installed: $EXT"
    ((SKIPPED++))
  fi
done

# === Load GNOME dconf Settings ===
DCONF_FILE="$SCRIPT_DIR/gnome-settings.dconf"
if [[ -f "$DCONF_FILE" ]]; then
  info "Applying GNOME Shell extension settings from: $DCONF_FILE"
  if dconf load /org/gnome/shell/extensions/ < "$DCONF_FILE"; then
    success "Settings applied"
  else
    error "Failed to apply dconf settings"
  fi
else
  warning "dconf settings file not found: $DCONF_FILE"
fi

# === Final Summary ===
echo -e "\n${CYAN}=== Summary ===${NC}"
echo -e "${GREEN}✓ Extensions installed: ${INSTALLED}${NC}"
echo -e "${YELLOW}⚠ Extensions skipped (already installed): ${SKIPPED}${NC}"
