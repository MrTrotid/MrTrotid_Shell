# SystemService - CPU, Memory & Temperature Monitoring

## Purpose
Polls CPU usage, memory usage, and CPU temperature from /proc and /sys for display in the status bar.

## Architecture
Singleton service. Three Process elements read from procfs/sysfs every 2 seconds.

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `cpuPercent` | int | 0 | CPU usage percentage (0-100) |
| `cpuTemp` | int | 0 | CPU temperature in °C |
| `memoryPercent` | int | 0 | Memory usage percentage (0-100) |
| `previousCpuStats` | var | null | Previous CPU stats for delta calculation |

## Key Processes / Timers
| Element | Command | Interval | Purpose |
|---|---|---|---|
| `Timer` | - | 2000ms | Triggers all three processes |
| `tempRead` | Shell script scanning `/sys/class/hwmon/hwmon*/temp1_input` for coretemp | 2000ms | Reads CPU temperature |
| `memInfo` | `cat /proc/meminfo` | 2000ms | Reads memory usage |
| `cpuStat` | `cat /proc/stat` | 2000ms | Reads CPU time counters |

## CPU Usage Calculation
```javascript
// From /proc/stat first line:
// cpu  user nice system idle ...
var total = user + nice + system + idle
var totalDiff = total - previousCpuStats.total
var idleDiff = idle - previousCpuStats.idle
cpuPercent = Math.round((1 - idleDiff / totalDiff) * 100)
```

## Memory Usage Calculation
```javascript
// From /proc/meminfo:
memoryPercent = Math.round((MemTotal - MemAvailable) / MemTotal * 100)
```

## CPU Temperature
Reads from `/sys/class/hwmon/hwmon*/temp1_input` where the hwmon name is "coretemp". Value is in millidegrees, divided by 1000 for °C.

## Bar Display (BarContent.qml)
- CPU: `cpuPercent`% + processor icon
- CPU Temp: `cpuTemp`° + thermometer icon (color-coded: green < 65°C, yellow 65-79°C, red ≥ 80°C)
- Memory: `memoryPercent`% + memory icon

## Modifying This File
- Change poll interval: Modify Timer interval (default 2000ms)
- Add GPU temp: Add new hwmon reading for GPU
- Change temp thresholds: Modify BarContent.qml color conditions
