# Linux Rice Dotfiles Agent Guidance

## Critical Rules
- **Never edit generated color files** (marked in docs): They are overwritten on every wallpaper change
- Edit templates instead: `~/.config/matugen/templates/` or `~/.config/wallust/templates/`
- Generated files include:
  - `~/.config/waybar/colors.css` and `colors-waybar.css`
  - `~/.config/rofi/colors/colors-matugen.rasi`
  - `~/.config/hypr/colors/*`
  - `~/.cache/wallust/colors-kitty.conf`

## Essential Commands
- Change wallpaper: `wallset` (opens selector) or `Super + W`
- Random wallpaper on login: `wallset-backend-startup`
- Apply current wallpaper theme manually: `wallset-backend`
- Toggle bar: `Super + O` (Quickshell bar visibility)
- Toggle media visualizer: `Super + M` (slides in from right)
- Toggle notification panel: `Super + A` (slide-in from right)
- Toggle quick actions HUD: `Super + J` (slide-up from bottom)
- Toggle cheatsheet: `Super + /` (keybind reference with executable actions)
- Toggle Calendar popup: Click time in bar
- Cycle workspaces: `Super + Tab` / `Super + Shift + Tab`
- Lock screen: `Super + Shift + P` (hyprlock)
- Suspend: `Super + Shift + L`
- Toggle night light: `Super + Shift + N` (hyprsunset)
- Restart Quickshell: `Ctrl + Super + R`
- Test Quickshell: `quickshell -c mrtrotid-shell -v`

## Configuration Locations
- Hyprland: `dotfiles/.config/hypr/hyprland.conf` (main entry)
- Quickshell: `~/.config/quickshell/mrtrotid-shell/` (symlink to `~/Desktop/Trotid_Shell/quickshell/`)
- Quickshell (custom): `~/.config/quickshell/custom/` (same symlink target)
- Waybar (legacy): `dotfiles/.config/waybar/config.jsonc` + styles in `custom styles/`
- Rofi: Launchers in `dotfiles/.config/rofi/launchers/`, applets in `applets/`
- Kitty: `dotfiles/.config/kitty/kitty.conf` (references wallust cache)
- Wallpapers: `dotfiles/.config/wallpapers/` (scanned by selector)

## Theming Pipeline
1. Wallpaper set via `wallset` or `wallset-backend-startup`
2. `swaybg` updates wallpaper
3. `matugen` generates Material You colors -> ColorService reads `colors.json`
4. `wallust` generates terminal colors -> Kitty, Hyprland
5. Components reload/apply on next start

## Quickshell Config Structure
All config lives at `~/Desktop/Trotid_Shell/quickshell/` (symlinked to `~/.config/quickshell/{custom,mrtrotid-shell}`):

- `shell.qml` - **Single entry point**: Each component runs in its own Wayland layer shell surface:
  - `PanelWindow (main)` - Bar (exclusiveZone: 48, Top layer)
  - `PanelWindow (popupOverlay)` - Full-screen transparent overlay for click-outside-to-close
  - `PanelWindow (blPopup)` - Bluetooth popup (exclusiveZone: 0)
  - `PanelWindow (wifiPopup)` - WiFi popup (exclusiveZone: 0)
  - `PanelWindow (notifPopup)` - Notification panel with Loader-based slide+fade animation
  - `PanelWindow (calPopup)` - Calendar popup (exclusiveZone: 0)
  - `PanelWindow (csPopup)` - Cheatsheet popup (exclusiveZone: 0, keyboard focus)
  - `PanelWindow (qaPopup)` - Quick Actions HUD (bottom-center, slide-up)
  - `PanelWindow (osdPopup)` - Volume/brightness OSD (bottom-center, auto-hide)
  - `PanelWindow (toastPopup)` - Notification toasts (stacked, below bar, max 3)
  - `PanelWindow (wpPopup)` - Wallpaper picker (full-screen overlay, coverflow)
  - `Window (MediaCard)` - Separate window for media card slide-in
  - `GlobalShortcut` handlers - IPC from keybinds.conf
