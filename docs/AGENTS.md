# Linux Rice Dotfiles Agent Guidance

## Critical Rules
- **Never edit generated color files** (marked ⚠️ in docs): They are overwritten on every wallpaper change
- Edit templates instead: `~/.config/matugen/templates/` or `~/.config/wallust/templates/`
- Generated files include:
  - `~/.config/waybar/colors.css` and `colors-waybar.css`
  - `~/.config/rofi/colors/colors-matugen.rasi`
  - `~/.config/swaync/colors-swaync.css`
  - `~/.config/hypr/colors/*`
  - `~/.cache/wallust/colors-kitty.conf`

## Essential Commands
- Change wallpaper: `wallset` (opens selector) or `Super + W`
- Random wallpaper on login: `wallset-backend-startup` (or `Super + Shift + R`)
- Apply current wallpaper theme manually: `wallset-backend`
- Reload Hyprland: `Super + Shift + R` (restarts Hyprland)
- Toggle bar: `Super + O` (Quickshell bar visibility)
- Toggle media visualizer: `Super + M` (slides in from right)
- Toggle notification panel: `Super + A`
- Toggle cheatsheet: `Super + /` (keybind reference with executable actions)
- Toggle Calendar popup: Click time in bar
- Cycle workspaces: `Super + Tab` / `Super + Shift + Tab`
- Lock screen: `Super + Shift + P` (hyprlock)
- Suspend: `Super + Shift + L`
- Restart Quickshell: `Ctrl + Super + R`
- Test Quickshell: `quickshell -c mrtrotid-shell -v`

## Configuration Locations
- Hyprland: `dotfiles/.config/hypr/hyprland.conf` (main entry)
- Quickshell: `~/.config/quickshell/mrtrotid-shell/` (symlink → `~/Desktop/Trotid_Shell/quickshell/`)
- Quickshell (custom): `~/.config/quickshell/custom/` (same symlink target)
- Waybar (legacy): `dotfiles/.config/waybar/config.jsonc` + styles in `custom styles/`
- Rofi: Launchers in `dotfiles/.config/rofi/launchers/`, applets in `applets/`
- Kitty: `dotfiles/.config/kitty/kitty.conf` (references wallust cache)
- Wallpapers: `dotfiles/.config/wallpapers/` (scanned by selector)

## Theming Pipeline
1. Wallpaper set via `wallset` or `wallset-backend-startup`
2. `swww` updates wallpaper
3. `matugen` generates Material You colors → Waybar, Rofi, Hyprland
4. `wallust` generates terminal colors → Kitty, Hyprland
5. Components reload/Apply on next start

## Quickshell Config Structure
All config lives at `~/Desktop/Trotid_Shell/quickshell/` (symlinked to `~/.config/quickshell/{custom,mrtrotid-shell}`):

- `shell.qml` - **Single entry point**: Each component runs in its own Wayland layer shell surface:
  - `PanelWindow (main)` — Bar (exclusiveZone: 48, Top layer)
  - `PanelWindow (popupOverlay)` — Full-screen transparent overlay for click-outside-to-close (behind popups)
  - `PanelWindow (blPopup)` — Bluetooth popup (exclusiveZone: 0)
  - `PanelWindow (wifiPopup)` — WiFi popup (exclusiveZone: 0)
  - `PanelWindow (notifPopup)` — Notification panel (exclusiveZone: 0, exempt from click-outside-to-close)
  - `PanelWindow (calPopup)` — Calendar popup (exclusiveZone: 0)
  - `PanelWindow (csPopup)` — Cheatsheet popup (exclusiveZone: 0, keyboard focus enabled)
  - `PanelWindow (toastPopup)` — Notification toasts (stacked, below bar)
  - `Window (MediaCard)` — Separate window for media card slide-in
  - `GlobalShortcut` handlers — IPC from keybinds.conf
- `services/` - **Singleton services** (pragma Singleton + qmldir):
  - `ShellState.qml` — UI toggle states (activePopup pattern for mutual exclusion)
  - `AudioService.qml` — wpctl sink enumeration, switching, Bluetooth auto-switch/revert
  - `BrightnessService.qml` — Brightness polling + control
  - `VolumeService.qml` — Volume polling + control
  - `NetworkService.qml` — nmcli monitoring
  - `BatteryService.qml` — UPower + health (hasBattery fallback for desktop)
  - `SystemService.qml` — CPU + memory from /proc
  - `NotificationService.qml` — File-based IPC notifications, sound playback
- `BarContent.qml` - Bar layout (colors, workspace pills, clock) — binds to singleton services
- `widgets/` - MediaCard.qml, PlayerCard.qml, WaveVisualizer.qml, CalendarPopup.qml, WifiSelector.qml, BluetoothSelector.qml, NotificationPanel.qml, NotificationPopup.qml, WorkspaceOverview.qml, Cheatsheet.qml
- `calendar/` - weather.sh, .env (OpenWeatherMap config)
- `functions/ColorUtils.qml` - Color utilities
- `reload.sh` - Restart Quickshell for testing

