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
echo -e "${CYAN}🎨 Installing Tokyo Night GTK theme and Tela icon theme...${NC}"

# === Check Requirements ===
REQUIRED_CMDS=(git gsettings dnf unzip)
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

# === 0. Ensure user theme extension is installed ===
info "Checking for User Themes GNOME extension..."

if ! rpm -q gnome-shell-extension-user-theme &>/dev/null; then
  info "Installing gnome-shell-extension-user-theme..."
  sudo dnf install -y gnome-shell-extension-user-theme
else
  success "User Themes extension already installed"
fi

# === 1. Install Tokyo Night GTK Theme ===
TOKYONIGHT_DIR="$HOME/.themes"
TEMP_TOKYO="/tmp/tokyo-night-gtk-$(date +%s)"
mkdir -p "$TOKYONIGHT_DIR"

info "Cloning Tokyo Night GTK theme into $TEMP_TOKYO..."
if ! git clone --depth 1 https://github.com/Fausto-Korpsvart/Tokyo-Night-GTK-Theme "$TEMP_TOKYO"; then
  error "Failed to clone Tokyo Night GTK repository"
  exit 1
fi

info "Installing Tokyo Night GTK theme..."
mv "$TEMP_TOKYO/themes/Tokyonight-Dark-BL" "$TOKYONIGHT_DIR/Tokyonight-Dark-BL"

# === 2. Install Tela Icon Theme ===
TEMP_TELA="/tmp/tela-icons-$(date +%s)"
info "Downloading Tela icon theme to $TEMP_TELA..."

if ! git clone --quiet https://github.com/vinceliuice/Tela-icon-theme.git "$TEMP_TELA"; then
  error "Failed to clone Tela icon theme repository"
  exit 1
fi

info "Installing Tela icon theme..."
if ! "$TEMP_TELA"/install.sh -a; then
  error "Failed to install Tela icon theme"
  rm -rf "$TEMP_TELA"
  exit 1
fi
rm -rf "$TEMP_TELA"

# === 3. Enable User Theme Extension (requires GNOME Shell restart) ===
info "Enabling User Themes extension..."

if gnome-extensions list | grep -q "user-theme@gnome-shell-extensions.gcampax.github.com"; then
  gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || warning "Failed to enable user-theme extension. Try enabling it manually in GNOME Tweaks."
  success "User Themes extension enabled"
else
  warning "User Themes extension not found in gnome-extensions list. You may need to log out and back in first."
fi

# === 4. Apply Themes ===
info "Applying theme settings..."

apply_theme() {
  gsettings set org.gnome.desktop.interface gtk-theme "Tokyonight-Dark-BL"
  gsettings set org.gnome.desktop.wm.preferences theme "Tokyonight-Dark-BL"
  gsettings set org.gnome.desktop.interface icon-theme "Tela-dark"

  if gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
    gsettings set org.gnome.shell.extensions.user-theme name "Tokyonight-Dark-BL"
  else
    warning "GNOME Shell user-theme schema not found. Shell theme not applied."
  fi
}

if ! apply_theme; then
  warning "Failed to apply some theme settings (GNOME might not be running)"
fi

# === 5. Verification ===
info "Verifying theme installation..."

verify_theme() {
  local current_gtk=$(gsettings get org.gnome.desktop.interface gtk-theme)
  local current_icons=$(gsettings get org.gnome.desktop.interface icon-theme)

  if [[ "$current_gtk" != "'Tokyonight-Dark-BL'" ]]; then
    warning "GTK theme not applied correctly (current: $current_gtk)"
  fi

  if [[ "$current_icons" != "'Tela-dark'" ]]; then
    warning "Icon theme not applied correctly (current: $current_icons)"
  fi
}

verify_theme

success "✅ Tokyo Night GTK theme and Tela icons installed and applied!"
info "ℹ️ You may need to:"
echo "  - Restart GNOME Shell (Alt+F2, then type 'r' and press Enter)"
echo "  - Or log out and log back in to see full shell theme effect"
echo "  - Ensure 'User Themes' extension is enabled in GNOME Tweaks"
