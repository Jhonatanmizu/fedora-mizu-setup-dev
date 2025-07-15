#!/usr/bin/env bash

set -euo pipefail

# === Color Variables ===
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

# === Utility Functions ===
info() { echo -e "${BLUE}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✖ $1${NC}" >&2; }

# === Check Requirements ===
REQUIRED_CMDS=(curl jq gnome-extensions)
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

# === Main Script ===
BASE_URL="https://extensions.gnome.org"

# List of extension slugs with friendly names
declare -A EXTENSIONS=(
  ["dash-to-dock"]="Dash to Dock"
  ["just-perfection"]="Just Perfection"
  ["blur-my-shell"]="Blur My Shell"
  ["appindicator-support"]="AppIndicator Support"
  ["caffeine"]="Caffeine"
  ["clipboard-indicator"]="Clipboard Indicator"
  ["vitals"]="Vitals"
  ["gsconnect"]="GSConnect"
  ["emoji-selector"]="Emoji Selector"
)

# Get GNOME version
GNOME_VERSION=$(gnome-shell --version | awk '{print $3}')
info "Detected GNOME Shell version: ${GNOME_VERSION}"

# Function to install a single extension
install_extension() {
  local SLUG=$1
  local NAME=${EXTENSIONS[$SLUG]:-$SLUG}
  info "Processing: ${NAME} (${SLUG})"

  # Query extension metadata
  local JSON UUID EXTENSION_ID VERSION
  JSON=$(curl -fsS "${BASE_URL}/extension-query/?search=${SLUG}" || {
    error "Failed to query extension metadata"
    return 1
  })

  UUID=$(echo "$JSON" | jq -r '.extensions[0].uuid')
  EXTENSION_ID=$(echo "$JSON" | jq -r '.extensions[0].pk')

  if [[ -z "$UUID" || "$UUID" == "null" ]]; then
    warning "UUID not found for slug: ${SLUG}"
    return 1
  fi

  if [[ -z "$EXTENSION_ID" || "$EXTENSION_ID" == "null" ]]; then
    warning "Extension ID not found for ${SLUG}"
    return 1
  fi

  # Find compatible version
  VERSION=$(curl -fsS "${BASE_URL}/extension-info/?pk=${EXTENSION_ID}" | \
    jq -r ".shell_version_map[] | select(.shell_version == \"${GNOME_VERSION}\") | .pk" | \
    head -n 1)

  if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
    warning "No compatible version found for GNOME ${GNOME_VERSION} and ${NAME}"
    return 1
  fi

  # Download and install
  local TMP_DIR ZIP_URL
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT
  
  info "Downloading extension..."
  ZIP_URL="${BASE_URL}/download-extension/${UUID}.shell-extension.zip?version_tag=${VERSION}"
  if ! curl -fsSL "$ZIP_URL" -o "$TMP_DIR/extension.zip"; then
    error "Failed to download extension"
    return 1
  fi

  if gnome-extensions install --force "$TMP_DIR/extension.zip"; then
    success "Installed ${NAME}"
    
    if gnome-extensions enable "$UUID"; then
      success "Enabled ${NAME}"
    else
      warning "Could not enable ${NAME} - may require GNOME Shell restart"
    fi
  else
    error "Failed to install ${NAME}"
    return 1
  fi
}

# === Installation Summary ===
echo -e "\n${CYAN}=== GNOME Extensions Installer ===${NC}"
echo -e "Extensions to install: ${#EXTENSIONS[@]}"
echo -e "GNOME Version: ${GNOME_VERSION}\n"

# Loop through all extensions
INSTALLED=0
SKIPPED=0
FAILED=0

for EXT in "${!EXTENSIONS[@]}"; do
  if install_extension "$EXT"; then
    ((INSTALLED++))
  else
    ((FAILED++))
  fi
  echo
done

# === Final Report ===
echo -e "${CYAN}=== Installation Summary ===${NC}"
echo -e "${GREEN}✓ Successfully installed: ${INSTALLED}${NC}"
echo -e "${YELLOW}⚠ Skipped: ${SKIPPED}${NC}"
echo -e "${RED}✖ Failed: ${FAILED}${NC}"

if [ $FAILED -gt 0 ]; then
  warning "Some extensions failed to install. This is often due to:"
  echo "- Incompatible GNOME Shell version"
  echo "- Network issues"
  echo "- Missing dependencies"
  echo "Check the output above for specific errors."
fi

info "You may need to restart GNOME Shell (Alt+F2 then 'r') to see all changes."