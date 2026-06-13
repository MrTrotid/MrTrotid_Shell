# Trotid Shell

A custom Hyprland + Quickshell desktop shell with singleton service architecture, global IPC keybinds, Material You theming, Lua-based Hyprland config, and unified cheatsheet generation.

## Quick Start

```bash
# Clone and install (Arch-based systems)
git clone https://github.com/MrTrotid/MrTrotid_Shell ~/Desktop/MrTrotid_Shell
cd ~/Desktop/MrTrotid_Shell
chmod +x install.sh && ./install.sh
```

The installer handles everything:
- Installs **paru** (AUR helper) from `paru-bin`
- Interactive TUI for choosing terminal, browser, editor, file manager, extras
- Installs ALL packages (repo + AUR) through paru in one pass
- Backs up existing configs, deploys dotfiles, runs post-setup (GTK themes, fonts, services)

```bash
# After logging into Hyprland:
wallset                    # Set wallpaper (triggers theming pipeline)
Super + /                  # View keybind cheatsheet
Super + I                  # Open settings panel
```

**Prerequisites:** Arch-based Linux (pacman). Everything else is handled by the installer.

## What's Included

- **Hyprland 0.55+** with Lua config syntax, scroll layout, gestures, layerrules
- **Quickshell** - singleton services, global IPC, Wayland layer shell
- **Material You** color scheme via matugen (auto-generates M3 colors from wallpaper)
- **Notification system** with DBus server, grouped notifications, toasts, action buttons, urgency styling, persistence
- **Coverflow wallpaper picker** with thumbnails and filter bar
- **Quick Actions HUD** with keyboard navigation and executable actions
- **OSD** for volume/brightness/mic feedback
- **Cheatsheet** - searchable keybind reference with executable actions
- **Clipboard manager** - native Quickshell widget with cliphist integration, search/filter, image preview
- **Emoji picker** - native Quickshell widget with 5 categories, search, click to copy
- **GIF selector** - native Quickshell widget with Tenor API search (plays on hover)
- **Night light toggle** via hyprsunset
- **Settings panel** - floating centered panel with General/About sections, Update Shell (auto-detects git repo), system info (OS, kernel, GPU, CPU, memory)
- **Camera privacy indicator** - polls `/dev/video0` via `fuser` every 3s
- **Power menu** - wlogout with HyprNova-style icon buttons
- **CPU temperature chip** - color-coded (green/yellow/red) in bar
- **Network speed indicator** - ↓/↑ KB/s or MB/s
- **Low battery notification** - warns at configurable threshold (default 20%)
- **Workspace overview** - visual overview with live previews (Super+Tab)

## Quick Reference

| Key | Action |
|-----|--------|
| `Super + Return` | Terminal (Ghostty) |
| `Super + Space` | App launcher (Rofi) |
| `Super + /` | Toggle Cheatsheet |
| `Super + P` | Toggle power menu (wlogout) |
| `Super + A` | Toggle notification panel |
| `Super + J` | Toggle quick actions HUD |
| `Super + O` | Toggle bar |
| `Super + M` | Toggle media card |
| `Ctrl + Super + T` | Toggle wallpaper picker |
| `Super + I` | Toggle settings panel |
| `Super + V` | Toggle clipboard manager |
| `Super + .` | Toggle emoji picker |
| `Super + ,` | Toggle GIF picker |
| `Super + Tab` | Toggle workspace overview |
| `Super + W` | Browser (Zen) |
| `Super + E` | File manager (Thunar) |
| `Super + Shift + N` | Toggle night light |
| `Super + Shift + P` | Lock screen |
| `Super + Shift + L` | Suspend |
| `Ctrl + Super + R` | Restart Quickshell |
| `Print/Ctrl/Shift/Alt + Print` | Screenshot modes |
| `Ctrl + Shift + R` | Region record / stop |
| `Ctrl + Alt + R` | Full record / stop |

Full keybind list: see `hypr/configurations/keybinds.lua` or press `Super + /` in-shell.

## Requirements

| Component | Notes |
|-----------|-------|
| Hyprland 0.55+ | Lua config syntax |
| Quickshell 0.3.0+ | AUR via paru |
| matugen + wallust | Material You + terminal colors |
| Qt 6 | Quickshell dependency |
| swaybg | wallpaper setter |

**Install helper:** `wl-clipboard`, `cliphist`, `playerctl`, `wpctl`, `brightnessctl`, `grim`, `slurp`, `hyprpicker`, `swappy`, `wf-recorder`, `rofi`, `ImageMagick`, `xdg-desktop-portal-hyprland` — all handled by the installer.

## Project Structure

