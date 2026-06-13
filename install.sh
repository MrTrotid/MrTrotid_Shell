#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════════
#  TROTID SHELL — Automated Installer
#  Installs Hyprland + Quickshell desktop shell with all dependencies
#  Usage: chmod +x install.sh && ./install.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

# ── Colors & UI ──
RST='\e[0m'; BOLD='\e[1m'; DIM='\e[2m'; RED='\e[31m'; GREEN='\e[32m'
YELLOW='\e[33m'; BLUE='\e[34m'; MAGENTA='\e[35m'; CYAN='\e[36m'; WHITE='\e[37m'
GRAY='\e[90m'; BGRED='\e[41m'; BGGREEN='\e[42m'; BGBLUE='\e[44m'

logo() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo '  ╔═══════════════════════════════════════════╗'
  echo '  ║        TROTID SHELL INSTALLER             ║'
  echo '  ║   Hyprland + Quickshell Desktop Shell     ║'
  echo '  ╚═══════════════════════════════════════════╝'
  echo -e "${RST}"
}

info()    { echo -e "  ${BLUE}◆${RST} $*"; }
ok()      { echo -e "  ${GREEN}✔${RST} $*"; }
warn()    { echo -e "  ${YELLOW}⚠${RST} $*"; }
fail()    { echo -e "  ${RED}✘${RST} $*"; }
header()  { echo -e "\n  ${BOLD}${WHITE}── $* ──${RST}\n"; }
prompt_yn() {
  local msg="$1" default="${2:-y}"
  local yn
  while true; do
    echo -ne "  ${CYAN}?${RST} ${msg} ${GRAY}[${default^^}/$( [[ "$default" == "y" ]] && echo "n" || echo "N" )]${RST} "
    read -r yn
    [[ -z "$yn" ]] && yn="$default"
    case "${yn,,}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
    esac
  done
}

# ── Safety checks ──
if [[ $EUID -eq 0 ]]; then
  echo -e "\n  ${BGRED}${WHITE} ERROR ${RST} ${RED}Do not run this script as root. Run as a normal user.${RST}"
  exit 1
fi

logo

if ! command -v pacman &>/dev/null; then
  warn "This installer only supports Arch-based distributions."
  warn "Detected package manager is not pacman."
  prompt_yn "Continue anyway?" "n" || exit 1
fi

# ── Script paths ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# ═══════════════════════════════════════════════════════════════════════════════
#  PHASE 0 — Detect system
# ═══════════════════════════════════════════════════════════════════════════════
header "System Detection"

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS="${PRETTY_NAME:-$NAME $VERSION_ID}"
else
  OS="Arch Linux (unknown variant)"
fi
info "Distribution: ${BOLD}$OS${RST}"

ARCH=$(uname -m)
info "Architecture: ${BOLD}$ARCH${RST}"

HAS_PARU=false; HAS_YAY=false
command -v paru &>/dev/null && HAS_PARU=true
command -v yay &>/dev/null && HAS_YAY=true

if $HAS_PARU; then
  AUR_HELPER="paru"; ok "AUR helper found: ${BOLD}paru${RST}"
elif $HAS_YAY; then
  AUR_HELPER="yay";  ok "AUR helper found: ${BOLD}yay${RST}"
else
  warn "No AUR helper found. paru will be installed in the next step."
  AUR_HELPER=""
fi

if ! command -v sudo &>/dev/null; then
  warn "sudo is not installed. Install it first: ${GRAY}pacman -S sudo${RST}"
  exit 1
fi
if ! sudo -n true 2>/dev/null; then
  info "sudo access needed for package installation."
  sudo -v || { fail "sudo failed. Cannot continue."; exit 1; }
fi

echo
prompt_yn "Ready to start installing Trotid Shell?" "y" || exit 0

# ═══════════════════════════════════════════════════════════════════════════════
#  PHASE 1 — Install paru (AUR helper)
# ═══════════════════════════════════════════════════════════════════════════════
install_paru() {
  header "Phase 1/6 — AUR Helper (paru)"

  if $HAS_PARU; then
    ok "paru is already installed. Skipping."
    return 0
  fi

  info "paru is needed to install Quickshell from AUR."
  prompt_yn "Install paru?" "y" || { warn "Skipping paru. AUR packages must be installed manually."; return 1; }

  local workdir
  workdir=$(mktemp -d) || { fail "Failed to create temp dir"; return 1; }

  info "Installing build dependencies (base-devel, git)..."
  if ! sudo pacman -S --needed --noconfirm base-devel git 2>&1 | grep -v 'warning:\|^$'; then
    warn "Some build deps may have failed. Continuing..."
  fi

  info "Cloning paru from AUR..."
  if ! git clone https://aur.archlinux.org/paru.git "$workdir/paru" 2>/dev/null; then
    fail "Failed to clone paru. Check internet connection."
    rm -rf "$workdir"
    return 1
  fi

  info "Building paru (this may take a while)..."
  cd "$workdir/paru" || return 1
  if ! makepkg -si --noconfirm 2>&1 | tail -5; then
    fail "paru build failed."
    cd /; rm -rf "$workdir"
    return 1
  fi

  cd /; rm -rf "$workdir"
  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"; HAS_PARU=true
    ok "paru installed successfully."
    return 0
  else
    fail "paru installation seems to have failed."
    return 1
  fi
}

