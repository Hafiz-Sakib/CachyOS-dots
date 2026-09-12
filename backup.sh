#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$REPO_DIR/backup.log"
DRY_RUN=false
NO_PUSH=false

# ==========================================================
# Colors
# ==========================================================
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
RESET="\e[0m"

info()  { echo -e "${CYAN}$1${RESET}"; }
ok()    { echo -e "${GREEN}✓ $1${RESET}"; }
warn()  { echo -e "${YELLOW}⚠ $1${RESET}"; }
fail()  { echo -e "${RED}✗ $1${RESET}"; }

# ==========================================================
# Parse args
# ==========================================================
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --no-push) NO_PUSH=true ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--no-push]"
            exit 0
            ;;
    esac
done

# ==========================================================
# Trap errors
# ==========================================================
trap 'fail "Backup failed at line $LINENO. Check $LOG_FILE for details."' ERR

exec > >(tee -a "$LOG_FILE") 2>&1

cd "$REPO_DIR"

echo
echo "=========================================="
echo "        CachyOS Setup Backup"
echo "        $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo

# ==========================================================
# Pre-flight checks
# ==========================================================
command -v git >/dev/null 2>&1 || { fail "git not found. Aborting."; exit 1; }
command -v pacman >/dev/null 2>&1 || { fail "pacman not found. Aborting."; exit 1; }

if [ ! -d "$REPO_DIR/.git" ]; then
    fail "$REPO_DIR is not a git repository. Aborting."
    exit 1
fi

mkdir -p "$REPO_DIR/packages" "$REPO_DIR/configs" "$REPO_DIR/assets"

# ==========================================================
# 1. Update package lists
# ==========================================================

info "[1/5] Updating package lists..."

pacman -Qqen > "$REPO_DIR/packages/pacman-packages.txt" || warn "Failed to list native packages."
pacman -Qqem > "$REPO_DIR/packages/aur-packages.txt" || warn "Failed to list AUR packages."

if command -v flatpak >/dev/null 2>&1; then
    flatpak list --app --columns=application \
        > "$REPO_DIR/packages/flatpak-packages.txt" || warn "Failed to list flatpak apps."
    ok "Flatpak apps backed up."
else
    warn "flatpak not installed, skipping."
fi

ok "Package lists updated."

# ==========================================================
# 2. Backup configurations
# ==========================================================

echo
info "[2/5] Updating configurations..."

# Add/remove config folder names here — single source of truth.
CONFIGS=(
    "hypr"
    "caelestia"
    "kitty"
    "waybar"
    "rofi"
    "fastfetch"
)

for name in "${CONFIGS[@]}"; do
    src="$HOME/.config/$name"
    dest="$REPO_DIR/configs/$name"

    if [ -d "$src" ]; then
        if $DRY_RUN; then
            info "[dry-run] would sync $src -> $dest"
        else
            mkdir -p "$dest"
            rsync -a --delete \
                --exclude 'cache' --exclude '*.log' \
                "$src/" "$dest/"
            ok "$name configuration backed up."
        fi
    else
        warn "$name config not found, skipping."
    fi
done

# ==========================================================
# 3. Backup cursor
# ==========================================================

echo
info "[3/5] Updating cursor..."

CURSOR_NAME="Bibata-Modern-Ice"
CURSOR_SRC="$HOME/.local/share/icons/$CURSOR_NAME"
CURSOR_DEST="$REPO_DIR/assets/$CURSOR_NAME"

if [ -d "$CURSOR_SRC" ]; then
    if $DRY_RUN; then
        info "[dry-run] would sync $CURSOR_SRC -> $CURSOR_DEST"
    else
        mkdir -p "$CURSOR_DEST"
        rsync -a --delete "$CURSOR_SRC/" "$CURSOR_DEST/"
        ok "$CURSOR_NAME cursor backed up."
    fi
else
    warn "$CURSOR_NAME cursor not found. Existing backup was not changed."
fi

# ==========================================================
# 3b. Backup fonts
# ==========================================================

echo
info "Updating fonts..."

# Add custom font folder names here (folders inside ~/.local/share/fonts).
FONTS=(
    "JetBrainsMono"
)

FONT_SRC_ROOT="$HOME/.local/share/fonts"

if [ -d "$FONT_SRC_ROOT" ]; then
    for font in "${FONTS[@]}"; do
        src="$FONT_SRC_ROOT/$font"
        dest="$REPO_DIR/assets/fonts/$font"

        if [ -d "$src" ]; then
            if $DRY_RUN; then
                info "[dry-run] would sync $src -> $dest"
            else
                mkdir -p "$dest"
                rsync -a --delete "$src/" "$dest/"
                ok "$font font backed up."
            fi
        else
            warn "$font font not found, skipping."
        fi
    done
else
    warn "$FONT_SRC_ROOT not found, skipping fonts."
fi

if $DRY_RUN; then
    echo
    info "Dry run complete. No files were changed, nothing committed or pushed."
    exit 0
fi

# ==========================================================
# 4. Git add + commit
# ==========================================================

echo
info "[4/5] Creating Git commit..."

git add -A

if git diff --cached --quiet; then
    ok "No changes detected. Nothing to commit or push."
    echo
    echo "=========================================="
    echo "        Backup already up to date"
    echo "=========================================="
    echo
    exit 0
fi

COMMIT_MSG="Update CachyOS setup - $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG"

ok "Changes committed: \"$COMMIT_MSG\""

# ==========================================================
# 5. Git push
# ==========================================================

if $NO_PUSH; then
    warn "Skipping push (--no-push given). Commit is local only."
    exit 0
fi

echo
info "[5/5] Pushing to GitHub..."

if ! git push; then
    fail "Push failed. Check your network/remote/credentials and run 'git push' manually."
    exit 1
fi

ok "Changes pushed to GitHub."

echo
echo "=========================================="
echo "        Backup completed successfully!"
echo "=========================================="
echo
echo "✓ System packages backed up"
echo "✓ AUR packages backed up"
echo "✓ Flatpak apps backed up (if installed)"
echo "✓ Configs backed up: ${CONFIGS[*]}"
echo "✓ Cursor backed up"
echo "✓ Fonts backed up: ${FONTS[*]}"
echo "✓ Git commit created"
echo "✓ Changes pushed to GitHub"
echo