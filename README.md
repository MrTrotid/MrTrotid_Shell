# Trotid Shell

A modern, gesture-driven Wayland desktop shell built on Hyprland 0.55+ and Quickshell with Material You theming, singleton service architecture, and global IPC keybinds.

> **Disclaimer:** This is a custom desktop shell / "rice" — not a full desktop environment. It is designed for Arch-based systems with Hyprland and may require some manual setup depending on your hardware. The author is not responsible for any damage, data loss, or existential crises caused by using this configuration. Use at your own risk.

> **Note on Wayland:** This shell targets native Wayland compositors only (Hyprland). X11/XWayland fallbacks may work but are not tested or supported.

---

## Design Philosophy

- **Material You** — Colors generated from wallpaper using matugen (Material 3). Every UI element picks up the palette live, no manual color picking.
- **Keyboard-first** — Everything has a keybind. Super + / opens a searchable cheatsheet. No mouse required unless you want one.
- **Service-oriented** — Singleton QML services handle audio, brightness, network, battery, system monitoring, notifications, and theming. Popups are isolated PanelWindows with mutual exclusion.
- **Gesture-driven** — Bar auto-hides, popups slide/fade in, media card slides from the right, quick actions HUD slides from the bottom.
- **Live theme** — Change wallpaper and every themed element updates in real time via 2-second color polling.
- **Cross-machine** — Auto-detects monitors, GPU devices, VM vs physical hardware at install time.

---

## What's Included

| Feature | Description |
|---------|-------------|
| **Hyprland Lua config** | Full Lua-based config with modular `dofile()` includes |
| **Quickshell bar** | Auto-hiding top bar with workspaces, clock, system tray |
| **Notification system** | DBus server, grouped notifications, toast queue, persistence, action buttons |
| **Coverflow wallpaper picker** | Full-screen carousel with filter bar, thumbnails, live apply |
| **Quick Actions HUD** | Screenshot/recording shortcuts with keyboard navigation |
| **OSD** | Volume/brightness feedback with auto-hide |
| **Cheatsheet** | Searchable keybind reference with executable actions |
| **Clipboard manager** | cliphist integration with search and image preview |
| **Emoji picker** | 5 categories, search, click-to-copy |
| **GIF picker** | Tenor API search with hover preview |
| **Settings panel** | General settings + About tab with live update shell |
| **Workspace overview** | Visual workspace switcher with live previews |
| **Media card** | MPRIS player info, slides from right |
| **Calendar + Weather** | Click clock for calendar + weather popup |
| **Camera privacy** | Live indicator when `/dev/video0` is in use |
| **Night light** | hyprsunset toggle (Super + Shift + N) |
| **Power menu** | wlogout overlay with icon buttons |
| **CPU temperature** | Color-coded chip in bar (green/yellow/red) |
| **Network speed** | ↓/↑ KB/s or MB/s next to WiFi icon |
| **Battery warnings** | Low battery notification at configurable threshold |
| **Wallpaper theming** | wallust + matugen generate colors from wallpaper live |
| **Screenshots** | grim + slurp with multiple modes and annotation |
| **Screen recording** | wf-recorder with rofi audio picker |

---

## Keybinds

| Key | Action |
|-----|--------|
| `Super + Return` | Terminal (Ghostty) |
| `Super + Space` | App launcher (Rofi) |
| `Super + /` | Cheatsheet |
| `Super + P` | Power menu |
| `Super + A` | Notification panel |
| `Super + J` | Quick actions HUD |
| `Super + O` | Toggle bar |
| `Super + M` | Toggle media card |
| `Ctrl + Super + T` | Wallpaper picker |
| `Super + I` | Settings panel |
| `Super + V` | Clipboard manager |
| `Super + .` | Emoji picker |
| `Super + ,` | GIF picker |
| `Super + Tab` | Workspace overview |
| `Super + W` | Browser (Zen) |
| `Super + E` | File manager (Thunar) |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + G` | Toggle floating |
| `Super + S` | Scratchpad |
| `Super + 1-0` | Switch workspace |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + Shift + N` | Night light |
| `Super + Shift + P` | Lock screen |
| `Super + Shift + L` | Suspend |
| `Ctrl + Super + R` | Restart Quickshell |
| `Print` | Full screenshot |
| `Ctrl + Print` | Region screenshot |
| `Shift + Print` | Window screenshot |
| `Ctrl + Shift + Print` | Annotate screenshot |
| `Ctrl + Shift + R` | Region recording |
| `Ctrl + Alt + R` | Full recording |
| `Super + Shift + C` | Color picker |

Full list in `dotfiles/.config/hypr/configurations/keybinds.lua` or press `Super + /`.

---

## Installation

