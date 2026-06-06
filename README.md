# Trotid Shell

A custom Hyprland + Quickshell desktop shell — singleton service architecture, global IPC keybinds, Material You theming, and a unified keybinds.conf for cheatsheet generation.

## What's Included

- **Hyprland 0.55+** with scrolling layout, gestures, layerrules
- **Quickshell 0.3.0** — singleton services, global IPC, Wayland layer shell
- **Material You** color scheme via matugen (auto-generates M3 colors from wallpaper)
- **Notification system** with persistent history, popups, file-based IPC
- **Cheatsheet** — searchable keybind reference with executable actions
- **Click-outside-to-close** for all popups (except notification panel)
- **AI sidebar**, **clipboard history**, **OCR/screen translate**, **on-screen keyboard**, **AI image tools**, and more

---

## Quick Reference

| Key | Action |
|-----|--------|
| `Super + Return` | Terminal (Ghostty) |
| `Super + Space` | App launcher (Rofi) |
| `Super + /` | Toggle Cheatsheet |
| `Super + A` | Toggle notification panel |
| `Super + O` | Toggle bar |
| `Super + M` | Toggle media card |
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

<details>
<summary><strong>Required for end-4 features (click to expand)</strong></summary>

- `swww` — wallpaper daemon
- `hypridle` — idle/lock daemon
- `hyprsunset` — color temperature toggle
- `hyprpolkitagent` — polkit authentication prompts
- `mako` — fallback notification daemon
- `waybar`, `wofi`, `fuzzel` — only for legacy fallbacks
- `wl-clipboard`, `cliphist`, `playerctl`, `wpctl`, `brightnessctl` — clipboard/media/audio/brightness
- `grim`, `slurp`, `hyprpicker` — screenshots/region-select/color picker
- `nmcli` — network management
- `tesseract` — OCR (region OCR)
- `ollama` (optional) — local AI for sidebar/AI features
- `python-requests`, `python-pillow` — for AI scripts

</details>

---

## Installation

```bash
# Copy shell directory to your preferred location
cp -r ~/Desktop/Trotid_Shell ~/.local/share/

# Install ly session entry (requires sudo)
sudo cp ~/Desktop/Trotid_Shell/trotid-shell.desktop /etc/ly/custom-sessions/

# Make startup script executable
chmod +x ~/Desktop/Trotid_Shell/start-trotid.sh

# Generate initial Material You colors
matugen image /path/to/your/wallpaper.png
```

Select **"Trotid Shell"** from the ly login manager session picker.

---

## Project Structure

```
Trotid_Shell/
├── start-trotid.sh              # Session startup
├── trotid-shell.desktop          # Ly session entry
├── hypr/                         # Hyprland configuration
│   ├── hyprland.conf             # Layout, animations, decoration, exec-once
│   ├── keybinds.conf             # All keybindings (single file for cheatsheet)
│   └── windowrules.conf          # Window + layer rules
└── quickshell/                   # Quickshell configuration
    ├── shell.qml                 # Root shell — all PanelWindows + GlobalShortcuts
    ├── BarContent.qml            # Bar layout (binds to singleton services)
    ├── services/                 # Singleton services (pragma Singleton + qmldir)
    ├── widgets/                  # Popup widgets (Bluetooth, WiFi, Calendar, etc.)
    ├── calendar/                 # Weather scripts + OpenWeatherMap config
    ├── functions/                # Color utilities
    └── reload.sh                 # Restart Quickshell for testing
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
- Battery tooltip shows health info on hover
- System tray: left-click activates, right-click calls `secondaryActivate()`

**Colors:** Hardcoded hex matching current matugen theme (`#1a2120` base, `#81d5ca` accent)

</details>

<details>
<summary><strong>Popup Overlay (click-outside-to-close)</strong></summary>

A full-screen transparent PanelWindow that sits behind all popups. When any popup (except notification panel) is open, the overlay becomes active. Clicking anywhere on it closes the current popup.

**Exemptions:** Notification panel is exempt — it stays open until explicitly closed via `Super + A` or its close button.

**Z-ordering:** Created before popup PanelWindows in shell.qml so it sits behind them in the Wayland layer stack.

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

Full notification center with history, tools, and power controls.

**Features:**
- Notification history with grouped display
- Quick tools (screenshot, recording, etc.)
- Power menu (lock, suspend, poweroff, reboot)
- **Exempt from click-outside-to-close** — stays open until explicitly dismissed

**Positioning:** Top-right, 360px width, 590px height

</details>

<details>
<summary><strong>Notification Toasts</strong></summary>

macOS-style stacked notification cards below the bar.

**Features:**
- File-based IPC: Scripts write to `/tmp/quickshell-notifications`, Quickshell polls every 200ms
- App-based accent colors (Firefox→blue, Discord→indigo, Spotify→green, etc.)
- Slide-in from y=-100, stack at y=`index*10`, max 3 visible
- 3.5s auto-dismiss with slide-out animation
- Sound notification via `paplay`

**Positioning:** Centered below bar, 340px width

</details>

<details>
<summary><strong>Calendar Popup</strong></summary>

Calendar view with weather integration.

