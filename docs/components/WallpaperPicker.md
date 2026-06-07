# WallpaperPicker - Coverflow Wallpaper Selector

## Purpose
Full-screen wallpaper picker with coverflow carousel, color-based filtering, and live wallpaper application via swaybg + matugen.

## Architecture
```
Item (root, window)
├── Rectangle (blur background)
├── ListView (view, horizontal, coverflow)
│   └── delegate: Item (wallpaper card)
│       ├── MouseArea (click to apply)
│       ├── Image (thumbnail)
│       └── Item (border with clip)
├── Rectangle (filterBarBackground)
│   └── Row
│       ├── Rectangle (notifDrawer) - Status message
│       └── Repeater (filterData) - Color filter buttons
├── Rectangle (close button)
├── Text (countLabel) - "N / M"
├── Text (wallNameLabel) - Current filename
└── Rectangle (applyBtn) - "Apply Wallpaper" button
```

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `currentFilter` | string | "All" | Active color filter |
| `targetWallName` | string | "" | Wallpaper to focus on |
| `colorMap` | var | {} | Filename → hex color mapping |
| `cacheVersion` | int | 0 | Incremented on color map change |
| `isApplying` | bool | false | Prevents double-apply |
| `isModelChanging` | bool | false | Suppresses animations during filter |
| `visibleItemCount` | int | -1 | Count of filtered wallpapers |
| `scrollAccum` | real | 0 | Accumulated scroll delta |
| `scrollThreshold` | real | 300 | Pixels needed for one step |

## Filter Options
| Name | Hex | Description |
|---|---|---|
| All | (canvas) | Show all wallpapers |
| Red | #FF4500 | Red-toned wallpapers |
| Orange | #FFA500 | Orange-toned |
| Yellow | #FFD700 | Yellow-toned |
| Green | #32CD32 | Green-toned |
| Blue | #1E90FF | Blue-toned |
| Purple | #8A2BE2 | Purple-toned |
| Pink | #FF69B4 | Pink-toned |
| Monochrome | #A9A9A9 | Low-saturation/low-value |

## Color Extraction
Uses ImageMagick (`magick` or `convert`) to extract dominant color from thumbnails:
```bash
magick "$file" -modulate 100,200 -resize "1x1^" -gravity center -extent 1x1 -depth 8 \
    -format "%[hex:p{0,0}] info:-"
```
Results stored as marker files: `filename_HEX_AABBCC` in `colors_markers/` directory.

## Color Bucketing
`getHexBucket(hexStr)` converts hex to HSV and maps to category:
- Saturation < 5% or Value < 8% → Monochrome
- Hue ranges map to Red/Orange/Yellow/Green/Blue/Purple/Pink

## Carousel (ListView)
- Horizontal orientation, `StrictlyEnforceRange` highlight mode
- Current item: 600px wide (1.5x base), non-current: 200px (0.5x base)
- Skew transform: `skewFactor: -0.35` for 3D effect
- Header/footer: half-width spacers for centering
- `cacheBuffer: 2000` for smooth scrolling

## Wallpaper Application
```bash
cp thumb current_wallpaper.png
killall swaybg
nohup swaybg -i original_file -m fill &
matugen image thumb --prefer darkness
```

## Keyboard Shortcuts
| Key | Action |
|---|---|
| Left | Previous valid wallpaper |
| Right | Next valid wallpaper |
| Enter | Apply current wallpaper |
| Escape | Close picker |

## Scroll Handling
- Accumulates scroll delta
- Steps to next/prev valid index when threshold (300) reached
- 150ms throttle between steps

## Thumbnail Source
Thumbnails from `~/.cache/quickshell/wallpaper_picker/thumbs/` (pre-generated).
Source wallpapers from `$WALLPAPER_DIR` or `~/.config/wallpapers/`.

## Modifying This File
- Change carousel size: Modify `itemWidth` (400), `itemHeight` (420)
- Change skew: Modify `skewFactor` (-0.35)
- Add filter colors: Add to `filterData` array
- Change apply script: Modify `applyWallpaper()` function
