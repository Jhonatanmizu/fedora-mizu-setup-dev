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
  bat \  

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

# TODO: Clone wallpaper repo

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

echo -e "${GREEN}6. Installing Docker & Docker Compose...${NC}"

# Uninstall old docker versions
sudo dnf remove docker \
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
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
sudo systemctl enable --now docker

echo -e "${GREEN}7. Installing VSCode...${NC}"
if ! rpm -q code &> /dev/null; then
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
  sudo dnf install -y code
fi

echo -e "${GREEN}8. Installing Android Studio...${NC}"
if [ ! -d "/opt/android-studio" ]; then
  LATEST_URL=$(curl -s "https://developer.android.com/studio#downloads" | grep -o 'https://redirector.gvt1.com/edgedl/android/studio/ide-zips/[^"]*-linux.tar.gz' | head -n 1)
  wget "$LATEST_URL"
  sudo tar -xzf android-studio-*.tar.gz -C /opt
  rm android-studio-*.tar.gz
fi

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

# Ulauncher
echo -e "${GREEN}13. Installing Ulauncher..."
sudo dnf install -y ulauncher
mkdir -p ~/.config/autostart
cp /usr/share/applications/ulauncher.desktop ~/.config/autostart/

# Starship shell prompt
echo -e "${GREEN}14. Install Starship shell prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# Install gnome-extensions
echo -e "${GREEN}15. Installing GNOME extensions...${NC}"
bash "$(dirname "$0")/scripts/shell-extensions.sh"

# Gnome shortcuts
echo -e "${GREEN}16. Setting up GNOME shortcuts...${NC}"
bash "$(dirname "$0")/scripts/gnome-shortcuts.sh"

# Install themes
echo -e "${GREEN}17. Installing themes...${NC}"
bash "$(dirname "$0")/scripts/themes.sh"


# Install fonts
echo -e "${GREEN}18. Installing fonts...${NC}"
bash "$(dirname "$0")/scripts/fonts.sh"

echo -e "${GREEN}✅ Setup complete! Please restart your terminal or run \`exec zsh\` to apply changes.${NC}"
