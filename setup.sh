#!/usr/bin/env bash

set -eo pipefail

# === Colors ===
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# === Utility Functions ===
info() {
  echo -e "${CYAN}ℹ $1${NC}"
}

success() {
  echo -e "${GREEN}✓ $1${NC}"
}

warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

error() {
  echo -e "${RED}✖ $1${NC}" >&2
}

check_command() {
  if ! command -v "$1" &> /dev/null; then
    error "Missing command: $1. Please install it before proceeding."
    return 1
  fi
}

is_package_installed() {
  rpm -q "$1" &> /dev/null
}

install_packages() {
  local packages=("$@")
  local to_install=()
  
  for pkg in "${packages[@]}"; do
    if ! is_package_installed "$pkg"; then
      to_install+=("$pkg")
    else
      info "$pkg is already installed, skipping..."
    fi
  done
  
  if [ ${#to_install[@]} -gt 0 ]; then
    sudo dnf install -y "${to_install[@]}" || {
      error "Failed to install packages: ${to_install[*]}"
      return 1
    }
  fi
}

# === Main Script ===
echo -e "${CYAN}🚀 Fedora Mizu Setup Started${NC}"

# === Check Required Commands ===
REQUIRED_CMDS=(sudo git curl wget zsh gsettings stow)
for cmd in "${REQUIRED_CMDS[@]}"; do
  check_command "$cmd" || exit 1
done

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
  warning "This script should not be run as root. Please run as a normal user."
  exit 1
fi

# === System Update ===
info "1. Updating System..."
sudo dnf upgrade -y --refresh || {
  error "System update failed"
  exit 1
}

# === Basic Packages ===
info "2. Installing Basic Packages..."
BASIC_PKGS=(
  git
  curl
  wget
  gcc-c++
  make
#  bashtop
  fastfetch
  zsh
  zsh-syntax-highlighting
  zsh-autosuggestions
  neovim
  bat
)
install_packages "${BASIC_PKGS[@]}"

# Create bat symlink if needed
if ! command -v bat &> /dev/null && command -v batcat &> /dev/null; then
  sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
fi

# === Basic Tools ===
info "3. Installing Basic Tools..."

# Enable RPM Fusion
if ! is_package_installed rpmfusion-free-release; then
  info "Enabling RPM Fusion repositories..."
  sudo dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || {
    error "Failed to enable RPM Fusion"
    exit 1
  }
fi

# Install Flatpak and Flathub
if ! is_package_installed flatpak; then
  sudo dnf install -y flatpak || {
    error "Failed to install flatpak"
    exit 1
  }
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || {
    error "Failed to add Flathub repository"
    exit 1
  }
fi

# GUI Tools
GUI_PKGS=(
  xournalpp
  gnome-tweaks
  gnome-extensions-app
  gimp
  krita
  inkscape
  kdenlive
  vlc
)
install_packages "${GUI_PKGS[@]}"

# Flatpak Apps
info "Installing Flatpak applications..."
FLATPAK_APPS=(
  org.localsend.localsend_app
  md.obsidian.Obsidian
  com.spotify.Client
  com.dropbox.Client
  com.vivaldi.Vivaldi
)

for app in "${FLATPAK_APPS[@]}"; do
  if ! flatpak list --app | grep -q "$app"; then
    flatpak install --noninteractive -y flathub "$app" || {
      warning "Failed to install $app via flatpak"
    }
  else
    info "$app is already installed via flatpak, skipping..."
  fi
done


# === ZSH Setup ===
info "4. Setting ZSH as default shell..."
ZSH_PATH=$(which zsh)
if [ -z "$ZSH_PATH" ]; then
  error "ZSH not found in PATH"
  exit 1
fi

if [[ "$SHELL" != "$ZSH_PATH" ]]; then
  chsh -s "$ZSH_PATH" || {
    error "Failed to change default shell to ZSH"
    exit 1
  }
  info "Default shell changed to ZSH. Restart your terminal to apply."
fi

# === Mise Version Manager ===
info "5. Installing Mise Version Manager..."
if ! command -v mise &> /dev/null; then
  curl -fsSL https://mise.run | sh || {
    error "Failed to install Mise"
    exit 1
  }
  # Add mise to PATH for current session
  export PATH="$HOME/.local/bin:$PATH"
fi

# === Docker Setup ===
info "6. Installing Docker & Docker Compose..."

# Remove old versions
OLD_DOCKER_PKGS=(
  docker
  docker-client
  docker-client-latest
  docker-common
  docker-latest
  docker-latest-logrotate
  docker-logrotate
  docker-selinux
  docker-engine-selinux
  docker-engine
)

for pkg in "${OLD_DOCKER_PKGS[@]}"; do
  if is_package_installed "$pkg"; then
    sudo dnf remove -y "$pkg" || {
      warning "Failed to remove old docker package: $pkg"
    }
  fi
done

# Install Docker
if ! is_package_installed docker-ce; then
  sudo dnf -y install dnf-plugins-core || {
    error "Failed to install dnf-plugins-core"
    exit 1
  }

  sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo || {
   error "Failed to add Docker repository"
   exit 1
  }
  
  DOCKER_PKGS=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
  )
  install_packages "${DOCKER_PKGS[@]}"
  
  # Enable Docker service
  sudo systemctl enable --now docker || {
    error "Failed to enable Docker service"
    exit 1
  }
  
  # Add user to docker group
  sudo usermod -aG docker "$USER" && {
    info "Added $USER to docker group. You'll need to log out and back in for this to take effect."
  }
