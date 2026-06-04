# NotificationPanel.qml — Notification Center

## Purpose
Three-section popup replacing the old Quick Settings panel. Top section has control tools (Mic, Night Light, DND, Color Picker), middle section shows notifications grouped by app (iPhone-style, scrollable), bottom section has power buttons (Hibernate, Logout, Reboot, Power Off).

## Architecture
```
Item (root: panel)
├── Colors (monochrome teal, matching bar)
├── Tool states (micMuted, nightLight, dndEnabled)
├── Notification storage (groupedNotifications object)
├── NotificationServer (Quickshell.Services.Notifications)
├── Mic state polling (Process → wpctl)
├── Intro animation
├── Main container (Rectangle, rounded)
│   ├── SECTION 1: Control Tools (GridLayout, 4 columns)
│   │   ├── Mic Toggle (wpctl set-mute @DEFAULT_AUDIO_SOURCE@)
│   │   ├── Night Light (hyprctl togglespecialworkspace)
│   │   ├── DND (swaync-client -dn/-df)
│   │   └── Color Picker (hyprpicker -a)
│   ├── Divider
│   ├── SECTION 2: Notifications (ScrollView + ListView)
│   │   ├── Header ("Notifications" + "Clear All" button)
│   │   ├── App groups (grouped by appName)
│   │   │   ├── App header (icon + name + count)
│   │   │   └── Notification cards (summary + body + time)
│   │   └── Empty state ("No notifications")
│   ├── Divider
│   └── SECTION 3: Power Buttons (RowLayout, horizontal)
│       ├── Hibernate (systemctl hibernate)
│       ├── Logout (loginctl terminate-user $USER)
│       ├── Reboot (systemctl reboot)
│       └── Power Off (systemctl poweroff)
```

## File Location
- `widgets/NotificationPanel.qml` — main QML component

## Notification System
Uses `Quickshell.Services.Notifications.NotificationServer`:
- `keepOnReload: true` — Notifications survive shell reload
- `bodySupported: true` — Advertises body text support
- `imageSupported: true` — Advertises image support
- On `onNotification`: sets `notification.tracked = true`, adds to `groupedNotifications`

### Notification Storage
Notifications stored in `groupedNotifications` object:
```javascript
{
    "Firefox": [
        { id: 1, summary: "New message", body: "Hello!", appName: "Firefox", time: "14:30" },
        { id: 2, summary: "Download complete", body: "file.zip", appName: "Firefox", time: "14:25" }
    ],
    "Thunderbird": [
        { id: 3, summary: "New email", body: "Subject: Meeting", appName: "Thunderbird", time: "14:20" }
    ]
}
```

### Notification Display
- Grouped by `appName` with app icon (first letter fallback)
- Each card shows: summary (bold) + time (right) + body (truncated to 3 lines)
- Click to dismiss (calls `notification.dismiss()`)
- "Clear All" button dismisses all notifications

## Control Tools
| Tool | Icon | Command | State |
|------|------|---------|-------|
| Mic | \uF130/\uF131 | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` | Polled every 2s |
| Night Light | \uF186 | `hyprctl dispatch togglespecialworkspace nightlight` | Toggle bool |
| DND | \uF5B6 | `swaync-client -dn` / `-df` | Toggle bool |
| Color Picker | \uF04C2 | `hyprpicker -a` | One-shot |

## Power Buttons
| Button | Icon | Command | Color |
|--------|------|---------|-------|
| Hibernate | \uF0102 | `systemctl hibernate` | Peach (#e8a87c) |
| Logout | \uF0343 | `loginctl terminate-user $USER` | Error (#ffb4ab) |
| Reboot | \uF021A | `systemctl reboot` | Accent (#81d5ca) |
| Power Off | \uF0116 | `systemctl poweroff` | Error (#ffb4ab) |

## Toggle Mechanism
- `ctx.notificationPanelOpen` property in `ServiceContext.qml`
- `toggleNotificationPanel()` function in `ServiceContext.qml`
- Notification icon in `BarContent.qml` calls `toggleNotificationPanel()`
- `shell.qml`: `notifPanel` Item wraps `NotificationPanel`, width 360px, height 560px

## Key Decisions
- NotificationPanel is a **floating Item** inside main PanelWindow (NOT a separate Window)
- Replaced old QuickSettings inline panel entirely
- Notifications grouped by app (iPhone-style) rather than flat list
- Fixed max height for notification section with ScrollView
- Power buttons use system commands (systemctl/loginctl) not Quickshell APIs
- All tool toggles use shell commands (wpctl, hyprctl, swaync-client, hyprpicker)
