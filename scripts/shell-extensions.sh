#!/bin/bash

set -euo pipefail

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
NC="\033[0m"

# Base URL for extensions
BASE_URL="https://extensions.gnome.org"

# Extensions slugs (friendly names)
EXTENSIONS=(
  "dash-to-dock"
  "just-perfection"
  "blur-my-shell"
  "appindicator-support"
  "caffeine"
  "clipboard-indicator"
  "vitals"
  "gsconnect"
  "emoji-selector"
)

# Get current GNOME Shell version
GNOME_VERSION=$(gnome-shell --version | awk '{print $3}')
echo -e "${CYAN}Detected GNOME Shell version: ${GNOME_VERSION}${NC}"

# Function to install one extension
install_extension() {
  local SLUG=$1
  echo -e "${CYAN}Installing extension: $SLUG${NC}"

  # Get UUID
  UUID=$(curl -s "${BASE_URL}/extension-query/?search=${SLUG}" | jq -r ".extensions[0].uuid")

  if [ -z "$UUID" ]; then
    echo -e "${RED}✖ UUID not found for slug: ${SLUG}${NC}"
    return 1
  fi

  # Get extension ID
  EXTENSION_ID=$(curl -s "${BASE_URL}/extension-query/?search=${SLUG}" | jq -r ".extensions[0].pk")

  if [ -z "$EXTENSION_ID" ]; then
    echo -e "${RED}✖ Extension ID not found for $SLUG${NC}"
    return 1
  fi

  # Get compatible version ID
  VERSION=$(curl -s "${BASE_URL}/extension-info/?pk=${EXTENSION_ID}" |
    jq -r ".shell_version_map[] | select(.shell_version == \"${GNOME_VERSION}\") | .pk" |
    head -n 1)

  if [ -z "$VERSION" ]; then
    echo -e "${RED}✖ No compatible version found for GNOME $GNOME_VERSION and $SLUG${NC}"
    return 1
  fi

  # Download extension zip
  TMP_DIR=$(mktemp -d)
  ZIP_URL="${BASE_URL}/download-extension/${UUID}.shell-extension.zip?version_tag=${VERSION}"
  echo -e "${GREEN}→ Downloading: ${ZIP_URL}${NC}"
  curl -sL "${ZIP_URL}" -o "$TMP_DIR/extension.zip"

  # Install the extension
  gnome-extensions install --force "$TMP_DIR/extension.zip" && \
    echo -e "${GREEN}✔ Installed $SLUG successfully${NC}" || \
    echo -e "${RED}✖ Failed to install $SLUG${NC}"

  rm -rf "$TMP_DIR"
}

# Main installation loop
for EXT in "${EXTENSIONS[@]}"; do
  install_extension "$EXT"
done

echo -e "${GREEN}==> All GNOME extensions installed (as compatible with GNOME $GNOME_VERSION).${NC}"
