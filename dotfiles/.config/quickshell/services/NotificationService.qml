pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property ListModel notifications: ListModel {}
    property var _seenIds: []
    readonly property string notifFile: "/tmp/quickshell-notifications"

    Component.onCompleted: {
        Quickshell.execDetached(["bash", "-c", "> " + notifFile])
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            if (!readProc.running) readProc.running = true
        }
    }

    Process {
        id: readProc
        command: ["cat", root.notifFile]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length === 0) return

                var lines = text.split("\n")
                var newIds = []

                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.length === 0) continue

                    var parts = line.split("|")
                    if (parts.length < 2) continue

                    var id = parts[0]
                    if (root._seenIds.indexOf(id) !== -1) continue

                    newIds.push(id)
                    var title = parts[1] || ""
                    var body = parts[2] || ""
                    var icon = parts[3] || ""

                    root.addNotification(title, body, icon)
                }

                root._seenIds = root._seenIds.concat(newIds)
                if (root._seenIds.length > 500) {
                    root._seenIds = root._seenIds.slice(-200)
                }

                Quickshell.execDetached(["bash", "-c", "> " + root.notifFile])
            }
        }
    }

    function addNotification(title, body, icon) {
        root.notifications.insert(0, {
            "title": title,
            "body": body,
            "icon": icon || ""
        })

        Quickshell.execDetached(["paplay", "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"])

        // Remove oldest if over 3
        if (root.notifications.count > 3) {
            root.notifications.remove(root.notifications.count - 1)
        }
    }

    function removeNotification(idx) {
        if (idx >= 0 && idx < root.notifications.count) {
            root.notifications.remove(idx)
        }
    }
}
