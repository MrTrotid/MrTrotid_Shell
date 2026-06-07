# WifiSelector - WiFi Network Management UI

## Purpose
Orbiting-card UI for managing WiFi networks. Shows available/saved networks, allows connecting, disconnecting, scanning, and password entry.

## Architecture
```
Item (root)
└── Item (scale/opacity wrapper)
    └── Rectangle (main container, clip: true)
        ├── Rectangle (ambient blobs x2)
        ├── Item (radarItem) - 3 radar rings
        ├── Item (orbitContainer)
        │   ├── Item (coreItem) - Central hub
        │   │   ├── Rectangle (centralCore)
        │   │   │   ├── ColumnLayout (core content - varies by viewMode)
        │   │   │   ├── Item (pwdLayer) - Password input
        │   │   │   ├── Canvas (disconnect wave)
        │   │   │   └── MouseArea
        │   └── Repeater (orbitRepeater) - Network cards
        └── (no explicit footer)
```

## View Modes
```
home → devices → detail
  ↓       ↓        ↓
home ←── home ←── home
  ↓
saved
  ↓
scanning
```

| Mode | Description |
|---|---|
| `home` | Shows WiFi icon, connected SSID, "Networks" and "Saved" nav cards |
| `devices` | Shows available networks (signal ≥ 40 or active) |
| `detail` | Shows network info, disconnect/forget actions |
| `saved` | Shows saved network profiles |
| `scanning` | Active rescan in progress |

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `wifiEnabled` | bool | false | WiFi radio enabled |
| `wifiPresent` | bool | true | WiFi hardware present |
| `connectedNetwork` | var | null | Currently connected network entry |
| `networks` | var | [] | All visible networks |
| `savedNetworks` | var | [] | Saved connection profiles |
| `scanning` | bool | false | Scan in progress |
| `pendingSsid` | string | "" | SSID awaiting password |
| `showPassword` | bool | false | Password input visible |
| `viewMode` | string | "home" | Current view mode |
| `selectedNetwork` | var | null | Network being inspected |

## Key Processes / Timers
| Element | Command | Interval | Purpose |
|---|---|---|---|
| `wifiPoll` | `nmcli -t -f active,ssid,signal,security device wifi list` | 6000ms | Lists WiFi networks |
| `wifiPowerCheck` | `nmcli radio wifi` | 6000ms | Checks WiFi radio state |
| `savedListProc` | `nmcli -t -f NAME,TYPE connection show \| grep 802-11-wireless` | 6000ms | Lists saved networks |
| `wifiRescan` | `nmcli device wifi list --rescan yes` | On demand | Triggers network rescan |
| `connectProcess` | `nmcli device wifi connect <ssid> [password <pwd>]` | On demand | Connects to network |

## Key Functions
| Function | Description |
|---|---|
| `toggleWifi()` | Toggle WiFi radio on/off |
| `connectToNetwork(ssid, password)` | Connect via nmcli |
| `disconnectWifi()` | Disconnect WiFi device |
| `doScan()` | Trigger network rescan |
| `parseNetworks(output)` | Parse nmcli output into networks array |
| `isNetworkSaved(ssid)` | Check if network has saved profile |
| `goHome()` / `goNetworks()` / `goSaved()` / `goDetail()` | Navigate views |

## nmcli Output Format
```
ACTIVE:SSID:SIGNAL:SECURITY
yes:MyNetwork:75:WPA2
```

## Password Input
When a secured network is selected (not saved):
1. `showPassword` set to true
2. `pwdLayer` appears with TextInput
3. On Enter: calls `connectToNetwork(pendingSsid, text)`
4. On Escape: clears and hides password input

## Hold-to-Disconnect
Pressing and holding the core on home view fills a wave animation (700ms). On completion, disconnects WiFi.

## Network Card Fill Animation
Cards have a hold-to-connect fill animation:
- `fillAnim`: 600ms fill from 0→1 (InSine)
- On completion: connects to network or shows password
- `drainAnim`: 1500ms drain from fill→0 (OutQuad)

## Modifying This File
- Change signal threshold: Modify `strongNetworks` filter (default ≥ 40)
- Change scan timeout: Modify `wifiRescan` command
- Add network types: Modify `parseNetworks()` if format changes
