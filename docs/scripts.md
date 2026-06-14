# Scripts - Helper Scripts Reference

## Purpose
Shell scripts for screenshots, screen recording, clipboard history, and notifications. All scripts live at `~/.config/scripts/` (symlinked from `~/Desktop/MrTrotid_Shell/scripts/`).

## Scripts Directory Structure
```
~/.config/scripts/
├── screenshots/
│   └── screenshot.sh          # Screenshot capture
├── recording/
│   └── recording.sh           # Screen recording
├── clipboard-picker.sh        # Clipboard history picker
└── qs-notify                  # Quickshell notification helper (referenced but not in repo)
```

---

## screenshot.sh
**Location**: `~/.config/scripts/screenshots/screenshot.sh`
**Dependencies**: `grim`, `slurp`, `wl-copy`, `hyprctl`, `jq`, `swappy`

### Usage
```bash
screenshot.sh [mode]
```

### Modes
| Mode | Description | Keybind |
|---|---|---|
| `full` | Full screen to file + clipboard | `Print` |
| `region` | Region select (slurp) | `Ctrl+Print` |
| `window` | Active window (hyprctl) | `Shift+Print` |
| `timer` | 5-second delay, then full screen | (no keybind) |
| `monitor` | Focused monitor only | `Alt+Print` |
| `copy` | Region to clipboard only (no file) | (no keybind) |
| `annotate` | Region + swappy annotation | `Ctrl+Shift+Print` |

### Output
- Saves to `~/Pictures/Screenshots/Screenshot_YYYY-MM-DD_HH.MM.SS.png`
- Annotated screenshots: `Annotate_YYYY-MM-DD_HH.MM.SS.png`
- Copies to clipboard via `wl-copy --type image/png`
- Sends notification via `qs-notify`

### slurp Styling
```bash
slurp -d -c '#81d5caAA' -b '#1a212080'
```

---

## recording.sh
**Location**: `~/.config/scripts/recording/recording.sh`
**Dependencies**: `wf-recorder`, `slurp`, `hyprctl`, `jq`, `ffmpeg`, `pactl`, `rofi`

### Usage
```bash
recording.sh [mode]
```

### Modes
| Mode | Description | Keybind |
|---|---|---|
| `region` | Region record (or stop if active) | `Ctrl+Shift+R` |
| `full` | Full screen record (or stop if active) | `Ctrl+Alt+R` |
| `stop` | Stop active recording | (no keybind) |
| `status` | Print recording status | (no keybind) |

### Audio Modes (Rofi Picker)
| Mode | Description |
|---|---|
| Device audio only | Records sink.monitor via PulseAudio |
| Input audio (mic) | Records default source |
| Both (device + input) | Records both, mixes via ffmpeg |
| No audio | Video only |

### Recording Pipeline
1. `slurp` selects region (or full monitor)
2. Rofi picker selects audio mode
3. `wf-recorder` starts with libx264rgb (crf=20, superfast, zerolatency)
4. For "both" audio: ffmpeg captures mixed audio separately
5. On stop: kills wf-recorder, merges video+audio via ffmpeg

### Output
- Saves to `~/Videos/Recordings/Recording_YYYY-MM-DD_HH.MM.SS.mp4`
- PID tracked at `/tmp/wf-recorder.pid`
- Audio PID at `/tmp/wf-recorder-audio.pid`

---

## clipboard-picker.sh
**Location**: `~/.config/scripts/clipboard-picker.sh`
**Dependencies**: `cliphist`, `rofi`, `wl-copy`

### Usage
```bash
clipboard-picker.sh
```
Bound to `Super + V`.

### Behavior
1. Lists clipboard history via `cliphist list`
2. Opens rofi dmenu with preview support
3. On selection: decodes via `cliphist decode` and copies to clipboard
4. Sends notification via `qs-notify`

### Rofi Configuration
```bash
rofi -dmenu -theme ~/.config/rofi/launchers/type-1/style-1.rasi
    -hover-select -me-select-entry "" -me-accept-entry "MousePrimary"
    -preview-cmd "$SCRIPT_DIR/clipboard-preview.sh"
```

---

## weather.sh
**Location**: `quickshell/calendar/weather.sh`
**Dependencies**: `curl`, `jq`, `date`

### Usage
```bash
weather.sh --json    # Read from cache (or fetch if stale)
weather.sh --refresh # Force refresh
```

### Configuration
Edit `quickshell/calendar/.env`:
```bash
OPENWEATHER_KEY=<your_api_key>
OPENWEATHER_CITY_ID=<city_id>
OPENWEATHER_UNIT=metric  # metric|imperial|standard
```

### Output
JSON written to `~/.cache/quickshell/weather/weather.json`:
```json
{
    "current_temp": "25.0",
    "current_icon": "☀",
    "current_hex": "#f9e2af",
    "current_desc": "Clear Sky",
    "forecast": [...]
}
```

### Caching
- Cache valid for 900 seconds (15 minutes)
- Returns cached file immediately, refreshes in background
- Falls back to dummy data if no API key

### Weather Icons (Nerd Font)
| Code | Icon | Description |
|---|---|---|
| 01d | 󰖨 | Sunny |
| 01n | 󰖨 | Clear |
| 02d/02n/03d/03n/04d/04n | 󰖟 | Cloudy |
| 09d/09n/10d/10n | 󰖗 | Rainy |
| 11d/11n | 󰖔 | Storm |
| 13d/13n | 󰖘 | Snow |
| 50d/50n | 󰖑 | Mist |

## Modifying Scripts
- Screenshot output dir: Modify `DIR` in screenshot.sh
- Recording output dir: Modify `DIR` in recording.sh
- Weather cache duration: Modify `CACHE_LIMIT` in weather.sh
- Add new screenshot mode: Add case to screenshot.sh
