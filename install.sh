#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════════
#  TROTID SHELL — Automated Installer
#  Interactive TUI installer for Hyprland + Quickshell desktop shell
#  Usage: chmod +x install.sh && ./install.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

FAILED_PKGS=()

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
  local msg="$1"
  local yn
  while true; do
    echo -ne "  ${CY}?${R}  ${msg} ${GY}[Y/n]${R} "
    read -r yn
    [[ -z "$yn" ]] && yn="y"
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
  wait "$pid"
  local rc=$?
  if [[ $rc -eq 0 ]]; then
    echo -e "\r  ${GR}✔${R}  ${msg}"
  else
    echo -e "\r  ${RED}✘${R}  ${msg} ${GY}(failed)${R}"
  fi
  return $rc
}

# ── Safety ──
if [[ $EUID -eq 0 ]]; then
  echo -e "\n  ${BG_R}${WH} ERROR ${R} ${RED}Do not run as root. Run as a normal user.${R}"
  exit 1
fi

logo

if ! command -v pacman &>/dev/null; then
  warn "This installer requires an Arch-based distribution (pacman)."
  ask "Continue anyway?" || exit 1
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

# ── GPU device access check ──
title "GPU Access Check"
dri_ok=true
for d in /dev/dri/renderD* /dev/dri/card*; do
  [[ -c "$d" ]] || continue
  if ! [[ -r "$d" && -w "$d" ]]; then
    dri_ok=false
    break
  fi
done
if ! $dri_ok; then
  warn "No GPU device access detected. Adding user to 'video' and 'render' groups..."
  sudo usermod -aG video,render "$USER"
  warn "You'll need to log out and back in before Hyprland will work."
  warn "(Or run: ${B}exec su -l $USER${R} to apply groups immediately)"
else
  ok "GPU device access OK"
fi

