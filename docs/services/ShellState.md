# ShellState - UI Visibility & Popup State Management

## Purpose
Central state manager for all UI visibility toggles. Implements mutual exclusion for popups via a single `activePopup` string property.

## Architecture
Singleton service. Pure state container — no Process elements or timers (except `keepBarTimer`).

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `barVisible` | bool | true | Whether the bar is visible |
| `keepBarVisible` | bool | false | Temporarily prevents bar auto-hide |
| `batteryTooltipVisible` | bool | false | Whether battery tooltip is expanded |
| `batteryTooltipText` | string | "" | Battery tooltip content |
| `mediaCardOpen` | bool | false | Whether media card window is visible |
| `activePopup` | string | "" | Currently open popup name (mutual exclusion) |

## Derived Booleans (readonly)
| Property | Condition |
|---|---|
| `bluetoothPanelOpen` | `activePopup === "bluetooth"` |
| `wifiSelectorOpen` | `activePopup === "wifi"` |
| `calendarPopupOpen` | `activePopup === "calendar"` |
| `notificationPanelOpen` | `activePopup === "notification"` |
| `cheatsheetOpen` | `activePopup === "cheatsheet"` |
| `wallpaperPickerOpen` | `activePopup === "wallpaper"` |
| `quickActionsOpen` | `activePopup === "quickactions"` |
| `anyPopupOpen` | `activePopup !== ""` |

## Key Functions
| Function | Description |
|---|---|
| `toggleBar()` | Toggles `barVisible` |
| `toggleMediaCard()` | Toggles `mediaCardOpen` |
| `togglePopup(name)` | Toggles `activePopup` (if same name, closes; otherwise opens). Shows bar if opening. Clears battery tooltip. |
| `openPopup(name)` | Opens specific popup, shows bar, clears battery tooltip |
| `closePopup()` | Sets `activePopup` to "" |
| `toggleBluetoothPanel()` | Wrapper for `togglePopup("bluetooth")` |
| `toggleWifiSelector()` | Wrapper for `togglePopup("wifi")` |
| `toggleCalendarPopup()` | Wrapper for `togglePopup("calendar")` |
| `toggleNotificationPanel()` | Wrapper for `togglePopup("notification")` |
| `toggleCheatsheet()` | Wrapper for `togglePopup("cheatsheet")` |
| `toggleWallpaperPicker()` | Wrapper for `togglePopup("wallpaper")` |
| `toggleQuickActions()` | Wrapper for `togglePopup("quickactions")` |
| `keepBarTemporarily()` | Sets `keepBarVisible = true` for 5000ms |

## Key Timers
| Timer | Interval | Purpose |
|---|---|---|
| `keepBarTimer` | 5000ms (one-shot) | Resets `keepBarVisible` after temporary keep |

## Modifying This File
- Add new popup: Add `activePopup` value, derived boolean, and toggle wrapper
- Change keep duration: Modify `keepBarTimer.interval` (default 5000ms)
