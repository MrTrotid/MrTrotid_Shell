# Linux Rice Dotfiles Agent Guidance

## Critical Rules
- **Never edit generated color files** (marked in docs): They are overwritten on every wallpaper change
- Edit templates instead: `~/.config/matugen/templates/` or `~/.config/wallust/templates/`
- Generated files include:
  - `~/.config/waybar/colors.css` and `colors-waybar.css`
  - `~/.config/rofi/colors/colors-matugen.rasi`
  - `~/.config/hypr/colors/*`
  - `~/.cache/wallust/colors-kitty.conf`
  - `~/.config/wlogout/style.css` (generated from matugen template)

## Setup Instructions

### Fresh Install
```bash
# Clone the repo
git clone https://github.com/Noro18/linux-ricing-dotfiles ~/Desktop/MrTrotid_Shell
cd ~/Desktop/MrTrotid_Shell

# Run the installer (Arch-based systems)
chmod +x install.sh && ./install.sh
```

This will:
- Install all required packages (Hyprland, Quickshell, wallust, matugen, etc.)
- Backup existing configs to `~/.config.bak-<timestamp>/`
- Symlink quickshell config for live development updates
- Copy hypr, rofi, kitty, wallpapers, and other configs
- Copy bin scripts (wallset-backend, etc.) to `~/.local/bin/`
- Symlink wlogout and scripts directories
- Install JetBrains Nerd Font
- Set up quickshell-overview user config
- Add Quickshell auto-start to hyprland.conf

### Post-Install
```bash
# Log out and back in to Hyprland, then:
wallset                    # Set initial wallpaper (triggers theming pipeline)
Super + /                  # Open keybind cheatsheet
Super + I                  # Open settings panel
```

### Dev Workflow (after install)
```bash
./reload.sh                # Reload Quickshell after QML edits
./start-trotid.sh          # Launch Hyprland with this config (for testing)
```

### Update Shell (from Settings panel)
1. Open Settings with `Super + I`
2. Go to the **About** tab
3. The **Update Shell** section auto-detects the repo path
4. Click **Check Updates** to fetch and show commits behind
5. Click **Update Now** to pull latest changes
6. Click **Restart Shell** to apply

## Essential Commands
- Change wallpaper: `wallset` (opens selector) or `Super + W`
- Random wallpaper on login: `wallset-backend-startup`
- Apply current wallpaper theme manually: `wallset-backend`
- Toggle bar: `Super + O` (Quickshell bar visibility)
- Toggle media visualizer: `Super + M` (slides in from right)
- Toggle notification panel: `Super + A` (slide-in from right)
- Toggle quick actions HUD: `Super + J` (slide-up from bottom)
- Toggle cheatsheet: `Super + /` (keybind reference with executable actions)
- Toggle settings panel: `Super + I` (floating centered panel with General/About sections)
- Toggle power menu: `Super + P` (wlogout overlay — lock/suspend/logout/reboot/power off)
- Toggle Calendar popup: Click time in bar
- Toggle workspace overview: `Super + Tab` (quickshell-overview GUI)
- Lock screen: `Super + Shift + P` (hyprlock)
- Suspend: `Super + Shift + L`
- Toggle night light: `Super + Shift + N` (hyprsunset)
- Restart Quickshell: `Ctrl + Super + R`
- Test Quickshell: `quickshell -c mrtrotid-shell -v`

## Configuration Locations
- Hyprland: `dotfiles/.config/hypr/hyprland.conf` (main entry)
- Quickshell: `~/.config/quickshell/mrtrotid-shell/` (symlink to `~/Desktop/MrTrotid_Shell/dotfiles/.config/quickshell/mrtrotid-shell/`)
- Quickshell (custom): `~/.config/quickshell/custom/` (same symlink target)
- Rofi: Launchers in `dotfiles/.config/rofi/launchers/`, applets in `applets/`
- Kitty: `dotfiles/.config/kitty/kitty.conf` (references wallust cache)
- Wallpapers: `dotfiles/.config/wallpapers/` (scanned by selector)
- wlogout: `~/.config/wlogout/` (symlink to `~/Desktop/Trotid_Shell/wlogout/`)

## Theming Pipeline
1. Wallpaper set via `wallset` (rofi selector), `Ctrl+Super+T` (Quickshell picker), or `wallset-backend-startup`
2. `wallset-backend` runs: `swaybg` (wallpaper), `wallust` (terminal colors), `matugen` (Material You colors), `pywal_cava`, lock screen bg copy, swaync restart
3. `ColorService` reads `colors.json` via `Process` + `cat` (2s polling) — updates bar and popup colors live
4. `wallust` generates terminal colors -> Kitty, Hyprland, waybar, rofi
5. All components update live via singleton service bindings

