# NotificationPanel - Notification History Panel

## Purpose
Full notification panel showing grouped notification history with expand/collapse, silent mode toggle, and clear-all functionality.

## Architecture
```
Item (root)
└── Rectangle (background, radius: 20)
    └── ColumnLayout
        └── Rectangle (notification island, radius: 20)
            ├── ColumnLayout
            │   ├── Item (listContainer)
            │   │   ├── ColumnLayout (placeholderCol) - "No notifications" with bell
            │   │   └── ListView (listView) - Grouped notifications
            │   └── RowLayout (bottom action row)
            │       ├── Rectangle (silent toggle)
            │       ├── Rectangle (notification count)
            │       └── Rectangle (clear all button)
            └── Timer (clearDelayTimer)
```

## Key Properties
| Property | Type | Source | Description |
|---|---|---|---|
| `colLayer0` through `colLayer3` | color | ColorService | Surface hierarchy colors |
| `colOnSurface` | color | ColorService | Text on surface |
| `colPrimary` | color | ColorService | Primary accent |
| `colPrimaryContainer` | color | ColorService | Silent mode active bg |
| `colSecondaryContainer` | color | ColorService | App icon bg |
| `colOutline` / `colOnOutline` | color | ColorService | Border colors |
| `_triggeredByClear` | bool | local | Tracks if clear was just pressed |

## Notification List
- Model: `NotificationService.appNameList` (sorted app names)
- Delegate: `groupDelegate` - Grouped by app name
- Each group shows: app icon, app name, time, expand button, notification items

## Group Delegate Structure
```
Rectangle (groupDelegate, radius: 16, colLayer2)
└── ColumnLayout
    ├── RowLayout (header)
    │   ├── Rectangle (app icon, 38x38)
    │   │   ├── Image (tries candidates from NotificationUtils)
    │   │   └── Text (Nerd Font fallback icon)
    │   └── ColumnLayout
    │       ├── RowLayout (app name + time + expand)
    │       └── ColumnLayout (expandedColumn)
    │           └── Repeater (notification items)
```

## Notification Item
- Shows summary (bold) when multiple in group
- Shows body preview (1 line collapsed, 100 lines expanded)
- Click on item → discards that notification
- Expand/collapse via chevron button

## Bottom Action Row
| Element | Action |
|---|---|
| Silent toggle | Toggles `NotificationService.silent` |
| Notification count | Shows "X notifications" or "No notifications" |
| Clear all | Triggers 250ms delay → `discardAllNotifications()` → bell swing animation |

## Bell Swing Animation
When notifications are cleared or all dismissed:
```
0→20° (250ms, OutBack)
20→-20° (400ms, InOutSine)
-20→15° (300ms, InOutSine)
15→-10° (250ms, InOutSine)
-10→0° (200ms, OutSine)
```

## Modifying This File
- Change group display: Modify Repeater model/delegate in ListView
- Change icon resolution: Modify `NotificationUtils.getAppIconCandidates()` calls
- Change clear delay: Modify `clearDelayTimer.interval` (default 250ms)
