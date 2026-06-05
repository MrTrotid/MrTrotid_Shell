pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool networkConnected: false
    property string networkSsid: ""
    property int networkStrength: 0

    // Monitor nmcli events for real-time changes
    Process {
        id: nmMonitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: nmPoll.running = true
        }
    }

    // Debounce after nmcli event
    Timer {
        id: nmPoll
        interval: 500
        repeat: false
        onTriggered: nmUpdate.running = true
    }

    // Fallback poll every 10 seconds
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: if (!nmUpdate.running) nmUpdate.running = true
    }

    Process {
        id: nmUpdate
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SIGNAL,SSID device wifi list --rescan no | grep '^yes:' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (!line) {
                    root.networkConnected = false
                    return
                }
                var parts = line.split(":")
                if (parts.length >= 3 && parts[0] === "yes") {
                    root.networkConnected = true
                    root.networkStrength = parseInt(parts[1]) || 0
                    root.networkSsid = parts[2]
                } else {
                    root.networkConnected = false
                }
            }
        }
    }

    Component.onCompleted: {
        nmUpdate.running = true
    }
}
