#!/bin/bash

set -e

# === Colors ===
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 Fedora Mizu Setup Started${NC}"

# === Check Required Commands ===
REQUIRED_CMDS=(git curl wget zsh gsettings stow)
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" &> /dev/null; then
    echo -e "${RED}✖ Missing command: $cmd. Please install it before proceeding.${NC}"
    exit 1
  fi
done

echo -e "${GREEN}1. Updating System...${NC}"
sudo dnf update -y

echo -e "${GREEN}2. Installing Basic Packages...${NC}"
sudo dnf install -y \
  git \
  curl \
  wget \
  gcc-c++ \
  make \
  bashtop \
  fastfetch \
  zsh \
  zsh-syntax-highlighting \
  zsh-autosuggestions \
  neovim \
  bat

echo -e "${GREEN}3. Installing Basic Tools...${NC}"

# Enable RPM Fusion (for codecs and extra tools)
sudo dnf install -y \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install Flatpak and Flathub
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# GUI Tools via DNF
sudo dnf install -y \
  xournal \
  gnome-tweaks \
  gnome-extensions-app \
  gimp \
  krita \
  inkscape \
  kdenlive \
  vlc

# Flatpak Apps
flatpak install --noninteractive -y flathub \
  org.localsend.localsend_app \
  com.obsidian.Obsidian \
  com.spotify.Client \
  com.dropbox.Client \
  com.vivaldi.Vivaldi

echo -e "${GREEN}4. Installing Development Tools...${NC}"
sudo dnf groupinstall -y "Development Tools" "Development Libraries"

echo -e "${GREEN}5. Setting ZSH as default shell...${NC}"
if [[ "$SHELL" != "$(which zsh)" ]]; then
  chsh -s "$(which zsh)"
  echo -e "${CYAN}→ Default shell changed to ZSH. Restart your terminal to apply.${NC}"
fi

echo -e "${GREEN}6. Installing Mise Version Manager...${NC}"
if ! command -v mise &> /dev/null; then
  curl https://mise.run | sh
fi

echo -e "${GREEN}7. Installing Docker & Docker Compose...${NC}"

# Remove old versions
sudo dnf remove -y \
  docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-selinux \
  docker-engine-selinux \
  docker-engine

# Install Docker
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Enable Docker service
sudo systemctl enable --now docker

echo -e "${GREEN}8. Installing VSCode...${NC}"
if ! rpm -q code &> /dev/null; then
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
  sudo dnf install -y code
fi

echo -e "${GREEN}9. Installing Android Studio...${NC}"
if [ ! -d "/opt/android-studio" ]; then
  LATEST_URL=$(curl -s "https://developer.android.com/studio#downloads" | grep -o 'https://redirector.gvt1.com/edgedl/android/studio/ide-zips/[^"]*-linux.tar.gz' | head -n 1)
  FILE_NAME=$(basename "$LATEST_URL")
  wget "$LATEST_URL" -O "$FILE_NAME"
  sudo tar -xzf "$FILE_NAME" -C /opt
  rm "$FILE_NAME"
fi

echo -e "${GREEN}10. Installing Alacritty Terminal...${NC}"
sudo dnf copr enable -y atim/alacritty
sudo dnf install -y alacritty

echo -e "${GREEN}11. Creating default folders...${NC}"
mkdir -p ~/Developer ~/Wallpapers

echo -e "${GREEN}12. Loading dotfiles...${NC}"
sudo dnf install -y stow
bash "$(dirname "$0")/stow-dotfiles.sh"

echo -e "${GREEN}13. Installing Ulauncher...${NC}"
sudo dnf install -y ulauncher
mkdir -p ~/.config/autostart
cp /usr/share/applications/ulauncher.desktop ~/.config/autostart/

echo -e "${GREEN}14. Installing Starship shell prompt...${NC}"
curl -sS https://starship.rs/install.sh | sh -s -- -y

echo -e "${GREEN}15. Installing GNOME Extensions...${NC}"
bash "$(dirname "$0")/scripts/shell-extensions.sh"

echo -e "${GREEN}16. Setting GNOME Shortcuts...${NC}"
bash "$(dirname "$0")/scripts/gnome-shortcuts.sh"

echo -e "${GREEN}17. Installing Themes...${NC}"
bash "$(dirname "$0")/scripts/themes.sh"

echo -e "${GREEN}18. Installing Fonts...${NC}"
bash "$(dirname "$0")/scripts/fonts.sh"

echo -e "${GREEN}✅ Fedora Mizu setup complete!${NC}"
echo -e "${CYAN}ℹ️ Please restart your terminal or run 'exec zsh' to activate your new environment.${NC}"