# ── Package lists ──
REPO_PACKAGES=(
  hyprland rofi kitty wallust matugen swaybg cava wlogout cliphist
  grim slurp swappy hyprpicker hyprsunset wf-recorder playerctl
  brightnessctl jq wl-clipboard wget unzip fontconfig imagemagick
)

AUR_PACKAGES=(quickshell)

# Extra optional packages for a complete desktop
OPTIONAL_PACKAGES=(
  "ghostty"        "Terminal emulator (used by Super+Return)"
  "thunar"         "File manager (used by Super+E)"
  "zen-browser"    "Browser (used by Super+W)"
  "brave-browser"  "Alternative browser (Super+Shift+W)"
  "nvim"           "Text editor (used by Super+C)"
  "btop"           "System monitor"
  "pavucontrol"    "Audio settings"
  "nm-connection-editor" "Network settings"
  "spotify"        "Music player"
  "discord"        "Chat app"
  "obsidian"       "Note taking"
)

# ── Phase 2 — Install packages ──
install_packages() {
  header "Phase 2/6 — Package Installation"

  info "Checking package status..."
  local to_install=()
  for pkg in "${REPO_PACKAGES[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
      echo -e "  ${GRAY}  ✔ $pkg${RST} ${GREEN}(installed)${RST}"
    else
      to_install+=("$pkg")
    fi
  done

  if [[ ${#to_install[@]} -eq 0 ]]; then
    ok "All repository packages are already installed."
  else
    echo -e "  ${GRAY}  ${#to_install[@]} packages need installation${RST}"
    prompt_yn "Install ${#to_install[@]} missing packages?" "y" || { warn "Skipping package installation."; }
    if [[ $? -eq 0 ]]; then
      info "Updating package databases..."
      sudo pacman -Sy --noconfirm 2>&1 | grep -v 'warning:\|^$' || true

      info "Installing missing packages..."
      if ! sudo pacman -S --needed --noconfirm "${to_install[@]}"; then
        warn "Some packages failed. Check output above."
        prompt_yn "Continue anyway?" "y" || exit 1
      else
        ok "Repository packages installed."
      fi
    fi
  fi

  # AUR packages
  if [[ ${#AUR_PACKAGES[@]} -gt 0 ]]; then
    local aur_missing=()
    for pkg in "${AUR_PACKAGES[@]}"; do
      pacman -Qi "$pkg" &>/dev/null || aur_missing+=("$pkg")
    done

    if [[ ${#aur_missing[@]} -gt 0 ]]; then
      echo
      info "AUR packages to install: ${aur_missing[*]}"
      if [[ -n "${AUR_HELPER:-}" ]]; then
        prompt_yn "Install AUR packages?" "y" || { warn "Skipping AUR packages."; }
        if [[ $? -eq 0 ]]; then
          if ! $AUR_HELPER -S --needed --noconfirm "${aur_missing[@]}"; then
            warn "Some AUR packages failed."
            prompt_yn "Continue anyway?" "y" || exit 1
          else
            ok "AUR packages installed."
          fi
        fi
      else
        warn "No AUR helper available. Install manually:"
        echo -e "  ${GRAY}  ${AUR_HELPER:-paru} -S ${aur_missing[*]}${RST}"
      fi
    else
      ok "All AUR packages already installed."
    fi
  fi
}

# ── Phase 3 — Optional extras ──
install_optional() {
  header "Phase 3/6 — Optional Applications"

  info "These applications are referenced by keybinds but not required."
  prompt_yn "Choose optional apps to install?" "y" || return 0

  local i=0 selected=()
  for ((i=0; i<${#OPTIONAL_PACKAGES[@]}; i+=2)); do
    local pkg="${OPTIONAL_PACKAGES[i]}"
    local desc="${OPTIONAL_PACKAGES[i+1]}"

    if pacman -Qi "$pkg" &>/dev/null; then
      echo -e "  ${GRAY}  ✔ $pkg — $desc${RST} ${GREEN}(installed)${RST}"
      continue
    fi

    if prompt_yn "Install ${BOLD}$pkg${RST}? ${GRAY}($desc)${RST}" "n"; then
      selected+=("$pkg")
    fi
  done

  if [[ ${#selected[@]} -gt 0 ]]; then
    info "Installing selected packages..."
    if ! sudo pacman -S --needed --noconfirm "${selected[@]}"; then
      warn "Some optional packages failed."
    else
      ok "Optional packages installed."
    fi
  fi
}

# ── Phase 4 — Backup ──
backup_configs() {
  header "Phase 4/6 — Configuration Backup"

  local backup_dirs=()
  for dir in hypr rofi kitty quickshell wlogout scripts; do
    [[ -d "$HOME/.config/$dir" ]] && backup_dirs+=("$dir")
  done

  if [[ ${#backup_dirs[@]} -eq 0 ]]; then
    ok "No existing configs to back up."
    return 0
  fi

  info "Existing configs found: ${backup_dirs[*]}"
  prompt_yn "Back up these configs?" "y" || { warn "Skipping backup."; return 0; }

  local ts; ts=$(date +"%Y%m%d_%H%M%S")
  local backup="$HOME/.config.bak-$ts"
  mkdir -p "$backup" || { fail "Cannot create backup dir."; return 1; }

  for dir in "${backup_dirs[@]}"; do
    mv "$HOME/.config/$dir" "$backup/" 2>/dev/null && ok "Backed up: ${BOLD}$dir${RST}"
  done

  info "Backup saved to: ${GRAY}$backup${RST}"
}

# ── Phase 5 — Deploy dotfiles ──
deploy_dotfiles() {
  header "Phase 5/6 — Deploying Dotfiles"

  # Quickshell (symlink for live dev)
  if [[ -d "$DOTFILES_DIR/.config/quickshell" ]]; then
    if prompt_yn "Symlink quickshell config? ${GRAY}(enables live QML reload)${RST}" "y"; then
      [[ -d "$HOME/.config/quickshell" ]] && rm -rf "$HOME/.config/quickshell"
      ln -sf "$DOTFILES_DIR/.config/quickshell" "$HOME/.config/quickshell"
      ok "Symlinked quickshell config"
    else
      info "Copying quickshell config instead..."
      cp -r "$DOTFILES_DIR/.config/quickshell" "$HOME/.config/"
      ok "Copied quickshell config"
    fi
  fi

  # Other configs (hypr, rofi, kitty, wallpapers, etc.)
  for dir in "$DOTFILES_DIR/.config/"*/; do
    local name; name=$(basename "$dir")
    [[ "$name" == "quickshell" ]] && continue
    [[ "$name" == "." ]] || [[ "$name" == ".." ]] && continue

    if [[ -d "$dir" ]]; then
      if [[ -d "$HOME/.config/$name" ]]; then
        if prompt_yn "Replace existing ${BOLD}$name${RST} config?" "y"; then
          rm -rf "$HOME/.config/$name"
          cp -r "$dir" "$HOME/.config/$name"
          ok "Deployed: ${BOLD}$name${RST}"
        else
          info "Skipped: ${GRAY}$name${RST}"
        fi
      else
        cp -r "$dir" "$HOME/.config/$name"
        ok "Deployed: ${BOLD}$name${RST}"
      fi
    fi
  done

  # Bin scripts
  if [[ -d "$DOTFILES_DIR/.local/bin" ]]; then
    mkdir -p "$HOME/.local/bin"
    for f in "$DOTFILES_DIR/.local/bin/"*; do
      [[ -f "$f" ]] && cp "$f" "$HOME/.local/bin/"
    done
    ok "Copied bin scripts (wallset, wallset-backend, etc.)"
  fi

  # Wlogout symlink
  local wlogout_src=""
  [[ -d "$SCRIPT_DIR/wlogout" ]] && wlogout_src="$SCRIPT_DIR/wlogout"
  [[ -z "$wlogout_src" && -d "$DOTFILES_DIR/.config/wlogout" ]] && wlogout_src="$DOTFILES_DIR/.config/wlogout"
  if [[ -n "$wlogout_src" ]]; then
    [[ -d "$HOME/.config/wlogout" ]] && rm -rf "$HOME/.config/wlogout"
    ln -sf "$wlogout_src" "$HOME/.config/wlogout"
    ok "Symlinked wlogout config"
  fi

  # Scripts symlink
  local scripts_src=""
  [[ -d "$SCRIPT_DIR/scripts" ]] && scripts_src="$SCRIPT_DIR/scripts"
  [[ -z "$scripts_src" && -d "$DOTFILES_DIR/.config/scripts" ]] && scripts_src="$DOTFILES_DIR/.config/scripts"
  if [[ -n "$scripts_src" ]]; then
    [[ -d "$HOME/.config/scripts" ]] && rm -rf "$HOME/.config/scripts"
    ln -sf "$scripts_src" "$HOME/.config/scripts"
    ok "Symlinked scripts"
  fi

  # Set permissions
  find "$HOME/.local/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
  find "$HOME/.config/scripts" -type f -exec chmod +x {} \; 2>/dev/null || true

  # Wallpapers
  if [[ -d "$DOTFILES_DIR/.config/wallpapers" ]]; then
    mkdir -p "$HOME/.config/wallpapers"
    cp -rn "$DOTFILES_DIR/.config/wallpapers/"* "$HOME/.config/wallpapers/" 2>/dev/null
    ok "Copied wallpapers"
  fi
}

# ── Phase 6 — Post-install ──
post_install() {
  header "Phase 6/6 — Post-Install Setup"

  # Wallpaper thumbnails
  if command -v magick &>/dev/null; then
    info "Generating wallpaper thumbnails..."
    local thumb="$HOME/.cache/quickshell/wallpaper_picker/thumbs"
    mkdir -p "$thumb"
    for img in "$HOME/.config/wallpapers/"*; do
      [[ -f "$img" ]] || continue
      local t="$thumb/$(basename "$img")"
      [[ -f "$t" ]] || magick "$img" -resize 200x200^ -gravity center -extent 200x200 "$t" 2>/dev/null
    done
    ok "Wallpaper thumbnails generated"
  fi

  # JetBrains Nerd Font
  if [[ -d "$HOME/.local/share/fonts/JetBrainsMono" ]]; then
    ok "JetBrains Nerd Font already installed"
  else
    info "Installing JetBrains Nerd Font..."
    local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
    mkdir -p "$font_dir"

    if wget -q -O /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip; then
      unzip -q -o /tmp/JetBrainsMono.zip -d "$font_dir" 2>/dev/null
      rm /tmp/JetBrainsMono.zip
      fc-cache -f "$font_dir" >/dev/null 2>&1 || true
      ok "JetBrains Nerd Font installed"
    else
      warn "Font download failed. Skipping."
    fi
  fi

  # Quickshell-overview (pre-packaged user config)
  local overview_dst="$HOME/.config/quickshell/overview"
  if [[ -d "$DOTFILES_DIR/.config/quickshell/overview" && ! -d "$overview_dst" ]]; then
    info "Setting up quickshell-overview..."
    cp -r "$DOTFILES_DIR/.config/quickshell/overview" "$overview_dst"
    ok "quickshell-overview config deployed"
  elif [[ -d "$overview_dst" ]]; then
    ok "quickshell-overview already configured"
  else
    warn "No overview config in dotfiles. Skipping."
  fi

  # Auto-start in hyprland.conf
  local hypr_conf="$HOME/.config/hypr/hyprland.conf"
  if [[ -f "$hypr_conf" ]] && ! grep -q "quickshell" "$hypr_conf" 2>/dev/null; then
    info "Adding quickshell auto-start to hyprland.conf..."
    {
      echo ""
      echo "# Trotid Shell — Quickshell"
      echo "exec-once = quickshell -c mrtrotid-shell &"
    } >> "$hypr_conf"
    ok "Auto-start added"
  fi

  # Overview auto-start (separate Quickshell instance)
  local shconf="$HOME/.config/quickshell/shell.qml"
  if [[ -f "$shconf" ]] && grep -q "overview" "$shconf" 2>/dev/null; then
    ok "Overview auto-start already configured in shell.qml"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
#  RUN ALL PHASES
# ═══════════════════════════════════════════════════════════════════════════════

install_paru
echo
install_packages
echo
install_optional
echo
backup_configs
echo
deploy_dotfiles
echo
post_install

# ═══════════════════════════════════════════════════════════════════════════════
#  SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════
header "Installation Complete"

echo -e "  ${GREEN}${BOLD}✔ Trotid Shell is ready!${RST}"
echo
echo -e "  ${BOLD}Next steps:${RST}"
echo -e "  ${GRAY}  1.${RST} Log out and select Hyprland in your display manager"
echo -e "  ${GRAY}  2.${RST} Set wallpaper: ${CYAN}wallset${RST} ${GRAY}(or Super+W / Ctrl+Super+T)${RST}"
echo -e "  ${GRAY}  3.${RST} View keybinds: ${CYAN}Super + /${RST}"
echo -e "  ${GRAY}  4.${RST} Open settings: ${CYAN}Super + I${RST}"
echo -e "  ${GRAY}  5.${RST} Update shell: ${CYAN}Settings → About → Update Shell${RST}"
echo
echo -e "  ${DIM}Need help? Check AGENTS.md or visit github.com/Noro18/linux-ricing-dotfiles${RST}"
echo
