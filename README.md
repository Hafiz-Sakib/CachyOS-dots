# CachyOS Setup

Personal backup and restoration setup for my **CachyOS + Hyprland + Caelestia** environment.

This repository contains my installed package lists, desktop configurations, cursor theme, and setup scripts so I can reproduce my preferred Linux environment on another PC.

---

## 🖥️ Current Environment

- **OS:** CachyOS
- **Desktop Environment:** Hyprland
- **Shell:** Caelestia Shell
- **Terminal:** Kitty
- **Cursor:** Bibata-Modern-Ice
- **Browser:** Google Chrome
- **Shell:** Fish
- **Package Manager:** pacman
- **AUR Helper:** yay / paru
- **Flatpak:** Supported

---

## 📁 Repository Structure

```text
cachyos-setup/
│
├── assets/
│   └── Bibata-Modern-Ice/
│       ├── cursor.theme
│       └── index.theme
│
├── configs/
│   │
│   ├── caelestia/
│   │   ├── hyper-vars.lua
│   │   ├── hypr-user.lua
│   │   ├── hypr-vars.lua
│   │   ├── shell.json
│   │   └── user-config.fish
│   │
│   └── hypr/
│       ├── hyprland.conf
│       ├── hyprland-gui.lua
│       ├── hyprland.lua
│       └── variables.lua
│
├── packages/
│   ├── pacman-packages.txt
│   ├── aur-packages.txt
│   └── flatpak-packages.txt
│
├── backup.sh
├── install.sh
└── README.md
