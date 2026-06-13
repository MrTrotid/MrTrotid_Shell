#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════════
#  TROTID SHELL — Automated Installer
#  Interactive TUI installer for Hyprland + Quickshell desktop shell
#  Usage: chmod +x install.sh && ./install.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

# ── Terminal colors ──
R='\e[0m'; B='\e[1m'; D='\e[2m'; I='\e[3m'
RED='\e[31m'; GR='\e[32m'; YE='\e[33m'; BL='\e[34m'; MG='\e[35m'; CY='\e[36m'
WH='\e[37m'; GY='\e[90m'; BG_R='\e[41m'; BG_G='\e[42m'; BG_B='\e[44m'

# ── UI helpers ──
logo() {
  clear
  echo -e "  ${CY}${B}╔═══════════════════════════════════════════════╗${R}"
  echo -e "  ${CY}${B}║         T R O T I D   S H E L L              ║${R}"
  echo -e "  ${CY}${B}║   Hyprland + Quickshell Desktop Shell         ║${R}"
  echo -e "  ${CY}${B}╚═══════════════════════════════════════════════╝${R}"
  echo
}

info()  { echo -e "  ${BL}◆${R}  $*"; }
ok()    { echo -e "  ${GR}✔${R}  $*"; }
warn()  { echo -e "  ${YE}⚠${R}  $*"; }
fail()  { echo -e "  ${RED}✘${R}  $*"; }
muted() { echo -e "  ${GY}${D}$*${R}"; }
title() { echo -e "\n  ${B}${WH}┌─ $*${R}"; echo -e "  ${B}${WH}└${R}"; }

ask() {
  local msg="$1" default="${2:-y}"
  local yn
  while true; do
    echo -ne "  ${CY}?${R}  ${msg} ${GY}[${default^^}/$( [[ "$default" == "y" ]] && echo "n" || echo "N" )]${R} "
    read -r yn
    [[ -z "$yn" ]] && yn="$default"
    case "${yn,,}" in y|yes) return 0;; n|no) return 1;; esac
  done
}

pick() {
  local msg="$1"; shift
  local options=("$@")
  echo -e "  ${CY}?${R}  ${msg}"
  for i in "${!options[@]}"; do
    echo -e "      ${GY}$((i+1)).${R} ${options[$i]}"
  done
  local choice
  while true; do
    echo -ne "  ${GY}  Enter number [1-${#options[@]}]:${R} "
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#options[@]})); then
      return $choice
    fi
  done
}

spinner() {
  local pid=$1; local msg="$2"
  local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i=0
  echo -ne "  ${GY}${spin[0]}${R}  ${msg}..."
  while kill -0 "$pid" 2>/dev/null; do
    echo -ne "\r  ${GY}${spin[i]}${R}  ${msg}..."
    i=$(( (i+1) % 10 ))
    sleep 0.1
  done
  wait "$pid" && echo -e "\r  ${GR}✔${R}  ${msg}" || echo -e "\r  ${RED}✘${R}  ${msg} ${GY}(failed)${R}"
}

# ── Safety ──
if [[ $EUID -eq 0 ]]; then
  echo -e "\n  ${BG_R}${WH} ERROR ${R} ${RED}Do not run as root. Run as a normal user.${R}"
  exit 1
fi

logo

if ! command -v pacman &>/dev/null; then
  warn "This installer requires an Arch-based distribution (pacman)."
  ask "Continue anyway?" "n" || exit 1
fi

# ── SCRIPT DIRS ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# ═══════════════════════════════════════════════════════════════════════════════
#  SYSTEM CHECK
# ═══════════════════════════════════════════════════════════════════════════════
title "System Information"

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS="${PRETTY_NAME:-$NAME $VERSION_ID}"
else
  OS="Arch Linux (unknown)"
fi
info "Distribution: ${B}${OS}${R}"
info "Kernel: ${B}$(uname -r)${R}"

HAS_PARU=false; HAS_YAY=false
command -v paru &>/dev/null && HAS_PARU=true
command -v yay &>/dev/null && HAS_YAY=true

