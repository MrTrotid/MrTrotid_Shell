# Trotid Shell

A custom Hyprland + Quickshell desktop shell with singleton service architecture, global IPC keybinds, Material You theming, and unified keybinds.conf for cheatsheet generation.

## What's Included

- **Hyprland 0.55+** with scrolling layout, gestures, layerrules
- **Quickshell 0.3.0** - singleton services, global IPC, Wayland layer shell
- **Material You** color scheme via matugen (auto-generates M3 colors from wallpaper)
- **Notification system** with DBus server, grouped notifications, toasts
- **Coverflow wallpaper picker** with thumbnails and filter bar
- **Quick Actions HUD** with keyboard navigation and executable actions
- **OSD** for volume/brightness feedback
- **Cheatsheet** - searchable keybind reference with executable actions
- **Night light toggle** via hyprsunset
- **Power menu confirm dialog** for dangerous actions

## Quick Reference

| Key | Action |
|-----|--------|
| `Super + Return` | Terminal (Ghostty) |
| `Super + Space` | App launcher (Rofi) |
| `Super + /` | Toggle Cheatsheet |
| `Super + A` | Toggle notification panel |
| `Super + J` | Toggle quick actions HUD |
| `Super + O` | Toggle bar |
| `Super + M` | Toggle media card |
| `Ctrl + Super + T` | Toggle wallpaper picker |
| `Super + V` | Clipboard history |
| `Super + W` | Browser (Zen) |
| `Super + E` | File manager (Thunar) |
| `Super + Shift + N` | Toggle night light |
| `Super + Shift + P` | Lock screen |
| `Super + Shift + L` | Suspend |
| `Ctrl + Super + R` | Restart Quickshell |
| `Print` | Screenshot to clipboard |
| `Ctrl + Shift + R` | Region record / stop |
| `Ctrl + Alt + R` | Full record / stop |

Full keybind list: see `hypr/keybinds.conf` or press `Super + /` in-shell.

## Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| Hyprland | 0.51+ | tested on 0.55.2 |
| Quickshell | 0.3.0 | install via `quickshell-git` from AUR |
| matugen | latest | generates Material You colors |
| Qt 6 | - | Quickshell dependency |
| swaybg | latest | wallpaper setter |

**Required for full functionality:**
- `wl-clipboard`, `cliphist` - clipboard history
- `playerctl`, `wpctl`, `brightnessctl` - media/audio/brightness
- `grim`, `slurp`, `hyprpicker` - screenshots/region-select/color picker
- `nmcli` - network management
- `wf-recorder` - screen recording
- `rofi` - app launcher
- `ImageMagick` - wallpaper thumbnails
- `xdg-desktop-portal-hyprland` - screen share, file pickers

## Project Structure

```
Trotid_Shell/
├── hypr/                         # Hyprland configuration
│   ├── hyprland.conf             # Layout, animations, decoration, exec-once
│   ├── keybinds.conf             # All keybindings (single file for cheatsheet)
│   └── windowrules.conf          # Window + layer rules
└── quickshell/                   # Quickshell configuration
    ├── shell.qml                 # Root shell - all PanelWindows + GlobalShortcuts
    ├── BarContent.qml            # Bar layout (binds to singleton services)
    ├── Caching.qml               # Cache/state directory management
    ├── core/
    │   └── NotificationUtils.js  # Time formatting and icon mapping
    ├── services/                 # Singleton services (pragma Singleton + qmldir)
    │   ├── ShellState.qml        # UI toggle states (activePopup pattern)
    │   ├── AudioService.qml      # wpctl parsing, sink switching
    │   ├── BrightnessService.qml # Brightness polling + control
    │   ├── VolumeService.qml     # Volume polling + control
    │   ├── NetworkService.qml    # nmcli monitoring
    │   ├── BatteryService.qml    # UPower + sysfs
    │   ├── SystemService.qml     # CPU + memory from /proc
    │   ├── NotificationService.qml # DBus notification server
    │   ├── ColorService.qml      # matugen colors.json reader (2s polling)
    │   └── qmldir                # Singleton declarations
    ├── widgets/                  # Popup widgets
    │   ├── BluetoothSelector.qml
    │   ├── WifiSelector.qml
    │   ├── CalendarPopup.qml
    │   ├── NotificationPanel.qml # Nandoroid-style grouped notifications
    │   ├── NotificationPopup.qml # Toast notifications (ListModel, max 3)
    │   ├── WallpaperPicker.qml   # Coverflow carousel with thumbnails
    │   ├── QuickActions.qml      # Bottom-center floating action bar
    │   ├── Cheatsheet.qml        # Searchable keybind reference
    │   ├── OsdPopup.qml          # Volume/brightness OSD
    │   ├── MediaCard.qml
    │   ├── PlayerCard.qml
    │   ├── WaveVisualizer.qml
    │   ├── WorkspaceOverview.qml
    │   └── Colors.qml
    ├── calendar/                 # Weather scripts + OpenWeatherMap config
    └── functions/
        └── ColorUtils.qml        # Color utilities
```

## Components

<details>
<summary><strong>Bar</strong></summary>