**Features:**
- Monthly calendar grid
- Current time display
- Weather data from OpenWeatherMap (Bhaktapur, Nepal)

**Positioning:** Centered, 70% screen width, 500px height

</details>

<details>
<summary><strong>Cheatsheet</strong></summary>

Searchable keybind reference with executable actions.

**Features:**
- 8 categories: Shell, Apps, Windows, Workspaces, Session, Screenshots, Recording, Hardware
- Live filter-as-you-type search (TextField with keyboard focus via `WlrKeyboardFocus.OnDemand`)
- **Executable keybinds:** Apps, Session, Screenshots, Recording categories run commands on click (play icon ▶)
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
- `activePopup` — Current open popup (`"bluetooth" | "wifi" | "calendar" | "notification" | "cheatsheet" | ""`)
- `mediaCardOpen` — Media card visibility
- `batteryTooltip*` — Battery tooltip state
- `keepBarVisible` — Temporary keep-alive flag

**Derived booleans:** `bluetoothPanelOpen`, `wifiSelectorOpen`, `calendarPopupOpen`, `notificationPanelOpen`, `cheatsheetOpen`, `anyPopupOpen`

**Functions:** `togglePopup(name)`, `openPopup(name)`, `closePopup()`, `toggleBar()`, `toggleMediaCard()`, `keepBarTemporarily()`

</details>

<details>
<summary><strong>AudioService.qml</strong></summary>

Audio sink management via `wpctl`.

**Features:**
- Parses `wpctl status` with Unicode box-drawing chars (`\u2502\u251c\u2514\u2500`)
- Sink switching via `wpctl set-default`
- Auto-switch to Bluetooth on connect, auto-revert on disconnect
- `sinkIcon()` maps device names to Nerd Font icons

</details>

<details>
<summary><strong>BrightnessService.qml</strong></summary>

Brightness polling (300ms) + control via `brightnessctl`.

</details>

<details>
<summary><strong>VolumeService.qml</strong></summary>

Volume polling (500ms) via `wpctl`.

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

File-based IPC notifications. Polls `/tmp/quickshell-notifications` every 200ms. ListModel-based for insert without destroying delegates. Sound playback via `paplay`.

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
| `Ctrl+Print` | Region select |
| `Shift+Print` | Window select |
| `Alt+Print` | Monitor select |

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

**Gap between bar and popup** = `popupGap` (2px), controlled by bar's exclusiveZone calculation.

</details>

<details>
<summary><strong>Popup Overlay System</strong></summary>

Click-outside-to-close uses a transparent full-screen PanelWindow (`popupOverlay`) on `WlrLayer.Top`:
- Visible when `ShellState.anyPopupOpen && !ShellState.notificationPanelOpen`
- Clicking it calls `ShellState.closePopup()`
- Created before popup PanelWindows (lower z-order)
- Notification panel exempt (stays open until explicitly dismissed)

</details>

<details>
<summary><strong>Keybinds Architecture</strong></summary>

All keybinds in `hypr/keybinds.conf` (single file for cheatsheet generation). Shell toggles use Hyprland's global shortcut protocol (`global, quickshell:<action>`).

**Global IPC flow:** keybinds.conf → `global, quickshell:<action>` → `GlobalShortcut.onPressed` in shell.qml → `ShellState.togglePopup("name")`

</details>

---

## Configuration

User configuration is stored at `~/.config/illogical-impulse/config.json` (auto-generated on first run). Edit via:
- **GUI**: Super + Slash → "Settings" (built-in settings panel)
- **Direct**: Edit the JSON, then Ctrl+Super+R to reload

<details>
<summary><strong>Configuration categories (click to expand)</strong></summary>

`appearance`, `transparency`, `fonts`, `wallpaperTheming`, `bar`, `dock`, `sidebar`, `ui`, `general`, `background`, `notifications`, `mediaControls`, `ai`, `screenRecorder`, `hyprland`, `keybinds`, `session`

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
killall quickshell && quickshell -c ~/Desktop/Trotid_Shell/quickshell/ &
```

</details>

<details>
<summary><strong>Icons showing as squares / missing</strong></summary>

Edit `~/.config/illogical-impulse/config.json` `appearance.fonts.iconNerd` to a Nerd Font you have installed (e.g. `"JetBrainsMono Nerd Font"`, `"Hack Nerd Font"`, `"Symbols Nerd Font"`)

</details>

<details>
<summary><strong>Lock screen not appearing</strong></summary>

- Lock is `loginctl lock-session` by default — no hypridle needed
- For auto-lock on idle, install `hypridle` and add to `hyprland.conf` `exec-once = hypridle`

</details>

<details>
<summary><strong>Wallpaper switching fails</strong></summary>

- Install `swww`: `yay -S swww` (requires sudo)
- Or change `Directories.wallpaperSwitchScriptPath` in `Directories.qml` to your own script

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

- Shell design and QML: **[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)** (illogical-impulse / ii)
- Compositor: **[Hyprland](https://hyprland.org/)** + **hyprscrolling** plugin
- QML framework: **[Quickshell](https://quickshell.org/)**
- Material You generation: **[matugen](https://github.com/InioX/matugen)**
- Trotid-specific config: Trotid team
