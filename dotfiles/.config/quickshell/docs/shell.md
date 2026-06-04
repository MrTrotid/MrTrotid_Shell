# shell.qml - Main Shell Entry Point

## Purpose
The root entry point for the Quickshell configuration. Creates the main panel window, hosts all popups, and manages keybinds.

## Architecture
```
ShellRoot
├── ServiceContext (id: ctx)          — Shared state store
├── PanelWindow (id: main)            — Single layered shell window
│   ├── BarContent                    — The 36px top bar
│   ├── BluetoothSelector popup       — BT device picker (Item, not Window)
│   ├── WifiSelector popup            — WiFi network picker (Item, not Window)
│   ├── NotificationPanel             — Tools + Notifications + Power (Item, not Window)
│   ├── Battery tooltip               — Hover tooltip for battery info
│   ├── CalendarPopup                 — Calendar/Weather/Time popup (Item, not Window)
│   └── Auto-hide cursor logic        — Shows bar when cursor nears top
├── Window (MediaCard)                — Separate window for media card slide-in
└── Shortcuts                         — Super+O, Super+M, Super+N, Super+B
```

## Key Design Decisions

### Single PanelWindow (not multiple)
All popups (BT, WiFi, Notification, Battery, Calendar) are `Item` children of the main `PanelWindow`, NOT separate `Window` or `PanelWindow` instances. This avoids:
- Focus stealing between windows
- Flicker from height animations
- Complex multi-window coordination

The `PanelWindow` has a fixed `implicitHeight: 600` to provide enough space for popups without needing height animations (which cause flicker).

### ExclusionMode
- `exclusionMode: ExclusionMode.Normal` — Other panels can overlap
- `exclusiveZone: 36` — Reserves 36px at the top for the bar

### Layer Configuration
- `WlrLayershell.layer: WlrLayer.Top` — Always on top
- `WlrLayershell.namespace: "custom:bar"` — For Hyprland window rules

### Margins
- `margins.top: 10` — Gap from screen top
- `margins.left: 8` / `margins.right: 8` — Side gaps

## Popups
Each popup is an `Item` with:
- `visible: ctx?.propertyName ?? false` — Controlled by ServiceContext
- `anchors.right: parent.right` — Right-aligned
- `anchors.top: barContent.bottom` — Below the bar
- `opacity: visible ? 1 : 0` with `Behavior on opacity` — Fade in/out

### Notification Panel (replaces old QuickSettings)
- Width: 360px, Height: 590px
- Three sections:
  - **Top**: Control tools grid (Mic, Night Light, DND, Color Picker, Screenshot)
  - **Middle**: Notifications grouped by app (scrollable, iPhone-style)
  - **Bottom**: Power buttons (Hibernate, Logout, Reboot, Power Off)
- Uses `Quickshell.Services.Notifications.NotificationServer` for receiving notifications
- Notifications are grouped by `appName` and displayed in a scrollable list
- Click a notification to dismiss it

### Lockscreen (hyprlock)
- `Super+L` — Lock screen
- `Super+Shift+L` — Suspend
- Auto-lock after 5min idle via hypridle
- Config: `~/.config/hypr/hyprlock.conf`
- Blurred wallpaper background, clock bottom-left, password input bottom-right

## Auto-Hide Logic
A 100ms timer checks cursor Y position:
- `y <= 2` → Show bar, stop hide timer
- `y > 50` and cursor was near top → Start 1.5s hide timer
- `keepBarVisible` flag → Temporary 5s keep-alive (used by panel toggles)

## Keybinds
| Key | Action |
|-----|--------|
| `Super+O` | Toggle bar visibility |
| `Super+M` | Toggle media card |
| `Super+N` | Toggle WiFi selector |
| `Super+B` | Toggle Bluetooth panel |
| `Super+L` | Lock screen (hyprlock) |
| `Super+Shift+L` | Suspend |

## Media Card
The media card is a separate `Window` (not Item) because it needs:
- Slide-in animation from left (`Behavior on x`)
- `Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowTransparentForInput`
- Independent positioning

## Modifying This File
- To add a new popup: Add an `Item` child of `main` with `visible: ctx?.newPopupOpen`
- To add a keybind: Add a `Shortcut` element with `sequence` and `onActivated`
- To change bar height: Modify `BarContent.height` and `main.exclusiveZone`
