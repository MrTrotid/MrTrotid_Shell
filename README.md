# Trotid Shell

A custom Hyprland + Quickshell desktop shell — singleton service architecture, global IPC keybinds, Material You theming, and a unified keybinds.conf for cheatsheet generation.

## What's Included

- **Hyprland 0.55+** with scrolling layout, gestures, layerrules
- **Quickshell 0.3.0** — singleton services, global IPC, Wayland layer shell
- **Material You** color scheme via matugen (auto-generates M3 colors from wallpaper)
- **Notification system** with DBus server, grouped notifications, toasts
- **Coverflow wallpaper picker** with thumbnails and filter bar
- **Quick Actions HUD** with keyboard navigation and executable actions
- **Cheatsheet** — searchable keybind reference with executable actions
- **Click-outside-to-close** for all popups (except notification panel)

---

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
| `Super + Shift + P` | Lock screen |
| `Super + Shift + L` | Suspend |
| `Ctrl + Super + R` | Restart Quickshell |
| `Print` | Screenshot to clipboard |
| `Ctrl + Shift + R` | Region record / stop |
| `Ctrl + Alt + R` | Full record / stop |

Full keybind list: see `hypr/keybinds.conf` or press `Super + /` in-shell.

---

## Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| Hyprland | 0.51+ | tested on 0.55.2 |
| Quickshell | 0.3.0 | install via `quickshell-git` from AUR |
| matugen | latest | generates Material You colors |
| Qt 6 | — | Quickshell dependency |
| swaybg | latest | wallpaper setter |

**Required for full functionality:**

- `wl-clipboard`, `cliphist` — clipboard history
- `playerctl`, `wpctl`, `brightnessctl` — media/audio/brightness
- `grim`, `slurp`, `hyprpicker` — screenshots/region-select/color picker
- `nmcli` — network management
- `wf-recorder` — screen recording
- `rofi` — app launcher
- `ImageMagick` — wallpaper thumbnails

---

## Project Structure

```
Trotid_Shell/
├── hypr/                         # Hyprland configuration
│   ├── hyprland.conf             # Layout, animations, decoration, exec-once
│   ├── keybinds.conf             # All keybindings (single file for cheatsheet)
│   └── windowrules.conf          # Window + layer rules
└── quickshell/                   # Quickshell configuration
    ├── shell.qml                 # Root shell — all PanelWindows + GlobalShortcuts
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
    │   ├── MediaCard.qml
    │   ├── PlayerCard.qml
    │   ├── WaveVisualizer.qml
    │   ├── WorkspaceOverview.qml
    │   └── Colors.qml
    ├── calendar/                 # Weather scripts + OpenWeatherMap config
    └── functions/
        └── ColorUtils.qml        # Color utilities
```

---

## Components

<details>
<summary><strong>Bar (PanelWindow — main)</strong></summary>

The top bar is a Wayland layer shell surface with `exclusiveZone: 48` (reserves screen space). Auto-hides when cursor moves away from the top edge.

**Layout:** Left section (workspaces, media) → Center (clock) → Right (volume, brightness, battery, bluetooth, wifi, tray)

**Key behaviors:**
- Auto-hide: Cursor near top shows bar; cursor 50px+ away hides it after 1.5s
- `keepBarTemporarily()` prevents hide during popup interaction (5s timer)
- Volume click cycles audio sinks; hover shows sink name
- Battery: hardcoded green/yellow/red independent of colorscheme, text uses `colOnPrimary`
- Window title: capped at 416px max width
- WiFi icon: solid `colPrimary` color matching Bluetooth
- System tray: left-click activates, right-click calls `secondaryActivate()`

**Colors:** Bound to ColorService (Material You from matugen)

</details>

<details>
<summary><strong>Popup Click-Outside-to-Close</strong></summary>

Popups close when the cursor moves away from the top edge of the screen (y > 50).

**How it works:**
- Bar PanelWindow has a 100ms Timer that monitors cursor position
- When cursor is near top (y ≤ 2): show bar, mark `cursorNearTop = true`
- When cursor moves away (y > 50): close any open popup, start hide timer
- No overlay PanelWindow needed — avoids Wayland layer shell input conflicts

**Exemptions:** Notification panel stays open until explicitly dismissed via `Super+A`.

</details>

