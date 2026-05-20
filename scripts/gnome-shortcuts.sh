#!/usr/bin/env bash

set -euo pipefail

# === Start ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils.sh"
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