- `services/` - **Singleton services** (pragma Singleton + qmldir):
  - `ShellState.qml` - UI toggle states (activePopup pattern)
  - `AudioService.qml` - wpctl status parsing, sink switching, Bluetooth auto-switch/revert, mic source parsing (Sources + Filters sections), updates VolumeService volume, micMuted/micVolume properties, toggleMicMute/cycleMicSource functions
  - `BrightnessService.qml` - Brightness polling (200ms) + control
  - `VolumeService.qml` - Volume from AudioService (no independent poll), debounced refresh for muted state
  - `NetworkService.qml` - nmcli monitoring with `-e yes` SSID escaping, network speed from /proc/net/dev
  - `BatteryService.qml` - UPower + sysfs, hasBattery guard, low battery notification at configurable threshold
  - `SystemService.qml` - CPU + memory + temperature from /proc (2s poll)
  - `NotificationService.qml` - DBus notification server, grouped notifications, toast list, startup sound guard (1.5s), persistence to ~/.cache/quickshell/notifications.json, action buttons, urgency-based styling
  - `ColorService.qml` - Reads matugen colors.json with 2s polling, skips parse if unchanged
- `BarContent.qml` - Bar layout, binds to singleton services
- `widgets/` - All popup widgets including OsdPopup.qml
- `core/NotificationUtils.js` - Time formatting, icon resolution from system dirs, and icon mapping
- `calendar/` - weather.sh, .env (OpenWeatherMap config)
- `functions/ColorUtils.qml` - Color utilities

### Key Architecture Rules
- **Each popup is its own PanelWindow** with `exclusiveZone: 0`
- **Popup click-outside-to-close** - Popups close when cursor moves away from top edge (y > 50)
- **Singleton services** - `pragma Singleton` + `services/qmldir` entry
- **ShellState.activePopup pattern** - Mutual exclusion via single string property
- **Popups use Loader-based animations** - Notification panel and quick actions use Loader with states/transitions
- **GlobalShortcut uses `onPressed`** - name is bare action (e.g., `barToggle`)
- **Root type is `Item`** - not `QtObject` or `Singleton`
- **Cheatsheet executable actions** - power actions show confirmation dialog; others copy keybind to clipboard
- **Notification toasts use ListModel** - Separate `toastList` (max 3) from `notifications` (JS array)
- **Notification icons** - Resolves app icons from system hicolor/pixmaps dirs via `NotificationUtils.getAppIconCandidates()`; falls back to Nerd Font icons based on summary text
- **OSD for volume/brightness** - Watches service properties, auto-hides after 2s; updates in-place if already visible (no restart animation)
- **PanelWindow doesn't support anchors.horizontalCenter** - Use `anchors.left: true` with calculated `margins.left`
- **Low battery notification** - BatteryService warns at configurable threshold (default 20%), critical urgency toast
- **Notification persistence** - Saved to ~/.cache/quickshell/notifications.json, restored on reload
- **Notification action buttons** - Chip buttons for notification actions (Reply, Dismiss, etc.)
- **Urgency-based styling** - Critical notifications get red border and 15s dismiss timeout
- **CPU temperature** - SystemService reads coretemp from /sys/class/hwmon, color-coded (green/yellow/red)
- **Network speed** - NetworkService reads /proc/net/dev wlan0, shows KB/s or MB/s next to WiFi icon

### Key Decisions
- Colors bound to ColorService (Material You from matugen)
- **All keybinds in one file** (`hypr/keybinds.conf`) for cheatsheet generation
- **Shell toggles use global IPC** (`global, quickshell:<action>`)
- **Notification DBus server** - Single `NotificationServer` in `NotificationService.qml`
- **swaybg for wallpaper setting** - swww not in repos
- **Wallpaper thumbnails pre-generated** - In `~/.cache/quickshell/wallpaper_picker/thumbs/`
- **Night light toggle** - `Super + Shift + N` toggles hyprsunset on/off
- **Weather location configurable** - Edit `calendar/.env` with OpenWeatherMap city ID

## Scripts
All scripts live at `~/.config/scripts/` (symlinked from `~/Desktop/Trotid_Shell/scripts/`).

### Screenshots (`~/.config/scripts/screenshots/screenshot.sh`)
| Key | Mode |
|-----|------|
| `Print` | Full screen to clipboard |
| `Ctrl+Print` | Region select |
| `Shift+Print` | Window select |
| `Alt+Print` | Monitor select |
| `Ctrl+Shift+Print` | Region select + swappy annotation |

