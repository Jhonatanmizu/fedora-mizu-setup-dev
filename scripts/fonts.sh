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

# === Font Variables ===
FONT_DIR="${HOME}/.local/share/fonts"
TMP_DIR="$(mktemp -d)"
NERD_FONT_REPO="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
FONTS=("FiraCode" "Meslo")

# === Download and Install Fonts ===
install_fonts() {
  mkdir -p "${FONT_DIR}"
  cd "$TMP_DIR"

  for font in "${FONTS[@]}"; do
    info "Downloading ${font} Nerd Font..."
    archive="${font}.zip"
    url="${NERD_FONT_REPO}/${archive}"

    if curl -fsSLO "$url"; then
      info "Extracting ${archive}..."
      unzip -q "$archive" -d "${FONT_DIR}"
      success "${font} installed to ${FONT_DIR}"
    else
      warning "Failed to download ${font} from ${url}"
    fi
  done
}

# === Verify Fonts Installed ===
verify_fonts() {
  local fonts_installed=0
  info "Verifying font installation..."

  for font in "${FONTS[@]}"; do
    if find "$FONT_DIR" -iname "*${font}*" -print -quit | grep -q .; then
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

# === Refresh Font Cache ===
refresh_font_cache() {
  info "Refreshing font cache..."
  if fc-cache -fv > /dev/null; then
    success "Font cache updated"
  else
    warning "Font cache refresh failed"
  fi
}

# === Clean Up Temp Files ===
cleanup() {
  rm -rf "$TMP_DIR"
}

# === Main Execution ===
echo -e "${CYAN}🔤 Installing Nerd Fonts from official GitHub releases...${NC}"
install_fonts
refresh_font_cache
verify_fonts
cleanup

# === Final Report ===
echo -e "\n${CYAN}=== Font Installation Summary ===${NC}"
if verify_fonts; then
  success "✅ Nerd Fonts installed successfully!"
  info "You may need to:"
  echo "  - Restart terminal applications to use the new fonts"
  echo "  - Configure your terminal emulator to use the installed fonts"
else
  warning "Some fonts may not have installed correctly"
  info "Try downloading and installing them manually from:"
  echo "  https://github.com/ryanoasis/nerd-fonts/releases"
fi
