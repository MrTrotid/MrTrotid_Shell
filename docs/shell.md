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
├── PanelWindow (popupOverlay)          — Full-screen transparent overlay for click-outside-to-close
├── PanelWindow (blPopup)               — Bluetooth popup (exclusiveZone: 0)
│   └── BluetoothSelector               — BT device picker
├── PanelWindow (wifiPopup)             — WiFi popup (exclusiveZone: 0)
│   └── WifiSelector                    — WiFi network picker
├── PanelWindow (notifPopup)            — Notification panel (exclusiveZone: 0, exempt from overlay)
│   └── NotificationPanel               — Tools + Notifications + Power
├── PanelWindow (calPopup)              — Calendar popup (exclusiveZone: 0)
│   └── CalendarPopup                   — Calendar/Weather/Time
├── PanelWindow (csPopup)               — Cheatsheet popup (exclusiveZone: 0, keyboard focus)
│   └── Cheatsheet                      — Searchable keybind reference with executable actions
├── PanelWindow (toastPopup)            — Notification toasts (stacked, exclusiveZone: 0)
│   └── NotificationPopup               — Stacked notification cards
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

---

## Popup Overlay (Click-Outside-to-Close)

A full-screen transparent PanelWindow that enables click-outside-to-close behavior for all popups except the notification panel.

### Configuration
```qml
PanelWindow {
    id: popupOverlay
    visible: ShellState.anyPopupOpen && !ShellState.notificationPanelOpen
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "custom:popup-overlay"

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: ShellState.closePopup()
    }
}
```

### Behavior
- **Visible when:** Any popup is open EXCEPT notification panel
- **Click action:** Calls `ShellState.closePopup()` to dismiss the active popup
- **Z-ordering:** Created before popup PanelWindows in shell.qml (lower z-order)
- **Exemptions:** Notification panel stays open until explicitly dismissed

### Why Notification Panel Is Exempt
The notification panel is a persistent UI element that users may want to keep open while interacting with other parts of the desktop. It has its own close button and can be toggled via `Super + A`.

---

## Cheatsheet Popup

Searchable keybind reference with executable actions and horizontal scrolling.

### Configuration
```qml
PanelWindow {
    id: csPopup
    visible: ShellState.cheatsheetOpen
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "custom:cheatsheet"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    implicitWidth: (sw - 16) * 0.85 + 20   // 85% screen width
    implicitHeight: visible ? 750 : 0
}
```

### Key Features
- **Keyboard focus:** `WlrKeyboardFocus.OnDemand` enables text input in search field
- **Executable keybinds:** Apps, Session, Screenshots, Recording categories run commands on click
- **Copy to clipboard:** Other categories copy key combo to clipboard
- **Horizontal scrolling:** Mouse wheel translates to horizontal scroll
- **Visible scrollbar:** Bottom scrollbar with hover opacity change

### Category Data Structure
```qml
{
    name: "Apps",
    icon: "\uF120",
    binds: [
        { keys: "Super + Enter", desc: "Terminal (Ghostty)", action: "ghostty" },
        // action field = execute command on click
        // no action field = copy to clipboard on click
    ]
}
```

### Executable Categories
| Category | Actions |
|----------|---------|
| Apps | ghostty, rofi, clipboard-picker, zen-browser, brave-browser, thunar, nvim |
| Session | hyprlock, systemctl suspend/poweroff/reboot |
| Screenshots | screenshot.sh full/region/window/monitor, hyprpicker |
| Recording | recording.sh region/full |

---

## Notification Toasts

Notification toasts appear below the bar and stack downward with a 10px offset.

### PanelWindow Configuration
- `margins.top: barTopMargin + barHeight - 6` — positions below the bar
- `margins.left: (sw - 340) / 2` — horizontally centered
- `implicitHeight: 64 + (count - 1) * 10` — grows with stacked notifications (max 3)

### Toast Stacking
- Each notification card is 64px tall
- Cards stack with 10px offset: card 0 at y=0, card 1 at y=10, card 2 at y=20
- Newest notification is always on top (index 0)
- Maximum 3 visible at once; oldest is removed when a 4th arrives

