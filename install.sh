#!/bin/bash

set -euo pipefail

# Color-coded logging
info()    { echo -e "\e[34m[INFO]\e[0m $*"; }
success() { echo -e "\e[32m[OK]\e[0m $*"; }
warn()    { echo -e "\e[33m[WARN]\e[0m $*"; }
error()   { echo -e "\e[31m[ERROR]\e[0m $*"; exit 1; }

# Check if script is run as root
if [[ $EUID -eq 0 ]]; then
   error "This script must not be run as root. Please run as a regular user."
fi

# Detect distribution and set package manager
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [[ -f /etc/debian_version ]]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [[ -f /etc/arch-release ]]; then
        OS="Arch Linux"
        VER=""
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

detect_distro

# Set package manager based on OS
case "$OS" in
    *"Arch Linux"*|*"Manjaro"*|*"CachyOS"*)
        PKG_MANAGER="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        PKG_UPDATE="sudo pacman -Sy"
        if command -v paru &>/dev/null; then
            AUR_HELPER="paru"
        elif command -v yay &>/dev/null; then
            AUR_HELPER="yay"
        else
            AUR_HELPER=""
        fi
        ;;
    *"Fedora"*)
        PKG_MANAGER="dnf"
        PKG_INSTALL="sudo dnf install -y"
        PKG_UPDATE="sudo dnf check-update"
        ;;
    *"Ubuntu"*|*"Debian"*|*"Linux Mint"*)
        PKG_MANAGER="apt"
        PKG_INSTALL="sudo apt install -y"
        PKG_UPDATE="sudo apt update"
        ;;
    *)
        warn "Unsupported distribution: $OS"
        warn "Proceeding with pacman (may not work correctly)"
        PKG_MANAGER="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        PKG_UPDATE="sudo pacman -Sy"
        ;;
esac

info "Detected distribution: $OS $VER"
info "Using package manager: $PKG_MANAGER"

# Official repo packages
OFFICIAL_PACKAGES=(
    "hyprland"
    "rofi"
    "kitty"
    "wallust"
    "matugen"
    "swaybg"
    "cava"
    "wlogout"
    "cliphist"
    "grim"
    "slurp"
    "swappy"
    "hyprpicker"
    "hyprsunset"
    "wf-recorder"
    "playerctl"
    "jq"
    "wl-clipboard"
    "brightnessctl"
    "wget"       # needed for font download
    "unzip"      # needed for font extraction
    "fontconfig" # for fc-cache
)

# AUR packages (only on Arch-based with AUR helper)
AUR_PACKAGES=(
    "quickshell"
)

# Check available packages
info "Checking package availability..."
for pkg in "${OFFICIAL_PACKAGES[@]}"; do
    if pacman -Si "$pkg" &>/dev/null; then
        success "Package '$pkg' found in repositories."
    else
        warn "Package '$pkg' not found in official repos. May fail during installation."
    fi
done

# Update package repositories
info "Updating package repositories..."
$PKG_UPDATE || warn "Repository update failed. Continuing anyway..."

# Backup existing config files
info "Backing up existing config files..."
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME/.config.bak-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

CONFIG_DIRS=("hypr" "rofi" "kitty" "quickshell")
for dir in "${CONFIG_DIRS[@]}"; do
    if [[ -d "$HOME/.config/$dir" ]]; then
        mv "$HOME/.config/$dir" "$BACKUP_DIR/"
        success "Backed up $HOME/.config/$dir to $BACKUP_DIR/$dir"
    fi
done

# Install official packages
info "Installing official packages..."
if ! $PKG_INSTALL "${OFFICIAL_PACKAGES[@]}"; then
    error "Official package installation failed. Check output above."
fi
success "Official packages installed."

