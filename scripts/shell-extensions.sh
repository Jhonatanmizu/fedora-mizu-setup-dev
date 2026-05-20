#!/usr/bin/env bash

set -euo pipefail

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

# === GNOME Shell Extension Settings ===
info "GNOME extension settings can be configured manually via GNOME Tweaks or Extensions app."

# === Final Summary ===
echo -e "\n${CYAN}=== Summary ===${NC}"
echo -e "${GREEN}✓ Extensions installed: ${INSTALLED}${NC}"
echo -e "${YELLOW}⚠ Extensions skipped (already installed): ${SKIPPED}${NC}"