### Toast Design
- **Background**: Solid `#1a1c1e` (opaque)
- **Border**: Subtle white 8% opacity with top highlight edge
- **App-based accent color**: Each notification type gets a distinct tint:
  - Firefox/Chrome/Brave → Blue
  - Discord/Telegram → Indigo
  - Spotify/Music/Mpv → Green
  - Kitty/Terminal → Teal
  - Thunar/Files → Orange
  - Screenshot → Light Blue
  - Recording → Red
  - Clipboard → Lime
  - Volume/Audio → Purple
  - Battery/Power → Yellow
  - Default → Neutral glass
- Accent applied to: icon background glow, icon text color

### Toast Lifecycle
- **Entry**: Slides in from y=-100 with 350ms ease-out + fade in over 300ms
- **Reposition**: When index changes (new notification added/removed), existing cards animate to new y position over 250ms
- **Exit**: After 3.5s, slides up to y=-100 over 300ms + fades out over 250ms, then removes from ListModel

### File-based IPC
Notifications come from external scripts writing to `/tmp/quickshell-notifications`:
```
id|title|body|icon
```
Quickshell polls every 200ms, deduplicates by ID, and auto-clears the file.

Sound notification: `paplay /usr/share/sounds/freedesktop/stereo/message-new-instant.oga`

---

## Multi-PanelWindow Design (Each Popup Gets Its Own Surface)

### Why Each Popup Is a Separate PanelWindow

Each popup is a separate `PanelWindow` with `exclusiveZone: 0` to solve the **Wayland layer shell input limitation**: a surface with `exclusiveZone: N` only receives input in the N-pixel exclusive zone. Popups below the exclusive zone are visible but non-interactive.

By giving each popup its own layer shell surface with `exclusiveZone: 0`, it gets its own independent input region and can receive mouse clicks.

---

## Layer Configuration
All PanelWindows use:
- `WlrLayershell.layer: WlrLayer.Top` — Always on top
- `ExclusionMode.Normal` — Can overlap

Each popup has a unique `WlrLayershell.namespace`:
- `custom:bar` — Bar surface
- `custom:popup-overlay` — Click-outside-to-close overlay
- `custom:bl-popup` — Bluetooth popup
- `custom:wifi-popup` — WiFi popup
- `custom:notif-popup` — Notification panel
- `custom:cal-popup` — Calendar popup
- `custom:cheatsheet` — Cheatsheet popup
- `custom:toast` — Notification toasts

---

## Keybinds
All keybinds are defined in `hypr/keybinds.conf` (single file for cheatsheet generation). Shell toggles use Hyprland's global shortcut protocol (`global, quickshell:<action>`) and are handled by `GlobalShortcut` elements in shell.qml.

### Shell Toggles (Global IPC)
| Key | Action | Handler |
|-----|--------|---------|
| `Super+O` | Toggle bar visibility | `barToggle` |
| `Super+A` | Toggle notification panel | `notificationPanelToggle` |
| `Super+M` | Toggle media card | `mediaControlsToggle` |
| `Super+/` | Toggle cheatsheet | `cheatsheetToggle` |

### Screen Recording
| Key | Action |
|-----|--------|
| `Ctrl+Shift+R` | Region recording (select → pick audio → record) / Stop |
| `Ctrl+Alt+R` | Full screen recording (pick audio → record) / Stop |

### Screenshots
| Key | Mode |
|-----|------|
| `Print` | Full screen to clipboard |
| `Ctrl+Print` | Full screen to file |
| `Shift+Print` | Region select |
| `Alt+Print` | Window select |
| `Ctrl+Shift+Print` | Monitor select |
| `Ctrl+Alt+Print` | Timed full screen (5s delay) |

### Clipboard
| Key | Action |
|-----|--------|
| `Super+V` | Clipboard history picker (rofi + cliphist) |

### App Launcher
| Key | Action |
|-----|--------|
| `Super+Space` | Rofi app launcher |

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
| `Super+Shift+C` | Color picker (hyprpicker) |
| `Ctrl+Super+R` | Restart Quickshell |

---

## Media Card
The media card is a separate `Window` (not PanelWindow) because it needs:
- Slide-in animation from left (`Behavior on x`)
- `Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowTransparentForInput`
- Independent positioning
