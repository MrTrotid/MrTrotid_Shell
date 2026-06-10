# Trotid Shell

A custom Hyprland + Quickshell desktop shell with singleton service architecture, global IPC keybinds, Material You theming, and unified keybinds.conf for cheatsheet generation.

## What's Included

- **Hyprland 0.55+** with scrolling layout, gestures, layerrules
- **Quickshell 0.3.0** - singleton services, global IPC, Wayland layer shell
- **Material You** color scheme via matugen (auto-generates M3 colors from wallpaper)
- **Notification system** with DBus server, grouped notifications, toasts, action buttons (keeps original NotificationAction refs for invoke()), urgency styling, persistence
- **Coverflow wallpaper picker** with thumbnails and filter bar
- **Quick Actions HUD** with keyboard navigation and executable actions
- **OSD** for volume/brightness/mic feedback
- **Cheatsheet** - searchable keybind reference with executable actions
- **Clipboard manager** - native Quickshell widget with cliphist integration, search/filter, image preview
- **Emoji picker** - native Quickshell widget with 5 categories, search, click to copy
- **GIF selector** - native Quickshell widget with Tenor API search, AnimatedImage preview (plays on hover), click to copy URL
- **Night light toggle** via hyprsunset
- **Power menu** - wlogout with HyprNova-style icon buttons (lock/suspend/logout/reboot/power off)
- **CPU temperature chip** - color-coded (green/yellow/red) in bar
- **Network speed indicator** - ↓/↑ KB/s or MB/s next to WiFi icon
- **Low battery notification** - warns at configurable threshold (default 20%)

## Quick Reference

| Key | Action |
|-----|--------|
| `Super + Return` | Terminal (Ghostty) |
| `Super + Space` | App launcher (Rofi) |
| `Super + /` | Toggle Cheatsheet |
| `Super + P` | Toggle power menu |
| `Super + A` | Toggle notification panel |
| `Super + J` | Toggle quick actions HUD |
| `Super + O` | Toggle bar |
| `Super + M` | Toggle media card |
| `Ctrl + Super + T` | Toggle wallpaper picker |
| `Super + V` | Toggle clipboard manager |
| `Super + .` | Toggle emoji picker |
| `Super + ,` | Toggle GIF picker |
| `Super + W` | Browser (Zen) |
| `Super + E` | File manager (Thunar) |
| `Super + Shift + N` | Toggle night light |
| `Super + Shift + P` | Lock screen |
| `Super + Shift + L` | Suspend |
| `Ctrl + Super + R` | Restart Quickshell |
| `Print` | Screenshot to clipboard |
| `Ctrl + Print` | Region screenshot |
| `Shift + Print` | Window screenshot |
| `Ctrl + Shift + Print` | Annotate screenshot (swappy) |
| `Alt + Print` | Monitor screenshot |
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
- `grim`, `slurp`, `hyprpicker`, `swappy` - screenshots/region-select/color picker/annotation
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
    │   ├── ColorService.qml      # matugen colors.json reader (Process + cat, 2s polling)
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
    │   ├── ClipboardManager.qml  # cliphist integration, search, image preview
    │   ├── EmojiPicker.qml       # 5 categories, search, click to copy
    │   ├── GifPicker.qml         # Tenor API search, AnimatedImage preview
    │   ├── PowerMenu.qml          # Centered power overlay (lock/suspend/logout/reboot/off)
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

Top bar with exclusiveZone: 34, auto-hides when cursor moves away.

**Layout:** Left (workspaces, media) -> Center (clock) -> Right (volume, brightness, cpu, temp, battery, bluetooth, wifi+speed, tray)

**Key behaviors:**
- Auto-hide: Cursor near top shows bar; cursor 50px+ away hides after 1.5s
- Volume click cycles audio sinks
- Mic indicator: left click = toggle mute, right click = cycle mic sources
- Network speed: shows ↓/↑ KB/s or MB/s next to WiFi icon when active
- CPU temperature: color-coded green (<65°), yellow (65-79°), red (≥80°)
- Battery: hardcoded green/yellow/red colors, sky blue when charging, text uses colOnPrimary
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
- Resolves app icons from system hicolor/pixmaps dirs; falls back to Nerd Font icons
- Startup sound guard: 1.5s delay prevents replayed notifications from playing sound on reload
- Action buttons: prominent separated buttons at bottom of toast (keeps original NotificationAction refs for invoke)
- Urgency styling: Critical notifications get red border and 15s dismiss timeout
- Pause on hover: dismiss timer pauses when cursor hovers over toast
- Persistence: Notifications saved to ~/.cache/quickshell/notifications.json, restored on reload
</details>