<details>
<summary><strong>Bluetooth Popup</strong></summary>

Full Bluetooth device management panel.

**Features:**
- Central power toggle with animated rings and radar pulse
- Connected/Paired device lists with icon detection (headphones, keyboard, phone, etc.)
- Device detail view with battery level, connect/disconnect/forget actions
- 30-second scan with countdown, auto-refresh during scan
- Orbiting card layout with 3D-style animation

**Positioning:** Top-right, 40% screen width, 500px height

</details>

<details>
<summary><strong>WiFi Popup</strong></summary>

WiFi network selector with nmcli integration.

**Features:**
- Scans available networks with signal strength indicators
- Connect/disconnect toggle
- Saved network management

**Positioning:** Top-right, 40% screen width, 500px height

</details>

<details>
<summary><strong>Notification Panel</strong></summary>

Nandoroid-style grouped notification panel with slide+fade animation.

**Features:**
- Notifications grouped by app name with expand/collapse chevron
- Single notification: summary in header, body only in item
- Multiple: app name + summary+body per item
- Bottom action row: silent toggle, count pill, clear all
- Slide+fade animation via Loader with states/transitions
- **Exempt from click-outside-to-close** — stays open until explicitly dismissed

**Positioning:** Top-right, 360px width, 590px height

</details>

<details>
<summary><strong>Notification Toasts</strong></summary>

Stacked notification toasts below the bar.

**Features:**
- Real DBus notifications via `Quickshell.Services.Notifications.NotificationServer`
- Uses ListModel (max 3) — newest at top, oldest animates out on overflow
- Nerd font icons only (no system appIcon mismatch)
- Slide+fade animations

**Positioning:** Centered below bar, 340px width

</details>

<details>
<summary><strong>Wallpaper Picker</strong></summary>

Coverflow-style wallpaper selector with thumbnails.

**Features:**
- FolderListModel loading from `~/.cache/quickshell/wallpaper_picker/thumbs/`
- Matrix4x4 skew transforms for coverflow effect
- Filter bar: All / Landscapes / Nature / Dark / City
- Apply via `swaybg` + `matugen image` for color generation
- `Ctrl + Super + T` to toggle

**Positioning:** Full-screen overlay

</details>

<details>
<summary><strong>Quick Actions HUD</strong></summary>

Floating bottom-center action bar with keyboard navigation.

**Features:**
- 7 action buttons: Full Screenshot, Region Screenshot, Open Screenshots, Record Region, Record Fullscreen, Open Recordings, Color Picker
- Animated tab highlight with slide animation
- Keyboard navigation: arrows, h/l, Enter to execute, Escape to close
- Slide-up animation via Loader with states/transitions
- `Super + J` to toggle

**Positioning:** Bottom-center, 440px width, 60px height

</details>

<details>
<summary><strong>Calendar Popup</strong></summary>

Calendar view with weather integration.

**Features:**
- Monthly calendar grid
- Current time display
- Weather data from OpenWeatherMap

**Positioning:** Centered, 70% screen width, 500px height

</details>

<details>
<summary><strong>Cheatsheet</strong></summary>

Searchable keybind reference with executable actions.

**Features:**
- 8 categories: Shell, Apps, Windows, Workspaces, Session, Screenshots, Recording, Hardware
- Live filter-as-you-type search (TextField with keyboard focus via `WlrKeyboardFocus.OnDemand`)
- **Executable keybinds:** Apps, Session, Screenshots, Recording categories run commands on click (play icon)
- **Copy to clipboard:** Other categories copy key combo to clipboard on click
- Horizontal scrolling with mouse wheel, visible scrollbar at bottom
- Esc to close, auto-focus search on open

**Positioning:** Centered, 85% screen width, 750px height

</details>

<details>
<summary><strong>Media Card</strong></summary>

Separate Window (not PanelWindow) for media playback controls with slide-in animation.

**Features:**
- Album art, track info, play/pause/next/prev
- Wave visualizer
- Slides in from left with `Behavior on x`
- `Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowTransparentForInput`

**Positioning:** Left side, 320x200px

</details>

---

## Services (Singletons)

All services live in `quickshell/services/` with `pragma Singleton` + `qmldir` entry.

<details>
<summary><strong>ShellState.qml</strong></summary>

