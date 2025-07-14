#!/bin/bash

set -euo pipefail

# === Colors for output ===
GREEN="\033[1;32m"
CYAN="\033[1;36m"
NC="\033[0m"

echo -e "${CYAN}==> Setting up GNOME keyboard shortcuts...${NC}"

# === Step 1: Workspace switching shortcuts ===
echo -e "${GREEN}→ Setting workspace shortcuts...${NC}"
for i in {1..6}; do
  gsettings set "org.gnome.desktop.wm.keybindings" "switch-to-workspace-$i" "['<Super>$i']"
done

# === Step 2: Custom application shortcuts ===
# Format: name:command:binding
CUSTOM_SHORTCUTS=(
  "Alacritty:alacritty:<Control><Alt>t"
  "Ulauncher:ulauncher:<Super>space"
)

# Base path for custom keybindings
BASE_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

# Build the list of keybinding paths
echo -e "${GREEN}→ Applying custom app shortcuts...${NC}"
BINDINGS=()
INDEX=0

for entry in "${CUSTOM_SHORTCUTS[@]}"; do
  IFS=":" read -r NAME CMD BIND <<< "$entry"

  KEY_PATH="${BASE_PATH}/custom${INDEX}/"
  BINDINGS+=("'$KEY_PATH'")

  gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH" name "$NAME"
  gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH" command "$CMD"
  gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH" binding "$BIND"

  echo -e "${CYAN}✔ $NAME → $BIND${NC}"
  ((INDEX++))
done

# Apply the full list of custom keybinding paths
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[${BINDINGS[*]}]"

echo -e "${GREEN}==> GNOME shortcuts successfully configured!${NC}"
