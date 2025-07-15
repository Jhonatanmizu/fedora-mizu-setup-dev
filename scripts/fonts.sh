#!/usr/bin/env bash

set -euo pipefail

# === Color Variables ===
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

# === Utility Functions ===
info() { echo -e "${BLUE}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✖ $1${NC}" >&2; }

# === Main Script ===
echo -e "${CYAN}🔤 Installing Nerd Fonts using getnf...${NC}"

# === 1. Install getnf if not present ===
install_getnf() {
  if ! command -v getnf &> /dev/null; then
    info "Downloading getnf CLI..."
    if ! curl -fsSL https://raw.githubusercontent.com/ronniedroid/getnf/main/install.sh | bash; then
      error "Failed to install getnf"
      exit 1
    fi
    
    # Add to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v getnf &> /dev/null; then
      warning "getnf installed but not in PATH"
      info "Please run:"
      echo "  source ~/.bashrc"
      echo "Or add to your shell config:"
      echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
      exit 1
    fi
  fi
}

# === 2. Install fonts ===
install_fonts() {
  local fonts=("Meslo" "FiraCode")
  info "Installing fonts: ${fonts[*]}..."
  
  if ! getnf "${fonts[@]}"; then
    error "Font installation failed"
    return 1
  fi
}

# === 3. Verify installation ===
verify_fonts() {
  local font_dir="${HOME}/.local/share/fonts"
  local fonts_installed=0
  
  info "Verifying font installation..."
  
  for font in "Meslo" "FiraCode"; do
    if find "$font_dir" -iname "*${font}*" -print -quit | grep -q .; then
      success "Found ${font} font files"
      ((fonts_installed++))
    else
      warning "Could not find ${font} font files"
    fi
  done
  
  if [ "$fonts_installed" -eq 0 ]; then
    error "No fonts were installed"
    return 1
  fi
}

# === 4. Refresh font cache ===
refresh_font_cache() {
  info "Refreshing font cache..."
  if ! fc-cache -fv > /dev/null; then
    warning "Font cache refresh failed (continuing anyway)"
  else
    success "Font cache updated"
  fi
}

# === Main Execution ===
install_getnf
install_fonts
refresh_font_cache
verify_fonts

# === Final Report ===
echo -e "\n${CYAN}=== Font Installation Summary ===${NC}"
if verify_fonts; then
  success "✅ Nerd Fonts installed successfully!"
  info "You may need to:"
  echo "  - Restart terminal applications to use the new fonts"
  echo "  - Configure your terminal emulator to use the installed fonts"
else
  warning "Some fonts may not have installed correctly"
  info "Try running manually:"
  echo "  getnf Meslo FiraCode"
fi