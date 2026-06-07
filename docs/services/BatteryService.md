# BatteryService - Battery State & Health Monitoring

## Purpose
Tracks battery percentage, charging state, and health (capacity ratio) via UPower and sysfs. Sends low-battery notifications when crossing the warn threshold.

## Architecture
Singleton service. Uses UPower's `displayDevice` for live state and a Process to read battery health from sysfs every hour.

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `batteryDevice` | UPowerDevice | `UPower.displayDevice` | UPower display device |
| `hasBattery` | bool (readonly) | computed | Whether a battery device exists |
| `isCharging` | bool (readonly) | computed | True if Charging, FullyCharged, or PendingCharge |
| `batteryPercent` | int (readonly) | computed | Battery percentage (0-100) |
| `warnThreshold` | int | 20 | Low battery warning threshold (%) |
| `_prevBatteryPercent` | int | -1 | Previous percent (for threshold crossing detection) |
| `batteryHealth` | real | -1 | Battery health percentage (1.0 = 100%), -1 if unknown |
| `batteryTooltipText` | string (readonly) | computed | Formatted tooltip: "Battery Health: X%\nRemaining Time: Xh Xm" |

## Key Processes / Timers
| Element | Command | Interval | Purpose |
|---|---|---|---|
| `healthProc` | Shell script reading `/sys/class/power_supply/BAT*` | 3600000ms (1h) | Reads battery health from sysfs |
| `Timer` | - | 3600000ms | Triggers `healthProc` (only if `hasBattery`) |

## Low Battery Notification
When `batteryPercent` changes:
1. If was above `warnThreshold` and now at/below → sends notification
2. Uses `NotificationService.addNotification("Battery", "Low Battery", ..., "critical")`

## Health Reading (healthProc)
The shell script:
```bash
for d in /sys/class/power_supply/BAT*; do
    # Tries energy_full_design + energy_full first
    # Falls back to charge_full_design + charge_full
    # Calculates: ef * 100 / efd (with one decimal)
done
```

## Modifying This File
- Change warning threshold: Modify `warnThreshold` (default 20%)
- Change health poll interval: Modify `Timer.interval` (default 3600000ms)
- Add battery status icons: Modify `BarContent.qml` battery pill section
