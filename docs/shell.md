# shell.qml — Main Shell Entry Point

## Purpose
The root entry point for the Quickshell configuration. Each component (bar, popups) runs in its own Wayland layer shell surface for independent input regions.

## Architecture
```
ShellRoot
├── import "services"                    — Singleton services (BrightnessService, VolumeService, etc.)
├── PanelWindow (id: main)              — Bar (exclusiveZone: 48 when visible)
│   ├── BarContent                      — The 36px top bar (binds to singletons)
│   └── Auto-hide cursor logic          — Shows bar when cursor nears top
├── PanelWindow (blPopup)               — Bluetooth popup (exclusiveZone: 0)
│   └── BluetoothSelector               — BT device picker
├── PanelWindow (wifiPopup)             — WiFi popup (exclusiveZone: 0)
│   └── WifiSelector                    — WiFi network picker
├── PanelWindow (notifPopup)            — Notification panel (exclusiveZone: 0)
│   └── NotificationPanel               — Tools + Notifications + Power
├── PanelWindow (calPopup)              — Calendar popup (exclusiveZone: 0)
│   └── CalendarPopup                   — Calendar/Weather/Time
├── Window (MediaCard)                  — Separate window for media card slide-in
└── GlobalShortcuts                     — IPC handlers for keybinds.conf
```

## Properties
| Property | Value | Purpose |
|----------|-------|---------|
| `barTopMargin` | `10` | Pixels from screen top to bar content start |
| `barHeight` | `36` | Height of the bar content area |
| `barGap` | `4` | Internal gap between bar capsules |
| `popupGap` | `2` | Gap between bar bottom edge and popup top edge |
| `sideMargin` | `8` | Horizontal margin for bar from screen edges |
| `sw` | `Quickshell.screens[0]?.width ?? 1920` | Screen width for proportional popup sizing |

---

## Wayland Layer Shell — How Positioning Works

### Critical: `margins.top` Does NOT Control Popup Surface Position

This is the single most important thing to understand about this shell's layout.

**`margins.top` on a PanelWindow does NOT control where the Wayland compositor places the surface on screen.** It only offsets the content *within* the surface. The actual surface position is determined by the **compositor** based on `exclusiveZone` values of surfaces on the same layer and edge.

What this means in practice:
- The bar has `exclusiveZone: 48` (barTopMargin + barHeight + popupGap = 10 + 36 + 2)
- This reserves 48px from the top of the screen
- All popup surfaces (with `exclusiveZone: 0`) are placed by the compositor **right after** this reserved zone, at y=48
- Changing `margins.top` on popup PanelWindows has **zero effect** on their screen position
- The popup content fills the entire surface starting from y=48

### What Actually Controls the Gap Between Bar and Popup

The gap is controlled by the bar's `exclusiveZone`:

```
exclusiveZone = barTopMargin + barHeight + popupGap
               = 10          + 36       + 2
               = 48
```

- Bar content occupies: y=10 to y=46 (barTopMargin + barHeight)
- Bar exclusive zone reserves: y=0 to y=48
- Popup surface starts at: y=48 (right after the exclusive zone)
- **Visible gap = popupGap = 2 pixels**

### How to Adjust the Gap

| Goal | Change | Effect |
|------|--------|--------|
| **Decrease gap** (popup closer to bar) | Set `popupGap: 0` | Popup touches bar edge (y=46) |
| **Negative gap** (popup overlaps bar) | Set `popupGap: -2` | Popup overlaps bar by 2px |
| **Increase gap** (popup further from bar) | Set `popupGap: 8` | 8px gap between bar and popup |
| **No gap at all** | Set `popupGap: 0` and ensure bar content fills exactly barHeight |

**Formula:** `exclusiveZone = barTopMargin + barHeight + popupGap`

### Why `margins.top` Was Removed from Popups

Previously, popup PanelWindows had `margins.top: popupY` where `popupY = barTopMargin + barHeight + 5`. This was removed because:
1. `margins.top` on Wayland layer shell PanelWindows does not control surface position
2. The compositor positions surfaces based on `exclusiveZone` of other surfaces on the same edge
3. Having `margins.top` on popups was misleading and had no visible effect
4. The bar's `exclusiveZone` is the single source of truth for popup vertical positioning

### What `margins.top` IS Used For

