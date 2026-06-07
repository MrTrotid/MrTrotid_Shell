# Cheatsheet - Keybind Reference Panel

## Purpose
Searchable keybind reference panel with executable actions. Categories are displayed in a horizontal scrollable layout.

## Architecture
```
Item (root)
└── Item (scale/opacity wrapper)
    └── Rectangle (main container, radius: 16)
        └── ColumnLayout
            ├── RowLayout (header)
            │   ├── Text (icon)
            │   ├── Text ("Keybind Reference")
            │   └── Rectangle (close button)
            ├── TextField (search bar)
            ├── Item (flickable container)
            │   ├── Flickable (horizontal)
            │   │   └── Row (categoriesRow)
            │   │       └── Repeater (filteredCategories)
            │   │           └── Item (240px wide category column)
            │   │               ├── Category header
            │   │               ├── Separator
            │   │               └── Repeater (binds)
            │   │                   └── ColumnLayout (keybind row)
            │   └── ScrollBar.horizontal
            └── Text (footer hint)
        └── Rectangle (confirmDialog) - Power action confirmation
```

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `searchQuery` | string | "" | Current search filter |
| `showConfirm` | bool | false | Confirmation dialog visible |
| `confirmCommand` | string | "" | Command to execute on confirm |
| `confirmLabel` | string | "" | Description for confirm dialog |
| `categories` | var | (see below) | All keybind categories |
| `filteredCategories` | var | computed | Categories matching search query |

## Categories
| Category | Icon | Keybinds |
|---|---|---|
| Shell |  | Panel toggles (A, O, M, J, T, /, Ctrl+R) |
| Apps |  | Terminal, launcher, clipboard, browser, file mgr, editor |
| Windows |  | Focus, move, close, float, pin, fullscreen |
| Workspaces |  | Switch, move, cycle, scratchpad |
| Session |  | Lock, suspend, power off, reboot |
| Screenshots |  | Full, region, window, monitor, annotate, color picker |
| Recording |  | Region record, full record |
| Hardware |  | Brightness, volume, mute, night light, media keys |

## Keybind Object Structure
```javascript
{
    keys: string,      // Key combination (e.g., "Super + A")
    desc: string,      // Description
    action?: string    // Optional command to execute
}
```

## Search
Filters categories by matching `keys` or `desc` against `searchQuery` (case-insensitive). Shows "No matching keybinds" when empty.

## Executable Actions
- If `action` is defined and contains "poweroff", "reboot", or "suspend" → shows confirmation dialog
- Otherwise → executes command via `Quickshell.execDetached()`
- If no `action` → copies key combination to clipboard via `wl-copy`

## Confirmation Dialog
- 280x140 centered rectangle
- Shows "Confirm {label}" and "Are you sure?"
- Cancel button → closes dialog
- Confirm button → executes command, closes popup

## Intro Animation
1. `introMain` (0→1, 400ms, OutQuart)
2. `introContent` (0→1, 500ms, OutQuint, +80ms delay)

## Horizontal Scroll
- Flickable with `horizontalFlick` direction
- Mouse wheel scrolls horizontally
- ScrollBar appears when content overflows
- Each category column is 240px wide

## Modifying This File
- Add new category: Add to `categories` array
- Add new keybind: Add to category's `binds` array
- Change column width: Modify `width: 240` in category delegate
- Change confirmation commands: Modify the `indexOf` checks in click handler