Uses `grim` + `slurp`. Saves to `~/Pictures/Screenshots/`, copies to clipboard via `wl-copy`. Annotation uses `swappy`.

### Screen Recording (`~/.config/scripts/recording/recording.sh`)
| Key | Mode |
|-----|------|
| `Ctrl+Shift+R` | Region recording / stop |
| `Ctrl+Alt+R` | Full screen recording / stop |

Uses `wf-recorder`. Saves to `~/Videos/Recordings/`.

### Clipboard History (`~/.config/scripts/clipboard-picker.sh`)
- `Super+V` - Opens clipboard history picker (rofi + cliphist)
- Shows text and image previews

### Rofi Launcher
- `Super+Space` - App launcher (rofi style-1)

## Keybinds Reference
| Key | Action | IPC Command |
|-----|--------|-------------|
| `Super + O` | Toggle bar | `quickshell:barToggle` |
| `Super + A` | Toggle notification panel | `quickshell:notificationPanelToggle` |
| `Super + M` | Toggle media card | `quickshell:mediaControlsToggle` |
| `Super + J` | Toggle quick actions HUD | `quickshell:quickActionsToggle` |
| `Super + /` | Toggle cheatsheet | `quickshell:cheatsheetToggle` |
| `Ctrl + Super + T` | Toggle wallpaper picker | `quickshell:wallpaperToggle` |
| `Super + Tab` | Next workspace | Hyprland dispatch |
| `Super + Shift + Tab` | Previous workspace | Hyprland dispatch |
| `Super + Return` | Terminal (ghostty) | exec |
| `Super + Space` | App launcher (rofi) | exec |
| `Super + V` | Clipboard history | exec |
| `Super + W` | Browser (zen) | exec |
| `Super + E` | File manager (thunar) | exec |
| `Super + C` | Editor (nvim) | exec |
| `Super + Q` | Close window | killactive |
| `Super + G` | Toggle floating | togglefloating |
| `Super + F` | Fullscreen | fullscreen |
| `Super + S` | Scratchpad | togglespecialworkspace |
| `Super + Shift + N` | Toggle night light | exec (hyprsunset toggle) |
| `Super + Shift + P` | Lock screen | loginctl lock-session |
| `Super + Shift + L` | Suspend | systemctl suspend |
| `Ctrl + Super + R` | Restart Quickshell | exec |
| `Print` | Full screenshot | exec |
| `Ctrl + Print` | Region screenshot | exec |
| `Shift + Print` | Window screenshot | exec |
| `Ctrl + Shift + Print` | Annotate screenshot (swappy) | exec |
| `Alt + Print` | Monitor screenshot | exec |
| `Super + Shift + C` | Color picker (hyprpicker) | exec |
| `Ctrl + Shift + R` | Region recording | exec |
| `Ctrl + Alt + R` | Full recording | exec |

## Verification
- Check if changes survived wallpaper switch: Run `wallset`
- Test theme application: `wallset-backend` applies without changing wallpaper
- Test notification panel: `notify-send "test" "body"`
- Test quick actions: `Super + J`
- Test wallpaper picker: `Ctrl + Super + T`
- Test OSD: Adjust volume/brightness
- Test night light: `Super + Shift + N`
- Test power menu: Open cheatsheet, click Power off

## Audit Log

