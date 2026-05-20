#!/usr/bin/env bash

GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
