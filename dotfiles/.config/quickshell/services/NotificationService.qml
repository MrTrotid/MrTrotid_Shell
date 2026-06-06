pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Item {
    id: root

    property var notifications: []
    property ListModel toastList: ListModel {}
    property int _maxToasts: 3
    property int unread: 0
    property bool silent: false
    property var activePopup: null
    property bool _startupPhase: true

    Timer {
        id: startupGuard
        interval: 1500
        running: true
        repeat: false
        onTriggered: root._startupPhase = false
    }

    NotificationServer {
        id: notifServer
        actionsSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: (notification) => {
            notification.tracked = true

            if (root.activePopup) {
                root.activePopup = null
            }

            var notifObj = {
                "notificationId": notification.id,
                "notification": notification,
                "appName": notification.appName ?? "",
                "summary": notification.summary ?? "",
                "body": notification.body ?? "",
                "appIcon": notification.appIcon ?? "",
                "image": notification.image ?? "",
                "urgency": notification.urgency?.toString() ?? "normal",
                "time": Date.now(),
                "actions": notification.actions ? notification.actions.map(a => ({identifier: a.identifier, text: a.text})) : [],
                "popup": false
            }

            if (!root.silent) {
                notifObj.popup = true
                root.activePopup = notifObj
                root.unread++
            }

            root.notifications = [...root.notifications, notifObj]

            if (!root.silent) {
                if (root.toastList.count >= root._maxToasts) {
                    var overflow = root.toastList.get(root.toastList.count - 1)
                    root.toastList.remove(root.toastList.count - 1, 1)
                    if (overflow && overflow.notificationId) {
                        var idx = root.notifications.findIndex(n => n.notificationId === overflow.notificationId)
                        if (idx !== -1 && root.notifications[idx].notification)
                            root.notifications[idx].notification.dismiss()
                    }
                }
                root.toastList.insert(0, {
                    "notificationId": notifObj.notificationId,
                    "summary": notifObj.summary,
                    "body": notifObj.body,
                    "appIcon": notifObj.appIcon,
                    "appName": notifObj.appName
                })
            }

            if (!root._startupPhase)
                Quickshell.execDetached(["paplay", "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"])
        }
    }

    property var groupsByAppName: {
        var groups = {}
        for (var i = 0; i < notifications.length; i++) {
            var n = notifications[i]
            var name = n.appName || "Unknown"
            if (!groups[name]) {
                groups[name] = {
                    appName: name,
                    appIcon: n.appIcon,
                    time: n.time,
                    notifications: []
                }
            }
            groups[name].notifications.push(n)
            if (n.time > groups[name].time) groups[name].time = n.time
        }
        return groups
    }

    property var appNameList: {
        var keys = Object.keys(groupsByAppName)
        keys.sort(function(a, b) {
            return (groupsByAppName[b].time || 0) - (groupsByAppName[a].time || 0)
        })
        return keys
    }

    function discardNotification(id) {
        var idx = root.notifications.findIndex(n => n.notificationId === id)
        if (idx === -1) return

        var notif = root.notifications[idx]
        if (notif.notification) notif.notification.dismiss()
        if (root.unread > 0) root.unread--

        root.notifications = root.notifications.filter(n => n.notificationId !== id)

        for (var i = root.toastList.count - 1; i >= 0; i--) {
            if (root.toastList.get(i).notificationId === id) {
                root.toastList.remove(i, 1)
                break
            }
        }
    }

    function dismissToast(id) {
        for (var i = root.toastList.count - 1; i >= 0; i--) {
            if (root.toastList.get(i).notificationId === id) {
                root.toastList.remove(i, 1)
                break
            }
        }
    }

    function discardAllNotifications() {
        for (var i = 0; i < root.notifications.length; i++) {
            var notif = root.notifications[i]
            if (notif.notification) notif.notification.dismiss()
        }
        root.notifications = []
        root.toastList.clear()
        root.activePopup = null
        root.unread = 0
    }

    function markAllRead() {
        root.unread = 0
    }

    function getCountForApp(appId) {
        if (!appId) return 0
        var count = 0
        for (var i = 0; i < root.notifications.length; i++) {
            if (root.notifications[i].appName === appId) count++
        }
        return count
    }

    function attemptInvokeAction(id, actionIdentifier) {
        var notif = root.notifications.find(n => n.notificationId === id)
        if (!notif || !notif.notification) return

        if (actionIdentifier === "default") {
            if (typeof notif.notification.invokeDefaultAction === "function") {
                notif.notification.invokeDefaultAction()
            } else {
                var action = notif.actions.find(a => a.identifier === "default" || a.identifier === "")
                if (action) action.invoke()
            }
        } else {
            var action = notif.actions.find(a => a.identifier === actionIdentifier)
            if (action) action.invoke()
        }

        root.discardNotification(id)
    }
}