<details>
<summary><strong>Wallpaper Picker</strong></summary>

Coverflow-style wallpaper selector with thumbnails.

**Features:**
- FolderListModel loading from cache directory
- Matrix4x4 skew transforms for coverflow effect
- Filter bar: All / Landscapes / Nature / Dark / City
- Apply via wallset-backend (swaybg + wallust + matugen + pywal_cava + lock screen bg)
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

<details>
<summary><strong>Power Menu (wlogout)</strong></summary>

wlogout with HyprNova-style icon buttons.

**Features:**
- Shutdown, Reboot, Logout, Hibernate, Lock buttons
- Circular icon buttons with hover animation (green highlight)
- Semi-transparent dark overlay background
- Keybinds: s/r/e/h/l for quick selection
- `Super + P` to toggle
</details>

<details>
<summary><strong>Clipboard Manager</strong></summary>

Native clipboard history widget with cliphist integration.

**Features:**
- Batch reads clipboard history via `cliphist list` (fast bulk parse)
- Search/filter with debounced input
- Image preview (decodes to /tmp for preview)
- Click to copy, keyboard navigation
- Left-side panel (topLeftRadius: 0, bottomLeftRadius: 0)
- `Super + V` to toggle
</details>

<details>
<summary><strong>Emoji Picker</strong></summary>

Native emoji picker with 5 categories.

**Features:**
- Categories: Smileys, Gestures, Nature, Objects, Symbols
- Text search via emojiNames mapping
- Click to copy via wl-copy
- Left-side panel with slide animation
- `Super + .` to toggle
</details>

<details>
<summary><strong>GIF Picker</strong></summary>

Native GIF search powered by Tenor API.

**Features:**
- Tenor API search with 350ms debounce
- AnimatedImage preview - plays on hover only
- Click to copy GIF URL via wl-copy
- Loading spinner and error fallback
- Dynamic grid sizing (adapts to container width)
- `Super + ,` to toggle
</details>

## Services

All services live in `quickshell/services/` with `pragma Singleton` + `qmldir` entry.

| Service | Description |
|---------|-------------|
| ShellState | UI toggle states (activePopup pattern) |
| ColorService | Reads matugen colors.json via `Process` + `cat` (2s polling) — requires `import Quickshell` |
| AudioService | wpctl status parsing, sink switching, Bluetooth auto-switch, mic source parsing, updates VolumeService |
| BrightnessService | Brightness polling (200ms) + control |
| VolumeService | Volume from AudioService (no independent poll), debounced refresh for muted state |
| NetworkService | nmcli monitoring with `-e yes` SSID escaping, network speed from /proc/net/dev |
| BatteryService | UPower + sysfs, hasBattery guard, low battery notification at configurable threshold |
| SystemService | CPU + memory + temperature from /proc (2s poll) |
| NotificationService | DBus notification server, grouped notifications, toast list, startup sound guard, persistence, action buttons, urgency styling |

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
- **ColorService** reads matugen JSON via `Process` + `cat` with 2s polling for live theme updates
- **Wallpaper restore** - shell.qml restores last wallpaper on startup from cached current_wallpaper.png
- **Hypridle** - Screen dim at 7.5min, lock at 10min, screen off + suspend at 30min

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
- ColorService uses `Process` + `cat` to read `colors.json` every 2s (FileView doesn't detect atomic rewrites)
- Requires `import Quickshell` (not just `Quickshell.Io`) for `Quickshell.env("HOME")`
- Missing import causes silent `ReferenceError: Quickshell is not defined` — bar shows only hardcoded fallback colors
- Check logs: `quickshell -c mrtrotid-shell log | grep -i color`

**Wallpaper picker not applying:**
- Uses `$HOME/.local/bin/wallset-backend` (full path) — `execDetached` doesn't inherit user PATH
- wallset-backend runs swaybg, wallust, matugen, pywal_cava, lock screen bg copy, swaync restart
- If picker freezes, check if `sudo -n true` fails (wallset-backend tries sudo for SDDM copy)

**Check logs:**
```bash
journalctl --user -u quickshell -f
```

## Credits

- **Calendar, Bluetooth, WiFi popups** - inspired by ilyamiro/nixos-configuration
- **Bar design** - inspired by Noro18/linux-ricing-dotfiles
- **Notification panel** - inspired by nandoroid (custom dependencies not available)
- **Coverflow wallpaper picker** - inspired by ilyamiro's wallpaper carousel
- **GIF search** - powered by Tenor API (Google)
- **Compositor** - Hyprland
- **QML framework** - Quickshell
- **Material You color generation** - matugen
- **Rofi themes** - adi1090x/rofi
