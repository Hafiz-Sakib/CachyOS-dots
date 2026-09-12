#!/usr/bin/env bash

set -euo pipefail

# ==========================================================
# CachyOS Personal Setup Installer
# Hyprland + Caelestia + Packages + Configs
# ==========================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$REPO_DIR/install.log"
DRY_RUN=false

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
        -h|--help)
            echo "Usage: $0 [--dry-run]"
            echo "  --dry-run   Show what would be installed/restored without changing anything."
            exit 0
            ;;
    esac
done

# ==========================================================
# Trap errors
# ==========================================================
trap 'fail "Install failed at line $LINENO. Check $LOG_FILE for details."' ERR

# Only log to disk on a real run — dry-run must not touch the filesystem.
if $DRY_RUN; then
    info "[dry-run] no output will be written to $LOG_FILE"
else
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

echo
echo "=================================================="
echo "        CachyOS Personal Setup Installer"
echo "        $(date '+%Y-%m-%d %H:%M:%S')"
$DRY_RUN && echo "        (DRY RUN — nothing will be installed)"
echo "=================================================="
echo
echo "Repository: $REPO_DIR"
echo

# ==========================================================
# Pre-flight checks
# ==========================================================
if [ "$(id -u)" -eq 0 ]; then
    fail "Don't run this script as root — it calls sudo itself where needed. Aborting."
    exit 1
fi

command -v pacman >/dev/null 2>&1 || { fail "pacman not found. This installer is for Arch-based systems. Aborting."; exit 1; }
command -v git >/dev/null 2>&1 || { fail "git not found. Aborting."; exit 1; }
command -v sudo >/dev/null 2>&1 || { fail "sudo not found. Aborting."; exit 1; }

# Single source of truth: CONFIGS, DOTFILES, FONTS, CURSOR_NAME all live
# in dotfiles.conf and are shared with backup.sh, so a new config folder
# only ever needs to be added in one place.
if [ ! -f "$REPO_DIR/dotfiles.conf" ]; then
    fail "dotfiles.conf not found in $REPO_DIR. Aborting."
    exit 1
fi
# shellcheck source=dotfiles.conf
source "$REPO_DIR/dotfiles.conf"

run() {
    # Wrapper so every mutating command respects --dry-run consistently.
    if $DRY_RUN; then
        info "[dry-run] would run: $*"
    else
        "$@"
    fi
}

# ==========================================================
# 1. Update system
# ==========================================================

echo "--------------------------------------------------"
echo "[1/10] Updating system"
echo "--------------------------------------------------"

run sudo pacman -Syu --needed


# ==========================================================
# 2. Install basic Hyprland dependencies
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[2/10] Installing Hyprland dependencies"
echo "--------------------------------------------------"

run sudo pacman -S --needed \
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
    rsync \
    base-devel


# ==========================================================
# 3. Install Caelestia dependencies
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[3/10] Installing Caelestia dependencies"
echo "--------------------------------------------------"

run sudo pacman -S --needed \
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
echo "[4/10] Checking paru"
echo "--------------------------------------------------"

if command -v paru >/dev/null 2>&1; then

    ok "paru is already installed."

elif $DRY_RUN; then

    info "[dry-run] would clone and build paru from the AUR"

else

    info "paru was not found. Installing paru from the AUR..."

    # Defensive checks up front — fail with a clear, actionable message
    # instead of a bare "line N failed" from the generic ERR trap.
    command -v makepkg >/dev/null 2>&1 || {
        fail "makepkg not found — base-devel did not install correctly. Try: sudo pacman -S --needed base-devel"
        exit 1
    }

    if ! git ls-remote https://aur.archlinux.org/paru.git >/dev/null 2>&1; then
        fail "Cannot reach aur.archlinux.org. Check your network connection and try again."
        exit 1
    fi

    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' EXIT

    if ! git clone --quiet https://aur.archlinux.org/paru.git "$TEMP_DIR/paru"; then
        fail "Failed to clone paru from the AUR."
        exit 1
    fi

    if ! (cd "$TEMP_DIR/paru" && makepkg -si --noconfirm); then
        fail "Building paru with makepkg failed. Common causes: missing base-devel packages, or sudo permissions. See the makepkg output above for details."
        exit 1
    fi

    rm -rf "$TEMP_DIR"
    trap - EXIT

    command -v paru >/dev/null 2>&1 || {
        fail "makepkg reported success but 'paru' is still not on PATH. Try opening a new shell and re-running this script."
        exit 1
    }

    ok "paru installed."

