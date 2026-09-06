#!/usr/bin/env bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "       CachyOS Setup Installer"
echo "=========================================="
echo

# ------------------------------------------
# 1. Update system
# ------------------------------------------

echo "[1/7] Updating system..."
sudo pacman -Syu --needed

# ------------------------------------------
# 2. Install official packages
# ------------------------------------------

echo
echo "[2/7] Installing official packages..."

if [ -f "$REPO_DIR/packages/pacman-packages.txt" ]; then
    sudo pacman -S --needed \
        - < "$REPO_DIR/packages/pacman-packages.txt"
else
    echo "WARNING: pacman package list not found."
fi

# ------------------------------------------
# 3. Install / detect AUR helper
# ------------------------------------------

echo
echo "[3/7] Checking AUR helper..."

AUR_HELPER=""

if command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
fi

if [ -n "$AUR_HELPER" ]; then
    echo "Found AUR helper: $AUR_HELPER"
else
    echo "WARNING: No yay or paru found."
    echo "AUR packages will be skipped."
fi

# ------------------------------------------
# 4. Install AUR packages
# ------------------------------------------

echo
echo "[4/7] Installing AUR packages..."

if [ -n "$AUR_HELPER" ] &&
   [ -f "$REPO_DIR/packages/aur-packages.txt" ]; then

    "$AUR_HELPER" -S --needed \
        - < "$REPO_DIR/packages/aur-packages.txt"

elif [ ! -f "$REPO_DIR/packages/aur-packages.txt" ]; then
    echo "WARNING: AUR package list not found."

else
    echo "Skipping AUR packages."
fi

# ------------------------------------------
# 5. Install Flatpak apps
# ------------------------------------------

echo
echo "[5/7] Installing Flatpak applications..."

if command -v flatpak >/dev/null 2>&1 &&
   [ -f "$REPO_DIR/packages/flatpak-packages.txt" ]; then

    while IFS= read -r app; do

        [ -z "$app" ] && continue

        echo "Installing Flatpak: $app"

        flatpak install -y flathub "$app" || {
            echo "WARNING: Could not install $app"
        }

    done < "$REPO_DIR/packages/flatpak-packages.txt"

else
    echo "Flatpak not available or package list missing."
fi

# ------------------------------------------
# 6. Restore configurations
# ------------------------------------------

echo
echo "[6/7] Restoring configurations..."

mkdir -p "$HOME/.config"

# Hyprland
if [ -d "$REPO_DIR/configs/hypr" ]; then
    rm -rf "$HOME/.config/hypr"
    cp -r "$REPO_DIR/configs/hypr" "$HOME/.config/"
    echo "Hyprland configuration restored."
fi

# Caelestia
if [ -d "$REPO_DIR/configs/caelestia" ]; then
    rm -rf "$HOME/.config/caelestia"
    cp -r "$REPO_DIR/configs/caelestia" "$HOME/.config/"
    echo "Caelestia configuration restored."
fi

# Kitty
if [ -d "$REPO_DIR/configs/kitty" ]; then
    rm -rf "$HOME/.config/kitty"
    cp -r "$REPO_DIR/configs/kitty" "$HOME/.config/"
    echo "Kitty configuration restored."
fi

# ------------------------------------------
# 7. Restore cursor
# ------------------------------------------

echo
echo "[7/7] Restoring cursor theme..."

mkdir -p "$HOME/.local/share/icons"

if [ -d "$REPO_DIR/assets/Bibata-Modern-Ice" ]; then

    rm -rf "$HOME/.local/share/icons/Bibata-Modern-Ice"

    cp -r \
        "$REPO_DIR/assets/Bibata-Modern-Ice" \
        "$HOME/.local/share/icons/"

    echo "Bibata-Modern-Ice cursor restored."

else
    echo "WARNING: Bibata-Modern-Ice cursor backup not found."
fi

# ------------------------------------------
# Finish
# ------------------------------------------

echo
echo "=========================================="
echo "       Installation completed!"
echo "=========================================="
echo
echo "Your packages and configurations have"
echo "been restored from this repository."
echo
echo "Please restart your session or reboot."
echo
