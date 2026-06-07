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
            onRead: nmPoll.restart()
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
        command: ["sh", "-c", "nmcli -t -e yes -f ACTIVE,SIGNAL,SSID device wifi list --rescan no | grep '^yes:' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (!line) {
                    root.networkConnected = false
                    return
                }
                // Format: ACTIVE:SIGNAL:SSID (-e yes escapes colons as \:)
                var firstColon = line.indexOf(':')
                var secondColon = line.indexOf(':', firstColon + 1)
                if (firstColon === -1) {
                    root.networkConnected = false
                    return
                }
                var active = line.substring(0, firstColon)
                var signal = secondColon === -1 ? line.substring(firstColon + 1) : line.substring(firstColon + 1, secondColon)
                var ssid = secondColon === -1 ? "" : line.substring(secondColon + 1)
                // Unescape \: from -e yes mode
                ssid = ssid.replace(/\\:/g, ":")

                if (active === "yes") {
                    root.networkConnected = true
                    root.networkStrength = parseInt(signal) || 0
                    root.networkSsid = ssid
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
