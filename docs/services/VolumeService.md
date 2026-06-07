# VolumeService - Audio Volume Control

## Purpose
Provides volume level and mute state for the default audio sink, with functions to increase/decrease/toggle mute. Volume data is driven by AudioService's parsed wpctl output.

## Architecture
Singleton service. No independent poll — volume is updated by AudioService when it parses `wpctl status`. A debounce timer provides immediate refresh after user actions.

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `currentVolume` | real | 0.5 | Current volume (0.0-1.5, 150% max) |
| `volumePercent` | int | computed | Volume as percentage (0-150) |
| `volumeMuted` | bool | false | Whether default sink is muted |

## Key Processes / Timers
| Element | Command | Interval | Purpose |
|---|---|---|---|
| `getVolumeCmd` | `wpctl get-volume @DEFAULT_AUDIO_SINK@` | On demand | Reads current volume |
| `volRefresh` | - | 50ms (one-shot) | Debounce after user action |

## Key Functions
| Function | Description |
|---|---|
| `increaseVolume()` | Adds 2%, sets volume with max 1.5 cap, starts volRefresh |
| `decreaseVolume()` | Subtracts 2%, starts volRefresh |
| `toggleMute()` | Toggles mute on default sink, starts volRefresh |

## Volume Range
Volume supports up to 150% (over-amplification). The `wpctl set-volume` command uses `-l 1.5` for the increase command.

## wpctl Output Format
```
Volume: 0.75
Volume: 0.75 [MUTED]
```

## Modifying This File
- Change volume step: Modify the `0.02` in increase/decrease functions (2%)
- Change max volume: Modify `Math.min(1.5, ...)` and `-l 1.5`
- Change debounce: Modify `volRefresh.interval` (default 50ms)