### Fixed Issues
- **B2 (PowerProfiles)** - Legacy copies contained `PowerProfiles.profile` without import. Fixed by syncing services.
- **B1 (Qt.Object.assign)** - Legacy `NotificationPanel.qml` had `Qt.Object.assign()`. Fixed by syncing widgets.
- **F11 (NotificationPopup accent color)** - Was matching `notif.title` instead of `appName`. Fixed.
- **F9 (Window title width)** - Doubled from 200px to 400px max.
- **OSD signal names** - Used `onVolumeChanged` (doesn't exist); fixed to `onVolumePercentChanged`. PanelWindow was invisible on startup — removed `visible` binding so surface always exists.
- **OSD update-in-place** - Rapid changes now update values without restarting entry animation.
- **BrightnessService poll** - 5000ms → 200ms to match VolumeService responsiveness.
- **Notification startup sound guard** - 1.5s guard prevents replayed notifications from playing sound on reload.
- **ColorService hardcoded path** - Replaced `/home/mrtrotid-ssd/` with `Quickshell.env("HOME")`.
- **ColorService idle CPU** - Skips `_parseColors()` when JSON string is unchanged.
- **NetworkService SSID colons** - Uses `nmcli -e yes` and unescapes `\:` → `:` for SSIDs containing colons.
- **AudioService section detection** - Switched from exact match to prefix match (`indexOf`) for forward-compat.
- **VolumeService/AudioService merged** - Eliminated independent 200ms poll; volume driven by AudioService's `wpctl status`.
- **AudioService sink parsing (Devices eating Sinks)** - New Devices section parsing intercepted `Sinks:` header and `continue`d past Sinks detection, so sinks were never parsed. Fixed by letting Devices exit fall through to section detection.
- **AudioService mic mute optimistic toggle** - `toggleMicMute()` was setting `micMuted = !micMuted` before wpctl command ran, causing UI/state mismatch. Fixed: no optimistic toggle; immediate 200ms re-poll after `wpctl set-mute` for actual state.
- **AudioService Bluetooth mic duplicate** - Bluetooth sources appeared in both Sources (friendly name) and Filters (raw `bluez_input.xxx`). Fixed: Filters section skips all `bluez_` entries since Sources always has the friendly-name version.
- **AudioService mic source cycling race** - Sources array empty on early right-click (before first 3s poll). Fixed: forces re-poll if sources empty during cycle.

### Added Features
- **xdg-desktop-portal-hyprland** - Added to exec-once for screen share, file pickers, Flatpak
- **OSD for volume/brightness** - OsdPopup.qml with animated popup, progress bar, 2s auto-hide
- **Power menu confirm dialog** - Cheatsheet shows confirmation for poweroff/reboot/suspend
- **Night light toggle** - `Super + Shift + N` keybind for hyprsunset
- **Weather location docs** - Updated .env with city ID examples
- **CPU temperature chip** - SystemService reads coretemp from /sys/class/hwmon, color-coded display in bar
- **Network speed indicator** - NetworkService reads /proc/net/dev, shows ↓/↑ KB/s or MB/s next to WiFi icon
- **Notification action buttons** - Chip buttons for notification actions (Reply, Dismiss, etc.)
- **Urgency-based notification styling** - Critical notifications get red border and 15s dismiss timeout
- **Notification persistence** - Notifications saved to ~/.cache/quickshell/notifications.json, restored on reload
- **Low battery notification** - BatteryService warns at configurable threshold (default 20%), critical urgency toast
- **Wallpaper restore on startup** - shell.qml restores last wallpaper from current_wallpaper.png on Component.onCompleted
- **Charging battery color** - Battery pill shows sky blue (#7dd3fc) when charging
- **Hypridle timeouts** - Dim: 7.5min, Lock: 10min, Screen off/Suspend: 30min

### False Claims (No Fix Needed)
- **B3** - SystemService uses Process{}, not FileView
- **B4** - BarContent has no Process{} elements
- **B6** - NotificationPanel fully connected to NotificationService via property binding
- **B7** - No Night Light toggle existed; added new keybind
- **B8** - No hardcoded username in NotificationPanel
- **B9** - Layerrules target `custom:*`, gesture syntax valid, daemons active, no duplicate keybinds
- **B10** - No swaync-client in Quickshell shell
- **B11** - Single NotificationServer in NotificationService.qml
- **F1** - WiFi icon uses `colPrimary`, not `colError`
- **F2** - BrightnessService poll is 200ms, matches VolumeService
- **F3** - AudioService parser is section-based, handles format changes gracefully
- **F4** - Layerrules for `custom:*` exist (lines 96-97 of hyprland.conf)
- **F5** - Cheatsheet fully wired in shell.qml (PanelWindow + GlobalShortcut)
- **A1** - NotificationPanel uses ColorService, no hardcoded colors
- **A2** - No 50ms blob animation timer in current code
- **A3** - NotificationServer in service, not widget
- **MissingImpact** - hypridle/hyprpolkitagent active, layerrules exist, matugen live via ColorService, gesture syntax valid, wallpaper selector wired, cheatsheet wired
