# BarContent.qml - Top Bar

## Purpose
The main status bar at the top of the screen. Three-section layout: left (Nix icon + clock + active window), center (workspaces + brightness + volume), right (CPU + memory + battery + bluetooth + wifi + notifications + tray). All service logic lives in singleton services — BarContent is pure layout and UI.

## Architecture
```
Item (root)
├── import "services"                     — Singleton services
├── Color properties                      — Monochrome teal palette
├── Local state (currentTime, activeWindowTitle, mprisPlayer)
├── LEFT SECTION (Row)
│   ├── Nix icon capsule
│   ├── Clock capsule
│   └── Active window title
├── CENTER SECTION (Rectangle capsule)
│   ├── Workspaces (6 pills, scroll to switch)
│   ├── Brightness → BrightnessService.brightnessPercent
│   └── Volume → VolumeService.volumePercent
└── RIGHT SECTION (Row in capsule)
    ├── CPU % → SystemService.cpuPercent
    ├── Memory % → SystemService.memoryPercent
    ├── Battery pill → BatteryService.*
    ├── Bluetooth → Bluetooth module + ShellState
    ├── WiFi → NetworkService + ShellState
    ├── Notifications → ShellState
    └── System tray (dynamic)
```

## Color Scheme (Monochrome Teal)
| Variable | Color | Usage |
|----------|-------|-------|
| `colSurfaceContainer` | `#1a2120` | Bar background, capsules |
| `colSurfaceContainerHighest` | `#303635` | Inactive workspace pills |
| `colOnSurface` | `#dde4e2` | Primary text |
| `colPrimary` | `#81d5ca` | Bluetooth icon, accent |
| `colOnPrimary` | `#003732` | Text on primary-colored elements |
| `colTertiary` | `#aec9e6` | Volume icon |
| `colColor3` | `#578466` | Overlay/secondary accent |
| `colColor4` | `#2D8948` | Active workspace, WiFi disconnected |
| `colError` | `#ffb4ab` | WiFi connected (red) |
| `colSuccess` | `#92d5ab` | Battery healthy |
| `colBlue` | `#96ccf8` | (unused currently) |
| `colYellow` | `#bccf81` | Battery medium |
| `colRed` | `#ffb59f` | Battery low |
| `colForeground` | `#DDDCD0` | Active window title |

## Data Sources (all in singleton services)
BarContent has **no** timers, processes, or polling. All data comes from singletons:

| Widget | Singleton | Property |
|--------|-----------|----------|
| Brightness | `BrightnessService` | `.brightnessPercent` |
| Volume | `VolumeService` | `.volumePercent`, `.volumeMuted` |
| Audio Sink | `AudioService` | `.sinks`, `.defaultSinkName`, `.sinkIcon()` |
| CPU | `SystemService` | `.cpuPercent` |
| Memory | `SystemService` | `.memoryPercent` |
| Battery | `BatteryService` | `.batteryPercent`, `.hasBattery`, `.batteryDevice` |
| WiFi | `NetworkService` | `.networkConnected` |
| Bluetooth | `Quickshell.Bluetooth` | `Bluetooth.defaultAdapter?.enabled` |

### Active Window (local)
- `hyprctl activewindow -j` on workspace/focus change
- Displays `json.title` from output

### System Tray
- `SystemTray.items.values` from Quickshell
- Filters out bluetooth/blueman items (handled by BT popup)
- Click activates the tray item

## Interactions

### Workspaces
- 6 pills, numbered 1-6
- Active workspace: wider (50px), green background, shows number
- Inactive: narrow (20px), dark background, no text
- Click to switch workspace
- Scroll wheel: `workspace r+1` / `workspace r-1`

### Battery Tooltip
- Click toggles `ShellState.batteryTooltipVisible`
- Sets `ShellState.batteryTooltipText` from `BatteryService.batteryTooltipText`
- Collapsed: battery icon + percentage
- Expanded: health, remaining time, power plan

### Right Section Icons
| Icon | Codepoint | Click Action |
|------|-----------|-------------|
| CPU | (empty) | None (display only) |
| Memory | `\uF0C9` (fa-bars) | None (display only) |
| Bluetooth on | `\uF293` | `ShellState.toggleBluetoothPanel()` |
| Bluetooth off | `\uF294` | `ShellState.toggleBluetoothPanel()` |
| WiFi connected | 󰤨 (surrogate pair) | `ShellState.toggleWifiSelector()` |
| WiFi disconnected | 󰤭 (surrogate pair) | `ShellState.toggleWifiSelector()` |
| Notifications | 󰂚 (surrogate pair) | `ShellState.toggleNotificationPanel()` + keep bar visible |
| Brightness high | `\uF185` | `BrightnessService.increaseBrightness()` |
| Brightness low | `\uF186` | `BrightnessService.decreaseBrightness()` |
| Volume high | `\uF028` | Cycles to next sink |
| Volume low | `\uF027` | Cycles to next sink |
| Volume muted | `MUTE` text | Cycles to next sink |
| Audio sink icon | dynamic per device | Hover for tooltip |

**Volume interaction:**
- Scroll: adjust volume
- Click: cycle to next audio sink (headphones → speakers → HDMI → ...)
- Hover: tooltip shows current sink name
- Mute toggle: use `XF86AudioMute` keybind

**Icon note:** All Nerd Font icons use `\uXXXX` escapes in QML. BMP codepoints (< U+FFFF) use simple escapes. Icons above U+FFFF require surrogate pairs (e.g., wifi icons).

## Modifying This File
- To add a module: Add to the appropriate section (left/center/right), bind to a singleton property
- To change colors: Modify the color properties at the top
- To add a new right-section icon: Add a `Text` element with `MouseArea` in `rightRow`
- **Do not add service logic here** — extract to a new singleton in `services/` instead
