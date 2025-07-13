# 🐧 Fedora Mizu Dev Setup

A simple and opinionated shell script to quickly set up a Fedora-based development environment. Designed to automate the installation of essential tools, configure dotfiles using `stow`, and provide a clean, consistent developer experience across machines.

---

## 🎯 Purpose

This project was created to streamline the process of setting up my personal development environment on Fedora. It automates the installation of commonly used applications, tools, and configurations, ensuring a consistent and productive setup every time.

---

## ⚙️ Features

- 📦 Install essential packages and developer tools
- 🧰 Setup Flatpak with recommended remotes
- 🚫 Avoids `snap` (Snapcraft) usage entirely
- 🖥️ Configure GNOME with tweaks and extensions
- 🗂️ Apply dotfiles using GNU `stow`
- ✨ Minimal and modular – split into manageable scripts

---

## 📋 Tools Installed

The script installs the following (among others):

### 📚 Utilities & Essentials

- `xournal` – PDF annotation
- `localsend` – Local file sharing
- `gnome-tweaks` – Customize GNOME desktop
- `gnome-extensions-app` – Manage GNOME shell extensions

### 📦 Package Managers

- `dnf` – Fedora's native package manager
- `flatpak` – Universal app store (with Flathub remote)

### 🧩 Dotfiles

- Managed using [GNU stow](https://www.gnu.org/software/stow/) for clean and modular configuration

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/Jhonatanmizu/fedora-mizu-setup-dev.git
cd fedora-mizu-setup-dev
```

### 2. Run the setup script

```bash
chmod +x setup.sh
./setup.sh
```

### 3. Customize your dotfiles

The script automatically calls another shell script to manage your dotfiles using stow. You can modify the contents in the dotfiles/ directory to suit your needs.

## 🗃️ Repository Structure

```bash
fedora-mizu-setup-dev/
├── dotfiles/           # Your dotfiles organized by app (bash, nvim, git, etc.)
├── scripts/            # Helper scripts split by purpose (e.g., flatpak, tools)
├── setup.sh            # Main entrypoint shell script
├── stow-dotfiles.sh    # Handles dotfile setup via GNU stow
└── README.md           # This file
```

## 🧠 Requirements

- Fedora (tested on Fedora Workstation)
- sudo privileges
- Internet connection

## 📝 Notes

Flatpak is preferred over Snap for app installation
The script assumes GNOME is the default desktop environment
Some GNOME extensions may need manual approval via the Extensions app

## 🤝 Contributing

Feel free to fork the project or open an issue if you want to suggest improvements or report problems.

## 🐛 License

This project is licensed under the MIT License. See the LICENSE file for more details.
