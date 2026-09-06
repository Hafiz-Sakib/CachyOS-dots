#!/usr/bin/env bash

set -e

# ==========================================================
# CachyOS Personal Setup Installer
# Hyprland + Caelestia + Packages + Configs
# ==========================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "=================================================="
echo "        CachyOS Personal Setup Installer"
echo "=================================================="
echo
echo "Repository: $REPO_DIR"
echo


# ==========================================================
# 1. Update system
# ==========================================================

echo "--------------------------------------------------"
echo "[1/8] Updating system"
echo "--------------------------------------------------"

sudo pacman -Syu --needed


# ==========================================================
# 2. Install basic Hyprland dependencies
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[2/8] Installing Hyprland dependencies"
echo "--------------------------------------------------"

sudo pacman -S --needed \
    hyprland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    hyprpicker \
    wl-clipboard \
    cliphist \
    inotify-tools \
    wireplumber \
    trash-cli \
    fish \
    fastfetch \
    starship \
    btop \
    jq \
    eza \
    kitty \
    git \
    curl \
    wget \
    base-devel


# ==========================================================
# 3. Install Caelestia dependencies
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[3/8] Installing Caelestia dependencies"
echo "--------------------------------------------------"

sudo pacman -S --needed \
    ddcutil \
    brightnessctl \
    libcava \
    networkmanager \
    lm_sensors \
    aubio \
    libpipewire \
    libqalculate \
    power-profiles-daemon \
    qt6-base \
    qt6-declarative \
    qt6-imageformats \
    swappy \
    bash


# ==========================================================
# 4. Install paru
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[4/8] Checking paru"
echo "--------------------------------------------------"

if command -v paru >/dev/null 2>&1; then

    echo "✓ paru is already installed."

else

    echo "paru was not found."
    echo "Installing paru from the AUR..."

    TEMP_DIR="$(mktemp -d)"

    git clone \
        https://aur.archlinux.org/paru.git \
        "$TEMP_DIR/paru"

    cd "$TEMP_DIR/paru"

    makepkg -si --noconfirm

    cd "$REPO_DIR"

    rm -rf "$TEMP_DIR"

    echo "✓ paru installed."

fi


# ==========================================================
# 5. Install Caelestia
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[5/8] Installing Caelestia"
echo "--------------------------------------------------"

paru -S --needed \
    caelestia-shell \
    caelestia-cli \
    quickshell-git

echo "✓ Caelestia installed."


# ==========================================================
# 6. Restore saved packages
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[6/8] Restoring saved packages"
echo "--------------------------------------------------"

# -------------------------
# Official packages
# -------------------------

if [ -f "$REPO_DIR/packages/pacman-packages.txt" ]; then

    echo
    echo "Installing official packages..."

    sudo pacman -S --needed \
        - < "$REPO_DIR/packages/pacman-packages.txt"

    echo "✓ Official packages restored."

else

    echo "WARNING:"
    echo "pacman-packages.txt was not found."

fi


# -------------------------
# AUR packages
# -------------------------

if [ -f "$REPO_DIR/packages/aur-packages.txt" ]; then

    echo
    echo "Installing AUR packages..."

    paru -S --needed \
        - < "$REPO_DIR/packages/aur-packages.txt"

    echo "✓ AUR packages restored."

else

    echo "WARNING:"
    echo "aur-packages.txt was not found."

fi


# -------------------------
# Flatpak applications
# -------------------------

if command -v flatpak >/dev/null 2>&1 &&
   [ -f "$REPO_DIR/packages/flatpak-packages.txt" ]; then

    echo
    echo "Installing Flatpak applications..."

    while IFS= read -r app; do

        # Ignore empty lines
        [ -z "$app" ] && continue

        echo "Installing Flatpak: $app"

        flatpak install -y flathub "$app" || {
            echo "WARNING: Could not install $app"
        }

    done < "$REPO_DIR/packages/flatpak-packages.txt"

    echo "✓ Flatpak applications processed."

else

    echo "Flatpak list not found or Flatpak is not installed."

fi


# ==========================================================
# 7. Restore configurations
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[7/8] Restoring configurations"
echo "--------------------------------------------------"

mkdir -p "$HOME/.config"


# -------------------------
# Hyprland
# -------------------------

if [ -d "$REPO_DIR/configs/hypr" ]; then

    rm -rf "$HOME/.config/hypr"

    cp -r \
        "$REPO_DIR/configs/hypr" \
        "$HOME/.config/"

    echo "✓ Hyprland configuration restored."

else

    echo "WARNING: Hyprland config not found."

fi


# -------------------------
# Caelestia
# -------------------------

if [ -d "$REPO_DIR/configs/caelestia" ]; then

    rm -rf "$HOME/.config/caelestia"

    cp -r \
        "$REPO_DIR/configs/caelestia" \
        "$HOME/.config/"

    echo "✓ Caelestia configuration restored."

else

    echo "WARNING: Caelestia config not found."

fi


# -------------------------
# Kitty
# -------------------------

if [ -d "$REPO_DIR/configs/kitty" ]; then

    rm -rf "$HOME/.config/kitty"

    cp -r \
        "$REPO_DIR/configs/kitty" \
        "$HOME/.config/"

    echo "✓ Kitty configuration restored."

fi


# ==========================================================
# 8. Restore cursor
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[8/8] Restoring cursor theme"
echo "--------------------------------------------------"

mkdir -p "$HOME/.local/share/icons"

if [ -d "$REPO_DIR/assets/Bibata-Modern-Ice" ]; then

    rm -rf \
        "$HOME/.local/share/icons/Bibata-Modern-Ice"

    cp -r \
        "$REPO_DIR/assets/Bibata-Modern-Ice" \
        "$HOME/.local/share/icons/"

    echo "✓ Bibata-Modern-Ice restored."

else

    echo "WARNING: Bibata-Modern-Ice backup not found."

fi


# ==========================================================
# Finish
# ==========================================================

echo
echo
echo "=================================================="
echo "          INSTALLATION COMPLETED"
echo "=================================================="
echo
echo "Your CachyOS setup has been restored."
echo
echo "Installed:"
echo "  ✓ Hyprland"
echo "  ✓ Caelestia"
echo "  ✓ paru"
echo "  ✓ Official packages"
echo "  ✓ AUR packages"
echo "  ✓ Flatpak applications"
echo "  ✓ Hyprland configuration"
echo "  ✓ Caelestia configuration"
echo "  ✓ Kitty configuration"
echo "  ✓ Bibata-Modern-Ice cursor"
echo
echo "=================================================="
echo
echo "Please log out and select Hyprland"
echo "from your display manager."
echo
echo "Then log back in."
echo
