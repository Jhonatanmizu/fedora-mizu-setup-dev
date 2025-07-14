#!/bin/bash

set -euo pipefail

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
NC="\033[0m"

# Required commands
for cmd in curl jq gnome-extensions; do
  if ! command -v "$cmd" &> /dev/null; then
    echo -e "${RED}✖ Required command '$cmd' not found. Please install it first.${NC}"
    exit 1
  fi
done

# Base URL
BASE_URL="https://extensions.gnome.org"

# List of extension slugs
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

# Get GNOME version
GNOME_VERSION=$(gnome-shell --version | awk '{print $3}')
echo -e "${CYAN}Detected GNOME Shell version: ${GNOME_VERSION}${NC}"

# Function to install a single extension
install_extension() {
  local SLUG=$1
  echo -e "${CYAN}Installing extension: $SLUG${NC}"

  # Query extension metadata
  JSON=$(curl -s "${BASE_URL}/extension-query/?search=${SLUG}")
  UUID=$(echo "$JSON" | jq -r '.extensions[0].uuid')
  EXTENSION_ID=$(echo "$JSON" | jq -r '.extensions[0].pk')

  if [[ -z "$UUID" || "$UUID" == "null" ]]; then
    echo -e "${RED}✖ UUID not found for slug: ${SLUG}${NC}"
    return 1
  fi

  if [[ -z "$EXTENSION_ID" || "$EXTENSION_ID" == "null" ]]; then
    echo -e "${RED}✖ Extension ID not found for $SLUG${NC}"
    return 1
  fi

  # Find compatible version
  VERSION=$(curl -s "${BASE_URL}/extension-info/?pk=${EXTENSION_ID}" |
    jq -r ".shell_version_map[] | select(.shell_version == \"${GNOME_VERSION}\") | .pk" |
    head -n 1)

  if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
    echo -e "${RED}✖ No compatible version found for GNOME $GNOME_VERSION and $SLUG${NC}"
    return 1
  fi

  # Download and install
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT
  ZIP_URL="${BASE_URL}/download-extension/${UUID}.shell-extension.zip?version_tag=${VERSION}"
  echo -e "${GREEN}→ Downloading: ${ZIP_URL}${NC}"
  curl -sL "$ZIP_URL" -o "$TMP_DIR/extension.zip"

  if gnome-extensions install --force "$TMP_DIR/extension.zip"; then
    echo -e "${GREEN}✔ Installed $SLUG successfully${NC}"
    gnome-extensions enable "$UUID" 2>/dev/null && \
      echo -e "${GREEN}✓ Enabled $SLUG${NC}" || \
      echo -e "${RED}⚠ Could not enable $SLUG — restart GNOME Shell or relogin may be required.${NC}"
  else
    echo -e "${RED}✖ Failed to install $SLUG${NC}"
  fi
}

# Loop through all extensions
for EXT in "${EXTENSIONS[@]}"; do
  install_extension "$EXT"
done

echo -e "${GREEN}==> All compatible GNOME extensions installed and attempted to enable.${NC}"
