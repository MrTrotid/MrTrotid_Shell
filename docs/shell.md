# shell.qml - Main Shell Entry Point

## Purpose
The root entry point for the Quickshell configuration. Each component (bar, popups) runs in its own layer shell surface for independent input regions.

## Architecture
```
ShellRoot
├── ServiceContext (id: ctx)              — Shared state store
├── PanelWindow (id: main)               — Bar only (exclusiveZone: 36, height: 46)
│   ├── BarContent                       — The 36px top bar
│   ├── Battery tooltip                  — Hover tooltip for battery info
│   └── Auto-hide cursor logic           — Shows bar when cursor nears top
├── PanelWindow (blPopup)                — Bluetooth popup (exclusiveZone: 0)
│   └── BluetoothSelector                — BT device picker
├── PanelWindow (wifiPopup)              — WiFi popup (exclusiveZone: 0)
│   └── WifiSelector                     — WiFi network picker
├── PanelWindow (notifPopup)             — Notification panel (exclusiveZone: 0)
│   └── NotificationPanel                — Tools + Notifications + Power
├── PanelWindow (calPopup)               — Calendar popup (exclusiveZone: 0)
│   └── CalendarPopup                    — Calendar/Weather/Time
├── Window (MediaCard)                   — Separate window for media card slide-in
└── Shortcuts                            — Super+O, Super+M, Super+N, Super+B
```

## Key Design Decisions

### Multi-PanelWindow (each popup gets its own surface)
Each popup is a separate `PanelWindow` with `exclusiveZone: 0` to solve the Wayland layer shell input limitation: a surface with `exclusiveZone: 36` only receives input in the 36px exclusive zone — popups below are visible but non-interactive.

By giving each popup its own layer shell surface with `exclusiveZone: 0`, it gets its own independent input region and can receive mouse clicks.

### Why exclusiveZone: 0 for popups
- `exclusiveZone: 0` means the surface does not reserve screen space
- The compositor still renders it, and input events go to it when the cursor is over it
- The bar's `exclusiveZone: 36` remains unchanged — it reserves space and gets input in that zone
- Popup surfaces don't interfere with each other or the bar

### Layer Configuration
All PanelWindows use:
- `WlrLayershell.layer: WlrLayer.Top` — Always on top
- `ExclusionMode.Normal` — Can overlap

Each popup has a unique `WlrLayershell.namespace`:
- `custom:bar` — Bar surface
- `custom:bl-popup` — Bluetooth popup
- `custom:wifi-popup` — WiFi popup
- `custom:notif-popup` — Notification panel
- `custom:cal-popup` — Calendar popup

### Bar PanelWindow
- `exclusiveZone: 36` when visible, `0` when hidden (auto-hide)
- `implicitHeight: barHeight + barTopMargin` when visible, `0` when hidden
- `anchors.top: true` with `margins.top: 10`

### Popup PanelWindows
- `exclusiveZone: 0` — no screen space reservation
- `anchors.top: true` with `margins.top: popupY` (barTopMargin + barHeight + barGap)
- `anchors.right: true` for BT/WiFi/Notification
- `anchors.left: true` for Calendar (centered via margins.left)
- `implicitHeight: visible ? <height> : 0` — collapses when hidden

## Popups
Each popup PanelWindow contains an Item with:
- `visible: ctx?.propertyName ?? false` — Controlled by ServiceContext
- `anchors.fill: parent` — Fills the PanelWindow
- `onVisibleChanged: { if (visible) inner.show() }` — Triggers staggered animations

### Auto-hide with popups
When cursor moves away:
- If any popup is open: close all popups, keep bar visible
- If no popups: start 1.5s hide timer for bar

Opening a popup via keybind always sets `barVisible = true` so the bar is visible alongside the popup.

## Notification Panel (replaces old QuickSettings)
- Width: 360px, Height: 590px
- Three sections:
  - **Top**: Control tools grid (Mic, Night Light, DND, Color Picker, Screenshot)
  - **Middle**: Notifications grouped by app (scrollable, iPhone-style)
  - **Bottom**: Power buttons (Hibernate, Logout, Reboot, Power Off)
- Uses `Quickshell.Services.Notifications.NotificationServer` for receiving notifications
- Notifications are grouped by `appName` and displayed in a scrollable list
- Click a notification to dismiss it

## Lockscreen (hyprlock)
- `Super+L` — Lock screen
- `Super+Shift+L` — Suspend
- Auto-lock after 5min idle via hypridle
- Config: `~/.config/hypr/hyprlock.conf`
- Blurred wallpaper background, clock bottom-left, password input bottom-right

## Auto-Hide Logic
A 100ms timer checks cursor Y position:
- `y <= 2` → Show bar, stop hide timer
- `y > 50` and cursor was near top → If any popup open, close all; then start 1.5s hide timer
- Opening popup via keybind always shows bar (`barVisible = true`)

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
The media card is a separate `Window` (not PanelWindow) because it needs:
- Slide-in animation from left (`Behavior on x`)
- `Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowTransparentForInput`
- Independent positioning

## Modifying This File
- To add a new popup: Add a new `PanelWindow` with `exclusiveZone: 0` containing the popup Item
- To add a keybind: Add a `Shortcut` element with `sequence` and `onActivated`
- To change bar height: Modify `BarContent.height` and `main.exclusiveZone`
- Each popup needs a unique `WlrLayershell.namespace` to avoid compositor conflicts