### Key Architecture Rules
- **Each popup is its own PanelWindow** with `exclusiveZone: 0` for independent input regions (Wayland layer shell limitation)
- **Popup overlay** — Full-screen transparent PanelWindow (`popupOverlay`) sits behind popups. Clicking it closes the active popup. Exempts notification panel.
- **Singleton services** — Each service is `pragma Singleton` + `services/qmldir` entry. Bar and popups import `"services"` and bind to singleton properties directly.
- **ShellState.activePopup pattern** — Mutual exclusion via single string property (`"bluetooth" | "wifi" | "calendar" | "notification" | "cheatsheet" | ""`). Derived booleans (`bluetoothPanelOpen`, etc.) provide backward compat.
- **No more ServiceContext** — Replaced by singleton services. No prop drilling.
- **Popups use opacity fade** (not height animation) to avoid flicker
- **QML property scope**: property declarations on a parent Item are NOT visible inside Repeater delegates or nested layouts — always prefix with parent id
- **GlobalShortcut uses `onPressed`** (not `onActivated`) — name is bare action (e.g., `barToggle`), not `quickshell:barToggle`
- **Root type is `Item`** (not `QtObject` or `Singleton`) — QtObject doesn't support child elements; `Singleton` type not available in this Quickshell version
- **Cheatsheet keyboard focus** — `WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand` enables text input in the search field
- **Cheatsheet executable actions** — Categories with `action` field (Apps, Session, Screenshots, Recording) execute commands on click; others copy keybind to clipboard

### Key Decisions
- Colors are hardcoded hex (#1a2120 etc.) matching current matugen theme
- Media Card remains as a separate Window (for slide-in animation with `Behavior on x`)
- **All keybinds in one file** (`hypr/keybinds.conf`) for cheatsheet generation
- **Shell toggles use global IPC** (`global, quickshell:<action>`) — no QML Shortcut elements
- **Brightness/volume have independent poll timers** — keybinds run commands externally via Hyprland exec, bypassing Quickshell
- **BatteryService.hasBattery** — null guard for desktop/VM without battery
- **Audio via wpctl** — `Quickshell.Services.Pipewire` not available in this Quickshell version
- **Click volume to cycle sinks** — most common action; mute via `XF86AudioMute` keybind
- **File-based IPC for notifications** — scripts write to `/tmp/quickshell-notifications`, Quickshell polls every 200ms
- **Popup click-outside-to-close** — Uses transparent overlay PanelWindow behind popups; clicking overlay closes active popup (except notification panel)
- **Cheatsheet uses horizontal scrolling** — Categories displayed side-by-side, mouse wheel scroll, visible scrollbar at bottom

## Scripts
All scripts live at `~/.config/scripts/` (symlinked from `~/Desktop/Trotid_Shell/scripts/`).

### Screenshots (`~/.config/scripts/screenshots/screenshot.sh`)
| Key | Mode |
|-----|------|
| `Print` | Full screen to clipboard |
| `Ctrl+Print` | Full screen to file |
| `Shift+Print` | Region select |
| `Alt+Print` | Window select |
| `Ctrl+Shift+Print` | Monitor select |
| `Ctrl+Alt+Print` | Timed full screen (5s delay) |

Uses `grim` + `slurp`. Saves to `~/Pictures/Screenshots/`, copies to clipboard via `wl-copy`.

### Screen Recording (`~/.config/scripts/recording/recording.sh`)
| Key | Mode |
|-----|------|
| `Ctrl+Shift+R` | Region recording (select region → pick audio → record) / Stop if recording |
| `Ctrl+Alt+R` | Full screen recording (pick audio → record) / Stop if recording |

**Audio options (rofi picker, positioned near selection):**
- Device audio only — records from output sink monitor (what you hear)
- Input audio (mic) — records from microphone
- Both (device + input) — records video with wf-recorder, captures mixed audio with ffmpeg, merges on stop
- No audio — video only

Uses `wf-recorder`. Saves to `~/Videos/Recordings/`.

### Clipboard History (`~/.config/scripts/clipboard-picker.sh`)
- `Super+V` — Opens clipboard history picker (rofi + cliphist)
- Shows text and image previews (images via ImageMagick thumbnails)
- Config: `~/.config/cliphist/config` (max-items: 10000)
- Clipboard watchers: `wl-paste --type text --watch cliphist store` and `wl-paste --type image --watch cliphist store`

### Rofi Launcher
- `Super+Space` — App launcher (rofi style-1)

## Verification
- Check if changes survived wallpaper switch: Run `wallset` → pick same/wallpaper
- Test theme application: `wallset-backend` applies without changing wallpaper