# Install AUR packages
if [[ ${#AUR_PACKAGES[@]} -gt 0 ]]; then
    if [[ -n "${AUR_HELPER:-}" ]]; then
        info "Installing AUR packages..."
        if ! $AUR_HELPER -S --noconfirm "${AUR_PACKAGES[@]}"; then
            warn "Some AUR packages failed to install."
        else
            success "AUR packages installed."
        fi
    else
        warn "No AUR helper found (paru/yay). Install AUR packages manually:"
        warn "  ${AUR_PACKAGES[*]}"
    fi
fi

# Deploy dotfiles
info "Deploying dotfiles..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# Symlink quickshell config (for live dev updates)
if [[ -d "$DOTFILES_DIR/.config/quickshell" ]]; then
    # Remove existing quickshell dir if it was copied by accident
    [[ -d "$HOME/.config/quickshell" ]] && rm -rf "$HOME/.config/quickshell"
    ln -sf "$DOTFILES_DIR/.config/quickshell" "$HOME/.config/quickshell"
    success "Symlinked quickshell config to $HOME/.config/quickshell"
fi

# Copy other config files (hypr, rofi, kitty, etc.)
for dir in "$DOTFILES_DIR/.config/"*/; do
    dirname=$(basename "$dir")
    # Skip quickshell - already symlinked
    [[ "$dirname" == "quickshell" ]] && continue
    if [[ -d "$dir" ]]; then
        cp -r "$dir" "$HOME/.config/"
        success "Copied $dirname config to $HOME/.config/$dirname"
    fi
done

# Copy bin files (wallset-backend, etc.)
if [[ -d "$DOTFILES_DIR/.local/bin" ]]; then
    mkdir -p "$HOME/.local/bin"
    for f in "$DOTFILES_DIR/.local/bin/"*; do
        [[ -f "$f" ]] && cp "$f" "$HOME/.local/bin/" && success "Copied $(basename "$f")"
    done
fi

# Symlink wlogout config (from dotfiles or repo root)
if [[ -d "$SCRIPT_DIR/wlogout" ]]; then
    WLOGOUT_SRC="$SCRIPT_DIR/wlogout"
elif [[ -d "$DOTFILES_DIR/.config/wlogout" ]]; then
    WLOGOUT_SRC="$DOTFILES_DIR/.config/wlogout"
else
    WLOGOUT_SRC=""
fi
if [[ -n "$WLOGOUT_SRC" ]]; then
    [[ -d "$HOME/.config/wlogout" ]] && rm -rf "$HOME/.config/wlogout"
    ln -sf "$WLOGOUT_SRC" "$HOME/.config/wlogout"
    success "Symlinked wlogout config from $WLOGOUT_SRC"
fi

# Symlink scripts (from dotfiles or repo root)
if [[ -d "$SCRIPT_DIR/scripts" ]]; then
    SCRIPTS_SRC="$SCRIPT_DIR/scripts"
elif [[ -d "$DOTFILES_DIR/.config/scripts" ]]; then
    SCRIPTS_SRC="$DOTFILES_DIR/.config/scripts"
else
    SCRIPTS_SRC=""
fi
if [[ -n "$SCRIPTS_SRC" ]]; then
    [[ -d "$HOME/.config/scripts" ]] && rm -rf "$HOME/.config/scripts"
    ln -sf "$SCRIPTS_SRC" "$HOME/.config/scripts"
    success "Symlinked scripts from $SCRIPTS_SRC"
fi

# Copy wallpapers
if [[ -d "$DOTFILES_DIR/.config/wallpapers" ]]; then
    mkdir -p "$HOME/.config/wallpapers"
    cp -r "$DOTFILES_DIR/.config/wallpapers/"* "$HOME/.config/wallpapers/"
    success "Copied wallpapers"
fi

# Set permissions for executables
info "Setting permissions for executables..."
find "$HOME/.local/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
find "$HOME/.config/scripts" -type f -exec chmod +x {} \; 2>/dev/null || true

# Generate wallpaper thumbnails for picker
info "Generating wallpaper thumbnails..."
THUMB_DIR="$HOME/.cache/quickshell/wallpaper_picker/thumbs"
mkdir -p "$THUMB_DIR"
for img in "$HOME/.config/wallpapers/"*; do
    [[ -f "$img" ]] || continue
    thumb="$THUMB_DIR/$(basename "$img")"
    [[ -f "$thumb" ]] || magick "$img" -resize 200x200^ -gravity center -extent 200x200 "$thumb" 2>/dev/null
done
success "Wallpaper thumbnails generated."

# Install JetBrains Nerd Font
info "Installing JetBrains Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
mkdir -p "$FONT_DIR"

if ! wget -q -O /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip; then
    warn "Failed to download JetBrains Nerd Font. Continuing..."
else
    unzip -q -o /tmp/JetBrainsMono.zip -d "$FONT_DIR" 2>/dev/null
    rm /tmp/JetBrainsMono.zip
    fc-cache -fv >/dev/null 2>&1 || warn "Font cache update failed."
    success "JetBrains Nerd Font installed."
fi

# Setup quickshell-overview (system config with user overrides)
info "Setting up quickshell-overview..."
OVERVIEW_SRC="/etc/xdg/quickshell/overview"
OVERVIEW_DST="$HOME/.config/quickshell/overview"
if [[ -d "$OVERVIEW_SRC" ]]; then
    mkdir -p "$OVERVIEW_DST"
    cp -r "$OVERVIEW_SRC/"* "$OVERVIEW_DST/"
    success "quickshell-overview config copied from system"
else
    warn "quickshell-overview system config not found at $OVERVIEW_SRC"
fi

# Auto-start in Hyprland
info "Adding quickshell auto-start to Hyprland..."
AUTOSTART_LINE="exec-once = quickshell -c mrtrotid-shell &"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [[ -f "$HYPR_CONF" ]] && ! grep -q "quickshell" "$HYPR_CONF" 2>/dev/null; then
    echo "" >> "$HYPR_CONF"
    echo "# Quickshell shell" >> "$HYPR_CONF"
    echo "$AUTOSTART_LINE" >> "$HYPR_CONF"
    success "Added quickshell auto-start to hyprland.conf"
fi

# Final summary
echo
success "Trotid Shell installation completed!"
echo
info "Summary:"
info "- Shell: Quickshell + custom QML shell"
info "- Compositor: Hyprland"
info "- Terminal: Kitty (with wallust theming)"
info "- Launcher: Rofi"
info "- Packages installed from official repos: ${#OFFICIAL_PACKAGES[@]}"
if [[ -n "${AUR_HELPER:-}" ]]; then
    info "- AUR packages installed: ${AUR_PACKAGES[*]}"
fi
info "- Config files backed up to: $BACKUP_DIR"
info "- Dotfiles deployed from: $DOTFILES_DIR"
info "- JetBrains Nerd Font installed to: $FONT_DIR"
info
info "Next steps:"
info "1. Log out and log back in to Hyprland"
info "2. Set wallpaper with: wallset (or Super + W / Ctrl+Super+T)"
info "3. Press Super + / for keybind cheatsheet"
info "4. Customize weather location: edit ~/.config/quickshell/calendar/.env"
