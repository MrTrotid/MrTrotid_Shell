# QuickActions - Screenshot & Recording Quick Access HUD

## Purpose
Bottom-center floating HUD with quick-access buttons for screenshots, screen recording, folder shortcuts, and color picker.

## Architecture
```
FocusScope (root)
└── Rectangle (bgRect, pill shape)
    ├── Rectangle (flatten bottom edge)
    ├── Rectangle (tabHighlight) - Animated selection indicator
    └── RowLayout (layout)
        └── Repeater (7 action buttons)
            └── Item (toolBtn)
                ├── Rectangle (button background)
                │   └── Text (icon)
                └── MouseArea
```

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `currentIndex` | int | 0 | Currently selected button |
| `totalItems` | int | 7 | Number of action buttons |
| `focus` | bool | true | Accepts keyboard input |

## Actions
| Index | Icon | Label | Command |
|---|---|---|---|
| 0 |  | Full Screenshot | `screenshot.sh full` |
| 1 |  | Region Screenshot | `screenshot.sh region` |
| 2 |  | Open Screenshots | `xdg-open ~/Pictures/Screenshots` |
| 3 |  | Record Region | `recording.sh region` |
| 4 |  | Record Fullscreen | `recording.sh full` |
| 5 |  | Open Recordings | `xdg-open ~/Videos/Recordings` |
| 6 |  | Color Picker | `hyprpicker -a` |

## Keyboard Navigation
| Key | Action |
|---|---|
| Left / H | Previous button |
| Right / L | Next button |
| Enter / Return | Execute selected action |
| Escape | Close popup |

## Tab Highlight Animation
- `tabHighlight` rectangle slides behind selected button
- `Behavior on x`: 150ms OutCubic
- `Behavior on width`: 150ms OutCubic
- Color: `ColorService.primary`

## Button Style
- 44x44px circles
- Active: `Qt.alpha(primary, 0.15)` background, primary icon
- Hover: `Qt.alpha(surfaceText, 0.08)` background
- Inactive: transparent background, surfaceText icon

## Layout
- Pill-shaped background: `radius: height/2` with flattened bottom edge
- Height: 64px
- Width: `layout.implicitWidth + 40`
- Anchored to bottom of parent

## Modifying This File
- Add new action: Add to model array and `executeItem()` switch
- Change button size: Modify `width: 44, height: 44`
- Change pill height: Modify `height: 64`