## Quickshell Config Structure
All config lives at `~/Desktop/MrTrotid_Shell/dotfiles/.config/quickshell/mrtrotid-shell/` (symlinked to `~/.config/quickshell/mrtrotid-shell/`):

- `shell.qml` - **Single entry point**: Each component runs in its own Wayland layer shell surface:
  - `PanelWindow (main)` - Bar (exclusiveZone: 34, Top layer)
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
  - `PanelWindow (clipboardPopup)` - Clipboard manager (left side, cliphist integration)
  - `PanelWindow (emojiPopup)` - Emoji picker (left side, 5 categories)
  - `PanelWindow (gifPopup)` - GIF picker (left side, Tenor API search)
  - `PanelWindow (powerPopup)` - Power menu overlay (unused, wlogout used instead)
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
  - `NotificationService.qml` - DBus notification server, grouped notifications, toast list, startup sound guard (1.5s), persistence to ~/.cache/quickshell/notifications.json, action buttons (keeps NotificationAction refs for invoke()), urgency-based styling
  - `ColorService.qml` - Reads matugen colors.json via `Process` + `cat` (2s polling) — requires `import Quickshell` for `Quickshell.env("HOME")`
- `BarContent.qml` - Bar layout, binds to singleton services
- `widgets/` - All popup widgets including OsdPopup.qml, ClipboardManager.qml, EmojiPicker.qml, GifPicker.qml, PowerMenu.qml
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
- **Notification action buttons** - Chip buttons for notification actions (Reply, Dismiss, etc.) — keeps original NotificationAction refs for invoke()
- **Urgency-based styling** - Critical notifications get red border and 15s dismiss timeout
- **CPU temperature** - SystemService reads coretemp from /sys/class/hwmon, color-coded (green/yellow/red)
- **Network speed** - NetworkService reads /proc/net/dev wlan0, shows KB/s or MB/s next to WiFi icon

### ColorService Theming Status
All themeable widgets now use `ColorService` (Material You from matugen). ColorService properties are:

| ColorService property | Maps to `colors.json` key | Usage |
|----------------------|--------------------------|-------|
| `surfaceContainerLow` | `surface_container_low` | Deepest background (base) |
| `surface / surfaceContainer` | `surface` / `surface_container` | Card/panel backgrounds |
| `surfaceContainerHigh` / `surfaceContainerHighest` | `surface_container_high` / `_highest` | Elevated surfaces |
| `surfaceText` | `on_surface` | Primary text |
| `surfaceVariantText` | `on_surface_variant` | Secondary/subtitle text |
| `primary` | `primary` | Accent color |
| `primaryText` | `on_primary` | Text on primary backgrounds |
| `primaryContainer` | `primary_container` | Lighter accent fills |
| `error` | `error` | Error/red |
| `errorText` | `on_error` | Text on error backgrounds |
| `errorContainer` | `error_container` | Error fills |
| `outline` | `outline` | Borders, muted secondary text |
| `outlineVariant` | `outline_variant` | Subtle borders/surfaces |
| `success` / `blue` / `yellow` / `red` | Custom keys | Semantic colors |
| `scrim` / `shadow` | `scrim` / `shadow` | Overlays, shadows |

