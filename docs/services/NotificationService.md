# NotificationService - DBus Notification Server & Management

## Purpose
Implements a DBus notification server that receives, stores, groups, and manages desktop notifications. Provides toast popups, persistence, and action invocation.

## Architecture
Singleton service. Contains a `NotificationServer` (from Quickshell.Services.Notifications) that receives DBus notifications. Notifications are stored in a JS array; toasts in a `ListModel`.

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `notifications` | var (array) | [] | All notifications (raw array) |
| `toastList` | ListModel | {} | Toast queue (max 3) |
| `_maxToasts` | int | 3 | Maximum simultaneous toasts |
| `unread` | int | 0 | Unread notification count |
| `silent` | bool | false | Suppress toast popups |
| `activePopup` | var | null | Currently displayed notification popup |
| `_startupPhase` | bool | true | True for first 1.5s (suppresses sound) |
| `_persistPath` | string | ~/.cache/quickshell/notifications.json | Persistence file path |
| `groupsByAppName` | var (readonly) | computed | Notifications grouped by appName |
| `appNameList` | var (readonly) | computed | App names sorted by most recent |

## Notification Object Structure
```javascript
{
    notificationId: int,      // Unique ID (Date.now() + random)
    notification: Notification, // Quickshell notification object (null for programmatic)
    appName: string,          // Application name
    summary: string,          // Notification title
    body: string,             // Notification body text
    appIcon: string,          // App icon path/name
    image: string,            // Notification image
    urgency: string,          // "low" | "normal" | "critical"
    time: int,                // Timestamp (Date.now())
    actions: var,             // [{identifier, text}]
    popup: bool               // Whether to show as toast
}
```

## Key Processes / Timers
| Element | Command | Interval | Purpose |
|---|---|---|---|
| `NotificationServer` | DBus listener | - | Receives desktop notifications |
| `startupGuard` | - | 1500ms (one-shot) | Suppresses sound during reload |
| `_writeFileProc` | `sh -c` (dynamic) | On demand | Writes notifications to disk |
| `_readFileProc` | `cat <path>` | On demand | Reads persisted notifications |

## Key Functions
| Function | Description |
|---|---|
| `addNotification(appName, summary, body, urgency)` | Creates programmatic notification (used by BatteryService) |
| `discardNotification(id)` | Removes notification, dismisses DBus object, removes from toast |
| `dismissToast(id)` | Removes from toastList only |
| `discardAllNotifications()` | Clears everything, dismisses all DBus objects |
| `markAllRead()` | Sets unread to 0 |
| `getCountForApp(appId)` | Returns notification count for given app |
| `attemptInvokeAction(id, actionIdentifier)` | Invokes notification action, then discards |

## Toast Management
- Max 3 toasts in `toastList`
- New toasts insert at index 0
- Overflow: oldest toast removed, its DBus notification dismissed
- Toasts auto-dismiss after 3500ms (normal) or 15000ms (critical)

## Sound
Plays `message-new-instant.oga` via `paplay` for each notification (except during startup phase).

## Persistence
- Saves to `~/.cache/quickshell/notifications.json` on every change
- Loads on `Component.onCompleted`
- Saves only serializable fields (not Quickshell Notification objects)

## Notification Grouping
`groupsByAppName` groups notifications by `appName`, with most recent time. `appNameList` sorts groups by most recent.

## Modifying This File
- Change max toasts: Modify `_maxToasts` (default 3)
- Change toast timeout: Modify `NotificationPopup.qml` timers
- Change persistence path: Modify `_persistPath`
- Change sound: Modify `paplay` command path
