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
CUSTOM_SHORTCUTS=(
  "Alacritty:alacritty:<Control><Alt>t"
  "Ulauncher:ulauncher-toggle:<Super>space"
)

BASE_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
BINDINGS=()
INDEX=0

echo -e "${GREEN}→ Applying custom app shortcuts...${NC}"

for entry in "${CUSTOM_SHORTCUTS[@]}"; do
  IFS=":" read -r NAME CMD BIND <<< "$entry"

  KEY_PATH="${BASE_PATH}/custom${INDEX}/"
  BINDINGS+=("'$KEY_PATH'")

  # Use dconf to write the custom keybinding values
  dconf write "${KEY_PATH}name" "'$NAME'"
  dconf write "${KEY_PATH}command" "'$CMD'"
  dconf write "${KEY_PATH}binding" "'$BIND'"

  echo -e "${CYAN}✔ $NAME → $BIND${NC}"
  ((INDEX++))
done

# Apply the complete list of keybinding paths
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[${BINDINGS[*]}]"

echo -e "${GREEN}==> GNOME shortcuts successfully configured!${NC}"