UI toggle states using `activePopup` string pattern for mutual exclusion.

**Properties:**
- `barVisible` — Bar visibility
- `activePopup` — Current open popup (`"bluetooth" | "wifi" | "calendar" | "notification" | "cheatsheet" | "wallpaper" | "quickactions" | ""`)
- `mediaCardOpen` — Media card visibility
- `keepBarVisible` — Temporary keep-alive flag

**Derived booleans:** `bluetoothPanelOpen`, `wifiSelectorOpen`, `calendarPopupOpen`, `notificationPanelOpen`, `cheatsheetOpen`, `wallpaperPickerOpen`, `quickActionsOpen`, `anyPopupOpen`

**Functions:** `togglePopup(name)`, `openPopup(name)`, `closePopup()`, `toggleBar()`, `toggleMediaCard()`, `keepBarTemporarily()`, `toggleQuickActions()`

</details>

<details>
<summary><strong>ColorService.qml</strong></summary>

Reads matugen `colors.json` with 2-second polling timer. All color properties named `*Text` to avoid QML signal handler conflicts.

</details>

<details>
<summary><strong>AudioService.qml</strong></summary>

Audio sink management via `wpctl`.

**Features:**
- Parses `wpctl status` with Unicode box-drawing chars
- Sink switching via `wpctl set-default`
- Auto-switch to Bluetooth on connect, auto-revert on disconnect
- `sinkIcon()` maps device names to Nerd Font icons

</details>

<details>
<summary><strong>BrightnessService.qml</strong></summary>

Brightness polling (5000ms) + control via `brightnessctl`.

</details>

<details>
<summary><strong>VolumeService.qml</strong></summary>

Volume polling (200ms) via `wpctl`, 2% increment.

</details>

<details>
<summary><strong>NetworkService.qml</strong></summary>

Network monitoring via `nmcli monitor` + 10s polling fallback.

</details>

<details>
<summary><strong>BatteryService.qml</strong></summary>

Battery state via UPower + sysfs. `hasBattery` guard for desktop/VM without battery.

</details>

<details>
<summary><strong>SystemService.qml</strong></summary>

CPU + memory usage from `/proc` with 2s polling. Running guard prevents process leaks.

</details>

<details>
<summary><strong>NotificationService.qml</strong></summary>

Real DBus notification server via `Quickshell.Services.Notifications.NotificationServer`. JS array `notifications` for panel + ListModel `toastList` (max 3) for toasts. Stores `appName`, `summary`, `body`, `appIcon`, `image`, `urgency`, `time`, `actions`. Has `groupsByAppName`, `appNameList` computed properties.

</details>

---

## Scripts

All scripts live at `~/.config/scripts/` (symlinked from `~/Desktop/Trotid_Shell/scripts/`).

<details>
<summary><strong>Screenshots</strong></summary>

`screenshot.sh` — grim + slurp screenshot helper.

| Key | Mode |
|-----|------|
| `Print` | Full screen to clipboard |
| `Ctrl+Print` | Full screen to file |
| `Shift+Print` | Region select |
| `Alt+Print` | Window select |
| `Ctrl+Shift+Print` | Monitor select |
| `Ctrl+Alt+Print` | Timed full screen (5s delay) |

Saves to `~/Pictures/Screenshots/`, copies to clipboard via `wl-copy`.

</details>

<details>
<summary><strong>Screen Recording</strong></summary>

`recording.sh` — wf-recorder with rofi audio picker.

| Key | Mode |
|-----|------|
| `Ctrl+Shift+R` | Region recording / stop |
| `Ctrl+Alt+R` | Full screen recording / stop |

**Audio options:** Device audio only, Mic only, Both (ffmpeg mixing), No audio

Saves to `~/Videos/Recordings/`.

</details>

<details>
<summary><strong>Clipboard History</strong></summary>

`clipboard-picker.sh` — rofi + cliphist clipboard history.

- `Super+V` opens picker with text and image previews
- Config: `~/.config/cliphist/config` (max-items: 10000)
- Clipboard watchers: `wl-paste --type text|image --watch cliphist store`

</details>

<details>
<summary><strong>Rofi Launcher</strong></summary>

`Super+Space` — App launcher using rofi style-1.

</details>

---

## Architecture

<details>
<summary><strong>Wayland Layer Shell Positioning</strong></summary>

