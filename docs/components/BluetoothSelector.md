# BluetoothSelector - Bluetooth Device Management UI

## Purpose
Orbiting-card UI for managing Bluetooth devices. Shows connected/paired devices, allows scanning, connecting, disconnecting, and removing devices.

## Architecture
```
Item (root)
└── Item (scale/opacity wrapper)
    └── Rectangle (main container, clip: true)
        ├── Rectangle (ambient blob 1)
        ├── Rectangle (ambient blob 2)
        ├── Item (radarItem) - 3 radar ring circles
        ├── Item (orbitContainer)
        │   ├── Item (coreItem) - Central hub with icon/status
        │   │   ├── MultiEffect (shadow)
        │   │   ├── Rectangle (centralCore) - Gradient circle
        │   │   │   ├── Rectangle (pulse ring)
        │   │   │   ├── Item (scanning ripple)
        │   │   │   ├── ColumnLayout (core content)
        │   │   │   ├── Canvas (disconnect wave)
        │   │   │   └── MouseArea (coreMa)
        │   │   └── ...
        │   └── Repeater (orbitRepeater) - Orbiting device cards
        └── Rectangle (footer) - Power toggle button
```

## View Modes
```
home → devices → detail
  ↓       ↓        ↓
home ←── home ←── home
  ↓
scanning
```

| Mode | Description |
|---|---|
| `home` | Shows core BT icon, "Scan Devices" card, Connected/Paired nav cards |
| `devices` | Shows list of connected or paired devices as orbiting cards |
| `detail` | Shows device info, disconnect/forget actions, battery level |
| `scanning` | Active scan with countdown, shows new devices |

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `btEnabled` | bool | false | Bluetooth adapter powered |
| `connectedDevices` | var | [] | Currently connected devices |
| `devices` | var | [] | All known devices |
| `scanning` | bool | false | Scan in progress |
| `scanCountdown` | int | 0 | Seconds remaining in scan |
| `deviceBattery` | string | "" | Selected device battery level |
| `viewMode` | string | "home" | Current view mode |
| `selectedDevice` | var | null | Device being inspected |
| `connectedMacs` | var | [] | MACs of connected devices |
| `pairedMacs` | var | [] | MACs of paired devices |

## Key Processes / Timers
| Element | Command | Interval | Purpose |
|---|---|---|---|
| `btPoll` | `bluetoothctl show \| grep Powered` | 6000ms | Polls BT power state |
| `btListAll` | `bluetoothctl devices` | 6000ms | Lists all known devices |
| `btListConnected` | `bluetoothctl devices Connected` | 6000ms | Lists connected devices |
| `btListPaired` | `bluetoothctl devices Paired` | 6000ms | Lists paired devices |
| `scanProcess` | `bluetoothctl --timeout 30 scan on` | 30s max | Active device scan |
| `batCheckCmd` | `bluetoothctl info '<mac>'` | On demand | Checks device battery |
| `Timer` (scan countdown) | - | 1000ms | Counts down scan timer |

## Key Functions
| Function | Description |
|---|---|
| `toggleBt()` | Power on/off via `bluetoothctl power on/off` |
| `connectDevice(mac)` | Trust + connect via bluetoothctl |
| `disconnectDevice(mac)` | Disconnect via bluetoothctl |
| `triggerScan()` | Start 30s scan with countdown |
| `stopScan()` | Stop scan, refresh device lists |
| `removeDevice(mac)` | Remove device pairing |
| `goHome()` / `goDevices()` / `goDetail()` | Navigate between views |

## Orbiting Cards
Cards orbit the central core with:
- `globalOrbitAngle` animating over 200s (infinite loop)
- Per-card `baseAngle` based on index/total
- `orbitRadiusX: 200 + (index % 2) * 30`
- `orbitRadiusY: 140 + (index % 2) * 20`
- `bobOffset: Math.sin(globalOrbitAngle * 6) * 8`

## Device Icon Detection
`_detectIcon(name, btIcon)` maps device names to Nerd Font icons using regex patterns for headphones, speakers, keyboards, mice, phones, tablets, etc.

## Intro Animation
Sequential animation on show:
1. `introMain` (0→1, 400ms, OutQuart)
2. `introBg` (0→1, 600ms, OutSine, +50ms delay)
3. `introCore` (0→1, 500ms, OutBack, +120ms delay)
4. `introCards` (0→1, 500ms, OutQuint, +200ms delay)
5. `introFooter` (0→1, 400ms, OutQuint, +300ms delay)

## Modifying This File
- Change scan duration: Modify `scanTimer.interval` (31000ms) and `scanProcess` timeout
- Add device types: Add entries to `_btIconMap` or regex patterns in `_detectIcon()`
- Change orbit parameters: Modify `orbitRadiusX`, `orbitRadiusY`, `globalOrbitAngle` duration
