# BarContent - Status Bar Layout

## Purpose
The main status bar displayed at the top of the screen. Shows clock, workspaces, system stats, system tray, battery, mic, Bluetooth, WiFi, and notifications in a three-section layout.

## Architecture
```
Item (root)
├── Row (leftSection)         - Nix icon, clock, active window
├── Rectangle (centerCapsule) - Workspaces, backlight, volume
│   └── Row (centerRow)
│       ├── Row (workspaces)  - 6 workspace indicators + scroll
│       ├── Item (backlight)  - Brightness percentage + icon
│       └── Item (volume)     - Volume % + sink icon + sink switch
└── Row (rightSection)        - CPU, temp, memory, tray, battery, mic, BT, WiFi, notifs
    └── Rectangle (right capsule)
```

## Key Properties
| Property | Type | Source | Description |
|---|---|---|---|
| `colSurfaceContainer` | color | ColorService | Background capsules |
| `colOnSurface` | color | ColorService | Text on surface |
| `colPrimary` | color | ColorService | Primary accent |
| `colTertiary` | color | ColorService | Tertiary accent |
| `colError` | color | ColorService | Error/muted mic |
| `colColor3` | color | ColorService | Outline (clock bg) |
| `colColor4` | color | ColorService | Primary container (active workspace) |
| `colSuccess` | color | ColorService | Green |
| `colBlue` | color | ColorService | Blue |
| `colYellow` | color | ColorService | Yellow |
| `colRed` | color | ColorService | Red |
| `currentTime` | string | Timer | Current time "HH:MM " |
| `mprisPlayer` | var | Mpris | Current MPRIS player |
| `focusedWorkspaceId` | int | Hyprland | Active workspace ID |
| `displayTitle` | string | Hyprland | Workspace-aware window title (cleared on empty workspace) |

## Key Processes / Timers
| Element | Interval | Purpose |
|---|---|---|
| `Timer` | 1000ms | Updates `currentTime` |
| `Connections` | signal | `onFocusedWorkspaceChanged` / `onActiveToplevelChanged` → calls `updateDisplayTitle()` |

## Left Section
- **Nix icon capsule**: `󰣇` Nerd Font icon
- **Clock capsule**: Shows `currentTime`, click opens calendar popup
- **Active window capsule**: Shows `displayTitle` (workspace-aware override of `Hyprland.activeToplevel?.title`), max 400px, elided. Clears on workspace switch when no window is focused.

## Center Section
- **Workspaces**: 6 indicators (Repeater model: 6). Active workspace expands to 50px width with primary container color. Click dispatches `workspace N`. Wheel scrolls workspaces.
- **Backlight**: Shows `brightnessPercent`% + sun/moon icon. Wheel adjusts brightness.
- **Volume**: Shows volume % or "MUTE" + sink icon. Hover shows sink name. Click cycles sinks. Wheel adjusts volume.

## Right Section
- **CPU**: `cpuPercent`% + processor icon
- **CPU Temp**: `cpuTemp`° + thermometer (color-coded: green < 65, yellow 65-79, red ≥ 80)
- **Memory**: `memoryPercent`% + memory icon
- **System Tray**: Monochrome tray icons (filters out Bluetooth items), right-click for menu
- **Battery pill**: Color-coded (green ≥ 60%, yellow 30-59%, red < 30%). Click expands to show health + remaining time.
- **Mic indicator**: Muted = red `󰍭`, unmuted = primary `󰍬`. Left-click toggles mute, right-click cycles source.
- **Bluetooth**: `󰂲` (enabled) / `󰂲` (disabled). Click opens BT popup.
- **WiFi**: `󰤨` (connected) / `󰤭` (disconnected) + speed indicator (↓/↑ KB/s or MB/s). Click opens WiFi popup.
- **Notifications**: `󰂚` icon. Click opens notification panel, keeps bar visible for 5s.

## Interactions
| Element | Action | Effect |
|---|---|---|
| Clock | Click | Toggle calendar popup |
| Workspaces | Click | Switch to workspace |
| Workspaces | Wheel | Cycle workspaces |
| Backlight | Click | Increase brightness |
| Backlight | Wheel | Adjust brightness |
| Volume | Click | Cycle audio sinks |
| Volume | Wheel | Adjust volume |
| Battery | Click | Toggle tooltip |
| Mic | Left-click | Toggle mute |
| Mic | Right-click | Cycle mic source |
| Bluetooth | Click | Toggle BT popup |
| WiFi | Click | Toggle WiFi popup |
| Notifications | Click | Toggle notification panel |

## Modifying This File
- Add new bar element: Add to appropriate section Row
- Change workspace count: Modify Repeater `model: 6`
- Change max window title width: Modify `Math.min(..., 416)`
- Change capsule styling: Modify Rectangle `radius: 20`, colors