### Requirements
- Arch-based Linux distribution (pacman)
- Hyprland 0.55+
- An active internet connection

### Fresh Install

```bash
git clone https://github.com/MrTrotid/MrTrotid_Shell ~/Desktop/MrTrotid_Shell
cd ~/Desktop/MrTrotid_Shell
chmod +x install.sh && ./install.sh
```

The installer is fully interactive:
1. **AUR Helper** — Installs paru (or detects existing yay/paru)
2. **Package Selection** — Choose terminal, browser, editor, file manager
3. **Backup** — Existing configs saved to `~/.config.bak-<timestamp>/`
4. **Install** — All repo + AUR packages in one pass, tracks failures
5. **Deploy** — Dotfiles, symlinks, bin scripts, wallpapers
6. **Post-Setup** — Generates wallpaper thumbnails, installs JetBrains Nerd Font
7. **Monitor Config** — Auto-detects connected displays + VM detection
8. **Display Manager** — Optionally enables SDDM/GDM/LightDM

### Post-Install

```bash
# Log out and into Hyprland, then:
wallset                    # Set initial wallpaper (triggers theming)
Super + /                  # Open cheatsheet
Super + I                  # Open settings
```

### Updating

From the Settings panel (Super + I → About tab → Update Shell):
1. Click **Check Updates** to see commits behind
2. Click **Update Now** to pull latest
3. Click **Restart Shell** to apply

Or manually:
```bash
cd ~/Desktop/MrTrotid_Shell && git pull
```

---

## Architecture

```
Hyprland (compositor)
├── hyprland.lua           # Main Lua config
├── configurations/keybinds.lua  # All keybinds (single file)
├── monitors.lua           # Auto-generated monitor config
├── windowrules.lua        # Window/layer rules
└── colors/colors.lua      # Color variables

Quickshell (desktop shell)
└── mrtrotid-shell/
    ├── shell.qml           # Entry point — all PanelWindows
    ├── BarContent.qml      # Status bar
    ├── services/           # Singleton services
    │   ├── ShellState.qml  # Popup state management
    │   ├── AudioService.qml
    │   ├── BrightnessService.qml
    │   ├── VolumeService.qml
    │   ├── NetworkService.qml
    │   ├── BatteryService.qml
    │   ├── SystemService.qml
    │   ├── NotificationService.qml
    │   └── ColorService.qml
    └── widgets/            # Popup widgets
        ├── Cheatsheet.qml
        ├── ClipboardManager.qml
        ├── EmojiPicker.qml
        ├── GifPicker.qml
        ├── MediaCard.qml
        ├── NotificationPanel.qml
        ├── NotificationPopup.qml
        ├── OsdPopup.qml
        ├── QuickActions.qml
        ├── SettingsPopup.qml
        ├── WallpaperPicker.qml
        └── ...

Overview (workspace switcher)
└── ~/.config/quickshell/overview/   # Config override
```

### Theme Pipeline

```
1. Wallpaper set → wallset-backend
2. swaybg applies wallpaper
3. wallust generates terminal colors (Kitty, Hyprland)
4. matugen generates Material You colors (colors.json)
5. ColorService polls colors.json every 2s
6. All QML components update via property bindings
```

### Key Design Decisions

- **Lua config over hyprlang** — hyprland.lua is the primary config; hyprland.conf is auto-removed if both exist
- **Each popup is its own PanelWindow** with `exclusiveZone: 0`
- **Singleton services** with `pragma Singleton` — registered in `qmldir`
- **activePopup pattern** — only one popup visible at a time
- **Global IPC** — keybinds trigger shell actions via `global, quickshell:<action>`
- **Process + cat for ColorService** — FileView doesn't detect atomic file rewrites
- **pkill -x over killall** — killall matches partial names, causing collateral damage
- **VM detection** — monitor config auto-detects VM type and generates appropriate fallback
- **GPU group check** — script verifies user is in `video`/`render` groups for DRM access

---

## Project Structure

```
MrTrotid_Shell/
├── install.sh                       # Interactive installer
├── reload.sh                        # Quickshell hot-reload
├── start-trotid.sh                  # Hyprland test launch
├── AGENTS.md                        # AI/agent guidance
├── dotfiles/
│   └── .config/
│       ├── hypr/                    # Hyprland config (Lua)
│       │   ├── hyprland.lua
│       │   ├── monitors.lua
│       │   ├── windowrules.lua
│       │   ├── colors/
│       │   └── configurations/
│       ├── quickshell/
│       │   ├── mrtrotid-shell/      # Main shell QML
│       │   └── overview/            # Workspace overview override
│       ├── rofi/                    # Launchers + applets
│       ├── kitty/                   # Terminal config
│       ├── wallpapers/              # Wallpaper images
│       └── local/bin/               # Scripts (wallset, etc.)
├── scripts/                         # Screenshot, recording helpers
├── wlogout/                         # Power menu layout
└── docs/
    ├── architecture.md
    ├── file-structure.md
    ├── keybinds.md
    ├── scripts.md
    ├── theming-pipeline.md
    ├── services/                    # Per-service documentation
    └── components/                  # Per-component documentation
```

