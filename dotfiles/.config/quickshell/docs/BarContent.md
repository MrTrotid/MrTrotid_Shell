# BarContent.qml - Top Bar

## Purpose
The main status bar at the top of the screen. Three-section layout: left (Nix icon + clock + active window), center (workspaces + brightness + volume), right (CPU + memory + battery + bluetooth + wifi + notifications + tray).

## Architecture
```
Item (root)
├── State properties (time, brightness, volume, CPU, memory, network, etc.)
├── Timers & Processes (polling/refreshing data)
├── LEFT SECTION (Row)
│   ├── Nix icon capsule
│   ├── Clock capsule
│   └── Active window title
├── CENTER SECTION (Rectangle capsule)
│   ├── Workspaces (6 pills, scroll to switch)
│   ├── Brightness (scroll to adjust)
│   └── Volume (scroll to adjust, click to mute)
└── RIGHT SECTION (Row in capsule)
    ├── CPU % + icon
    ├── Memory % + icon
    ├── Battery pill (color-coded, hover for tooltip)
    ├── Bluetooth icon (click to toggle BT popup)
    ├── WiFi icon (click to toggle WiFi popup)
    ├── Notifications icon (click to toggle QS)
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

## Data Sources

### Time
- 1-second timer updates `currentTime` with `HH:MM ` format

### Brightness
- `brightnessctl g` (current) / `brightnessctl m` (max)
- 150ms debounce timer after changes
- Scroll wheel on brightness text: ±5%

### Volume
- `wpctl get-volume @DEFAULT_AUDIO_SINK@` every 2 seconds
- Parses `Volume: 0.80` and `[MUTED]` flag
- Supports up to 150% (PipeWire allows over-amplification)
- Scroll wheel: ±5%, click: toggle mute

### CPU / Memory
- Reads `/proc/stat` and `/proc/meminfo` every 3 seconds
- CPU: Calculates delta between readings (user+nice+system+idle)
- Memory: `(total - available) / total * 100`

### Battery
- Uses `UPower.displayDevice` from Quickshell
- Color-coded: red (≤20%), yellow (≤70%), green (>70%)
- Hover shows tooltip with health, remaining time, power plan
- Health read from `/sys/class/power_supply/BAT*/energy_full_design`

### Network
- `nmcli monitor` for real-time changes
- `nmcli -t -f ACTIVE,SIGNAL,SSID device wifi list` for details
- Polls every 10 seconds + on nmcli event

### Active Window
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
- `onEntered`: Sets `shellState.batteryTooltipText` and `batteryTooltipVisible = true`
- `onExited`: Sets `batteryTooltipVisible = false`
- Tooltip positioned at bottom-right of bar

### Right Section Icons
| Icon | Click Action |
|------|-------------|
| Bluetooth (`\uF293`) | `toggleBluetoothPanel()` |
| WiFi (󰤨/󰤭) | `toggleWifiSelector()` |
| Notifications (󰂚) | `toggleQuickSettings()` + keep bar visible |

## Modifying This File
- To add a module: Add to the appropriate section (left/center/right)
- To change colors: Modify the color properties at the top
- To change polling intervals: Adjust timer `interval` values
- To add a new right-section icon: Add a `Text` element with `MouseArea` in `rightRow`
