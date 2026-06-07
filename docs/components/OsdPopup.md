# OsdPopup - Volume/Brightness On-Screen Display

## Purpose
Shows a brief popup when volume or brightness changes, displaying an icon, progress bar, and percentage. Auto-hides after 2 seconds.

## Architecture
```
Item (root)
├── Timer (hideTimer) - 2s auto-hide
├── NumberAnimation (entryAnim) - Fade in 150ms
├── NumberAnimation (exitAnim) - Fade out 200ms
├── Connections (VolumeService.onVolumePercentChanged)
├── Connections (BrightnessService.onBrightnessPercentChanged)
└── Rectangle (osdRect, 200x60, radius: 16)
    └── RowLayout
        ├── Rectangle (icon container, 36x36)
        │   └── Text (osdIcon)
        ├── ColumnLayout
        │   ├── Text (type label: "Volume"/"Brightness"/"Microphone")
        │   ├── Rectangle (progress bar, 4px height)
        │   │   └── Rectangle (fill)
        │   └── Text (mic label, if type === "mic")
        └── Text (percentage, if not mic)
```

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `showOsd` | bool | false | OSD visibility |
| `osdType` | string | "" | "volume" / "brightness" / "mic" |
| `osdValue` | int | 0 | Current value (0-100) |
| `osdIcon` | string | "" | Nerd Font icon |
| `osdLabel` | string | "" | Label text (for mic) |
| `_lastVolume` | int | -1 | Previous volume (prevents duplicate triggers) |
| `_lastBrightness` | int | -1 | Previous brightness |

## Key Functions
| Function | Description |
|---|---|
| `trigger(type, value, icon)` | Shows/updates OSD for volume/brightness |
| `triggerMic(icon, label)` | Shows/updates OSD for mic mute/cycle |

## Service Connections
| Signal | Handler |
|---|---|
| `VolumeService.onVolumePercentChanged` | Triggers volume OSD (skips if same value) |
| `BrightnessService.onBrightnessPercentChanged` | Triggers brightness OSD (skips if same value) |

## Volume Icons
| Condition | Icon |
|---|---|
| Volume = 0 | 󰝟 (muted) |
| Volume < 50 | 󰕿 (low) |
| Volume ≥ 50 | 󰕾 (high) |

## Update-in-Place Behavior
If OSD is already visible when a new change occurs:
- Only restarts the `hideTimer` (2s)
- Does NOT restart entry animation
- Updates value/icon in-place

## Progress Bar
- Width: `parent.width * (osdValue / 100)`
- Color: `ColorService.primary`
- Animated: `Behavior on width { NumberAnimation { duration: 100 } }`
- Hidden when `osdType === "mic"`

## Modifying This File
- Change auto-hide duration: Modify `hideTimer.interval` (default 2000ms)
- Change animation timing: Modify `entryAnim`/`exitAnim` durations
- Add new OSD types: Add to `trigger()` function and connections