**Critical rule**: `_over0` secondary text must map to `ColorService.outline` (#6a7170), NOT `outlineVariant` (#4a4e4d) or `surfaceContainerHigh` (#2b3130). Surface colors are invisible on dark backgrounds — only text-level colors work.

**Battery indicator colors are hardcoded** (not ColorService) — they're functional/universal: `"#7dd3fc"` (charging), `"#4ade80"` (≥60%), `"#facc15"` (≥30%), `"#f87171"` (<30%).

### Key Decisions
- Colors bound to ColorService (Material You from matugen)
- **All keybinds in one file** (`hypr/keybinds.conf`) for cheatsheet generation
- **Shell toggles use global IPC** (`global, quickshell:<action>`)
- **Notification DBus server** - Single `NotificationServer` in `NotificationService.qml`
- **swaybg for wallpaper setting** - swww not in repos
- **Wallpaper thumbnails pre-generated** - In `~/.cache/quickshell/wallpaper_picker/thumbs/`
- **Night light toggle** - `Super + Shift + N` toggles hyprsunset on/off
- **Weather location configurable** - Edit `calendar/.env` with OpenWeatherMap city ID
- **Wallpaper picker uses wallset-backend** - Calls `$HOME/.local/bin/wallset-backend` (full path required) for unified theming pipeline
- **ColorService uses Process+cat** - `FileView.reload()` doesn't detect atomic file rewrites; `Process` + `cat` forces fresh read every 2s
- **Quickshell.env() requires `import Quickshell`** - Not included in `Quickshell.Io`; missing import causes `ReferenceError: Quickshell is not defined` at runtime

## Workspace Overview (quickshell-overview)
### Architecture
- Installed from AUR — system files at `/etc/xdg/quickshell/overview/`
- **User config override**: Copy all system files to `~/.config/quickshell/overview/` (user path takes priority over system path)
- IPC: `qs ipc -c overview call overview toggle` (`target: "overview"`, function: `toggle()`/`open()`/`close()`)
- Keybind: `Super + Tab` → `qs ipc -c overview call overview toggle`

### Navigation
| Key | Action |
|-----|--------|
| `Tab` | Next workspace (right) |
| `Shift+Tab` | Previous workspace (left) |
| `←/h` | Left one workspace |
| `→/l` | Right one workspace |
| `↑/k` | Up one row |
| `↓/j` | Down one row |
| `1-9` | Jump to 1st-9th workspace in group |
| `0` | Jump to 10th workspace |
| `Esc/Enter` | Close overview |

### Key Lessons
- **Config path matters for IPC**: `qs ipc -c overview` resolves the config path using standard search paths. If the running instance was started from `/etc/xdg/` but a user copy exists at `~/.config/quickshell/overview/`, IPC will fail with "No running instances" because it looks for the user-path instance. **Fix**: Kill the old process and restart from the user config path.
- **Override file**: `Overview.qml` at `~/.config/quickshell/overview/modules/overview/Overview.qml` — add keyboard navigation handlers here. The `Keys.onPressed` handler in the `keyHandler` Item (lines 120-214) manages all keyboard input.
- **Tab navigation added**: `Qt.Key_Tab` (next column) and `Qt.Key_Backtab` (previous column) — must be added to both the handler AND the `targetId === null` dispatch condition check.
- **Auto-start in shell.qml**: Uses `Process` with `pgrep -x qs | xargs -I{} sh -c 'cat /proc/{}/cmdline | tr "\\0" " " | grep -q "overview"' || qs -c overview` to check before starting (3s delay via Timer).
- **focused workspace indicator**: 2px colored border rectangle in `OverviewWidget.qml` (lines 1185-1205) — updates position via `Behavior on x/y` animations.

### Troubleshooting
- **"No running instances"**: Running instance was started from a different config path. Kill it and restart from the matching path.
- **Overview not appearing**: Check if process is running (`pgrep -a qs | grep overview`). If dead, nohup restart: `nohup qs -c overview > /dev/null 2>&1 & disown`.
- **Duplicate instances**: Shell.qml's auto-start checks for existing process via cmdline matching (`pgrep` + `grep -q "overview"`).
- **Config changes not picked up**: Quickshell doesn't hot-reload the overview config. Kill and restart the overview process.

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
| `Super + V` | Toggle clipboard manager | `quickshell:clipboardToggle` |
| `Super + .` | Toggle emoji picker | `quickshell:emojiToggle` |
| `Super + ,` | Toggle GIF picker | `quickshell:gifToggle` |
| `Super + Tab` | Toggle workspace overview | `qs ipc -c overview call overview toggle` |
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
| `Super + P` | Toggle power menu | wlogout |
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

## Changelog (Recent Fixes)

### Cross-Machine Compatibility
- **GPU group check**: Script verifies user belongs to `video`/`render` groups at start; adds them if missing (fixes `DRM_IOCTL_MODE_CREATE_DUMB failed: Permission denied`)
- **VM detection**: `systemd-detect-virt` with per-VM DRM fallbacks (VirtualBox → `Virtual1`, QEMU/KVM → `Virtual-1`, VMware → `Virtual1`, Hyper-V → `Virtual-1`)
- **Monitor auto-generation**: `step_monitors` generates `monitors.lua` + `monitors.conf` from `/sys/class/drm/card*-*/status`; non-interactive
- **Package failure tracking**: `FAILED_PKGS=()` array; failed repo + AUR packages tracked individually; styled "Failed Packages" box at end

### Quickshell Config
- **Restructured**: All QML files moved from `quickshell/` to `quickshell/mrtrotid-shell/` subdirectory so `quickshell -c mrtrotid-shell` resolves correctly
- **Overview config**: Stays at `quickshell/overview/` (separate qs instance)

### QML Fixes
- **Cheatsheet.qml:444**: `modelData.binds.length` → `bindsRepeater.bindsCount` (bind entries don't have `.binds`)
- **Cheatsheet.qml:301**: `hScrollBarMa` was referenced but never defined — wrapped scrollbar content in MouseArea
- **shell.qml:1093**: `exitCode` scope in `onRunningChanged` → `overviewStartProc.exitCode`

### Hyprland Lua API Fixes (0.55+)
- `hl.animation({ curve = "X" })` → `hl.animation({ bezier = "X" })` (`curve` field is silently ignored)
- `hl.dsp.togglefloating()` → `hl.dsp.window.float()` (no such namespace method)
- `hl.workspace({ id = N })` → `hl.workspace_rule({ workspace = "N" })` (`hl.workspace` does not exist)
- `size = {width=800,height=600}` → `size = "800 600"` (window rule effect uses space-separated string)
- `opacity_active` removed, merged into `opacity = "0.95 0.90"` (no such field)

### Scripts Cleaned
- `wallset-backend`, `wallset-backend-startup`, `colorscheme-backend`: removed `anaconda3/bin` PATH pollution
- `wallset-backend`, `wallset-backend-startup`, `wallock-set-backend`, `waybar-set`: removed `MONITOR="eDP-1"` hardcode (unused/swaybg uses auto-detect)
- `start-waybar`, `wallset-dark-backend-startup`: `killall` → `pkill -x`
- `colorscheme-backend`: removed `/home/noro18/anaconda3/bin/wal` and `/home/noro18/.cargo/bin/matugen` hardcoded paths
- `lyra-assistant`: now uses `$LYRA_DIR` env var instead of `/home/noro18` hardcoded path
- `setfhd`/`sethd`: auto-detect monitor name via `hyprctl monitors -j | jq -r '.[0].name'`

### Installer Fixes
- `step_backup` moved before `step_install` in pipeline
- `| tail -5` pipeline masking replaced with `spinner` + `wait` (preserves makepkg exit code)
- `killall qs quickshell` → `pkill -x qs; pkill -x quickshell` in keybinds
- `curl`/`wget` font download: added `--connect-timeout 30 --max-time 120` / `--timeout=30`
- Removed `$helper -Sy --noconfirm` partial-sync line
- `local` keyword removed from external-scope variables in functions

## Verification
- Check if changes survived wallpaper switch: Run `wallset`
- Test theme application: `wallset-backend` applies without changing wallpaper
- Test notification panel: `notify-send "test" "body"`
- Test quick actions: `Super + J`
- Test wallpaper picker: `Ctrl + Super + T`
- Test OSD: Adjust volume/brightness
- Test night light: `Super + Shift + N`
- Test power menu: `Super + P`
- Test clipboard manager: `Super + V`
- Test emoji picker: `Super + .`
- Test GIF picker: `Super + ,`

## Troubleshooting

**Colors not updating at runtime:**
- ColorService uses `Process` + `cat` to read `colors.json` every 2s (FileView doesn't detect atomic rewrites)
- Requires `import Quickshell` (not just `Quickshell.Io`) for `Quickshell.env("HOME")`
- Missing import causes silent `ReferenceError: Quickshell is not defined` — bar shows only hardcoded fallback colors
- Check logs: `quickshell -c mrtrotid-shell log | grep -i color`

**Overview not responding to IPC:**
- Running instance was started from a different config path than the IPC command resolves to
- Fix: `pkill -f "qs -c overview" && nohup qs -c overview > /dev/null 2>&1 & disown`
- Check path: `pgrep -a qs | grep overview` shows the running config path

**Ghostty crash after wallpaper change:**
- Wallset-backend previously had a `kill -USR1` loop for ghostty, which was REMOVED
- USR1 is redundant — wallust already sends OSC escape sequences for live colors
- `kill -USR1` caused ghostty to crash via SIGHUP when colliding with escape sequence processing, killing all terminal child processes
- **Never add kill -USR1 to wallset-backend**

**pkill -x over killall everywhere:**
- `killall` matches partial process names — `killall swaybg` can accidentally match other processes
- `killall qs` kills the opencode tool itself
- Always use `pkill -x <exact_name>` instead of `killall`

**Camera privacy indicator:**
- Camera usage detected via `fuser /dev/video0` (polls every 3s) — shows camera icon (`\uF030`, `colPrimary`, full opacity) when a process has the device open, or camera-off icon (`md-camera_off` at U+F05DF via surrogate pair `\uDB81\uDDDF`, 45% opacity) when idle
- Bar icon matches WiFi/Bluetooth: uses `colPrimary` with opacity differentiation
- About section in Settings panel shows Camera: IDLE / IN USE with matching icons
- Simple ON/OFF status — does not track which app is using the camera

**Wallpaper picker not applying:**
- Uses `$HOME/.local/bin/wallset-backend` (full path) — `execDetached` doesn't inherit user PATH
- wallset-backend runs swaybg, wallust, matugen, pywal_cava, lock screen bg copy, swaync restart
- If picker freezes, check if `sudo -n true` fails (wallset-backend tries sudo for SDDM copy)
