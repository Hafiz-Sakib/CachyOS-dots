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

# Only append to backup.log for real runs. In --dry-run nothing on disk
# should change, including the log file itself.
if $DRY_RUN; then
    info "[dry-run] no output will be written to $LOG_FILE"
else
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

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
command -v rsync >/dev/null 2>&1 || {
    fail "rsync not found. Install it with: sudo pacman -S rsync"
    exit 1
}

if [ ! -d "$REPO_DIR/.git" ]; then
    fail "$REPO_DIR is not a git repository. Aborting."
    exit 1
fi

# Single source of truth: CONFIGS, DOTFILES, FONTS, CURSOR_NAME all live
# in dotfiles.conf and are shared with install.sh, so a new config folder
# only ever needs to be added in one place.
if [ ! -f "$REPO_DIR/dotfiles.conf" ]; then
    fail "dotfiles.conf not found in $REPO_DIR. Aborting."
    exit 1
fi
# shellcheck source=dotfiles.conf
source "$REPO_DIR/dotfiles.conf"

if $DRY_RUN; then
    info "[dry-run] would ensure packages/, configs/, assets/, dotfiles/ directories exist"
    info "[dry-run] would ensure 'backup.log' is present in .gitignore"
else
    mkdir -p "$REPO_DIR/packages" "$REPO_DIR/configs" "$REPO_DIR/assets" "$REPO_DIR/dotfiles"

    # Make sure backup.log never gets committed to the repo.
    if [ ! -f "$REPO_DIR/.gitignore" ] || ! grep -qxF "backup.log" "$REPO_DIR/.gitignore"; then
        echo "backup.log" >> "$REPO_DIR/.gitignore"
    fi
fi

# If backup.log was already committed in a previous run (before it was
# gitignored), untrack it so .gitignore actually takes effect.
if git ls-files --error-unmatch backup.log >/dev/null 2>&1; then
    if $DRY_RUN; then
        info "[dry-run] would untrack backup.log (already committed previously)"
    else
        git rm --cached --quiet backup.log
        warn "backup.log was previously tracked — untracked it now."
    fi
fi

# ==========================================================
# 1. Update package lists
# ==========================================================

info "[1/7] Updating package lists..."

if $DRY_RUN; then
    info "[dry-run] would write packages/pacman-packages.txt, aur-packages.txt, flatpak-packages.txt"
else
    # No "|| warn" here on purpose: a failed package list is worse than a
    # failed backup run. Let set -e / the ERR trap stop the script instead
    # of silently committing a stale or empty list.
    pacman -Qqen > "$REPO_DIR/packages/pacman-packages.txt"
    pacman -Qqem > "$REPO_DIR/packages/aur-packages.txt"

    if command -v flatpak >/dev/null 2>&1; then
        flatpak list --app --columns=application \
            > "$REPO_DIR/packages/flatpak-packages.txt"
        ok "Flatpak apps backed up."
    else
        warn "flatpak not installed, skipping."
    fi

    ok "Package lists updated."
fi

# ==========================================================
# 2. Backup configurations (~/.config/*)
# ==========================================================

echo
info "[2/7] Updating configurations..."

for name in "${CONFIGS[@]}"; do
    src="$HOME/.config/$name"
    dest="$REPO_DIR/configs/$name"

    if [ -d "$src" ]; then
        if $DRY_RUN; then
            info "[dry-run] $name changes:"
            rsync -an --delete --itemize-changes \
                --exclude 'cache' --exclude '*.log' \
                "$src/" "$dest/" | sed 's/^/    /'
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
# 3. Backup top-level dotfiles (~/.gitconfig etc.)
# ==========================================================

echo
info "[3/7] Updating dotfiles..."

for name in "${DOTFILES[@]}"; do
    src="$HOME/$name"
    dest="$REPO_DIR/dotfiles/$name"

    if [ -f "$src" ]; then
        if $DRY_RUN; then
            if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
                info "[dry-run] $name unchanged"
            else
                info "[dry-run] would copy $name -> dotfiles/$name"
            fi
        else
            mkdir -p "$(dirname "$dest")"
            cp -f "$src" "$dest"
            ok "$name backed up."
        fi
    else
        warn "$name not found at \$HOME, skipping."
    fi
done

# ==========================================================
# 4. Backup cursor
# ==========================================================

echo
info "[4/7] Updating cursor..."

CURSOR_SRC="$HOME/.local/share/icons/$CURSOR_NAME"
CURSOR_DEST="$REPO_DIR/assets/$CURSOR_NAME"

if [ -d "$CURSOR_SRC" ]; then
    if $DRY_RUN; then
        info "[dry-run] $CURSOR_NAME changes:"
        rsync -an --delete --itemize-changes "$CURSOR_SRC/" "$CURSOR_DEST/" | sed 's/^/    /'
    else
        mkdir -p "$CURSOR_DEST"
        rsync -a --delete "$CURSOR_SRC/" "$CURSOR_DEST/"
        ok "$CURSOR_NAME cursor backed up."
    fi
else
    warn "$CURSOR_NAME cursor not found. Existing backup was not changed."
fi

# ==========================================================
# 5. Backup fonts
# ==========================================================

echo
info "[5/7] Updating fonts..."

FONT_SRC_ROOT="$HOME/.local/share/fonts"

if [ -d "$FONT_SRC_ROOT" ]; then
    for font in "${FONTS[@]}"; do
        src="$FONT_SRC_ROOT/$font"
        dest="$REPO_DIR/assets/fonts/$font"

        if [ -d "$src" ]; then
            if $DRY_RUN; then
                info "[dry-run] $font changes:"
                rsync -an --delete --itemize-changes "$src/" "$dest/" | sed 's/^/    /'
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
# 6. Git add + commit
# ==========================================================

echo
info "[6/7] Creating Git commit..."

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
# 7. Git push
# ==========================================================

if $NO_PUSH; then
    warn "Skipping push (--no-push given). Commit is local only."
    exit 0
fi

echo
info "[7/7] Pushing to GitHub..."

# Capture push output so we can react if GitHub reports the repo moved
# (e.g. renamed / transferred), instead of just failing next time.
set +e
PUSH_OUTPUT="$(git push 2>&1)"
PUSH_STATUS=$?
set -e

echo "$PUSH_OUTPUT"

if [ $PUSH_STATUS -ne 0 ]; then
    fail "Push failed. Check your network/remote/credentials and run 'git push' manually."
    exit 1
fi

# Detect GitHub's "This repository moved" redirect notice and update the
# remote automatically so future pushes don't warn/fail.
NEW_URL="$(echo "$PUSH_OUTPUT" | grep -oE 'https://github\.com/[^[:space:]]+\.git' | tail -n 1 || true)"
if [ -n "$NEW_URL" ] && echo "$PUSH_OUTPUT" | grep -qi "repository moved"; then
    CURRENT_URL="$(git remote get-url origin)"
    if [ "$CURRENT_URL" != "$NEW_URL" ]; then
        git remote set-url origin "$NEW_URL"
        ok "Remote 'origin' updated to new location: $NEW_URL"
    fi
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
echo "✓ Dotfiles backed up: ${DOTFILES[*]}"
echo "✓ Cursor backed up"
echo "✓ Fonts backed up: ${FONTS[*]}"
echo "✓ Git commit created"
echo "✓ Changes pushed to GitHub"
echo
