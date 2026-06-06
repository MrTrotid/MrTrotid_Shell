# ShellState.qml - UI State Singleton

## Purpose
Singleton managing all UI visibility states. Uses `activePopup` string pattern for mutual exclusion — only one popup can be open at a time.

## Architecture
```
Item (pragma Singleton)
├── barVisible, mediaCardOpen      — Simple toggles
├── activePopup: string            — Mutual exclusion ("bluetooth" | "wifi" | "calendar" | "notification" | "cheatsheet" | "")
├── Derived booleans               — bluetoothPanelOpen, wifiSelectorOpen, etc.
├── Toggle functions               — togglePopup("name"), openPopup("name"), closePopup()
├── batteryTooltip*                — Battery tooltip state
├── keepBarTemporarily() + timer   — Auto-hide delay
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `barVisible` | bool | true | Bar visibility |
| `keepBarVisible` | bool | false | Temporary keep-alive flag |
| `mediaCardOpen` | bool | false | Media card visibility |
| `activePopup` | string | "" | Current open popup (mutual exclusion) |
| `batteryTooltipVisible` | bool | false | Battery tooltip visibility |
| `batteryTooltipText` | string | "" | Battery tooltip content |

### Derived Booleans (backward-compat)
| Property | Resolves To |
|----------|------------|
| `bluetoothPanelOpen` | `activePopup === "bluetooth"` |
| `wifiSelectorOpen` | `activePopup === "wifi"` |
| `calendarPopupOpen` | `activePopup === "calendar"` |
| `notificationPanelOpen` | `activePopup === "notification"` |
| `cheatsheetOpen` | `activePopup === "cheatsheet"` |
| `anyPopupOpen` | `activePopup !== ""` |

## Functions

### Core (preferred)
```javascript
function togglePopup(name) {
    activePopup = (activePopup === name) ? "" : name
    if (activePopup !== "") barVisible = true
    batteryTooltipVisible = false
}

function openPopup(name) {
    activePopup = name
    barVisible = true
    batteryTooltipVisible = false
}

function closePopup() { activePopup = "" }
```

### Backward-compat wrappers
```javascript
function toggleBar() { barVisible = !barVisible }
function toggleMediaCard() { mediaCardOpen = !mediaCardOpen }
function toggleBluetoothPanel() { togglePopup("bluetooth") }
function toggleWifiSelector() { togglePopup("wifi") }
function toggleCalendarPopup() { togglePopup("calendar") }
function toggleNotificationPanel() { togglePopup("notification") }
function toggleCheatsheet() { togglePopup("cheatsheet") }
```

### keepBarTemporarily()
Sets `keepBarVisible = true` and starts a 5-second timer. Prevents auto-hide while interacting with popups.

## Usage
```qml
import "services"

// In shell.qml
visible: ShellState.bluetoothPanelOpen
GlobalShortcut { onPressed: ShellState.togglePopup("bluetooth") }

// In BarContent.qml
onClicked: ShellState.toggleCalendarPopup()
text: NetworkService.networkConnected ? "󰤨" : "󰤭"
```

## Adding a New Popup
1. Add `openPopup("newname")` / `togglePopup("newname")` calls
2. Add derived boolean: `readonly property bool newPopupOpen: activePopup === "newname"`
3. Add PanelWindow in shell.qml: `visible: ShellState.newPopupOpen`
4. Add GlobalShortcut handler in shell.qml
5. Add `bind = ..., global, quickshell:newPopupToggle` in keybinds.conf
