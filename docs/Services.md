# services/ - Singleton Services

## Purpose
Extracted service logic from the old monolithic ServiceContext.qml and BarContent.qml. Each service is a `pragma Singleton` with its own file, registered in `services/qmldir`.

## Services

| Service | Properties | Source | Poll Interval |
|---------|-----------|--------|---------------|
| `BrightnessService` | `brightnessPercent`, `maxBrightness` | `brightnessctl g/m` | 300ms |
| `VolumeService` | `currentVolume`, `volumePercent`, `volumeMuted` | `wpctl get-volume` | 500ms |
| `NetworkService` | `networkConnected`, `networkSsid`, `networkStrength` | `nmcli monitor` + poll | event + 10s |
| `BatteryService` | `batteryDevice`, `hasBattery`, `isCharging`, `batteryPercent`, `batteryHealth` | UPower + sysfs | one-shot |
| `SystemService` | `cpuPercent`, `memoryPercent` | `/proc/stat`, `/proc/meminfo` | 2s |
| `ShellState` | UI toggle states (see ShellState.md) | — | — |

## qmldir
```
singleton BrightnessService BrightnessService.qml
singleton VolumeService VolumeService.qml
singleton NetworkService NetworkService.qml
singleton BatteryService BatteryService.qml
singleton SystemService SystemService.qml
singleton ShellState ShellState.qml
```

## Import
```qml
import "services"
// Then use: BrightnessService.brightnessPercent, ShellState.toggleBar(), etc.
```

## Notes
- Root type is `Item` (not `QtObject` — doesn't support children; not `Singleton` — not available in this Quickshell version)
- `pragma Singleton` + qmldir entry makes it a singleton
- Process running guards prevent process leaks on slow systems
- `BatteryService.hasBattery` guards against desktop/VM with no battery
- NetworkService uses nmcli polling (plan: migrate to DBus for push notifications)