if $HAS_PARU; then
  ok "paru detected"
elif $HAS_YAY; then
  ok "yay detected (will be used for AUR packages)"
else
  warn "No AUR helper found — paru will be installed"
fi

if ! sudo -n true 2>/dev/null; then
  info "Some steps need sudo access."
  sudo -v || { fail "sudo authentication failed."; exit 1; }
fi

echo
ask "Begin installing Trotid Shell?" "y" || exit 0

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 1 — Install paru
# ═══════════════════════════════════════════════════════════════════════════════
step_paru() {
  title "Step 1: AUR Helper (paru)"

  $HAS_PARU && { ok "paru already installed"; return 0; }
  $HAS_YAY && { AUR_HELPER="yay"; ok "Using existing yay instead of paru"; return 0; }

  ask "Install paru (AUR helper)?" "y" || { warn "Skipping. AUR packages must be installed manually."; return 1; }

  local tmp
  tmp=$(mktemp -d) || { fail "Cannot create temp dir"; return 1; }

  info "Installing build dependencies..."
  if ! sudo pacman -S --needed --noconfirm base-devel git 2>/dev/null; then
    warn "Build deps may have partial failures. Continuing..."
  fi

  info "Cloning paru-bin (aur.archlinux.org/paru-bin)..."
  if ! git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$tmp/paru" 2>/dev/null; then
    fail "Failed to clone paru-bin — check internet connection."
    rm -rf "$tmp"
    return 1
  fi

  info "Building paru-bin (pre-compiled, faster)..."
  (cd "$tmp/paru" && makepkg -si --noconfirm) 2>&1 | tail -5

  rm -rf "$tmp"

  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"; HAS_PARU=true
    ok "paru installed successfully"
    return 0
  else
    fail "paru installation failed."
    ask "Continue without AUR helper?" "y" || exit 1
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 2 — Detect installed & choose packages
# ═══════════════════════════════════════════════════════════════════════════════
pkg_installed() { pacman -Qi "$1" &>/dev/null; }

CORE_PKGS=(
  hyprland
  swaybg
  rofi-wayland
  wlogout
  cliphist
  grim
  slurp
  swappy
  hyprpicker
  hyprsunset
  wf-recorder
  playerctl
  brightnessctl
  jq
  wl-clipboard
  imagemagick
  wget
  unzip
  noto-fonts
)

AUR_CORE=(
  quickshell
  wallust
  matugen
)

EXTRA_PKGS=(
  "cava"       "Audio visualizer (wave form in bar)"
  "pavucontrol" "Audio settings panel"
  "nm-connection-editor" "Network manager GUI"
  "btop"       "System monitor"
)

step_packages() {
  title "Step 2: Package Selection"

  # ── Terminal ──
  echo -e "  ${GY}Choose your default terminal:${R}"
  pick "" "ghostty (recommended)" "kitty" "alacritty" "foot" "wezterm" "Skip"
  local term_choice=$?
  local TERMINAL=""
  case $term_choice in
    1) TERMINAL="ghostty" ;;
    2) TERMINAL="kitty" ;;
    3) TERMINAL="alacritty" ;;
    4) TERMINAL="foot" ;;
    5) TERMINAL="wezterm" ;;
    6) TERMINAL="" ;;
  esac
  [[ -n "$TERMINAL" ]] && ok "Terminal: ${B}$TERMINAL${R}" || warn "No terminal selected"

  # ── Browser ──
  echo
  echo -e "  ${GY}Choose your browser:${R}"
  pick "" "zen-browser (recommended)" "brave-browser" "firefox" "chromium" "Skip"
  local br_choice=$?
  local BROWSER=""
  case $br_choice in
    1) BROWSER="zen-browser" ;;
    2) BROWSER="brave-browser" ;;
    3) BROWSER="firefox" ;;
    4) BROWSER="chromium" ;;
    5) BROWSER="" ;;
  esac
  [[ -n "$BROWSER" ]] && ok "Browser: ${B}$BROWSER${R}" || warn "No browser selected"

  # ── Editor ──
  echo
  echo -e "  ${GY}Choose your text editor:${R}"
  pick "" "neovim (recommended)" "vim" "nano" "visual-studio-code-bin (AUR)" "Skip"
  local ed_choice=$?
  local EDITOR_PKG=""
  case $ed_choice in
    1) EDITOR_PKG="neovim" ;;
    2) EDITOR_PKG="vim" ;;
    3) EDITOR_PKG="nano" ;;
    4) EDITOR_PKG="visual-studio-code-bin" ;;
    5) EDITOR_PKG="" ;;
  esac
  [[ -n "$EDITOR_PKG" ]] && ok "Editor: ${B}$EDITOR_PKG${R}" || warn "No editor selected"

  # ── File manager ──
  echo
  ask "Install file manager (thunar)?" "y" && { FILE_MGR="thunar"; ok "File manager: ${B}thunar${R}"; } || true

  # ── Assemble package list ──
  ALL_PKGS=("${CORE_PKGS[@]}")
  [[ -n "$TERMINAL" ]] && ALL_PKGS+=("$TERMINAL")
  [[ -n "$BROWSER" ]]   && ALL_PKGS+=("$BROWSER")
  [[ -n "$EDITOR_PKG" ]] && ALL_PKGS+=("$EDITOR_PKG")
  [[ -n "$FILE_MGR" ]]  && ALL_PKGS+=("$FILE_MGR")

  local pkg_type
  for pkg in "${EXTRA_PKGS[@]}"; do
    [[ "$pkg" == *" "* ]] && continue
    local desc_idx=$(( $(echo "${EXTRA_PKGS[*]}" | grep -o " $pkg " | wc -l) ))
    # Actually let me use a simpler approach
  done

  # ── Extra toggles ──
  echo
  echo -e "  ${GY}Extra packages:${R}"
  for ((i=0; i<${#EXTRA_PKGS[@]}; i+=2)); do
    local ep="${EXTRA_PKGS[i]}"
    local ed="${EXTRA_PKGS[i+1]}"
    if ask "Install ${B}$ep${R}? ${GY}($ed)${R}" "n"; then
      ALL_PKGS+=("$ep")
      ok "Added: $ep"
    fi
  done
}

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 3 — Install all packages via paru (handles both repo + AUR)
# ═══════════════════════════════════════════════════════════════════════════════
step_install() {
  title "Step 3: Installing Packages"

  local ALL_NEED=("${ALL_PKGS[@]}" "${AUR_CORE[@]}")
  local NEED=()
  for pkg in "${ALL_NEED[@]}"; do
    pkg_installed "$pkg" || NEED+=("$pkg")
  done

  if [[ ${#NEED[@]} -eq 0 ]]; then
    ok "All packages already installed"
    return 0
  fi

  echo -e "  ${GY}${#NEED[@]} packages to install:${R}"
  muted "${NEED[*]}"
  echo
  ask "Install missing packages?" "y" || { warn "Skipping package installation"; return 0; }

  local helper="${AUR_HELPER:-paru}"
  if ! command -v "$helper" &>/dev/null; then
    fail "AUR helper ($helper) not found. Install paru first or manually."
    return 1
  fi

  info "Syncing repositories..."
  $helper -Sy --noconfirm 2>/dev/null || true

  info "Installing packages via $helper (handles both repo and AUR)..."
  if $helper -S --needed --noconfirm "${NEED[@]}"; then
    ok "All packages installed"
  else
    warn "Some packages failed to install."
    ask "Continue anyway?" "y" || return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 4 — Backup existing configs
# ═══════════════════════════════════════════════════════════════════════════════
step_backup() {
  title "Step 4: Configuration Backup"

  local dirs=()
  for d in hypr rofi quickshell wlogout scripts kitty; do
    [[ -d "$HOME/.config/$d" ]] && dirs+=("$d")
  done

  [[ ${#dirs[@]} -eq 0 ]] && { ok "No existing configs to back up"; return 0; }

  echo -e "  ${GY}These existing configs will be backed up:${R}"
  for d in "${dirs[@]}"; do echo -e "    ${GY}•${R} $HOME/.config/$d"; done
  echo

  ask "Back up configs before deploying?" "y" || { warn "Skipping backup"; return 0; }

  local ts; ts=$(date +"%Y%m%d_%H%M%S")
  local bk="$HOME/.config.bak-$ts"
  mkdir -p "$bk" || { fail "Cannot create backup directory"; return 1; }

  for d in "${dirs[@]}"; do
    mv "$HOME/.config/$d" "$bk/" 2>/dev/null && ok "Backed up: $d"
  done

  info "Backup saved to: ${GY}$bk${R}"
}

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 5 — Deploy dotfiles
# ═══════════════════════════════════════════════════════════════════════════════
step_deploy() {
  title "Step 5: Deploying Dotfiles"

  ask "Deploy configuration files?" "y" || { warn "Skipping deployment"; return 0; }

  # ── Quickshell (symlink choice) ──
  if ask "Symlink quickshell config? ${GY}(enables live QML hot-reload)${R}" "y"; then
    [[ -d "$HOME/.config/quickshell" ]] && rm -rf "$HOME/.config/quickshell"
    ln -sf "$DOTFILES_DIR/.config/quickshell" "$HOME/.config/quickshell"
    ok "Symlinked quickshell config"
  else
    cp -r "$DOTFILES_DIR/.config/quickshell" "$HOME/.config/"
    ok "Copied quickshell config"
  fi

  # ── Other configs ──
  for dir in "$DOTFILES_DIR/.config/"*/; do
    local name; name=$(basename "$dir")
    [[ "$name" == "quickshell" || "$name" == "." || "$name" == ".." ]] && continue

    if [[ -d "$dir" && -n "$(ls -A "$dir")" ]]; then
      if [[ -d "$HOME/.config/$name" ]]; then
        if ask "Replace ${B}$name${R} config?" "y"; then
          rm -rf "$HOME/.config/$name"
          cp -r "$dir" "$HOME/.config/$name"
          ok "Deployed: $name"
        else
          info "Skipped: $name"
        fi
      else
        cp -r "$dir" "$HOME/.config/$name"
        ok "Deployed: $name"
      fi
    fi
  done

  # ── Bin scripts ──
  if [[ -d "$DOTFILES_DIR/.local/bin" ]]; then
    mkdir -p "$HOME/.local/bin"
    for f in "$DOTFILES_DIR/.local/bin/"*; do
      [[ -f "$f" ]] && cp "$f" "$HOME/.local/bin/"
    done
    find "$HOME/.local/bin" -type f -exec chmod +x {} \;
    ok "Deployed bin scripts (wallset, wallset-backend, etc.)"
  fi

  # ── Wlogout ──
  local ws=""
  [[ -d "$SCRIPT_DIR/wlogout" ]] && ws="$SCRIPT_DIR/wlogout"
  [[ -z "$ws" && -d "$DOTFILES_DIR/.config/wlogout" ]] && ws="$DOTFILES_DIR/.config/wlogout"
  if [[ -n "$ws" ]]; then
    [[ -d "$HOME/.config/wlogout" ]] && rm -rf "$HOME/.config/wlogout"
    ln -sf "$ws" "$HOME/.config/wlogout"
    ok "Symlinked wlogout"
  fi

  # ── Scripts ──
  local ss=""
  [[ -d "$SCRIPT_DIR/scripts" ]] && ss="$SCRIPT_DIR/scripts"
  [[ -z "$ss" && -d "$DOTFILES_DIR/.config/scripts" ]] && ss="$DOTFILES_DIR/.config/scripts"
  if [[ -n "$ss" ]]; then
    [[ -d "$HOME/.config/scripts" ]] && rm -rf "$HOME/.config/scripts"
    ln -sf "$ss" "$HOME/.config/scripts"
    find "$HOME/.config/scripts" -type f -exec chmod +x {} \; 2>/dev/null || true
    ok "Symlinked scripts"
  fi

  # ── Wallpapers ──
  if [[ -d "$DOTFILES_DIR/.config/wallpapers" ]]; then
    mkdir -p "$HOME/.config/wallpapers"
    cp -rn "$DOTFILES_DIR/.config/wallpapers/"* "$HOME/.config/wallpapers/" 2>/dev/null
    ok "Copied wallpapers"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 6 — Post-install setup
# ═══════════════════════════════════════════════════════════════════════════════
step_post() {
  title "Step 6: Post-Install Setup"

  # ── Wallpaper thumbnails ──
  if command -v magick &>/dev/null; then
    info "Generating wallpaper thumbnails..."
    local td="$HOME/.cache/quickshell/wallpaper_picker/thumbs"
    mkdir -p "$td"
    for img in "$HOME/.config/wallpapers/"*; do
      [[ -f "$img" ]] || continue
      local t="$td/$(basename "$img")"
      [[ -f "$t" ]] && continue
      magick "$img" -resize 200x200^ -gravity center -extent 200x200 "$t" 2>/dev/null || true
    done
    ok "Wallpaper thumbnails ready"
  fi

  # ── JetBrains Nerd Font ──
  if [[ ! -d "$HOME/.local/share/fonts/JetBrainsMono" ]]; then
    info "Installing JetBrains Nerd Font..."
    mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"
    if wget -q -O /tmp/JBM.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip; then
      unzip -q -o /tmp/JBM.zip -d "$HOME/.local/share/fonts/JetBrainsMono" 2>/dev/null
      rm /tmp/JBM.zip
      fc-cache -f "$HOME/.local/share/fonts/JetBrainsMono" >/dev/null 2>&1
      ok "JetBrains Nerd Font installed"
    else
      warn "Font download failed (no internet?)"
    fi
  else
    ok "JetBrains Nerd Font already present"
  fi

  # ── quickshell-overview ──
  if [[ -d "$DOTFILES_DIR/.config/quickshell/overview" && ! -d "$HOME/.config/quickshell/overview" ]]; then
    mkdir -p "$HOME/.config/quickshell"
    cp -r "$DOTFILES_DIR/.config/quickshell/overview" "$HOME/.config/quickshell/"
    ok "quickshell-overview deployed"
  fi

  # ── Auto-start in hyprland.conf ──
  local hc="$HOME/.config/hypr/hyprland.conf"
  if [[ -f "$hc" ]] && ! grep -q "quickshell.*mrtrotid" "$hc" 2>/dev/null; then
    if ask "Add Quickshell auto-start to hyprland.conf?" "y"; then
      {
        echo ""
        echo "# Trotid Shell"
        echo "exec-once = quickshell -c mrtrotid-shell &"
      } >> "$hc"
      ok "Auto-start added to hyprland.conf"
    fi
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
#  RUN PIPELINE
# ═══════════════════════════════════════════════════════════════════════════════
step_paru
step_packages
step_install
step_backup
step_deploy
step_post

# ═══════════════════════════════════════════════════════════════════════════════
#  SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════
title "All Done!"

echo -e "  ${GR}${B}✔ Trotid Shell is installed${R}"
echo
echo -e "  ${B}Next steps:${R}"
echo -e "    ${GY}1.${R} Log out and select Hyprland in your display manager"
echo -e "    ${GY}2.${R} Set wallpaper: ${CY}wallset${R}"
echo -e "    ${GY}3.${R} View keybinds: ${CY}Super + /${R}"
echo -e "    ${GY}4.${R} Open settings: ${CY}Super + I${R}"
echo -e "    ${GY}5.${R} Update shell: ${CY}Settings → About → Update Shell${R}"
echo
echo -e "  ${D}Issues? github.com/Noro18/linux-ricing-dotfiles${R}"
echo