`margins.top` on the **bar** PanelWindow IS effective — it offsets the bar surface 10px from the screen top. This creates visual breathing room between the screen edge and the bar content.

For popups, `margins.right` and `margins.left` ARE used for horizontal positioning (e.g., calendar centered via `margins.left`, WiFi/BT right-aligned via `margins.right: 16`).

---

## Multi-PanelWindow Design (Each Popup Gets Its Own Surface)

### Why Each Popup Is a Separate PanelWindow

Each popup is a separate `PanelWindow` with `exclusiveZone: 0` to solve the **Wayland layer shell input limitation**: a surface with `exclusiveZone: N` only receives input in the N-pixel exclusive zone. Popups below the exclusive zone are visible but non-interactive.

By giving each popup its own layer shell surface with `exclusiveZone: 0`, it gets its own independent input region and can receive mouse clicks.

### Why `exclusiveZone: 0` for Popups
- `exclusiveZone: 0` means the surface does not reserve screen space
- The compositor still renders it, and input events go to it when the cursor is over it
- The bar's `exclusiveZone` (48 when visible) remains unchanged — it reserves space and gets input in that zone
- Popup surfaces don't interfere with each other or the bar

---

## Layer Configuration
All PanelWindows use:
- `WlrLayershell.layer: WlrLayer.Top` — Always on top
- `ExclusionMode.Normal` — Can overlap

Each popup has a unique `WlrLayershell.namespace`:
- `custom:bar` — Bar surface
- `custom:bl-popup` — Bluetooth popup
- `custom:wifi-popup` — WiFi popup
- `custom:notif-popup` — Notification panel
- `custom:cal-popup` — Calendar popup

---

## Bar PanelWindow
- `exclusiveZone: (barTopMargin + barHeight + popupGap)` when visible, `0` when hidden (auto-hide)
  - = `10 + 36 + 2 = 48` when visible
- `implicitHeight: barHeight + barTopMargin` when visible, `0` when hidden
  - = `46` when visible
- `anchors.top: true` with `margins.top: barTopMargin` (10)
- `anchors.left: true`, `anchors.right: true` with `margins.left/right: sideMargin` (8)

### Bar Geometry Breakdown
```
Screen top (y=0)
├── y=0 to y=10:   Bar top margin (margins.top: 10)
├── y=10 to y=46:  Bar content area (height: 36)
├── y=46 to y=48:  Popup gap (popupGap: 2)
├── y=48:          Popup surface starts here (after exclusiveZone)
└── y=48 to y=548: Popup content area (height: 500)
```

The bar's `implicitHeight` (46) includes the top margin. The bar content (`BarContent`) is positioned at `anchors.top: parent.top` with `height: barHeight` (36), so it fills y=10 to y=46.

---

## Popup PanelWindows
- `exclusiveZone: 0` — no screen space reservation
- `anchors.top: true` — anchored to screen top
- No `margins.top` — surface position determined by bar's exclusiveZone
- `anchors.right: true` for BT/WiFi/Notification (right-aligned)
- `anchors.left: true` for Calendar (centered via `margins.left`)
- `implicitHeight: visible ? <height> : 0` — collapses when hidden

### Popup Dimensions
| Popup | Width | Height | Horizontal Position |
|-------|-------|--------|-------------------|
| Bluetooth | `(sw - 16) * 0.4` | 500 | Right-aligned, `margins.right: 16` |
| WiFi | `(sw - 16) * 0.4` | 500 | Right-aligned, `margins.right: 16` |
| Notification | 360 | 590 | Right-aligned, `margins.right: 16` |
| Calendar | `(sw - 16) * 0.70 + 20` | 500 | Centered via `margins.left` |

---

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

---

## Notification Panel (replaces old QuickSettings)
- Width: 360px, Height: 590px
- Three sections:
  - **Top**: Control tools grid (Mic, Night Light, DND, Color Picker, Screenshot)
  - **Middle**: Notifications grouped by app (scrollable, iPhone-style)
  - **Bottom**: Power buttons (Hibernate, Logout, Reboot, Power Off)
- Uses `Quickshell.Services.Notifications.NotificationServer` for receiving notifications
- Notifications are grouped by `appName` and displayed in a scrollable list
- Click a notification to dismiss it

---

## Lockscreen (hyprlock)
- `Super+L` — Lock screen
- `Super+Shift+L` — Suspend
- Auto-lock after 5min idle via hypridle
- Config: `~/.config/hypr/hyprlock.conf`
- Blurred wallpaper background, clock bottom-left, password input bottom-right

