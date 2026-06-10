# Theming Pipeline - Material You Color System

## Purpose
Automatic Material You theming based on wallpaper. Changes wallpaper → generates color palette → applies to all UI components.

## Pipeline Flow
```
1. User sets wallpaper
       │
       ▼
2. wallset / wallset-backend
       │
       ▼
3. swaybg applies wallpaper image
       │
       ▼
4. matugen generates colors.json
       │
       ▼
5. ColorService polls colors.json (2s)
       │
       ▼
6. All components update via property bindings
```

## Step 1: Wallpaper Selection
- `wallset` opens the wallpaper selector (rofi or Quickshell wallpaper picker)
- `Super + W` or `Ctrl + Super + T` for Quickshell picker
- `wallset-backend-startup` applies random wallpaper on login

## Step 2: swaybg
Wallpaper applied via:
```bash
swaybg -i /path/to/wallpaper.png -m fill
```
Killed and restarted on each wallpaper change.

## Step 3: matugen
```bash
matugen image /path/to/wallpaper.png --prefer darkness
```
Generates `~/.config/quickshell/mrtrotid-shell/colors.json` with Material You tokens.

### Generated Color Tokens
The JSON contains these keys (used by ColorService):
- `background`, `on_background`
- `surface`, `on_surface`, `on_surface_variant`
- `surface_container`, `surface_container_high`, `surface_container_highest`, `surface_container_low`
- `primary`, `on_primary`, `primary_container`, `on_primary_container`
- `secondary`, `on_secondary`, `secondary_container`
- `tertiary`, `on_tertiary`, `tertiary_container`
- `error`, `on_error`, `error_container`
- `outline`, `outline_variant`
- `shadow`, `scrim`
- `inverse_surface`, `inverse_on_surface`, `inverse_primary`
- Custom: `success`, `blue`, `red`, `yellow`

## Step 4: ColorService Polling
```javascript
// Process + cat reads colors.json every 2s
// FileView.reload() doesn't detect atomic file rewrites
Process {
    id: colorReader
    command: ["cat", root._colorFilePath]
    onRunningChanged: {
        if (!running && root._fileBuffer.length > 0) {
            root._parseColors(root._fileBuffer)
            root._fileBuffer = ""
        }
    }
    stdout: SplitParser {
        onRead: data => root._fileBuffer += data + "\n"
    }
}

// Timer triggers process every 2s
Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: { root._fileBuffer = ""; colorReader.running = true } }
```

**Important:** Requires `import Quickshell` (not just `Quickshell.Io`) for `Quickshell.env("HOME")`.

## Step 5: Component Theming
All components bind to ColorService properties:
```qml
property color colPrimary: ColorService.primary
property color colSurface: ColorService.surfaceContainer
// etc.
```

## Generated Files (DO NOT EDIT)
These files are overwritten on every wallpaper change:
- `~/.config/waybar/colors.css`
- `~/.config/waybar/colors-waybar.css`
- `~/.config/rofi/colors/colors-matugen.rasi`
- `~/.config/hypr/colors/*`
- `~/.cache/wallust/colors-kitty.conf`

## Template Files (EDIT THESE)
- `~/.config/matugen/templates/` - Matugen templates
- `~/.config/wallust/templates/` - Wallust templates

## Additional: wallust
`wallust` generates terminal colors (Kitty, Hyprland) separately from matugen. Runs as part of `wallset-backend`.

## Modifying the Pipeline
- Change ColorService file path: Modify `_colorFilePath` property
- Change polling interval: Modify Timer interval (default 2000ms)
- Add new color token: Add to matugen template + ColorService property + _parseColors()
- Change matugen preferences: Modify `--prefer darkness` in wallpaper apply script
- Change swaybg mode: Modify `-m fill` in apply script
- Wallpaper picker calls `$HOME/.local/bin/wallset-backend` (full path required — `execDetached` doesn't inherit PATH)