**Critical:** `margins.top` on a PanelWindow does NOT control where the compositor places the surface. It only offsets content within the surface.

- Bar has `exclusiveZone: 48` (reserves 48px from top)
- Popups have `exclusiveZone: 0` (placed by compositor after reserved zone)
- `margins.top` on popups has zero effect on screen position

</details>

<details>
<summary><strong>Popup Click-Outside-to-Close</strong></summary>

Popups close when cursor moves away from top edge (y > 50):
- Bar PanelWindow has 100ms Timer monitoring cursor position
- No overlay PanelWindow — avoids Wayland layer shell input conflicts
- Notification panel exempt (stays open until explicitly dismissed via `Super+A`)

</details>

<details>
<summary><strong>Keybinds Architecture</strong></summary>

All keybinds in `hypr/keybinds.conf` (single file for cheatsheet generation). Shell toggles use Hyprland's global shortcut protocol (`global, quickshell:<action>`).

**Global IPC flow:** keybinds.conf → `global, quickshell:<action>` → `GlobalShortcut.onPressed` in shell.qml → `ShellState.togglePopup("name")`

</details>

<details>
<summary><strong>Theming Pipeline</strong></summary>

1. Wallpaper set via `wallset` or `wallset-backend-startup`
2. `swaybg` updates wallpaper
3. `matugen` generates Material You colors → ColorService reads `colors.json`
4. `wallust` generates terminal colors → Kitty, Hyprland
5. Components reload/apply on next start

</details>

---

## Troubleshooting

<details>
<summary><strong>Quickshell won't start</strong></summary>

```bash
quickshell -c ~/Desktop/Trotid_Shell/quickshell/
# Check log: cat /run/user/1000/quickshell/by-id/*/log.qslog
```

</details>

<details>
<summary><strong>Reload config without restarting</strong></summary>

```bash
pkill -x qs && quickshell -c ~/Desktop/Trotid_Shell/quickshell/ &
```

</details>

<details>
<summary><strong>Icons showing as squares / missing</strong></summary>

Ensure JetBrainsMono Nerd Font is installed. Check with `fc-list | grep JetBrainsMono`.

</details>

<details>
<summary><strong>Lock screen not appearing</strong></summary>

- Lock is `loginctl lock-session` by default — no hypridle needed
- For auto-lock on idle, install `hypridle` and add to `hyprland.conf` `exec-once = hypridle`

</details>

<details>
<summary><strong>Wallpaper switching fails</strong></summary>

- Ensure `swaybg` is installed
- Wallpaper thumbnails must be pre-generated in `~/.cache/quickshell/wallpaper_picker/thumbs/`

</details>

<details>
<summary><strong>Colors not updating</strong></summary>

- ColorService polls `colors.json` every 2 seconds
- Ensure `matugen` is installed and `~/.config/quickshell/mrtrotid-shell/colors.json` exists
- Check: `matugen image /path/to/wallpaper.png --prefer darkness`

</details>

<details>
<summary><strong>To check shell logs</strong></summary>

```bash
journalctl --user -u quickshell -f
# or: tail -f /run/user/1000/quickshell/by-id/*/log.qslog
```

</details>

---

## Credits

- **Calendar, Bluetooth, WiFi popups** — inspired by and adapted from **[ilyamiro/nixos-configuration](https://github.com/ilyamiro/nixos-configuration)**
- **Bar design** — inspired by **[Noro18/linux-ricing-dotfiles](https://github.com/Noro18/linux-ricing-dotfiles/tree/main)**
- **Notification panel** — inspired by **[nandoroid](https://github.com/nandoroid/dotfiles)** (custom dependencies not available)
- **Coverflow wallpaper picker** — inspired by ilyamiro's wallpaper carousel
- **Quick Actions HUD** — custom implementation with nerd font icons
- **Compositor** — **[Hyprland](https://hyprland.org/)**
- **QML framework** — **[Quickshell](https://quickshell.org/)**
- **Material You color generation** — **[matugen](https://github.com/InioX/matugen)**
- **Rofi themes** — **[adi1090x/rofi](https://github.com/adi1090x/rofi)** (type-1 launcher)
- **Scripts** — screenshots, recording, clipboard picker built with `grim`, `slurp`, `wf-recorder`, `cliphist`
