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
    property string _persistPath: Quickshell.env("HOME") + "/.cache/quickshell/notifications.json"

    Timer {
        id: startupGuard
        interval: 1500
        running: true
        repeat: false
        onTriggered: root._startupPhase = false
    }

    function _saveNotifications() {
        var serializable = []
        for (var i = 0; i < root.notifications.length; i++) {
            var n = root.notifications[i]
            serializable.push({
                "notificationId": n.notificationId,
                "appName": n.appName,
                "summary": n.summary,
                "body": n.body,
                "appIcon": n.appIcon,
                "image": n.image,
                "urgency": n.urgency,
                "time": n.time,
                "actions": n.actions
            })
        }
        _writeFile(_persistPath, JSON.stringify(serializable, null, 2))
    }

    function _loadNotifications() {
        var content = _readFile(_persistPath)
        if (!content || content.length === 0) return
        try {
            var loaded = JSON.parse(content)
            if (!Array.isArray(loaded)) return
            var restored = []
            for (var i = 0; i < loaded.length; i++) {
                var n = loaded[i]
                restored.push({
                    "notificationId": n.notificationId,
                    "notification": null,
                    "appName": n.appName || "",
                    "summary": n.summary || "",
                    "body": n.body || "",
                    "appIcon": n.appIcon || "",
                    "image": n.image || "",
                    "urgency": n.urgency || "normal",
                    "time": n.time || 0,
                    "actions": n.actions || [],
                    "popup": false
                })
            }
            root.notifications = restored
            root.unread = restored.length
        } catch (e) {}
    }

    function _writeFile(path, content) {
        var proc = _writeFileProc
        proc._command = "mkdir -p $(dirname \"" + path + "\") && echo '" + Qt.btoa(content).replace(/'/g, "'\\''") + "' | base64 -d > \"" + path + "\""
        proc.running = true
    }

    function _readFile(path) {
        var proc = _readFileProc
        proc.command = ["cat", path]
        proc._result = ""
        proc.running = true
        return proc._result
    }

    Process {
        id: _writeFileProc
        property string _command
        command: ["sh", "-c", _command]
        running: false
    }

    Process {
        id: _readFileProc
        property string _result: ""
        running: false
        stdout: StdioCollector {
            onStreamFinished: _readFileProc._result = text
        }
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
                "actions": notification.actions ? notification.actions.map(a => ({identifier: a.identifier, text: a.text, _ref: a})) : [],
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
                    "appName": notifObj.appName,
                    "actions": notifObj.actions,
                    "urgency": notifObj.urgency
                })
            }

            if (!root._startupPhase)
                Quickshell.execDetached(["paplay", "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"])

            root._saveNotifications()
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

        root._saveNotifications()
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
        root._saveNotifications()
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

    function addNotification(appName, summary, body, urgency) {
        var notifObj = {
            "notificationId": Date.now() + Math.floor(Math.random() * 1000),
            "notification": null,
            "appName": appName || "",
            "summary": summary || "",
            "body": body || "",
            "appIcon": "",
            "image": "",
            "urgency": urgency || "normal",
            "time": Date.now(),
            "actions": [],
            "popup": true
        }

        root.activePopup = notifObj
        root.unread++
        root.notifications = [...root.notifications, notifObj]

        if (root.toastList.count >= root._maxToasts) {
            var overflow = root.toastList.get(root.toastList.count - 1)
            root.toastList.remove(root.toastList.count - 1, 1)
        }
        root.toastList.insert(0, {
            "notificationId": notifObj.notificationId,
            "summary": notifObj.summary,
            "body": notifObj.body,
            "appIcon": notifObj.appIcon,
            "appName": notifObj.appName,
            "actions": notifObj.actions,
            "urgency": notifObj.urgency
        })

        root._saveNotifications()

        if (!root._startupPhase)
            Quickshell.execDetached(["paplay", "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"])
    }

    function attemptInvokeAction(id, actionIdentifier) {
        var notif = root.notifications.find(n => n.notificationId === id)
        if (!notif || !notif.notification) return

        var action = null
        if (actionIdentifier === "default") {
            action = notif.actions.find(a => a.identifier === "default" || a.identifier === "" || a.identifier === "0")
        } else {
            action = notif.actions.find(a => a.identifier === actionIdentifier)
        }

        if (action && action._ref) {
            action._ref.invoke()
        }

        root.discardNotification(id)
    }

    Component.onCompleted: {
        _loadNotifications()
    }
}