---

## Requirements

| Component | Min Version | Notes |
|-----------|-------------|-------|
| Hyprland | 0.55+ | Lua config syntax required |
| Quickshell | 0.3.0 | AUR (paru handles this) |
| matugen | latest | Material You color generation |
| wallust | latest | Terminal color generation |
| Qt 6 | 6.5+ | Quickshell dependency |
| swaybg | latest | Wallpaper setter |

Other dependencies installed automatically: `wl-clipboard`, `cliphist`, `playerctl`, `brightnessctl`, `grim`, `slurp`, `hyprpicker`, `swappy`, `wf-recorder`, `rofi`, `ImageMagick`, `jq`, `polkit-kde-agent`, `gnome-keyring`, `pipewire`, `wireplumber`, `hypridle`, `hyprlock`, `hyprsunset`.

---

## Changes from Upstream

This shell is a fork/evolution of [Noro18/linux-ricing-dotfiles](https://github.com/Noro18/linux-ricing-dotfiles). Key changes:

- **Lua-first**: Fully ported from hyprlang to Lua API. hyprland.conf is deprecated and auto-removed.
- **Cross-machine**: Installer auto-detects monitors, GPU groups, VM type. No more hardcoded eDP-1+HDMI-A-1.
- **Cleaner scripts**: Removed `kill -USR1` for ghostty (crashed terminals), removed killall (uses pkill -x), removed developer home paths.
- **Fixed QML errors**: `ReferenceError` bugs in Cheatsheet (modelData.binds, hScrollBarMa) and shell.qml (exitCode) fixed.
- **Structured quickshell**: Config now lives in `mrtrotid-shell/` subdirectory to match quickshell's `-c` convention.
- **Package tracking**: Failed packages are reported at the end of install instead of silent failure.
- **VM support**: systemd-detect-virt + per-VM monitor fallbacks (VirtualBox, QEMU/KVM, VMware, Hyper-V).
- **Hyprland API correctness**: `hl.workspace()` → `hl.workspace_rule()`, `hl.dsp.togglefloating()` → `hl.dsp.window.float()`, `curve` → `bezier` in animation specs, `{800,600}` → `"800 600"` in window rules.

---

## Troubleshooting

### Quickshell won't start
```bash
# Check the config path resolves correctly
quickshell -c mrtrotid-shell -v

# Check logs
journalctl --user -u quickshell -f
quickshell -c mrtrotid-shell log
```

### Hyprland config errors
```bash
hyprctl configerrors
lua ~/.config/hypr/hyprland.lua
```

### Colors not updating
```bash
# Ensure matugen is installed and colors.json exists
ls -la ~/.cache/quickshell/colors.json

# Check ColorService polling
quickshell -c mrtrotid-shell log | grep -i color
```

### Wallpaper picker not applying
- Uses `$HOME/.local/bin/wallset-backend` (full path required for execDetached)
- If picker freezes, check `sudo -n true` (wallset-backend tries sudo for SDDM copy)

### Overview not responding
```bash
pkill -f "qs -c overview" && nohup qs -c overview > /dev/null 2>&1 & disown
```

---

## Credits

- **Compositor** — [Hyprland](https://hyprland.org/)
- **QML Framework** — [Quickshell](https://github.com/outfoxxed/quickshell)
- **Original dotfiles** — [Noro18/linux-ricing-dotfiles](https://github.com/Noro18/linux-ricing-dotfiles)
- **Material You Colors** — [matugen](https://github.com/InioX/matugen) by InioX
- **Terminal Colors** — [wallust](https://github.com/explosion-mental/wallust)
- **Workspace Overview** — [quickshell-overview](https://github.com/Shanu-Kumawat/quickshell-overview) by Shanu-Kumawat
- **Calendar, Bluetooth, WiFi popups** — inspired by [ilyamiro/nixos-configuration](https://github.com/ilyamiro/nixos-configuration)
- **Notification panel** — inspired by nandoroid
- **Coverflow wallpaper picker** — inspired by ilyamiro's wallpaper carousel
- **GIF search** — Tenor API (Google)
- **Rofi themes** — [adi1090x/rofi](https://github.com/adi1090x/rofi)
- **Nerd Font** — [ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts)

---

## License

This project is provided as-is. Use it, modify it, share it. If you build something cool with it, a shoutout would be nice.

---

*Made with way too much caffeine and an unhealthy obsession with pixel-perfect theming.*