fi


# ==========================================================
# 5. Install Caelestia
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[5/10] Installing Caelestia"
echo "--------------------------------------------------"

if $DRY_RUN; then
    info "[dry-run] would run: paru -S --needed caelestia-shell caelestia-cli quickshell-git"
else
    paru -S --needed \
        caelestia-shell \
        caelestia-cli \
        quickshell-git
    ok "Caelestia installed."
fi


# ==========================================================
# 6. Restore saved packages
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[6/10] Restoring saved packages"
echo "--------------------------------------------------"

# Reads a package-list file into an array, skipping blank lines and
# comments (# ...). Used instead of piping the file straight into
# pacman/paru, since neither reads a target list from stdin via "-".
read_package_list() {
    local file="$1"
    local -a pkgs=()
    local line
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        line="$(echo "$line" | xargs)" # trim whitespace
        [ -n "$line" ] && pkgs+=("$line")
    done < "$file"
    printf '%s\n' "${pkgs[@]}"
}

# -------------------------
# Official packages
# -------------------------

if [ -f "$REPO_DIR/packages/pacman-packages.txt" ]; then

    echo
    info "Installing official packages..."

    mapfile -t PACMAN_PKGS < <(read_package_list "$REPO_DIR/packages/pacman-packages.txt")

    if [ "${#PACMAN_PKGS[@]}" -eq 0 ]; then
        warn "pacman-packages.txt is empty, skipping."
    else
        run sudo pacman -S --needed "${PACMAN_PKGS[@]}"
        ok "Official packages restored (${#PACMAN_PKGS[@]} packages)."
    fi

else
    warn "pacman-packages.txt was not found."
fi

# -------------------------
# AUR packages
# -------------------------

if [ -f "$REPO_DIR/packages/aur-packages.txt" ]; then

    echo
    info "Installing AUR packages..."

    mapfile -t AUR_PKGS < <(read_package_list "$REPO_DIR/packages/aur-packages.txt")

    if [ "${#AUR_PKGS[@]}" -eq 0 ]; then
        warn "aur-packages.txt is empty, skipping."
    elif $DRY_RUN; then
        info "[dry-run] would run: paru -S --needed ${AUR_PKGS[*]}"
    else
        paru -S --needed "${AUR_PKGS[@]}"
        ok "AUR packages restored (${#AUR_PKGS[@]} packages)."
    fi

else
    warn "aur-packages.txt was not found."
fi

# -------------------------
# Flatpak applications
# -------------------------

if command -v flatpak >/dev/null 2>&1 &&
   [ -f "$REPO_DIR/packages/flatpak-packages.txt" ]; then

    echo
    info "Installing Flatpak applications..."

    while IFS= read -r app; do
        [ -z "$app" ] && continue

        if $DRY_RUN; then
            info "[dry-run] would run: flatpak install -y flathub $app"
        else
            info "Installing Flatpak: $app"
            flatpak install -y flathub "$app" || warn "Could not install $app"
        fi
    done < "$REPO_DIR/packages/flatpak-packages.txt"

    ok "Flatpak applications processed."

else
    warn "Flatpak list not found or Flatpak is not installed."
fi


# ==========================================================
# 7. Restore configurations (~/.config/*)
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[7/10] Restoring configurations"
echo "--------------------------------------------------"

$DRY_RUN || mkdir -p "$HOME/.config"

HAVE_RSYNC=false
command -v rsync >/dev/null 2>&1 && HAVE_RSYNC=true

for name in "${CONFIGS[@]}"; do
    src="$REPO_DIR/configs/$name"
    dest="$HOME/.config/$name"

    if [ ! -d "$src" ]; then
        warn "$name config not found in backup, skipping."
        continue
    fi

    if $DRY_RUN; then
        if $HAVE_RSYNC; then
            info "[dry-run] $name changes:"
            rsync -an --delete --itemize-changes "$src/" "$dest/" | sed 's/^/    /'
        else
            info "[dry-run] would restore $name config to $dest (rsync unavailable for preview)"
        fi
    elif $HAVE_RSYNC; then
        mkdir -p "$dest"
        rsync -a --delete "$src/" "$dest/"
        ok "$name configuration restored."
    else
        # Fallback if rsync somehow isn't installed yet.
        rm -rf "$dest"
        cp -r "$src" "$HOME/.config/"
        ok "$name configuration restored (cp fallback)."
    fi
