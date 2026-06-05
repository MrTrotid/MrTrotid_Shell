# ServiceContext.qml - Shared State Store

## Purpose
Central state store for the entire shell. All toggle states, visibility flags, and shared functions live here. Every widget receives this via `serviceContext` property.

## Architecture
```
Item
├── readonly property var shellState: this   — Self-reference for backward compat
├── Visibility toggles (bool properties)
├── Toggle functions
├── keepBarTemporarily() + timer
├── ColorUtils instance
└── Component.onCompleted logging
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `shellState` | var | `this` | Self-reference. Allows `ctx.shellState.barVisible` to resolve to `ctx.barVisible` |
| `mediaCardOpen` | bool | false | Media card visibility |
| `barVisible` | bool | true | Bar visibility |
| `keepBarVisible` | bool | false | Temporary keep-alive flag |
| `quickSettingsOpen` | bool | false | Quick settings popup |
| `bluetoothPanelOpen` | bool | false | Bluetooth selector popup |
| `wifiSelectorOpen` | bool | false | WiFi selector popup |
| `batteryTooltipVisible` | bool | false | Battery tooltip visibility |
| `batteryTooltipText` | string | "" | Battery tooltip content |
| `calendarPopupOpen` | bool | false | Calendar popup |
| `notificationPanelOpen` | bool | false | Notification panel popup |
| `anyPopupOpen` | readonly bool | — | Computed: true if any popup is open |
| `colorUtils` | ColorUtils | {} | Color utility functions |

## Functions

### Toggle Functions
Each toggle function flips its boolean and closes other popups (mutual exclusion). Opening a popup always sets `barVisible = true`.

```javascript
function toggleBar() { barVisible = !barVisible }

function toggleMediaCard() { mediaCardOpen = !mediaCardOpen }

function toggleBluetoothPanel() {
    bluetoothPanelOpen = !bluetoothPanelOpen
    if (bluetoothPanelOpen) barVisible = true
    batteryTooltipVisible = false
    quickSettingsOpen = false
    wifiSelectorOpen = false
    notificationPanelOpen = false
}

function toggleWifiSelector() {
    wifiSelectorOpen = !wifiSelectorOpen
    if (wifiSelectorOpen) barVisible = true
    batteryTooltipVisible = false
    quickSettingsOpen = false
    bluetoothPanelOpen = false
    notificationPanelOpen = false
}

function toggleCalendarPopup() {
    calendarPopupOpen = !calendarPopupOpen
    if (calendarPopupOpen) barVisible = true
    batteryTooltipVisible = false
    quickSettingsOpen = false
    bluetoothPanelOpen = false
    wifiSelectorOpen = false
    notificationPanelOpen = false
}

function toggleNotificationPanel() {
    notificationPanelOpen = !notificationPanelOpen
    if (notificationPanelOpen) barVisible = true
    batteryTooltipVisible = false
    quickSettingsOpen = false
    bluetoothPanelOpen = false
    wifiSelectorOpen = false
    calendarPopupOpen = false
}
```

### keepBarTemporarily()
Sets `keepBarVisible = true` and starts a 5-second timer. Used when toggling Quick Settings to prevent the bar from auto-hiding while interacting with the popup.

## `shellState` Pattern
The `shellState` property is a self-reference that allows code like:
```javascript
serviceContext.shellState.toggleBluetoothPanel()
```
This resolves to:
```javascript
ctx.toggleBluetoothPanel()
```
This pattern exists because older code expected `serviceContext.shellState.*` access paths.

## Usage in Other Files
```qml
// In BarContent.qml
serviceContext.shellState.toggleBluetoothPanel()

// In shell.qml
ServiceContext { id: ctx }
// ...
visible: ctx?.bluetoothPanelOpen ?? false
```

## Modifying This File
- To add a new popup: Add `property bool newPopupOpen: false` and a toggle function
- To add state: Add a property and optionally a setter function
- Keep toggle functions mutually exclusive (close other popups)
