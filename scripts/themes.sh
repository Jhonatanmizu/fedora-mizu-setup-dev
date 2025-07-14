#!/bin/bash

set -e

GREEN="\033[1;32m"
CYAN="\033[1;36m"
NC="\033[0m"

echo -e "${CYAN}🎨 Installing Layan GTK theme and Tela icon theme...${NC}"

# 1. Install Layan GTK theme from COPR
sudo dnf copr enable -y tchakabam/layan-gtk-theme
sudo dnf install -y layan-gtk-theme

# 2. Install Tela icon theme from GitHub
git clone https://github.com/vinceliuice/Tela-icon-theme.git /tmp/tela-icons
/tmp/tela-icons/install.sh -a
rm -rf /tmp/tela-icons

# 3. Apply the themes using gsettings
echo -e "${CYAN}🎛️ Applying Layan theme and Tela icons...${NC}"

gsettings set org.gnome.desktop.interface gtk-theme "Layan-dark"
gsettings set org.gnome.desktop.wm.preferences theme "Layan-dark"
gsettings set org.gnome.desktop.interface icon-theme "Tela-dark"
gsettings set org.gnome.shell.extensions.user-theme name "Layan-dark" || true  # fallback in case the extension is not enabled

echo -e "${GREEN}✅ Themes installed and applied successfully!${NC}"
