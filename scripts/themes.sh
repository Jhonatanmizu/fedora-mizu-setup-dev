#!/usr/bin/env bash

set -euo pipefail

# === Color Variables ===
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

# === Utility Functions ===
info() { echo -e "${CYAN}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✖ $1${NC}" >&2; }

# === Main Script ===
echo -e "${CYAN}🎨 Installing Layan GTK theme and Tela icon theme...${NC}"

# === Check Requirements ===
REQUIRED_CMDS=(git gsettings dnf)
missing_cmds=()

for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    missing_cmds+=("$cmd")
  fi
done

if [ ${#missing_cmds[@]} -gt 0 ]; then
  error "Missing required commands: ${missing_cmds[*]}"
  info "Install them with:"
  echo "  sudo dnf install -y ${missing_cmds[*]}"
  exit 1
fi

# === 1. Install Layan GTK Theme ===
info "Adding Layan GTK theme repository..."
if ! sudo dnf copr enable -y tchakabam/layan-gtk-theme; then
  error "Failed to enable Layan COPR repository"
  exit 1
fi

info "Installing Layan GTK theme..."
if ! sudo dnf install -y layan-gtk-theme; then
  error "Failed to install Layan theme"
  exit 1
fi

# === 2. Install Tela Icon Theme ===
TEMP_DIR="/tmp/tela-icons-$(date +%s)"
info "Downloading Tela icon theme to $TEMP_DIR..."

if ! git clone --quiet https://github.com/vinceliuice/Tela-icon-theme.git "$TEMP_DIR"; then
  error "Failed to clone Tela icon theme repository"
  exit 1
fi

info "Installing Tela icon theme..."
if ! "$TEMP_DIR"/install.sh -a; then
  error "Failed to install Tela icon theme"
  rm -rf "$TEMP_DIR"
  exit 1
fi
rm -rf "$TEMP_DIR"

# === 3. Apply Themes ===
info "Applying theme settings..."

apply_theme() {
  local dark_mode="${1:-dark}"
  
  gsettings set org.gnome.desktop.interface gtk-theme "Layan-${dark_mode}"
  gsettings set org.gnome.desktop.wm.preferences theme "Layan-${dark_mode}"
  gsettings set org.gnome.desktop.interface icon-theme "Tela-${dark_mode}"
  
  # Only apply shell theme if user-theme extension is available
  if gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
    gsettings set org.gnome.shell.extensions.user-theme name "Layan-${dark_mode}"
  fi
}

if ! apply_theme "dark"; then
  warning "Failed to apply some theme settings (GNOME might not be running)"
fi

# === Verification ===
info "Verifying theme installation..."

verify_theme() {
  local current_gtk=$(gsettings get org.gnome.desktop.interface gtk-theme)
  local current_icons=$(gsettings get org.gnome.desktop.interface icon-theme)
  
  if [[ "$current_gtk" != "'Layan-dark'" ]]; then
    warning "GTK theme not applied correctly (current: $current_gtk)"
  fi
  
  if [[ "$current_icons" != "'Tela-dark'" ]]; then
    warning "Icon theme not applied correctly (current: $current_icons)"
  fi
}

verify_theme

success "✅ Themes installed and applied successfully!"
info "ℹ️ You may need to:"
echo "  - Restart GNOME (Alt+F2 then 'r')"
echo "  - Or log out and back in to see full effects"
echo "  - Install 'gnome-shell-extension-user-theme' for shell theme support"