---

## Auto-Hide Logic
A 100ms timer checks cursor Y position:
- `y <= 2` → Show bar, stop hide timer
- `y > 50` and cursor was near top → If any popup open, close all; then start 1..5s hide timer
- Opening popup via keybind always shows bar (`barVisible = true`)

---

## Keybinds
All keybinds are defined in `hypr/keybinds.conf` (single file for cheatsheet generation). Shell toggles use Hyprland's global shortcut protocol (`global, quickshell:<action>`) and are handled by `GlobalShortcut` elements in shell.qml.

### Shell Toggles (Global IPC)
| Key | Action | Handler |
|-----|--------|---------|
| `Super+O` | Toggle bar visibility | `barToggle` → `ctx.toggleBar()` |
| `Super+A` | Toggle notification panel | `notificationPanelToggle` → `ctx.toggleNotificationPanel()` |
| `Super+M` | Toggle media card | `mediaControlsToggle` → `ctx.toggleMediaCard()` |

### Window Management
| Key | Action |
|-----|--------|
| `Super+F` | Fullscreen toggle (true fullscreen) |
| `Super+Shift+F` | Windowed fullscreen toggle (fills screen with gaps) |
| `Super+G` | Toggle floating |
| `Super+Q` | Kill active window |
| `Super+P` | Pin window |
| `Super+H/L` or `Super+Left/Right` | Move focus |
| `Super+Shift+Arrow` | Move window |
| `Super+right-click drag` | Resize window |

### Workspace
| Key | Action |
|-----|--------|
| `Super+1-9,0` | Switch to workspace 1-10 |
| `Super+Shift+1-9,0` | Move window to workspace |
| `Super+Tab` | Next workspace |
| `Super+Shift+Tab` | Previous workspace |
| `Super+Page_Up/Page_Down` | Cycle workspaces |
| `Super+Equal/Minus` | Cycle workspaces |

### Apps
| Key | Action |
|-----|--------|
| `Super+Return` | Ghostty terminal |
| `Super+W` | Zen browser |
| `Super+Shift+W` | Brave browser |
| `Super+E` | Thunar file manager |
| `Super+C` | Neovim |

### Session
| Key | Action |
|-----|--------|
| `Super+Shift+P` | Lock screen (hyprlock) |
| `Super+Shift+L` | Suspend |
| `Ctrl+Shift+Alt+Super+Delete` | Power off |
| `Ctrl+Shift+Alt+Super+End` | Reboot |

### Other
| Key | Action |
|-----|--------|
| `Print` | Screenshot to clipboard |
| `Ctrl+Print` | Screenshot to file |
| `Super+Shift+C` | Color picker (hyprpicker) |
| `Ctrl+Super+R` | Restart Quickshell |

---

## Media Card
The media card is a separate `Window` (not PanelWindow) because it needs:
- Slide-in animation from left (`Behavior on x`)
- `Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowTransparentForInput`
- Independent positioning

---

## Modifying This File

### To change the gap between bar and popup
Edit `popupGap` at the top of the file:
```qml
readonly property real popupGap: 2  // Change this value
```
The bar's `exclusiveZone` automatically recalculates: `barTopMargin + barHeight + popupGap`

### To change bar height
1. Modify `barHeight` property
2. Update `BarContent.height` (should match `barHeight`)
3. `exclusiveZone` auto-adjusts via formula

### To add a new popup
1. Add a new `PanelWindow` with `exclusiveZone: 0`
2. Set `anchors.top: true` and appropriate horizontal anchors
3. Add unique `WlrLayershell.namespace: "custom:your-popup"`
4. Add `togglePopup("yourpopup")` calls in ShellState (or use existing `openPopup`)
5. Add `GlobalShortcut` element with `name` and `onPressed`
6. Add corresponding `bind = ..., global, quickshell:<name>` in `keybinds.conf`

### To change popup horizontal position
- **Right-aligned**: Use `anchors.right: true` with `margins.right: <offset>`
- **Centered**: Use `anchors.left: true` with `margins.left: (sw - popupWidth) / 2`
- **Left-aligned**: Use `anchors.left: true` with `margins.left: <offset>`

### Each popup needs a unique `WlrLayershell.namespace` to avoid compositor conflicts
