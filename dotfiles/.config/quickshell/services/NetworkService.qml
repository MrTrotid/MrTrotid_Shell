pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool networkConnected: false
    property string networkSsid: ""
    property int networkStrength: 0

    property int netDown: 0
    property int netUp: 0
    property var _prevRx: -1
    property var _prevTx: -1

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
        interval: 1000
        repeat: false
        onTriggered: { if (!nmUpdate.running) nmUpdate.running = true }
    }

    // Fallback poll every 10 seconds
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: if (!nmUpdate.running) nmUpdate.running = true
    }

    // Net speed poll every 2s
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: if (!netSpeed.running && !nmUpdate.running) netSpeed.running = true
    }

    Process {
        id: netSpeed
        command: ["cat", "/proc/net/dev"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i].trim()
                    if (l.indexOf("wlan0:") === 0) {
                        var parts = l.split(/\s+/)
                        var rx = parseInt(parts[1])
                        var tx = parseInt(parts[9])
                        if (!isNaN(rx) && !isNaN(tx)) {
                            if (root._prevRx >= 0) {
                                root.netDown = Math.round((rx - root._prevRx) / 2000)
                                root.netUp = Math.round((tx - root._prevTx) / 2000)
                            }
                            root._prevRx = rx
                            root._prevTx = tx
                        }
                        break
                    }
                }
            }
        }
    }

    Process {
        id: nmUpdate
        running: false
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
        netSpeed.running = true
    }
}