Top bar with exclusiveZone: 48, auto-hides when cursor moves away.

**Layout:** Left (workspaces, media) -> Center (clock) -> Right (volume, brightness, battery, bluetooth, wifi, tray)

**Key behaviors:**
- Auto-hide: Cursor near top shows bar; cursor 50px+ away hides after 1.5s
- Volume click cycles audio sinks
- Battery: hardcoded green/yellow/red colors, text uses colOnPrimary
- Window title: capped at 416px max width
- WiFi icon: solid colPrimary color matching Bluetooth

**Colors:** Bound to ColorService (Material You from matugen)
</details>

<details>
<summary><strong>Notification Panel</strong></summary>

Nandoroid-style grouped notification panel with slide+fade animation.

**Features:**
- Notifications grouped by app name with expand/collapse chevron
- Bottom action row: silent toggle, count pill, clear all
- Exempt from click-outside-to-close
</details>

<details>
<summary><strong>Notification Toasts</strong></summary>

Stacked notification toasts below the bar.

**Features:**
- Real DBus notifications via NotificationService
- Uses ListModel (max 3) - newest at top, oldest animates out on overflow
- Nerd font icons only (no system appIcon mismatch)
- Startup sound guard: 1.5s delay prevents replayed notifications from playing sound on reload
</details>

<details>
<summary><strong>Wallpaper Picker</strong></summary>

Coverflow-style wallpaper selector with thumbnails.

**Features:**
- FolderListModel loading from cache directory
- Matrix4x4 skew transforms for coverflow effect
- Filter bar: All / Landscapes / Nature / Dark / City
- Apply via swaybg + matugen image for color generation
- `Ctrl + Super + T` to toggle
</details>

<details>
<summary><strong>Quick Actions HUD</strong></summary>

Floating bottom-center action bar with keyboard navigation.

**Features:**
- 7 action buttons with executable actions
- Animated tab highlight with slide animation
- Keyboard navigation: arrows, h/l, Enter to execute, Escape to close
- `Super + J` to toggle
</details>

<details>
<summary><strong>OSD</strong></summary>

Volume/brightness feedback popup.

**Features:**
- Watches VolumeService and BrightnessService properties (200ms poll each)
- Shows icon, progress bar, and percentage
- Updates in-place if already visible (no restart animation)
- Auto-hides after 2 seconds
- Bottom-center positioning
</details>

<details>
<summary><strong>Cheatsheet</strong></summary>

Searchable keybind reference with executable actions.

**Features:**
- 8 categories: Shell, Apps, Windows, Workspaces, Session, Screenshots, Recording, Hardware
- Live filter-as-you-type search
- Power actions show confirmation dialog
- Horizontal scrolling with mouse wheel
</details>

## Services

All services live in `quickshell/services/` with `pragma Singleton` + `qmldir` entry.

| Service | Description |
|---------|-------------|
| ShellState | UI toggle states (activePopup pattern) |
| ColorService | Reads matugen colors.json with 2s polling |
| AudioService | wpctl parsing, sink switching, Bluetooth auto-switch |
| BrightnessService | Brightness polling (200ms) + control |
| VolumeService | Volume polling (200ms) + control |
| NetworkService | nmcli monitoring |
| BatteryService | UPower + sysfs, hasBattery guard |
| SystemService | CPU + memory from /proc (2s poll) |
| NotificationService | DBus notification server, grouped notifications, toast list, startup sound guard |

## Scripts

All scripts live at `~/.config/scripts/` (symlinked from `~/Desktop/Trotid_Shell/scripts/`).

| Script | Description |
|--------|-------------|
| `screenshots/screenshot.sh` | grim + slurp screenshot helper |
| `recording/recording.sh` | wf-recorder with rofi audio picker |
| `clipboard-picker.sh` | rofi + cliphist clipboard history |

## Architecture

- **Each popup is its own PanelWindow** with exclusiveZone: 0
- **Popup click-outside-to-close** via cursor position monitoring
- **Global IPC** for shell toggles (no QML Shortcut elements)
- **Single NotificationServer** in NotificationService singleton
- **ColorService** reads matugen JSON with 2s polling for live theme updates

## Troubleshooting

**Quickshell won't start:**
```bash
quickshell -c ~/Desktop/Trotid_Shell/quickshell/
```

**Reload config:**
```bash
pkill -x qs && quickshell -c ~/Desktop/Trotid_Shell/quickshell/ &
```

**Colors not updating:**
- ColorService polls colors.json every 2 seconds
- Ensure matugen is installed and colors.json exists

**Check logs:**
```bash
journalctl --user -u quickshell -f
```

## Credits

- **Calendar, Bluetooth, WiFi popups** - inspired by ilyamiro/nixos-configuration
- **Bar design** - inspired by Noro18/linux-ricing-dotfiles
- **Notification panel** - inspired by nandoroid (custom dependencies not available)
- **Coverflow wallpaper picker** - inspired by ilyamiro's wallpaper carousel
- **Compositor** - Hyprland
- **QML framework** - Quickshell
- **Material You color generation** - matugen
- **Rofi themes** - adi1090x/rofi
