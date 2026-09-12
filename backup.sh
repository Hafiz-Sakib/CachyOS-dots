```text
#!/usr/bin/env bash

set -euo pipefail

# ==========================================================
# CachyOS Setup Backup
# ==========================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "=========================================="
echo "        CachyOS Setup Backup"
echo "=========================================="
echo

cd "$REPO_DIR"

# ==========================================================
# Helper function
# ==========================================================

backup_dir() {
    local source="$1"
    local destination="$2"
    local name="$3"

    if [ -d "$source" ]; then
        rm -rf "$destination"
        mkdir -p "$(dirname "$destination")"
        cp -a "$source" "$destination"

        echo "✓ $name backed up."
    else
        echo "⚠ $name not found — skipped."
    fi
}

# ==========================================================
# Create required directories
# ==========================================================

mkdir -p \
    "$REPO_DIR/packages" \
    "$REPO_DIR/configs" \
    "$REPO_DIR/assets"

# ==========================================================
# 1. Backup package lists
# ==========================================================

echo "[1/5] Updating package lists..."

pacman -Qqen > "$REPO_DIR/packages/pacman-packages.txt"
pacman -Qqem > "$REPO_DIR/packages/aur-packages.txt"

if command -v flatpak >/dev/null 2>&1; then
    flatpak list --app --columns=application \
        > "$REPO_DIR/packages/flatpak-packages.txt"

    echo "✓ Flatpak package list updated."
else
    echo "⚠ Flatpak not installed — skipped."
fi

echo "✓ Package lists updated."

# ==========================================================
# 2. Backup configurations
# ==========================================================

echo
echo "[2/5] Updating configurations..."

backup_dir \
    "$HOME/.config/hypr" \
    "$REPO_DIR/configs/hypr" \
    "Hyprland configuration"

backup_dir \
    "$HOME/.config/caelestia" \
    "$REPO_DIR/configs/caelestia" \
    "Caelestia configuration"

backup_dir \
    "$HOME/.config/kitty" \
    "$REPO_DIR/configs/kitty" \
    "Kitty configuration"

backup_dir \
    "$HOME/.config/foot" \
    "$REPO_DIR/configs/foot" \
    "Foot configuration"

backup_dir \
    "$HOME/.config/waybar" \
    "$REPO_DIR/configs/waybar" \
    "Waybar configuration"

backup_dir \
    "$HOME/.config/wofi" \
    "$REPO_DIR/configs/wofi" \
    "Wofi configuration"

backup_dir \
    "$HOME/.config/fastfetch" \
    "$REPO_DIR/configs/fastfetch" \
    "Fastfetch configuration"

backup_dir \
    "$HOME/.config/gtk-3.0" \
    "$REPO_DIR/configs/gtk-3.0" \
    "GTK 3 configuration"

backup_dir \
    "$HOME/.config/gtk-4.0" \
    "$REPO_DIR/configs/gtk-4.0" \
    "GTK 4 configuration"

# ==========================================================
# Individual configuration files
# ==========================================================

if [ -f "$HOME/.config/starship.toml" ]; then
    cp -a \
        "$HOME/.config/starship.toml" \
        "$REPO_DIR/configs/starship.toml"

    echo "✓ Starship configuration backed up."
else
    echo "⚠ Starship configuration not found — skipped."
fi

# ==========================================================
# 3. Backup cursor
# ==========================================================

echo
echo "[3/5] Updating cursor..."

backup_dir \
    "$HOME/.local/share/icons/Bibata-Modern-Ice" \
    "$REPO_DIR/assets/Bibata-Modern-Ice" \
    "Bibata-Modern-Ice cursor"

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

if git push; then
    echo "✓ Changes pushed to GitHub."
else
    echo
    echo "✗ Git push failed."
    echo "  Your backup is committed locally."
    echo "  Run 'git push' manually when ready."
    exit 1
fi

# ==========================================================
# Done
# ==========================================================

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
echo "✓ Foot config backed up"
echo "✓ Waybar config backed up"
echo "✓ Wofi config backed up"
echo "✓ Fastfetch config backed up"
echo "✓ GTK configs backed up"
echo "✓ Starship config backed up"
echo "✓ Cursor backed up"
echo "✓ Git commit created"
echo "✓ GitHub synchronized"

echo
```