ask "Begin installing Trotid Shell?" || exit 0

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 1 — Install paru
# ═══════════════════════════════════════════════════════════════════════════════
step_paru() {
  title "Step 1: AUR Helper (paru)"

  if $HAS_PARU; then
    ok "paru already installed"
    ask "Reinstall paru?" || return 0
  elif $HAS_YAY; then
    AUR_HELPER="yay"
    ok "Using existing yay instead of paru"
    return 0
  fi

  ask "Install paru (AUR helper)?" || { warn "Skipping. AUR packages must be installed manually."; return 1; }

  local tmp
  tmp=$(mktemp -d) || { fail "Cannot create temp dir"; return 1; }

  info "Installing build dependencies..."
  if ! sudo pacman -S --needed --noconfirm base-devel git 2>/dev/null; then
    warn "Build deps may have partial failures. Continuing..."
  fi

  # Try pre-compiled paru-bin first (fast, ~5 seconds)
  info "Cloning paru-bin (pre-compiled, fast)..."
  if git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$tmp/paru" 2>/dev/null; then
    (cd "$tmp/paru" && makepkg -si --noconfirm) &
    local pid=$!
    spinner "$pid" "Building paru-bin"
  else
    warn "Failed to clone paru-bin. Trying source build..."
  fi

  # If paru-bin failed, try source build
  if ! command -v paru &>/dev/null; then
    warn "paru-bin failed. Source build takes a few minutes (Rust compilation)."
    ask "Try source build of paru instead?" || {
      echo
      echo -e "  ${GY}Install paru manually later:${R}"
      echo -e "    ${B}sudo pacman -S --needed base-devel git${R}"
      echo -e "    ${B}git clone https://aur.archlinux.org/paru.git${R}"
      echo -e "    ${B}cd paru && makepkg -si${R}"
      echo
      rm -rf "$tmp"
      ask "Continue without AUR helper?" || exit 1
      return 1
    }
    info "Cloning paru (aur.archlinux.org/paru)..."
    if ! git clone --depth=1 https://aur.archlinux.org/paru.git "$tmp/paru" 2>/dev/null; then
      fail "Failed to clone paru."
      rm -rf "$tmp"
      return 1
    fi
    (cd "$tmp/paru" && makepkg -si --noconfirm) &
    local pid=$!
    spinner "$pid" "Building paru from source"
  fi

  rm -rf "$tmp"

  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"; HAS_PARU=true
    ok "paru installed successfully"
    return 0
  else
    fail "paru installation failed."
    ask "Continue without AUR helper?" || exit 1
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 2 — Detect installed & choose packages
# ═══════════════════════════════════════════════════════════════════════════════
pkg_installed() { pacman -Qi "$1" &>/dev/null; }

CORE_PKGS=(
  hyprland
  hypridle
  hyprlock
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
  polkit-kde-agent
  gnome-keyring
  pipewire
  wireplumber
  pipewire-pulse
  qt6ct
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
  matugen-bin
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
  pick "" "zen-browser-bin (recommended, pre-compiled)" "brave-browser" "firefox" "chromium" "Skip"
  local br_choice=$?
  local BROWSER=""
  case $br_choice in
    1) BROWSER="zen-browser-bin" ;;
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
  ask "Install file manager (thunar)?" && { FILE_MGR="thunar"; ok "File manager: ${B}thunar${R}"; } || true

  # ── Assemble package list ──
  ALL_PKGS=("${CORE_PKGS[@]}")
  [[ -n "$TERMINAL" ]] && ALL_PKGS+=("$TERMINAL")
  [[ -n "$BROWSER" ]]   && ALL_PKGS+=("$BROWSER")
  [[ -n "$EDITOR_PKG" ]] && ALL_PKGS+=("$EDITOR_PKG")
  [[ -n "$FILE_MGR" ]]  && ALL_PKGS+=("$FILE_MGR")

  # ── Extra packages (not auto-installed) ──
  echo
  echo -e "  ${GY}Optional extras (install manually if needed):${R}"
  for ((i=0; i<${#EXTRA_PKGS[@]}; i+=2)); do
    local ep="${EXTRA_PKGS[i]}"
    local ed="${EXTRA_PKGS[i+1]}"
    echo -e "    ${GY}•${R} ${B}$ep${R} — ${GY}$ed${R}"
  done
  echo -e "  ${GY}  → ${R}${D}sudo pacman -S cava pavucontrol nm-connection-editor btop${R}"
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
  ask "Install missing packages?" || { warn "Skipping package installation"; return 0; }

  local helper="${AUR_HELPER:-paru}"
  if ! command -v "$helper" &>/dev/null; then
    fail "AUR helper ($helper) not found. Install paru first or manually."
    return 1
  fi

  # ── Split into repo vs AUR packages ──
  local KNOWN_AUR=("quickshell" "wallust" "matugen-bin" "ghostty" "zen-browser-bin" "visual-studio-code-bin")
  local REPO_NEED=() AUR_NEED=()
  local pkg
  for pkg in "${NEED[@]}"; do
    local is_aur=false
    for aur in "${KNOWN_AUR[@]}"; do
      [[ "$pkg" == "$aur" ]] && { is_aur=true; break; }
    done
    $is_aur && AUR_NEED+=("$pkg") || REPO_NEED+=("$pkg")
  done

  # ── Install repo packages via pacman first (always works) ──
  if [[ ${#REPO_NEED[@]} -gt 0 ]]; then
    info "Installing repo packages..."
    muted "${REPO_NEED[*]}"
    sudo pacman -S --needed --noconfirm "${REPO_NEED[@]}" || {
      warn "Some repo packages failed"
      for pkg in "${REPO_NEED[@]}"; do
        pkg_installed "$pkg" || FAILED_PKGS+=("$pkg")
      done
      ask "Continue anyway?" || return 1
    }
  fi

  # ── Install AUR packages via helper ──
  if [[ ${#AUR_NEED[@]} -gt 0 ]]; then
    local helper="${AUR_HELPER:-paru}"
    if ! command -v "$helper" &>/dev/null; then
      fail "AUR helper ($helper) not found. Skipping AUR packages: ${AUR_NEED[*]}"
    else
      # Resolve matugen-bin conflicts: remove source matugen first if installed
      if pkg_installed matugen 2>/dev/null && [[ " ${AUR_NEED[*]} " =~ " matugen-bin " ]]; then
        warn "Removing source matugen to avoid conflict with matugen-bin..."
        sudo pacman -Rdd --noconfirm matugen 2>/dev/null || sudo pacman -R --noconfirm matugen 2>/dev/null || true
      fi

      info "Installing AUR packages via $helper..."
      muted "${AUR_NEED[*]}"
      $helper -S --needed --noconfirm "${AUR_NEED[@]}" || {
        warn "Some AUR packages failed"
        for pkg in "${AUR_NEED[@]}"; do
          pkg_installed "$pkg" || FAILED_PKGS+=("$pkg")
        done
        ask "Continue anyway?" || return 1
      }
    fi
  fi

  ok "Package installation complete"

  # ── Verify hyprland is installed ──
  if ! pkg_installed hyprland; then
    warn "Hyprland was NOT installed. The compositor is required."
    ask "Continue anyway? (you'll need to install hyprland manually)" || exit 1
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

  ask "Back up configs before deploying?" || { warn "Skipping backup"; return 0; }

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

  ask "Deploy configuration files?" || { warn "Skipping deployment"; return 0; }

  # ── Quickshell (symlink choice) ──
  if ask "Symlink quickshell config? ${GY}(enables live QML hot-reload)${R}"; then
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
        if ask "Replace ${B}$name${R} config?"; then
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

  # ── Prefer Lua config over Hyprlang .conf ──
  if [[ -f "$HOME/.config/hypr/hyprland.lua" && -f "$HOME/.config/hypr/hyprland.conf" ]]; then
    info "Both hyprland.lua and hyprland.conf found — auto-removing .conf to prefer Lua config."
    rm "$HOME/.config/hypr/hyprland.conf"
    ok "Removed hyprland.conf — Lua config will be used"
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
  if fc-list | grep -qi "JetBrainsMonoNerd" &>/dev/null; then
    ok "JetBrains Nerd Font already installed"
  else
    info "Installing JetBrains Nerd Font..."
    mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"

    local JBM_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    if command -v curl &>/dev/null; then
      curl -LfsS --connect-timeout 30 --max-time 120 -o /tmp/JBM.zip "$JBM_URL" 2>/dev/null
    else
      wget -q --timeout=30 -O /tmp/JBM.zip "$JBM_URL" 2>/dev/null
    fi

    if [[ -f /tmp/JBM.zip ]] && unzip -q -o /tmp/JBM.zip -d "$HOME/.local/share/fonts/JetBrainsMono" 2>/dev/null; then
      rm -f /tmp/JBM.zip
      fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1
      ok "JetBrains Nerd Font installed"
    else
      warn "Font download failed. Trying fallback URL..."
      rm -f /tmp/JBM.zip
      # Fallback: use specific version tag
      local JBM_URL_FALLBACK="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip"
      if command -v curl &>/dev/null; then
        curl -LfsS --connect-timeout 30 --max-time 120 -o /tmp/JBM.zip "$JBM_URL_FALLBACK" 2>/dev/null
      else
        wget -q --timeout=30 -O /tmp/JBM.zip "$JBM_URL_FALLBACK" 2>/dev/null
      fi
      if [[ -f /tmp/JBM.zip ]] && unzip -q -o /tmp/JBM.zip -d "$HOME/.local/share/fonts/JetBrainsMono" 2>/dev/null; then
        rm -f /tmp/JBM.zip
        fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1
        ok "JetBrains Nerd Font installed (fallback URL)"
      else
        warn "Font download failed entirely. Install manually:"
        warn "  ${B}https://www.nerdfonts.com/font-downloads${R}"
      fi
    fi
  fi

  # ── quickshell-overview ──
  if [[ -d "$DOTFILES_DIR/.config/quickshell/overview" && ! -d "$HOME/.config/quickshell/overview" ]]; then
    mkdir -p "$HOME/.config/quickshell"
    cp -r "$DOTFILES_DIR/.config/quickshell/overview" "$HOME/.config/quickshell/"
    ok "quickshell-overview deployed"
  fi

  # ── Auto-start in hyprland config ──
  local hypr_cfg=""
  for f in "hyprland.conf" "hyprland.lua"; do
    [[ -f "$HOME/.config/hypr/$f" ]] && { hypr_cfg="$HOME/.config/hypr/$f"; break; }
  done
  if [[ -n "$hypr_cfg" ]] && ! grep -q "quickshell.*mrtrotid" "$hypr_cfg" 2>/dev/null; then
    if ask "Add Quickshell auto-start to your Hyprland config?"; then
      if [[ "$hypr_cfg" == *.lua ]]; then
        echo "" >> "$hypr_cfg"
        echo "-- Trotid Shell" >> "$hypr_cfg"
        echo "hl.exec_cmd(\"quickshell -c mrtrotid-shell &\")" >> "$hypr_cfg"
      else
        echo "" >> "$hypr_cfg"
        echo "# Trotid Shell" >> "$hypr_cfg"
        echo "exec-once = quickshell -c mrtrotid-shell &" >> "$hypr_cfg"
      fi
      ok "Auto-start added to $(basename "$hypr_cfg")"
    fi
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 7 — Hardware detection and monitor config generation
# ═══════════════════════════════════════════════════════════════════════════════
step_monitors() {
  title "Step 7: Hardware Detection"

  # ── GPU info ──
  if command -v lspci &>/dev/null; then
    local gpu; gpu=$(lspci 2>/dev/null | grep -iE "vga|3d|display" | head -1 | sed 's/.*: //')
    [[ -n "$gpu" ]] && info "GPU: ${B}$gpu${R}"
  fi

  # ── Detect connected DRM outputs ──
  local outputs=()
  for dev in /sys/class/drm/card*-*/status; do
    [[ ! -f "$dev" ]] && continue
    local name; name=$(basename "$(dirname "$dev")")
    name="${name#card*-}"
    [[ -z "$name" || "$name" == "card"* ]] && continue
    local status; status=$(cat "$dev" 2>/dev/null)
    [[ "$status" == "connected" ]] && outputs+=("$name")
  done

  if [[ ${#outputs[@]} -eq 0 ]]; then
    ok "Auto-detection fallback will handle monitor configuration"
    return 0
  fi

  info "Detected ${#outputs[@]} monitor(s): ${B}${outputs[*]}${R}"

  # ── Check if shipped config matches detected hardware ──
  local hypr_dir="$HOME/.config/hypr"
  local ml="$hypr_dir/monitors.lua"
  local mc="$hypr_dir/monitors.conf"

  if [[ -f "$ml" ]]; then
    local needs_update=false
    for out in "${outputs[@]}"; do
      if ! grep -qF "$out" "$ml" 2>/dev/null; then
        needs_update=true
        break
      fi
    done

    if $needs_update; then
      info "Shipped monitor config doesn't match your hardware — generating new one."
      # ── Generate monitors.lua ──
      {
        echo "-- Monitor configuration for Trotid Shell"
        echo "-- Auto-generated by installer"
        echo ""
        echo "for _, m in ipairs({"
        local x=0
        for out in "${outputs[@]}"; do
          echo "    { output = \"$out\", mode = \"preferred\", position = \"${x}x0\", scale = 1.0 },"
          x=$((x + 1920))
        done
        echo "}) do"
        echo "    hl.monitor(m)"
        echo "end"
        echo ""
        local i=1
        for out in "${outputs[@]}"; do
          local def="false"
          [[ $i -eq 1 ]] && def="true"
          echo "hl.workspace({ id = $i, monitor = \"$out\", default = $def })"
          i=$((i+1))
        done
      } > "$ml"

      # ── Generate monitors.conf ──
      {
        echo "# Monitor configuration — auto-generated by installer"
        echo ""
        for out in "${outputs[@]}"; do
          echo "monitor=$out,preferred,auto,1"
        done
        echo ""
        echo "# Catch-all fallback"
        echo "monitor=,preferred,auto,1"
      } > "$mc"

      ok "Generated monitor config for: ${outputs[*]}"
    fi
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 8 — Display Manager Auto-Start
# ═══════════════════════════════════════════════════════════════════════════════
step_autostart() {
  title "Step 8: Hyprland Startup"

  # Detect installed display managers (in priority order)
  local dms=()
  systemctl is-enabled sddm.service &>/dev/null 2>&1 && dms+=("sddm")
  systemctl is-enabled gdm.service &>/dev/null 2>&1 && dms+=("gdm")
  systemctl is-enabled lightdm.service &>/dev/null 2>&1 && dms+=("lightdm")
  systemctl is-enabled lxdm.service &>/dev/null 2>&1 && dms+=("lxdm")

  if [[ ${#dms[@]} -eq 0 ]]; then
    # Check if any DM is installed (but not enabled)
    for svc in sddm.service gdm.service lightdm.service lxdm.service; do
      systemctl list-unit-files "$svc" &>/dev/null 2>&1 && { dms+=("${svc%.service}"); break; }
    done
  fi

  if [[ ${#dms[@]} -eq 0 ]]; then
    warn "No display manager detected. You'll need one to start Hyprland from a login screen."
    if ask "Install SDDM (recommended)?"; then
      sudo pacman -S --needed --noconfirm sddm && {
        sudo systemctl enable sddm.service
        ok "SDDM installed and enabled for auto-start"
      }
    fi
    return 0
  fi

  local dm="${dms[0]}"
  info "Detected display manager: ${B}$dm${R}"

  if ask "Enable ${B}$dm${R} to start Hyprland automatically at boot?"; then
    if sudo systemctl enable "$dm.service" 2>/dev/null; then
      ok "$dm enabled — Hyprland will appear in the session list at login"
    else
      warn "Failed to enable $dm"
      ask "Continue anyway?" || return 1
    fi
  else
    info "Skipped. You can enable manually later: ${CY}sudo systemctl enable $dm${R}"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
#  RUN PIPELINE
# ═══════════════════════════════════════════════════════════════════════════════
step_paru
step_packages
step_backup
step_install
step_deploy
step_post
step_monitors
step_autostart

# ── Failed packages report ──
if [[ ${#FAILED_PKGS[@]} -gt 0 ]]; then
  echo
  echo -e "  ${YE}${B}┌─ Failed Packages ─────────────────────────────────┐${R}"
  echo -e "  ${YE}${B}│${R}  The following packages failed to install:"
  for pkg in "${FAILED_PKGS[@]}"; do
    echo -e "  ${YE}${B}│${R}    ${GY}•${R} ${B}$pkg${R}"
  done
  echo -e "  ${YE}${B}│${R}"
  echo -e "  ${YE}${B}│${R}  Install them manually:"
  echo -e "  ${YE}${B}│${R}    ${B}sudo pacman -S ${FAILED_PKGS[*]}${R}"
  echo -e "  ${YE}${B}└────────────────────────────────────────────────────┘${R}"
  echo
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════
title "All Done!"

echo -e "  ${GR}${B}✔ Trotid Shell is installed${R}"
echo
echo -e "  ${B}Next steps:${R}"
echo -e "    ${GY}1.${R} Reboot or select Hyprland in your display manager"
echo -e "    ${GY}2.${R} Set wallpaper: ${CY}wallset${R}"
echo -e "    ${GY}3.${R} View keybinds: ${CY}Super + /${R}"
echo -e "    ${GY}4.${R} Open settings: ${CY}Super + I${R}"
echo -e "    ${GY}5.${R} Update shell: ${CY}Settings → About → Update Shell${R}"
echo
echo -e "  ${D}Issues? github.com/MrTrotid/MrTrotid_Shell${R}"
echo
