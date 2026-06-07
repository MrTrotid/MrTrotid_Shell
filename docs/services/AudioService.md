# AudioService - PulseAudio/WirePlumber Sink & Source Management

## Purpose
Parses `wpctl status` output to track audio sinks, sources (mics), default device, Bluetooth auto-switching, and mic mute state. Updates VolumeService with parsed volume data.

## Architecture
Singleton service (`pragma Singleton`). Two main Process elements poll periodically:
- `statusProc` - Runs `wpctl status` every 3s (via Timer)
- `micStatusProc` - Runs `wpctl get-volume @DEFAULT_AUDIO_SOURCE@` every 3s

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `defaultSinkName` | string | "" | Current default sink description |
| `defaultSinkId` | int | -1 | Current default sink numeric ID |
| `sinks` | var (array) | [] | Array of `{id, name, description, isDefault, volume}` |
| `micMuted` | bool | false | Whether default source is muted |
| `micVolume` | int | 0 | Mic volume (0-100) |
| `sources` | var (array) | [] | Array of `{id, name, description, isDefault}` |
| `defaultSourceId` | int | -1 | Current default source ID |
| `_deviceNames` | var (object) | {} | Device ID → friendly name map (from Devices section) |
| `_prevSinkIds` | var (array) | [] | Previous poll's sink IDs (for BT detection) |
| `_fallbackSinkId` | int | -1 | Last non-Bluetooth default sink (for revert) |

## Key Processes / Timers
| Element | Command | Interval | Purpose |
|---|---|---|---|
| `Timer` | - | 3000ms | Triggers `statusProc` and `micStatusProc` |
| `statusProc` | `wpctl status` | 3000ms | Parses all sinks/sources/filters/devices |
| `micStatusProc` | `wpctl get-volume @DEFAULT_AUDIO_SOURCE@` | 3000ms | Gets mic volume and mute state |
| `defaultSwitchTimer` | - | 300ms (one-shot) | Re-polls after sink switch |
| `_quickMicPoll` | - | 200ms (one-shot) | Re-polls after mic mute toggle |

## Key Functions
| Function | Description |
|---|---|
| `setDefaultSink(sinkId)` | Runs `wpctl set-default`, starts `defaultSwitchTimer` |
| `toggleMicMute()` | Runs `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle`, starts `_quickMicPoll` |
| `cycleMicSource()` | Cycles through `sources` array, returns next source name |
| `isBluetoothSink(name)` | Returns true if name contains "bluetooth", "a2dp", or "bluez" |
| `sinkName(sinkId)` | Returns name for given sink ID |
| `sinkIcon(sinkName)` | Returns Nerd Font icon based on sink name keywords |

## wpctl status Parsing (statusProc)
The parser is section-based using `indexOf` for forward-compatibility:
```
Audio Section
├── Devices section → Builds _deviceNames map (ID → friendly name)
├── Sinks section → Parses sink entries (default marked with *)
├── Sources section → Parses source entries
└── Filters section → Captures Audio/Source entries (skips bluez_ duplicates)
```

**Sink entry regex**: `^([*]?)\s*(\d+)\.\s+(.+?)(?:\s+\[vol:\s*([\d.]+)\])?\s*$`

## Bluetooth Auto-Switch
On each poll, compares current sink IDs with `_prevSinkIds`:
1. If a new Bluetooth sink appears → auto-switches to it
2. If default sink disappeared and `_fallbackSinkId` is still available → reverts to fallback

## VolumeService Integration
After parsing sinks, updates VolumeService directly:
```javascript
VolumeService.currentVolume = result[v].volume
VolumeService.volumePercent = Math.min(150, Math.round(result[v].volume * 100))
```

## Sink Icon Mapping
| Keyword | Icon | Nerd Font Code |
|---|---|---|
| headphone, headset, earphone, earbud, soundcore | 🎧 | `\uF025` |
| bluetooth, a2dp, bluez | 🔊 | `\uF293` |
| hdmi, displayport | 🖥 | `\uF03D` |
| usb | 🎧 | `\uF025` |
| (default) | 🔈 | `\uF028` |

## Modifying This File
- To add new sink type icons: Add keyword match in `sinkIcon()`
- To change poll interval: Modify `Timer.interval` (default 3000ms)
- To change BT detection: Modify `isBluetoothSink()` keywords