done


# ==========================================================
# 8. Restore top-level dotfiles (~/.gitconfig etc.)
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[8/10] Restoring dotfiles"
echo "--------------------------------------------------"

for name in "${DOTFILES[@]}"; do
    src="$REPO_DIR/dotfiles/$name"
    dest="$HOME/$name"

    if [ ! -f "$src" ]; then
        warn "$name not found in backup, skipping."
        continue
    fi

    if $DRY_RUN; then
        if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
            info "[dry-run] $name unchanged"
        else
            info "[dry-run] would restore $name -> \$HOME/$name"
        fi
    else
        mkdir -p "$(dirname "$dest")"
        cp -f "$src" "$dest"
        ok "$name restored."
    fi
done


# ==========================================================
# 9. Restore fonts
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[9/10] Restoring fonts"
echo "--------------------------------------------------"

FONT_SRC_ROOT="$REPO_DIR/assets/fonts"
FONT_DEST_ROOT="$HOME/.local/share/fonts"

if [ -d "$FONT_SRC_ROOT" ]; then

    $DRY_RUN || mkdir -p "$FONT_DEST_ROOT"
    FONTS_RESTORED=false

    for font_dir in "$FONT_SRC_ROOT"/*/; do
        [ -d "$font_dir" ] || continue
        font="$(basename "$font_dir")"
        dest="$FONT_DEST_ROOT/$font"

        if $DRY_RUN; then
            if $HAVE_RSYNC; then
                info "[dry-run] $font changes:"
                rsync -an --delete --itemize-changes "$font_dir" "$dest/" | sed 's/^/    /'
            else
                info "[dry-run] would restore font $font to $dest (rsync unavailable for preview)"
            fi
        elif $HAVE_RSYNC; then
            mkdir -p "$dest"
            rsync -a --delete "$font_dir" "$dest/"
            ok "$font font restored."
        else
            rm -rf "$dest"
            cp -r "$font_dir" "$dest"
            ok "$font font restored (cp fallback)."
        fi
        FONTS_RESTORED=true
    done

    if $FONTS_RESTORED && ! $DRY_RUN; then
        command -v fc-cache >/dev/null 2>&1 && run fc-cache -f "$FONT_DEST_ROOT"
    fi

else
    warn "No fonts found in backup (assets/fonts), skipping."
fi


# ==========================================================
# 10. Restore cursor
# ==========================================================

echo
echo "--------------------------------------------------"
echo "[10/10] Restoring cursor theme"
echo "--------------------------------------------------"

CURSOR_SRC="$REPO_DIR/assets/$CURSOR_NAME"
CURSOR_DEST="$HOME/.local/share/icons/$CURSOR_NAME"

$DRY_RUN || mkdir -p "$HOME/.local/share/icons"

if [ -d "$CURSOR_SRC" ]; then

    if $DRY_RUN; then
        if $HAVE_RSYNC; then
            info "[dry-run] $CURSOR_NAME changes:"
            rsync -an --delete --itemize-changes "$CURSOR_SRC/" "$CURSOR_DEST/" | sed 's/^/    /'
        else
            info "[dry-run] would restore $CURSOR_NAME to $CURSOR_DEST (rsync unavailable for preview)"
        fi
    elif $HAVE_RSYNC; then
        mkdir -p "$CURSOR_DEST"
        rsync -a --delete "$CURSOR_SRC/" "$CURSOR_DEST/"
        ok "$CURSOR_NAME restored."
    else
        rm -rf "$CURSOR_DEST"
        cp -r "$CURSOR_SRC" "$HOME/.local/share/icons/"
        ok "$CURSOR_NAME restored (cp fallback)."
    fi

else
    warn "$CURSOR_NAME backup not found."
fi


# ==========================================================
# Finish
# ==========================================================

if $DRY_RUN; then
    echo
    info "Dry run complete. Nothing was installed or changed."
    exit 0
fi

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
echo "  ✓ Configs: ${CONFIGS[*]}"
echo "  ✓ Dotfiles: ${DOTFILES[*]}"
echo "  ✓ Fonts"
echo "  ✓ $CURSOR_NAME cursor"
echo
echo "=================================================="
echo
echo "Please log out and select Hyprland"
echo "from your display manager."
echo
echo "Then log back in."
echo
