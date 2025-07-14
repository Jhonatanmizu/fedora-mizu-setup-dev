#!/bin/bash

set -e

GREEN="\033[1;32m"
CYAN="\033[1;36m"
RED="\033[1;31m"
NC="\033[0m"

# Check required tools
for cmd in git gsettings dnf; do
  if ! command -v "$cmd" &> /dev/null; then
    echo -e "${RED}✖ Required command '$cmd' not found.${NC}"
    exit 1
  fi
done

echo -e "${CYAN}🎨 Installing Layan GTK theme and Tela icon theme...${NC}"

# 1. Install Layan GTK theme from COPR
sudo dnf copr enable -y tchakabam/layan-gtk-theme
sudo dnf install -y layan-gtk-theme

# 2. Install Tela icon theme from GitHub
rm -rf /tmp/tela-icons
git clone https://github.com/vinceliuice/Tela-icon-theme.git /tmp/tela-icons
/tmp/tela-icons/install.sh -a
rm -rf /tmp/tela-icons

# 3. Apply the themes using gsettings
echo -e "${CYAN}🎛️ Applying Layan theme and Tela icons...${NC}"

gsettings set org.gnome.desktop.interface gtk-theme "Layan-dark"
gsettings set org.gnome.desktop.wm.preferences theme "Layan-dark"
gsettings set org.gnome.desktop.interface icon-theme "Tela-dark"

# Only apply shell theme if user-theme extension is available
if gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
  gsettings set org.gnome.shell.extensions.user-theme name "Layan-dark"
fi

echo -e "${GREEN}✅ Themes installed and applied successfully!${NC}"
echo -e "${CYAN}ℹ️ You may need to log out and back in to see full effects.${NC}"
