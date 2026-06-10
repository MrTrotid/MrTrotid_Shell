# NotificationPopup - Toast Notification Display

## Purpose
Displays stacked toast notifications (max 3) below the bar with slide-in/out animations, auto-dismiss, and prominent separated action buttons.

## Architecture
```
Item (root, 320x64)
└── Repeater (model: NotificationService.toastList)
    └── delegate: Item (notif)
        ├── Rectangle (background, radius: 16)
        │   ├── MouseArea (hover → pause dismiss timer)
        │   ├── Rectangle (glowBg) - Accent-colored glow
        │   ├── Rectangle (iconBg) - App icon with fallback
        │   │   ├── Image (icon candidates)
        │   │   └── Text (Nerd Font fallback)
        │   └── Column
        │       ├── Text (title/summary)
        │       └── Text (body)
        ├── Rectangle (actionRow) - Separated action button row
        │   └── Row
        │       └── Repeater (actions)
        │           └── Rectangle (chip button)
        ├── NumberAnimation (entrySlide)
        ├── NumberAnimation (entryFade)
        ├── NumberAnimation (exitAnim)
        ├── NumberAnimation (exitFade)
        ├── NumberAnimation (reposition)
        └── Timer (dismissTimer)
```

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `width` | int | 320 | Toast width |
| `height` | int | 64 | Base toast height (grows by 36px with actions) |
| Notification delegate props: | | | |
| `notificationId` | int | required | Unique ID |
| `summary` | string | required | Title text |
| `body` | string | required | Body text |
| `appIcon` | string | required | App icon path |
| `appName` | string | required | Application name |
| `actions` | var | required | Action buttons array (keeps NotificationAction refs) |
| `urgency` | string | required | "low"/"normal"/"critical" |
| `hovered` | bool | false | Whether cursor hovers over toast |
| `appAccent` | color | computed | Accent color based on app name |
| `iconCandidates` | var | computed | Icon paths from NotificationUtils |

## App Accent Colors
| App Pattern | Color |
|---|---|
| firefox, chrome, brave, browser | Blue (0.35, 0.55, 0.95) |
| discord, telegram, signal | Purple (0.55, 0.40, 0.95) |
| spotify, music, mpv | Green (0.30, 0.85, 0.50) |
| kitty, terminal, shell | Teal (0.30, 0.80, 0.75) |
| thunar, nautilus, file | Orange (0.90, 0.65, 0.30) |
| screenshot, grim, slurp | Blue (0.40, 0.70, 0.95) |
| recording, wf-recorder | Red (0.95, 0.40, 0.40) |
| clipboard, cliphist | Green (0.60, 0.80, 0.50) |
| network, wifi, bluetooth | Blue (0.50, 0.65, 0.95) |
| battery, power | Yellow (0.90, 0.80, 0.35) |
| volume, audio, sound | Purple (0.80, 0.55, 0.90) |
| (default) | Gray (0.65, 0.70, 0.80) |

## Animations
| Animation | Duration | Easing | Description |
|---|---|---|---|
| `entrySlide` | 350ms | OutCubic | Slides from y:-100 to y:0 |
| `entryFade` | 300ms | OutCubic | Fades from 0 to 1 |
| `exitAnim` | 300ms | InCubic | Slides to y:-100 |
| `exitFade` | 250ms | InCubic | Fades to 0 |
| `reposition` | 250ms | OutCubic | Repositions when toasts shift |

## Auto-Dismiss
| Urgency | Timeout | Behavior |
|---|---|---|
| normal/low | 4000ms | Pauses on hover, resumes on exit |
| critical | 15000ms | Never auto-dismisses |

## Action Buttons
- **Separated row** at bottom of toast (not inline with text)
- Height increases by 36px if actions exist
- Minimum button width: 60px, height: 24px, radius: 8
- Bold text, app accent color with hover highlight
- Calls `NotificationService.attemptInvokeAction(id, identifier)`
- `NotificationService` keeps original `NotificationAction` refs (with `_ref` field) so `invoke()` works

## Critical Styling
Critical notifications get:
- `border.width: 2` (vs 1)
- `border.color: rgba(0.95, 0.30, 0.30, 0.8)` (red)

## Modifying This File
- Change toast size: Modify `width`/`height` properties
- Change auto-dismiss timeout: Modify `dismissTimer.interval`
- Add app accent colors: Add patterns to `appAccent` binding
- Change animation timing: Modify entry/exit animation durations
- Change action button styling: Modify `actionRow` and chip delegate properties
