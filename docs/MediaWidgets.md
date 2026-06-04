# Media Widgets - MediaCard, PlayerCard, WaveVisualizer

## MediaCard.qml

### Purpose
Container for the media player card + audio visualizer. Opens as a separate `Window` with slide-in animation.

### Architecture
```
Item (root)
├── cavaProc (Process: cava audio visualizer)
├── ColumnLayout
│   ├── PlayerCard (120px height)
│   └── Rectangle (80px height)
│       └── WaveVisualizer
└── Timer (1s polling for Mpris players)
```

### Cava Integration
- Runs `cava -p ~/.config/quickshell/custom/cava/config`
- Parses semicolon-separated float values from stdout
- Updates `visualizerPoints` array on each line
- Auto-starts/stops with visibility

### Window Configuration (in shell.qml)
```qml
Window {
    visible: ctx?.mediaCardOpen ?? false
    color: "transparent"
    width: 320; height: 200
    flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowTransparentForInput
    x: 0; y: 0
    Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
}
```

---

## PlayerCard.qml

### Purpose
Media player controls with album art, track info, progress bar, and playback controls.

### Architecture
```
Item (root)
├── MPRIS player binding
├── Album art download & caching
├── Color quantization (dominant color extraction)
├── Rectangle (card background)
│   ├── Image (blurred album art background)
│   └── RowLayout
│       ├── Album art thumbnail (64x64)
│       │   └── Play/pause button overlay
│       └── ColumnLayout
│           ├── Track title
│           ├── Artist name
│           └── Controls row
│               ├── Previous button
│               ├── Progress bar (clickable)
│               └── Next button
```

### Album Art System
1. **Local files**: `file://` URLs used directly
2. **Remote URLs**: Downloaded via `curl -sSL` to `~/.config/quickshell/cache/art/`
3. **Cache key**: `Qt.md5(trackArtUrl)` — filename is MD5 of URL
4. **Fallback**: Shows `󰓇` music icon when no art available

### Color Quantization
Uses `ColorQuantizer` to extract dominant color from album art. Currently not used for theming but available for future use.

### MPRIS Integration
- `Mpris.mprisList[0]` — First available player
- Properties: `trackTitle`, `trackArtist`, `trackArtUrl`, `position`, `length`, `isPlaying`
- Methods: `togglePlaying()`, `previous()`, `next()`
- `position` setter for seeking: `player.position = mouseX / width * length`

### Progress Bar
- Width: `parent.width * (position / length)`
- Color: `#7c3aed` (purple)
- Click to seek: `mouseX / width * length`

---

## WaveVisualizer.qml

### Purpose
Smooth audio waveform visualization using Canvas. Renders filled wave from cava output.

### Architecture
```
Canvas (root)
├── points (input: raw cava values)
├── smoothPoints (processed: smoothed values)
├── Smoothing algorithm (moving average)
├── Wave rendering (filled path with gradient)
└── Post-processing (MultiEffect blur + saturation)
```

### Smoothing
Moving average with configurable window (default: 2):
```javascript
for (var i = 0; i < n; ++i) {
    var sum = 0, count = 0;
    for (var j = -smoothWindow; j <= smoothWindow; ++j) {
        var idx = Math.max(0, Math.min(n - 1, i + j));
        sum += points[idx];
        count++;
    }
    smoothPoints.push(sum / count);
}
```

### Rendering
1. Clear canvas
2. Begin path at bottom-left
3. Line to each point: `x = i * width / (n-1)`, `y = height - (value / maxVal) * height`
4. Close path at bottom-right
5. Fill with gradient: `color` at 15% opacity

### Post-Processing
```qml
layer.enabled: true
layer.effect: MultiEffect {
    saturation: 0.2
    blurEnabled: true
    blurMax: 7
    blur: 1
}
```
Desaturates and blurs the wave for a soft glow effect.

### Properties
| Property | Type | Default | Description |
|----------|------|---------|-------------|
| points | list<var> | [] | Raw cava frequency values |
| smoothPoints | list<var> | [] | Smoothed values (auto-computed) |
| maxVisualizerValue | real | 1000 | Max amplitude for normalization |
| smoothing | int | 2 | Moving average window size |
| live | bool | true | Show animation (false = flat line) |
| color | color | #7c3aed | Wave fill color |

---

## Modifying Media Widgets

### Change visualizer color
Modify the `color` property in MediaCard.qml:
```qml
WaveVisualizer { color: "#81d5ca" }  // teal to match theme
```

### Change cava config
Modify the command in MediaCard.qml:
```qml
command: ["sh", "-c", "cava -p /path/to/custom/config"]
```

### Add playback controls
Extend PlayerCard.qml by adding buttons in the `RowLayout`:
```qml
Text {
    text: "\uF04D"  // stop icon
    MouseArea { onClicked: player.stop() }
}
```
