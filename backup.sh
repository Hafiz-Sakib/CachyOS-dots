#!/usr/bin/env bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "=========================================="
echo "        CachyOS Setup Backup"
echo "=========================================="
echo

cd "$REPO_DIR"


# ==========================================================
# 1. Update package lists
# ==========================================================

echo "[1/5] Updating package lists..."

pacman -Qqen > "$REPO_DIR/packages/pacman-packages.txt"
pacman -Qqem > "$REPO_DIR/packages/aur-packages.txt"

if command -v flatpak >/dev/null 2>&1; then
    flatpak list --app --columns=application \
        > "$REPO_DIR/packages/flatpak-packages.txt"
fi

echo "✓ Package lists updated."


# ==========================================================
# 2. Backup configurations
# ==========================================================

echo
echo "[2/5] Updating configurations..."

mkdir -p "$REPO_DIR/configs"


# -------------------------
# Hyprland
# -------------------------

if [ -d "$HOME/.config/hypr" ]; then

    rm -rf "$REPO_DIR/configs/hypr"

    cp -r \
        "$HOME/.config/hypr" \
        "$REPO_DIR/configs/"

    echo "✓ Hyprland configuration backed up."

fi


# -------------------------
# Caelestia
# -------------------------

if [ -d "$HOME/.config/caelestia" ]; then

    rm -rf "$REPO_DIR/configs/caelestia"

    cp -r \
        "$HOME/.config/caelestia" \
        "$REPO_DIR/configs/"

    echo "✓ Caelestia configuration backed up."

fi


# -------------------------
# Kitty
# -------------------------

if [ -d "$HOME/.config/kitty" ]; then

    rm -rf "$REPO_DIR/configs/kitty"

    cp -r \
        "$HOME/.config/kitty" \
        "$REPO_DIR/configs/"

    echo "✓ Kitty configuration backed up."

fi


# ==========================================================
# 3. Backup cursor
# ==========================================================

echo
echo "[3/5] Updating cursor..."

mkdir -p "$REPO_DIR/assets"

if [ -d "$HOME/.local/share/icons/Bibata-Modern-Ice" ]; then

    rm -rf "$REPO_DIR/assets/Bibata-Modern-Ice"

    cp -r \
        "$HOME/.local/share/icons/Bibata-Modern-Ice" \
        "$REPO_DIR/assets/"

    echo "✓ Bibata-Modern-Ice cursor backed up."

else

    echo "⚠ Bibata-Modern-Ice cursor not found."
    echo "  Existing cursor backup was not changed."

fi


# ==========================================================
# 4. Git add + commit
# ==========================================================

echo
echo "[4/5] Creating Git commit..."

git add .

if git diff --cached --quiet; then

    echo "✓ No changes detected."
    echo "Nothing to commit or push."

    echo
    echo "=========================================="
    echo "        Backup already up to date"
    echo "=========================================="
    echo

    exit 0

fi

git commit -m "Update CachyOS setup"

echo "✓ Changes committed."


# ==========================================================
# 5. Git push
# ==========================================================

echo
echo "[5/5] Pushing to GitHub..."

git push

echo
echo "=========================================="
echo "        Backup completed successfully!"
echo "=========================================="
echo
echo "✓ System packages backed up"
echo "✓ AUR packages backed up"
echo "✓ Flatpak apps backed up"
echo "✓ Hyprland config backed up"
echo "✓ Caelestia config backed up"
echo "✓ Kitty config backed up"
echo "✓ Cursor backed up"
echo "✓ Git commit created"
echo "✓ Changes pushed to GitHub"
echo
