#!/usr/bin/env bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "        CachyOS Setup Backup"
echo "=========================================="
echo

cd "$REPO_DIR"

# ------------------------------------------
# Update package lists
# ------------------------------------------

echo "Updating package lists..."

pacman -Qqen > "$REPO_DIR/packages/pacman-packages.txt"
pacman -Qqem > "$REPO_DIR/packages/aur-packages.txt"

if command -v flatpak >/dev/null 2>&1; then
    flatpak list --app --columns=application \
        > "$REPO_DIR/packages/flatpak-packages.txt"
fi


# ------------------------------------------
# Update configurations
# ------------------------------------------

echo "Updating configs..."

mkdir -p "$REPO_DIR/configs"

# Hyprland
if [ -d "$HOME/.config/hypr" ]; then
    rm -rf "$REPO_DIR/configs/hypr"
    cp -r "$HOME/.config/hypr" "$REPO_DIR/configs/"
fi

# Caelestia
if [ -d "$HOME/.config/caelestia" ]; then
    rm -rf "$REPO_DIR/configs/caelestia"
    cp -r "$HOME/.config/caelestia" "$REPO_DIR/configs/"
fi

# Kitty
if [ -d "$HOME/.config/kitty" ]; then
    rm -rf "$REPO_DIR/configs/kitty"
    cp -r "$HOME/.config/kitty" "$REPO_DIR/configs/"
fi


# ------------------------------------------
# Update cursor
# ------------------------------------------

echo "Updating cursor..."

mkdir -p "$REPO_DIR/assets"

if [ -d "$HOME/.local/share/icons/Bibata-Modern-Ice" ]; then
    rm -rf "$REPO_DIR/assets/Bibata-Modern-Ice"

    cp -r \
        "$HOME/.local/share/icons/Bibata-Modern-Ice" \
        "$REPO_DIR/assets/"
fi


# ------------------------------------------
# Git commit
# ------------------------------------------

echo
echo "Creating Git commit..."

git add .

if git diff --cached --quiet; then

    echo "No changes detected."
    echo "Nothing to commit."

else

    git commit -m "Update CachyOS setup"

    echo
    echo "✓ Changes committed successfully."

fi


# ------------------------------------------
# Finish
# ------------------------------------------

echo
echo "=========================================="
echo "        Backup completed!"
echo "=========================================="
echo
echo "GitHub push is NOT automatic."
echo
echo "To push the changes:"
echo
echo "    git push"
echo
