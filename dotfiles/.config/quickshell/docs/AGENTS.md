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
- Toggle QuickSettings: `Super + N`
- Toggle Bluetooth panel: `Super + B`
- Toggle Calendar popup: Click time in bar
- Lock screen: `Super + L` (hyprlock)
- Suspend: `Super + Shift + L`
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

- `shell.qml` - **Single entry point**: one `PanelWindow` (fixed 600px height, Top layer, exclusiveZone 36) contains:
  - `BarContent` (36px bar at top)
  - Bluetooth Panel (Item, anchored below bar)
  - QuickSettings Panel (Item, same area)
  - Battery Tooltip (Item, same area)
  - Auto-hide cursor timer
- `BarContent.qml` - Bar contents: workspace/clock/volume/backlight/battery/bt/tray/network/notifs
- `ServiceContext.qml` - Inline state store (replaces old `state/ShellState.qml` via `shellState: this`)
- `widgets/` - MediaCard.qml, PlayerCard.qml, WaveVisualizer.qml, CalendarPopup.qml, WifiSelector.qml, BluetoothSelector.qml, NotificationPanel.qml
- `calendar/` - weather.sh, .env (OpenWeatherMap config)
- `functions/ColorUtils.qml` - Color utilities

### Key Architecture Rules
- **No separate Windows for popups** - Bluetooth/QS/Tooltip are all `Item` children of the main PanelWindow
- **No separate `state/ShellState.qml`** - State is inline in ServiceContext (accessed as `ctx?.shellState.*` = `ctx.*`)
- **All service logic in BarContent.qml** - Avoids cross-file type resolution issues
- **Popups use opacity fade** (not height animation) to avoid flicker
- **QML property scope**: property declarations on a parent Item are NOT visible inside Repeater delegates or nested layouts — always prefix with parent id (`bl._surf`, `qs._prim`, etc.)

### Key Decisions
- `ctx.shellState` resolves to `ctx` itself via `readonly property var shellState: this` on ServiceContext
- Bluetooth scan: `adapter.discovering = value` (property toggle, no `startDiscovery()` available)
- Colors are hardcoded hex (#1a2120 etc.) matching current matugen theme — NOT color-generated files
- Media Card remains as a separate Window (for slide-in animation with `Behavior on x`)
- `bl._adapter?.devices?.values ?? []` to access Bluetooth device list, filter by `.paired`

## Verification
- Check if changes survived wallpaper switch: Run `wallset` → pick same/wallpaper
- Test theme application: `wallset-backend` applies without changing wallpaper