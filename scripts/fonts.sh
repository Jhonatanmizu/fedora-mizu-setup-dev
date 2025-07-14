#!/bin/bash

set -euo pipefail

GREEN="\033[1;32m"
CYAN="\033[1;36m"
NC="\033[0m"

echo -e "${CYAN}🔤 Installing Nerd Fonts using getnf...${NC}"

# 1. Install getnf if not present
if ! command -v getnf &> /dev/null; then
  echo -e "${CYAN}→ Downloading getnf CLI...${NC}"
  curl -fsSL https://raw.githubusercontent.com/ronniedroid/getnf/main/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
fi

# 2. Ensure getnf is in PATH
if ! command -v getnf &> /dev/null; then
  echo -e "${RED}✖ getnf is not in PATH. Please restart your terminal or add ~/.local/bin to your PATH.${NC}"
  exit 1
fi

# 3. Install Meslo and FiraCode fonts
echo -e "${CYAN}→ Installing Meslo and FiraCode Nerd Fonts...${NC}"
getnf Meslo FiraCode

# 4. Refresh font cache
echo -e "${CYAN}→ Refreshing font cache...${NC}"
fc-cache -fv > /dev/null

echo -e "${GREEN}✅ Nerd Fonts (Meslo & FiraCode) installed successfully!${NC}"
