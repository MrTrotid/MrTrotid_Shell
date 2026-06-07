# NetworkService - WiFi Status & Speed Monitoring

## Purpose
Monitors WiFi connection state, SSID, signal strength, and network speed (KB/s) using nmcli and /proc/net/dev.

## Architecture
Singleton service. Uses `nmcli monitor` for real-time events (debounced 500ms), a 10s fallback poll, and a 2s net speed poll.

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `networkConnected` | bool | false | Whether WiFi is connected |
| `networkSsid` | string | "" | Current SSID |
| `networkStrength` | int | 0 | Signal strength (0-100) |
| `netDown` | int | 0 | Download speed in KB/s |
| `netUp` | int | 0 | Upload speed in KB/s |
| `_prevRx` | var | -1 | Previous RX bytes from /proc/net/dev |
| `_prevTx` | var | -1 | Previous TX bytes from /proc/net/dev |

## Key Processes / Timers
| Element | Command | Interval | Purpose |
|---|---|---|---|
| `nmMonitor` | `nmcli monitor` | Event-driven | Real-time WiFi state changes |
| `nmPoll` | - | 500ms (one-shot) | Debounce after nmcli event |
| `nmUpdate` | `nmcli -t -e yes -f ACTIVE,SIGNAL,SSID device wifi list --rescan no` | 10000ms (fallback) | Polls active WiFi connection |
| `netSpeed` | `cat /proc/net/dev` | 2000ms | Calculates network throughput |
| `Timer` (fallback) | - | 10000ms | Ensures updates even if monitor misses events |
| `Timer` (speed) | - | 2000ms | Net speed calculation |

## Network Speed Calculation
```javascript
// From /proc/net/dev wlan0 line:
netDown = Math.round((rx - _prevRx) / 2000)  // KB/s (2s interval)
netUp = Math.round((tx - _prevTx) / 2000)
```

## SSID Escaping
Uses `nmcli -e yes` which escapes colons as `\:` in SSIDs. The parser unescapes:
```javascript
ssid = ssid.replace(/\\:/g, ":")
```

## nmcli Output Format
```
ACTIVE:SIGNAL:SSID
yes:75:MyNetwork
```
First colon separates ACTIVE, second colon separates SIGNAL from SSID (which may contain colons).

## Modifying This File
- Change net speed interval: Modify `Timer.interval` (default 2000ms)
- Change WiFi poll interval: Modify fallback `Timer.interval` (default 10000ms)
- Change debounce: Modify `nmPoll.interval` (default 500ms)
- Add network interface: Modify `netSpeed` command to parse different interface
