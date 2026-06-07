# Architecture - Trotid Shell Overview

## Purpose
Trotid Shell is a Wayland desktop shell built on Quickshell, providing a status bar, notification system, popups, and wallpaper management for Hyprland. It uses a singleton service architecture with Material You theming via matugen.

## Source Location
All source lives at `~/Desktop/Trotid_Shell/quickshell/`, symlinked to `~/.config/quickshell/mrtrotid-shell/` and `~/.config/quickshell/custom/`.

## Entry Point: shell.qml
The single entry point is `shell.qml`. It creates a `ShellRoot` containing all surfaces. Each popup runs in its own `PanelWindow` (Wayland layer shell surface) with `exclusiveZone: 0`.

### Global Properties (shell.qml)
| Property | Type | Default | Description |
|---|---|---|---|
| `barTopMargin` | real | 10 | Top margin for bar |
| `barHeight` | real | 36 | Bar height in px |
| `barGap` | real | 4 | Gap between bar and popups |
| `popupGap` | real | 2 | Gap below bar |
| `sideMargin` | real | 8 | Left/right margin |
| `sw` | real | screen width | Screen width fallback chain |

## Component Tree
```
ShellRoot
├── PanelWindow (main)                  - Bar (WlrLayer.Top, exclusiveZone dynamic)
│   └── BarContent                      - Bar layout (left/center/right sections)
├── Window (menuAnchor)                 - Hidden tray menu anchor
├── PanelWindow (toastPopup)            - Notification toasts (centered below bar)
│   └── NotificationPopup               - Toast list delegate
├── PanelWindow (blPopup)               - Bluetooth popup (top-right)
│   └── BluetoothSelector               - Orbiting card UI
├── PanelWindow (wifiPopup)             - WiFi popup (top-right)
│   └── WifiSelector                    - Orbiting card UI
├── PanelWindow (notifPopup)            - Notification panel (top-right, slide+fade)
│   └── Loader → NotificationPanel      - Grouped notification list
├── PanelWindow (calPopup)              - Calendar popup (top-center)
│   └── CalendarPopup                   - Clock + calendar + weather
├── PanelWindow (csPopup)               - Cheatsheet popup (top-center, 85% width)
│   └── Cheatsheet                      - Keybind reference with search
├── PanelWindow (qaPopup)               - Quick actions HUD (bottom-center, slide-up)
│   └── Loader → QuickActions           - Screenshot/recording shortcuts
├── PanelWindow (wpPopup)               - Wallpaper picker (full-screen overlay)
│   └── WallpaperPicker                 - Coverflow carousel
├── PanelWindow (osdPopup)              - Volume/brightness OSD (bottom-center)
│   └── OsdPopup                        - Progress bar + icon
├── Window (mediaCard)                  - Media card (separate window, frameless)
│   └── MediaCard                       - MPRIS player info
└── GlobalShortcut (x6)                - IPC handlers for keybinds
```

## Singleton Services (services/)
Registered in `services/qmldir`. All use `pragma Singleton` and `pragma ComponentBehavior: Bound`.

| Service | Purpose | Poll Interval |
|---|---|---|
| `ShellState` | UI toggle states, activePopup mutual exclusion | - |
| `AudioService` | wpctl status parsing, sink switching, BT auto-switch | 3000ms |
| `VolumeService` | Volume level from wpctl, mute state | Driven by AudioService |
| `BrightnessService` | brightnessctl polling + control | 200ms |
| `NetworkService` | nmcli monitoring, WiFi speed from /proc/net/dev | 10000ms (fallback) |
| `BatteryService` | UPower battery state, health from sysfs | 3600000ms (health) |
| `SystemService` | CPU/memory/temp from /proc | 2000ms |
| `NotificationService` | DBus notification server, toast list, persistence | - |
| `ColorService` | Material You colors from matugen colors.json | 2000ms |

## Popup Mutual Exclusion (ShellState.activePopup)
Only one popup can be open at a time. `activePopup` is a string property; derived booleans provide backward-compat bindings.

```
activePopup: ""          → No popup open
activePopup: "bluetooth" → Bluetooth popup open
activePopup: "wifi"      → WiFi popup open
activePopup: "calendar"  → Calendar popup open
activePopup: "notification" → Notification panel open
activePopup: "cheatsheet"   → Cheatsheet open
activePopup: "wallpaper"    → Wallpaper picker open
activePopup: "quickactions" → Quick actions HUD open
```

## Bar Auto-Hide
The bar auto-hides when cursor moves away from the top edge (y > 50). A 100ms poll checks `Hyprland.cursor.pos.y`. When cursor is near top (y ≤ 2), bar shows and hide timer stops. When cursor moves away, a 1500ms hide timer starts. `keepBarTemporarily()` keeps bar visible for 5000ms.

## Theming Pipeline
1. Wallpaper set via `wallset` or `wallset-backend-startup`
2. `swaybg` updates wallpaper
3. `matugen` generates Material You colors → `~/.config/quickshell/mrtrotid-shell/colors.json`
4. `ColorService` polls colors.json every 2s, updates all color properties
5. Components bind to `ColorService.*` properties for live theming

## Keybinds (Global IPC)
Global shortcuts in `shell.qml` map to `ShellState` toggle functions:

| Shortcut Name | ShellState Function |
|---|---|
| `barToggle` | `toggleBar()` |
| `notificationPanelToggle` | `toggleNotificationPanel()` |
| `mediaControlsToggle` | `toggleMediaCard()` |
| `cheatsheetToggle` | `toggleCheatsheet()` |
| `wallpaperToggle` | `toggleWallpaperPicker()` |
| `quickActionsToggle` | `toggleQuickActions()` |

## Helper Modules
- `Caching.qml` - Path management for cache/state/run dirs
- `core/NotificationUtils.js` - Time formatting, icon resolution, icon mapping
- `functions/ColorUtils.qml` - HSV/HSL color manipulation utilities
- `calendar/weather.sh` - OpenWeatherMap API script with caching
