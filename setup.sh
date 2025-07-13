#!/bin/bash

set -e  # Exit on any error
echo "🚀 Fedora Mizu Setup Started"

# Colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

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

echo -e "${GREEN}2. Installing Basic Tools...${NC}"

# Enable RPM Fusion (for some tools that may still need it)
sudo dnf install -y \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install Flatpak and Flathub if not already
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install tools from dnf (available directly)
sudo dnf install -y \
    xournal \
    gnome-tweaks \
    gnome-extensions-app \
    gimp \
    krita \
    inkscape \
    kdenlive \
    vlc

# Install flatpak packages (GUI apps not available via dnf)
flatpak install -y flathub \
    org.localsend.localsend_app \
    com.obsidian.Obsidian \
    com.spotify.Client \
    com.dropbox.Client \
    com.vivaldi.Vivaldi



echo -e "${GREEN}3. Installing Development Tools...${NC}"
sudo dnf groupinstall -y "Development Tools" "Development Libraries"

echo -e "${GREEN}4. Setting ZSH as default shell...${NC}"
if [[ "$SHELL" != "$(which zsh)" ]]; then
  chsh -s "$(which zsh)"
fi

echo -e "${GREEN}5. Installing Mise Version Manager...${NC}"
if ! command -v mise &> /dev/null; then
  curl https://mise.run | sh
fi

MISE_RC_LINE='eval "$(~/.local/bin/mise activate zsh)"'
if ! grep -Fxq "$MISE_RC_LINE" ~/.zshrc; then
  echo "$MISE_RC_LINE" >> ~/.zshrc
fi

# TODO: Replace with docker installation from https://docs.docker.com/
echo -e "${GREEN}6. Installing Docker & Docker Compose...${NC}"
sudo dnf install -y docker
sudo systemctl enable --now docker

# Docker Compose v2 (recommended way now)
if ! command -v docker-compose &> /dev/null; then
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

echo -e "${GREEN}7. Installing VSCode...${NC}"
if ! rpm -q code &> /dev/null; then
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
  sudo dnf install -y code
fi

# TODO: use jetbrains-toolbox for all jetbrains tools
echo -e "${GREEN}8. Installing Android Studio...${NC}"
sudo dnf install -y java-11-openjdk-devel
if [ ! -d "/opt/android-studio" ]; then
  wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2022.3.1.20/android-studio-2022.3.1.20-linux.tar.gz
  sudo tar -xzf android-studio-*.tar.gz -C /opt
  rm android-studio-*.tar.gz
fi
ANDROID_PATH='export PATH=$PATH:/opt/android-studio/bin'
if ! grep -Fxq "$ANDROID_PATH" ~/.zshrc; then
  echo "$ANDROID_PATH" >> ~/.zshrc
fi

echo -e "${GREEN}9. Installing IntelliJ IDEA Community Edition...${NC}"
sudo dnf copr enable -y phracek/PyCharm
sudo dnf install -y intellij-idea-community

echo -e "${GREEN}10. Installing Alacritty Terminal...${NC}"
sudo dnf copr enable -y atim/alacritty
sudo dnf install -y alacritty

echo -e "${GREEN}11. Creating default folders...${NC}"
mkdir -p ~/Developer
mkdir -p ~/Wallpapers


# Load dotfiles
echo -e "${GREEN}12. Loading dotfiles...${NC}"
# Ensure GNU Stow is installed
sudo dnf install -y stow
bash "$(dirname "$0")/stow-dotfiles.sh"



echo -e "${GREEN}✅ Setup complete! Please restart your terminal or run \`exec zsh\` to apply changes.${NC}"