```
Trotid_Shell/
├── hypr/                              # Hyprland configuration (Lua)
│   ├── hyprland.lua                   # Main entry — env, input, general, decoration,
│   │                                  #   animations, gestures, autostart
│   ├── monitors.lua                   # Monitor specs + workspace assignments
│   ├── colors/colors.lua              # Material You color variable globals
│   ├── configurations/keybinds.lua    # All keybindings (single file for cheatsheet)
│   └── windowrules.lua                # Window rules + layer rules
├── quickshell/                        # Quickshell configuration
│   ├── shell.qml                      # Root — all PanelWindows + GlobalShortcuts
│   ├── BarContent.qml                 # Bar layout (binds to singleton services)
│   ├── core/
│   │   └── NotificationUtils.js       # Time formatting and icon mapping
│   ├── services/                      # Singleton services (pragma Singleton + qmldir)
│   │   ├── ShellState.qml             # UI toggle states (activePopup pattern)
│   │   ├── AudioService.qml           # wpctl parsing, sink switching, mic
│   │   ├── BrightnessService.qml      # Brightness polling + control
│   │   ├── VolumeService.qml          # Volume from AudioService
│   │   ├── NetworkService.qml         # nmcli monitoring + speed from /proc
│   │   ├── BatteryService.qml         # UPower + sysfs
│   │   ├── SystemService.qml          # CPU + memory + temp from /proc
│   │   ├── NotificationService.qml    # DBus notification server
│   │   ├── ColorService.qml           # matugen colors.json reader
│   │   └── qmldir                     # Singleton declarations
│   ├── widgets/                       # Popup widgets
│   │   ├── BluetoothSelector.qml
│   │   ├── WifiSelector.qml
│   │   ├── CalendarPopup.qml
│   │   ├── NotificationPanel.qml      # Grouped notifications
│   │   ├── NotificationPopup.qml      # Toast notifications (ListModel, max 3)
│   │   ├── WallpaperPicker.qml        # Coverflow carousel with thumbnails
│   │   ├── QuickActions.qml           # Bottom-center floating action bar
│   │   ├── Cheatsheet.qml             # Searchable keybind reference
│   │   ├── OsdPopup.qml               # Volume/brightness OSD
│   │   ├── ClipboardManager.qml       # cliphist integration
│   │   ├── EmojiPicker.qml            # 5 categories, search, copy
│   │   ├── GifPicker.qml              # Tenor API search
│   │   ├── PowerMenu.qml              # Centered power overlay
│   │   ├── MediaCard.qml
│   │   ├── PlayerCard.qml
│   │   ├── SettingsPopup.qml          # Settings panel with Update Shell
│   │   └── WaveVisualizer.qml
│   ├── calendar/                      # Weather scripts + .env config
│   └── functions/
│       └── ColorUtils.qml             # Color utilities
├── scripts/                           # Helper scripts (symlinked to ~/.config/scripts)
├── wlogout/                           # wlogout power menu layout
├── dotfiles/.config/                  # Deployable config files
├── install.sh                         # Interactive TUI installer
├── reload.sh                          # Quick reload helper
└── start-trotid.sh                    # Launch script for testing
```

## Services

All services live in `quickshell/services/` with `pragma Singleton` + `qmldir` entry.

| Service | Description |
|---------|-------------|
| ShellState | UI toggle states (activePopup mutual exclusion) |
| ColorService | Reads matugen colors.json via Process + cat (2s polling) |
| AudioService | wpctl parsing, sink switching, Bluetooth auto-switch, mic parsing |
| BrightnessService | Brightness polling (200ms) + control |
| VolumeService | Volume from AudioService, debounced refresh |
| NetworkService | nmcli monitoring with SSID escaping, /proc/net/dev speed |
| BatteryService | UPower + sysfs, hasBattery guard, low battery notification |
| SystemService | CPU + memory + temperature from /proc (2s poll) |
| NotificationService | DBus notification server, grouped, toasts, persistence |

## Architecture

- **Hyprland config in Lua** (`hyprland.lua`) — all settings via `hl.config()`, `hl.bind()`, `hl.window_rule()`, `hl.animation()`, etc. Modular via `dofile()` for monitors, keybinds, colors, window rules
- **Each popup is its own PanelWindow** with `exclusiveZone: 0`
- **Popup click-outside-to-close** via cursor position monitoring
- **Global IPC** for shell toggles (`global, quickshell:<action>`)
- **Single NotificationServer** in NotificationService singleton
- **ColorService** reads matugen JSON via Process + cat (2s polling) — FileView doesn't detect atomic rewrites
- **Wallpaper restore** on startup from cached current_wallpaper.png
- **Hypridle** — Screen dim 7.5min, lock 10min, screen off + suspend 30min

## Troubleshooting

**Hyprland won't start:**
```bash
# Check config errors
hyprctl configerrors

# Test Lua config syntax
lua ~/.config/hypr/hyprland.lua
```

**Quickshell won't start:**
```bash
quickshell -c ~/Desktop/Trotid_Shell/quickshell/ 2>&1
```

**Reload config:**
```bash
pkill -x qs && quickshell -c ~/Desktop/Trotid_Shell/quickshell/ &
```

**Colors not updating:**
- ColorService uses `Process` + `cat` to read `colors.json` every 2s
- Requires `import Quickshell` (not just `Quickshell.Io`) for `Quickshell.env("HOME")`
- Missing import causes `ReferenceError: Quickshell is not defined`
- Check logs: `quickshell -c mrtrotid-shell log | grep -i color`

**Wallpaper picker not applying:**
- Uses `$HOME/.local/bin/wallset-backend` (full path required for execDetached)
- wallpaper picker runs swaybg, wallust, matugen, pywal_cava, lock screen bg copy
- If picker freezes, check `sudo -n true` (SDDM copy needs sudo)

**Check logs:**
```bash
journalctl --user -u quickshell -f
quickshell -c mrtrotid-shell log
```

## Credits

- **Calendar, Bluetooth, WiFi popups** — inspired by ilyamiro/nixos-configuration
- **Notification panel** — inspired by nandoroid
- **Coverflow wallpaper picker** — inspired by ilyamiro's wallpaper carousel
- **GIF search** — Tenor API (Google)
- **Compositor** — Hyprland
- **QML framework** — Quickshell
- **Material You color generation** — matugen
- **Rofi themes** — adi1090x/rofi
- **Workspace overview** — quickshell-overview by Shanu-Kumawat
