#!/usr/bin/env bash

set -euo pipefail

# === Color Variables ===
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
NC="\033[0m"

# === Utility Functions ===
info() { echo -e "${CYAN}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✖ $1${NC}" >&2; }

# === Check Requirements ===
check_requirements() {
  if ! command -v gsettings &> /dev/null; then
    error "gsettings not found. Are you running GNOME?"
    exit 1
  fi

  if ! command -v dconf &> /dev/null; then
    error "dconf not found. Required for custom shortcuts."
    exit 1
  fi
}

# === Main Script ===
echo -e "${CYAN}==> Setting up GNOME keyboard shortcuts...${NC}"
check_requirements

# === Step 1: Workspace switching shortcuts ===
info "Configuring workspace shortcuts..."
for i in {1..6}; do
  if ! gsettings set "org.gnome.desktop.wm.keybindings" "switch-to-workspace-$i" "['<Super>$i']"; then
    warning "Failed to set shortcut for workspace $i"
  else
    success "Set <Super>$i → Switch to workspace $i"
  fi
done

# === Step 2: Custom application shortcuts ===
declare -A CUSTOM_SHORTCUTS=(
  ["Alacritty"]="alacritty:<Control><Alt>t"
  ["Ulauncher"]="ulauncher-toggle:<Super>space"
  # Add more shortcuts here in format: ["Name"]="command:binding"
)

BASE_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
BINDINGS=()
INDEX=0

info "Applying custom application shortcuts..."

# First reset existing custom shortcuts to avoid conflicts
gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings

for NAME in "${!CUSTOM_SHORTCUTS[@]}"; do
  IFS=":" read -r CMD BIND <<< "${CUSTOM_SHORTCUTS[$NAME]}"
  KEY_PATH="${BASE_PATH}/custom${INDEX}/"
  
  # Verify command exists if it's not a special toggle command
  if [[ $CMD != *"toggle"* ]] && ! command -v "$CMD" &> /dev/null; then
    warning "Command '$CMD' not found - skipping '$NAME' shortcut"
    continue
  fi

  info "Creating shortcut: $NAME → $BIND"
  
  # Use dconf to write the custom keybinding values
  if ! dconf write "${KEY_PATH}name" "'$NAME'"; then
    warning "Failed to set name for $NAME"
    continue
  fi

  if ! dconf write "${KEY_PATH}command" "'$CMD'"; then
    warning "Failed to set command for $NAME"
    continue
  fi

  if ! dconf write "${KEY_PATH}binding" "'$BIND'"; then
    warning "Failed to set binding for $NAME"
    continue
  fi

  BINDINGS+=("'$KEY_PATH'")
  success "Created shortcut: $NAME → $BIND"
  ((INDEX++))
done

# Apply the complete list of keybinding paths
if [ ${#BINDINGS[@]} -gt 0 ]; then
  if ! gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[${BINDINGS[*]}]"; then
    error "Failed to apply custom keybindings list"
    exit 1
  fi
  success "Registered ${#BINDINGS[@]} custom shortcuts"
else
  warning "No custom shortcuts were configured"
fi

# === Verification ===
info "Verifying shortcuts..."
VERIFIED=0
TOTAL=$((6 + ${#CUSTOM_SHORTCUTS[@]}))

# Verify workspace shortcuts
for i in {1..6}; do
  CURRENT=$(gsettings get org.gnome.desktop.wm.keybindings "switch-to-workspace-$i")
  if [[ "$CURRENT" == "['<Super>$i']" ]]; then
    ((VERIFIED++))
  fi
done

# Verify custom shortcuts
CURRENT_BINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
for binding in "${BINDINGS[@]}"; do
  if [[ "$CURRENT_BINDINGS" == *"$binding"* ]]; then
    ((VERIFIED++))
  fi
done

# === Final Report ===
echo -e "\n${CYAN}=== Shortcut Configuration Summary ===${NC}"
echo -e "${GREEN}✓ Successfully configured: $VERIFIED/$TOTAL shortcuts${NC}"
if [ $VERIFIED -ne $TOTAL ]; then
  warning "Some shortcuts may not have been applied correctly"
  info "You may need to:"
  echo "  - Restart GNOME (Alt+F2 then 'r')"
  echo "  - Check for conflicting shortcuts in Settings → Keyboard Shortcuts"
fi

success "GNOME keyboard shortcuts setup complete!"