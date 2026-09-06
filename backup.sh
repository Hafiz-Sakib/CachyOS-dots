#!/usr/bin/env bash

set -e

BACKUP_DIR="$HOME/cachyos-setup"

echo "Updating package lists..."

pacman -Qqen > "$BACKUP_DIR/packages/pacman-packages.txt"
pacman -Qqem > "$BACKUP_DIR/packages/aur-packages.txt"

if command -v flatpak >/dev/null 2>&1; then
    flatpak list --app --columns=application > "$BACKUP_DIR/packages/flatpak-packages.txt"
fi

echo "Updating configs..."

rm -rf "$BACKUP_DIR/configs/hypr"
rm -rf "$BACKUP_DIR/configs/caelestia"

cp -r "$HOME/.config/hypr" "$BACKUP_DIR/configs/"
cp -r "$HOME/.config/caelestia" "$BACKUP_DIR/configs/"

if [ -d "$HOME/.config/kitty" ]; then
    rm -rf "$BACKUP_DIR/configs/kitty"
    cp -r "$HOME/.config/kitty" "$BACKUP_DIR/configs/"
fi

echo "Updating cursor..."

rm -rf "$BACKUP_DIR/assets/Bibata-Modern-Ice"

if [ -d "$HOME/.local/share/icons/Bibata-Modern-Ice" ]; then
    cp -r "$HOME/.local/share/icons/Bibata-Modern-Ice" "$BACKUP_DIR/assets/"
fi

echo "Backup completed successfully!"
