# BluetoothSelector.qml - Bluetooth Device Picker

## Purpose
Orbital-style Bluetooth device picker with multi-level navigation. Shows devices floating around a central core with radar rings, gradient borders, and wave fill animations.

## Architecture
```
Item (root)
├── Color scheme (monochrome teal)
├── State properties (btEnabled, devices, scanning, viewMode, etc.)
├── Device detection (icon mapping, name-based detection)
├── Navigation functions (goHome, goDevices, goDetail)
├── Polling system (btPoll → btListAll/Connected/Paired)
├── Race condition fix (_pending flags + _tryUpdateStatus)
├── Battery detection (batCheckCmd)
├── Main container (Rectangle, rounded)
│   ├── Background blobs (2 floating circles)
│   ├── Radar rings (3 concentric circles)
│   ├── Orbit container
│   │   ├── Central core (icon + text + pulse ring + scanning ripple)
│   │   └── Orbiting cards (Repeater with dynamic model)
│   └── Toggle bar (ON/OFF pill at bottom)
```

## View Modes (State Machine)
```
┌─────────┐    click scan     ┌───────────┐
│  HOME   │ ───────────────→  │ SCANNING  │
│         │ ←─── stop scan ── │           │
└────┬────┘                   └───────────┘
     │ click nav card
     ▼
┌─────────┐    click device   ┌───────────┐
│ DEVICES │ ───────────────→  │  DETAIL   │
│ (list)  │ ←─── core click ─ │ (actions) │
└─────────┘                   └───────────┘
```

### Home View
- **Center**: Bluetooth icon (`\uF293`) + "Tap to disconnect" subtitle (if connected)
- **Orbiting cards**:
  - [Scan Devices] — Always shown
  - [Connected Devices] — Only if `hasConn`
  - [Paired Devices] — Only if `hasPaired`

### Scanning View
- **Center**: Magnifying glass icon (`\uF002`) with bouncing animation + countdown
- **Orbiting cards**: Only new/unknown devices found during scan (connected AND paired devices filtered out)
- **Scan duration**: 30 seconds, polls every 2 seconds
- **Stop scan**: Click center core or wait for timeout
- **On timeout**: Stays on current view (does NOT auto-navigate to home)

### Devices View (Connected/Paired)
- **Center**: Headphones icon (`\uF502`) + "Connected Devices" / "Paired Devices" + "Tap to inspect"
- **Orbiting cards**: Individual device cards with icon, name, subtitle

### Detail View
- **Center**: Device icon + name + battery % (if available)
- **Orbiting cards**:
  - [Disconnect] (red) — Only shown for connected devices
  - [Forget Device] (red) — Tap to remove from paired list
  - [MAC Address] — Informational
  - [Battery Level] — Only shown if battery detected

## Navigation

### Core Click Actions
| View Mode | Action |
|-----------|--------|
| home | If connected: go to connected devices list |
| scanning | Stop scan |
| devices | Go home |
| detail | Go home |

### Card Click Actions
| Card Type | Action |
|-----------|--------|
| scan | Start/stop scan |
| nav-connected | Show connected devices list |
| nav-paired | Show paired devices list |
| device (tap) | Go to detail view |
| device (long-press) | Connect + go to detail view |
| disconnect | Disconnect + go home |
| forget | Remove device |

## Device Icon Detection
Uses `_detectIcon(name, btIcon)` function with two sources:

### 1. Bluetoothctl Icon Field
When viewing a device detail, `bluetoothctl info` returns `Icon: audio-headset`. This is mapped via `_btIconMap`.

### 2. Name-Based Heuristics
Regex matching on device name:
| Pattern | Icon |
|---------|------|
| headphone, headset, earbuds, airpods, soundcore, jbl, sony, bose, beats | `\uF025` (headphones) |
| speaker, homepod, echo | `\uF028` (speakers) |
| keyboard, mx keys | `\uF11C` (keyboard) |
| mouse, mx master | `\uF345` (mouse) |
| phone, iphone, galaxy, pixel | `\uF3CD` (phone) |
| ipad, tablet | `\uF10B` (tablet) |
| macbook, laptop, thinkpad | `\uF109` (computer) |
| watch, fitbit | `\uF017` (watch) |
| controller, ps4, xbox | `\uF11B` (gamepad) |
| car, aux, bmw | `\uF1B9` (car) |
| tv, roku, chromecast | `\uF108` (display) |
| Default | `\uF49A` (generic) |

## Battery Detection
Runs `bluetoothctl info <mac>` and parses:
```
Battery Percentage: 0x64 (100)
```
Regex: `/Battery Percentage:\s*0x([0-9a-fA-F]+)\s*\((\d+)\)/`

Falls back to: `/Battery Percentage:\s*(\d+)/`

## Polling System

### Normal Polling (6s interval)
```
btPoll (timer) → btPoll (process: bluetoothctl show)
    ↓ (if powered)
btListAll (bluetoothctl devices)
btListConnected (bluetoothctl devices Connected)
btListPaired (bluetoothctl devices Paired)
    ↓ (all three finish)
_tryUpdateStatus() → updateConnectionStatus()
```

### Scan Polling (2s interval)
Same three processes, but only during active scan.

### Race Condition Fix
Three boolean flags (`_pendingListAll`, `_pendingListConnected`, `_pendingListPaired`) ensure `updateConnectionStatus()` only runs after all three list processes complete. Without this, `btListAll` would set `devices` before `connectedMacs` was populated.

## Orbital Animation
- `globalOrbitAngle`: 0 → 2π over 200 seconds, infinite loop
- Cards orbit at radius 200-230px (X) / 140-160px (Y)
- Bob offset: `sin(angle * 6) * 8px` vertical oscillation
- Z-ordering: `sin(angle) > 0` → in front of center
- Staggered entry: Each card delays 40 + (index * 30) ms

## Toggle Bar
Bottom pill: 160×40px, radius 12
- **Powered**: Full width, accent color, shows `\uF293 ON`
- **Off**: Narrow (52px), centered, shows `\uF019` (power icon)

## Key Processes
| ID | Command | Purpose |
|----|---------|---------|
| btPoll | `bluetoothctl show \| grep 'Powered: yes'` | Check power state |
| btListAll | `bluetoothctl devices` | List all known devices |
| btListConnected | `bluetoothctl devices Connected` | List connected devices |
| btListPaired | `bluetoothctl devices Paired` | List paired devices |
| scanProcess | `bluetoothctl --timeout 30 scan on` | Active discovery |
| batCheckCmd | `bluetoothctl info <mac>` | Get battery + icon info |

## Modifying This File
- **Add a new view mode**: Add `property string viewMode: "newmode"` case in the orbiting model
- **Add a new card type**: Add to the model array and handle in `onClicked`
- **Change colors**: Modify the color properties at the top (`_base`, `_accent`, etc.)
- **Change orbit speed**: Modify `duration: 200000` in `globalOrbitAngle` animation
- **Add battery source**: Extend `batCheckCmd` command to check additional paths