fi

# === VSCode Installation ===
info "7. Installing VSCode..."
if ! is_package_installed code; then
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc || {
    error "Failed to import Microsoft GPG key"
    exit 1
  }
  
  sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' || {
    error "Failed to add VSCode repository"
    exit 1
  }
  
  sudo dnf install -y code || {
    error "Failed to install VSCode"
    exit 1
  }
fi


# === Alacritty Installation ===
info "8. Installing Alacritty Terminal..."
if ! is_package_installed alacritty; then
  sudo dnf copr enable -y atim/alacritty || {
    error "Failed to enable Alacritty COPR repository"
    exit 1
  }
  sudo dnf install -y alacritty || {
    error "Failed to install Alacritty"
    exit 1
  }
fi

# === Create Default Folders ===
info "9. Creating default folders..."
mkdir -p ~/Developer ~/Wallpapers || {
  warning "Failed to create default folders"
}

# === Dotfiles Setup ===
info "10. Loading dotfiles..."
if ! is_package_installed stow; then
  sudo dnf install -y stow || {
    error "Failed to install stow"
    exit 1
  }
fi

if [ -f "$(dirname "$0")/stow-dotfiles.sh" ]; then
  bash "$(dirname "$0")/stow-dotfiles.sh" || {
    error "Failed to stow dotfiles"
    exit 1
  }
else
  warning "stow-dotfiles.sh not found, skipping dotfiles setup"
fi

# === Ulauncher Installation ===
info "11. Installing Ulauncher..."
if ! is_package_installed ulauncher; then
  sudo dnf install -y ulauncher || {
    error "Failed to install Ulauncher"
    exit 1
  }
fi

mkdir -p ~/.config/autostart
if [ -f "/usr/share/applications/ulauncher.desktop" ]; then
  cp /usr/share/applications/ulauncher.desktop ~/.config/autostart/ || {
    warning "Failed to copy Ulauncher autostart file"
  }
fi

# === Starship Prompt ===
info "12. Installing Starship shell prompt..."
if ! command -v starship &> /dev/null; then
  curl -fsS https://starship.rs/install.sh | sh -s -- -y || {
    error "Failed to install Starship"
    exit 1
  }
fi

# === GNOME Extensions ===
if [ -f "$(dirname "$0")/scripts/shell-extensions.sh" ]; then
  info "14. Installing GNOME Extensions..."
  bash "$(dirname "$0")/scripts/shell-extensions.sh" || {
    warning "Failed to install GNOME extensions"
  }
else
  warning "shell-extensions.sh not found, skipping GNOME extensions setup"
fi

# === GNOME Shortcuts ===
if [ -f "$(dirname "$0")/scripts/gnome-shortcuts.sh" ]; then
  info "15. Setting GNOME Shortcuts..."
  bash "$(dirname "$0")/scripts/gnome-shortcuts.sh" || {
    warning "Failed to set GNOME shortcuts"
  }
else
  warning "gnome-shortcuts.sh not found, skipping GNOME shortcuts setup"
fi

# === Themes ===
if [ -f "$(dirname "$0")/scripts/themes.sh" ]; then
  info "16. Installing Themes..."
  bash "$(dirname "$0")/scripts/themes.sh" || {
    warning "Failed to install themes"
  }
else
  warning "themes.sh not found, skipping themes setup"
fi

# === Fonts ===
if [ -f "$(dirname "$0")/scripts/fonts.sh" ]; then
  info "17. Installing Fonts..."
  bash "$(dirname "$0")/scripts/fonts.sh" || {
    warning "Failed to install fonts"
  }
else
  warning "fonts.sh not found, skipping fonts setup"
fi

# === Final Message ===
success "✅ Fedora Mizu setup complete!"
info "ℹ️ Please restart your terminal or run 'exec zsh' to activate your new environment."
info "ℹ️ For Docker permissions, you may need to log out and back in."
info "ℹ️ For Android Studio, you may need to run: /opt/android-studio/bin/studio.sh"
