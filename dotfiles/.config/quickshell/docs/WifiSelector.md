# WifiSelector.qml - WiFi Network Picker

## Purpose
Orbital-style WiFi network picker. Shows networks floating around a central core with wave fill animations for connection progress. Hold-to-connect interaction with password input overlay.

## Architecture
```
Item (root)
├── Color scheme (monochrome teal)
├── State properties (wifiEnabled, networks, scanning, viewMode, etc.)
├── Signal strength icon mapping
├── Network parsing (nmcli output)
├── Saved networks (deduplicated with sort -u)
├── Polling system (wifiPoll + wifiPowerCheck + savedListProc)
├── Navigation functions (goHome, goNetworks, goSaved, goDetail)
├── Main container (Rectangle, rounded)
│   ├── Background blobs (2 floating circles)
│   ├── Radar rings (3 concentric circles)
│   ├── Orbit container
│   │   ├── Central core
│   │   │   ├── Core content (icon + SSID + status)
│   │   │   ├── Password layer (overlay for secured networks)
│   │   │   ├── Hold-to-disconnect wave (Canvas)
│   │   │   └── Pulse ring glow
│   │   └── Orbiting cards (network list)
│   └── Toggle bar (ON/OFF pill at bottom)
```

## Signal Strength Icons
Uses Nerd Font surrogate pairs (above U+FFFF):
| Signal | Icon | Unicode |
|--------|------|---------|
| ≥80% | Strong | `\uDB82\uDD28` |
| ≥60% | Good | `\uDB82\uDD25` |
| ≥40% | Fair | `\uDB82\uDD22` |
| ≥20% | Weak | `\uDB82\uDD1F` |
| <20% | Very weak | `\uDB82\uDD2F` |

## Network Filtering
Only shows networks with `signal >= 40` OR `active === "yes"` (connected network always shown):
```javascript
readonly property var strongNetworks: networks.filter(function(n) {
    return n.active === "yes" || n.signal >= 40
})
```

## View Modes (State Machine)
```
┌─────────┐    click center    ┌───────────┐
│  HOME   │ ───────────────→  │  DEVICES  │
│         │ ←── core click ── │ (networks)│
└─────────┘                   └───────────┘
     │ click saved               │ click network
     ▼                           ▼
┌─────────┐    click center    ┌───────────┐
│ SAVED   │ ───────────────→  │  DETAIL   │
│ (list)  │                   │ (actions) │
└─────────┘                   └───────────┘
```

### Home View
- **Center**: WiFi icon + SSID (if connected) or WiFi/power icon
- **Orbiting cards**:
  - [Networks] — Shows count of available networks (signal ≥ 40%)
  - [Saved Networks] — Shows count of saved profiles

### Devices View (Available Networks)
- **Center**: WiFi icon + "Available Networks"
- **Orbiting cards**: All networks with signal ≥ 40% (connected network filtered out)
- **Tap**: Go to detail view
- **Long-press**: Hold to connect (if saved, connects without password)

### Saved View
- **Center**: WiFi icon + "Saved Networks" + count
- **Orbiting cards**: Saved network profiles from `nmcli connection show`
- **Connected status**: Shows "Connected" for active network, "Tap to connect" for others
- **Tap**: Connect to network

### Detail View
- **Center**: Network icon + SSID + signal %
- **Orbiting cards**:
  - [Disconnect] (red) — Only shown if connected
  - [Forget Network] (red) — Only shown if saved
  - [Network info] — SSID + signal + security

### Scanning View
- **Center**: WiFi icon + countdown
- **Orbiting cards**: Available networks (connected filtered out)
- **Auto-navigate**: Returns to home after scan completes

## Hold-to-Connect (Cards)
Network cards use a hold-to-fill interaction:
1. **Press**: Starts `fillAnim` (600ms * remaining fill)
2. **Release before full**: `drainAnim` reverses (1500ms)
3. **Fill completes**: 
   - If connected network → disconnect
   - If secured → show password overlay
   - If open → connect immediately
4. **Visual**: Wave fill animation with gradient, text inverts to dark

## Hold-to-Disconnect (Center)
Center core has a separate hold interaction:
1. **Press**: `coreFillAnim` fills with wave (700ms)
2. **Release before full**: `coreDrainAnim` reverses (1000ms)
3. **Fill completes**: Disconnects WiFi

## Password Overlay
When connecting to a secured network:
- Scales in from 0.8 → 1.0 with `Easing.OutBack`
- Shows WiFi icon, SSID, password input
- `TextInput` with `echoMode: Password`
- Enter → `connectToNetwork(ssid, password)`
- Escape → Cancel

## Wave Fill Animation (Canvas)
Both cards and center core use Canvas-based wave fills:
- Horizontal fill (cards) or vertical fill (center)
- Bezier curve wave at the fill boundary
- Wave amplitude: `12 * sin(fillLevel * π)` (cards) or `10 * sin(fillLevel * π)` (center)
- Gradient fill: accent light → accent

## Polling System
```
wifiPoll (6s timer) → nmcli -t -f active,ssid,signal,security device wifi list
wifiPowerCheck (6s timer) → nmcli radio wifi
savedListProc (6s timer) → nmcli -t -f NAME,TYPE connection show | grep '802-11-wireless' | sort -u
```

### Initial Load
On `Component.onCompleted`:
1. `wifiPowerCheck` — Check WiFi power state
2. `wifiRescan` with `--rescan yes` — Force fresh scan at startup
3. `savedListProc` — Load saved network profiles

### Network Parsing
Input format: `yes:MyNetwork:85:WPA2`
Parsed to: `{active: "yes", ssid: "MyNetwork", signal: 85, security: "WPA2", icon: ..., secured: true}`

## Key Functions

| Function | Purpose |
|----------|---------|
| `toggleWifi()` | Turn WiFi on/off |
| `connectToNetwork(ssid, password)` | Connect to network |
| `disconnectWifi()` | Disconnect current network |
| `doScan()` | Trigger rescan |
| `parseNetworks(output)` | Parse nmcli output |
| `_wifiIcon(sig)` | Get signal strength icon |

## Key Processes
| ID | Command | Purpose |
|----|---------|---------|
| wifiPoll | `nmcli -t -f active,ssid,signal,security device wifi list` | List networks |
| wifiPowerCheck | `nmcli radio wifi` | Check WiFi power state |
| wifiRescan | `nmcli device wifi list --rescan yes` | Active rescan |
| savedListProc | `nmcli -t -f NAME,TYPE connection show \| grep '802-11-wireless' \| sort -u` | List saved networks |
| connectProcess | `nmcli device wifi connect <ssid> [password <pwd>]` | Connect to network |

## Modifying This File
- **Change signal thresholds**: Modify `strongNetworks` filter or `_wifiIcon()` ranges
- **Add security types**: Extend `parseNetworks()` to handle more security formats
- **Change hold duration**: Modify `fillAnim.duration` (currently `600 * (1 - fillLevel)`)
- **Add WPS support**: Add a new card type and handler in the orbiting model
