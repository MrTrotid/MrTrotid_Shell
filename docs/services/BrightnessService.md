# BrightnessService - Screen Brightness Control

## Purpose
Polls current brightness via `brightnessctl`, provides increase/decrease functions, and exposes brightness percentage for OSD and bar display.

## Architecture
Singleton service. Two Process elements read brightness and max brightness. A 200ms poll timer catches external changes (e.g., hardware keys).

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `brightnessPercent` | int | 100 | Current brightness (0-100) |
| `maxBrightness` | int | 100 | Maximum brightness value from `brightnessctl m` |

## Key Processes / Timers
| Element | Command | Interval | Purpose |
|---|---|---|---|
| `getBrightness` | `brightnessctl g` | 200ms (poll) | Reads current brightness value |
| `getMaxBrightness` | `brightnessctl m` | On demand | Reads max brightness (at startup and after changes) |
| `Timer` (poll) | - | 200ms | Triggers `getBrightness` if not already running |
| `brightRefresh` | - | 150ms (one-shot) | Debounce: re-reads after user action |

## Key Functions
| Function | Description |
|---|---|
| `increaseBrightness()` | Runs `brightnessctl s +5%`, starts `brightRefresh` |
| `decreaseBrightness()` | Runs `brightnessctl s 5%-`, starts `brightRefresh` |

## Brightness Calculation
```javascript
brightnessPercent = Math.round(val / maxBrightness * 100)
```

## Modifying This File
- Change brightness step: Modify the `5%` in `increaseBrightness()`/`decreaseBrightness()`
- Change poll interval: Modify the 200ms timer interval
- Change debounce delay: Modify `brightRefresh.interval` (default 150ms)
