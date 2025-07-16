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

# === Start ===
echo -e "\n${CYAN}=== GNOME Workspace & Keybinding Configuration ===${NC}"

# === Configure Static Workspaces ===
info "Disabling dynamic workspaces and setting fixed count to 6..."
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 6
success "Workspace configuration applied"

# === Unset Super+Number Application Switching ===
info "Disabling default Super+Number application switching..."
for i in {1..9}; do
  gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]"
done
success "Super+Number application bindings disabled"

# === Set Super+Number for Workspace Switching ===
info "Mapping Super+Number to workspace switching..."
for i in {1..6}; do
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']"
done
success "Workspace keybindings configured"

# === Remap Close Window Shortcut ===
info "Setting Super+W as shortcut to close windows..."
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>w']"
success "Close shortcut remapped"

# === Done ===
echo -e "\n${CYAN}✓ All GNOME settings applied successfully.${NC}"
