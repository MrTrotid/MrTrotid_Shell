#!/bin/bash

set -euo pipefail

# ── Color-coded logging ──────────────────────────────────────────────
info()    { echo -e "\e[34m[INFO]\e[0m $*"; }
success() { echo -e "\e[32m[OK]\e[0m $*"; }
warn()    { echo -e "\e[33m[WARN]\e[0m $*"; }
error()   { echo -e "\e[31m[ERROR]\e[0m $*"; exit 1; }

# ── Pre-flight ───────────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
    error "Do not run this as root. Run as a regular user."
fi

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.config.bak-$(date +%Y%m%d-%H%M%S)"

# Detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
    elif type lsb_release &>/dev/null; then
        OS=$(lsb_release -si)
    else
        OS=$(uname -s)
    fi
}

detect_distro
info "Detected distribution: $OS"

case "$OS" in
    *"Arch"*|*"Manjaro"*)
        PKG_MANAGER="pacman"
        ;;
    *"Debian"*|*"Ubuntu"*)
        PKG_MANAGER="apt"
        ;;
    *"Fedora"*)
        PKG_MANAGER="dnf"
        ;;
    *)
        error "Unsupported distribution: $OS"
        ;;
esac
info "Package manager: $PKG_MANAGER"

# ── Dependencies ──────────────────────────────────────────────────────
info "Checking dependencies..."

HYPRLAND_PKGS="hyprland hypridle hyprlock hyprpaper hyprsunset"
COMMON_PKGS="brightnessctl pipewire wireplumber network-manager-applet polkit-kde-agent bluez-utils"

case "$PKG_MANAGER" in
    pacman)
        if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
            warn "No AUR helper found. Will only install repo packages."
            warn "Install 'quickshell-git' manually from AUR."
            INSTALL_AUR=false
        else
            AUR_HELPER=$(command -v yay || command -v paru)
            INSTALL_AUR=true
        fi
        sudo pacman -S --needed --noconfirm $HYPRLAND_PKGS $COMMON_PKGS 2>/dev/null || true
        if $INSTALL_AUR; then
            $AUR_HELPER -S --needed --noconfirm quickshell-git 2>/dev/null || warn "quickshell-git install failed, install manually"
        fi
        ;;
    apt)
        sudo apt update
        sudo apt install -y hyprland brightnessctl pipewire wireplumber network-manager-gnome policykit-1-gnome 2>/dev/null || true
        warn "Install quickshell from: https://github.com/outfoxxed/quickshell/releases"
        ;;
    dnf)
        sudo dnf install -y hyprland brightnessctl pipewire wireplumber network-manager-applet polkit-kde-agent 2>/dev/null || true
        warn "Install quickshell from: https://github.com/outfoxxed/quickshell/releases"
        ;;
esac

# ── Fonts ─────────────────────────────────────────────────────────────
info "Installing JetBrainsMono Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if ! fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    case "$PKG_MANAGER" in
        pacman)
            sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd 2>/dev/null || true
            ;;
        *)
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
            unzip -q JetBrainsMono.zip -d JetBrainsMono
            cp JetBrainsMono/*.ttf "$FONT_DIR/"
            fc-cache -f
            rm -rf "$TEMP_DIR"
            ;;
    esac
fi

# ── Backup existing configs ────────────────────────────────────────────
info "Backing up existing configs..."
for dir in hypr quickshell; do
    if [[ -d "$HOME/.config/$dir" && ! -L "$HOME/.config/$dir" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$HOME/.config/$dir" "$BACKUP_DIR/$dir"
        success "Backed up ~/.config/$dir -> $BACKUP_DIR/$dir"
    fi
done
if [[ -d "$BACKUP_DIR" ]]; then
    success "Backups saved to: $BACKUP_DIR"
else
    info "No backups needed"
fi

# ── Deploy configs ─────────────────────────────────────────────────────
info "Deploying configs..."
for dir in "$DOTFILES_DIR/dotfiles/.config/"*/; do
    dir_name=$(basename "$dir")
    target="$HOME/.config/$dir_name"
    if [[ -L "$target" ]]; then
        rm "$target"
    elif [[ -d "$target" ]]; then
        rm -rf "$target"
    fi
    ln -sfn "$dir" "$target"
    success "Linked $dir -> $target"
done

# ── Post-install ───────────────────────────────────────────────────────
info "Post-install checks..."
if [[ $(find "$HOME/.local/bin" -type f 2>/dev/null | wc -l) -gt 0 ]]; then
    chmod +x "$HOME/.local/bin"/* 2>/dev/null || true
fi

# Verify links
info "Verifying symlinks..."
for dir in hypr quickshell; do
    if [[ -L "$HOME/.config/$dir" ]]; then
        success "~/.config/$dir -> $(readlink -f "$HOME/.config/$dir")"
    else
        warn "~/.config/$dir is not a symlink (may be a regular directory)"
    fi
done

echo ""
success "═══════════════════════════════════════"
success "  MrTrotid Shell — Installation Done!"
success "═══════════════════════════════════════"
echo ""
info "What was installed:"
echo "  - Hyprland (WM)"
echo "  - Quickshell (Bar/Shell)"
echo "  - JetBrainsMono Nerd Font"
echo "  - brightnessctl / pipewire (backlight/audio)"
echo ""
if [[ -d "$BACKUP_DIR" ]]; then
    info "Backup locations:"
    echo "  $BACKUP_DIR"
fi
echo ""
info "Next steps:"
echo "  1. Log out and select Hyprland from your display manager"
echo "  2. If quickshell doesn't start, run: quickshell -c mrtrotid-shell"
echo "  3. Check logs: cat /run/user/1000/quickshell/by-id/*/log.log"
echo ""
