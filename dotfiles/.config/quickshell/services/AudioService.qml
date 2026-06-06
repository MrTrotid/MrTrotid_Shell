pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string defaultSinkName: ""
    property int defaultSinkId: -1
    property var sinks: []

    property var _prevSinkIds: []
    property int _fallbackSinkId: -1

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: if (!statusProc.running) statusProc.running = true
    }

    Process {
        id: statusProc
        command: ["wpctl", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                var result = []
                var currentIds = []

                // Find the Sinks section under Audio
                // Strategy: look for "Sinks:" and parse lines after it until we hit another section header
                var inSinksSection = false
                var inAudioSection = false

                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]

                    // Detect Audio/Video/Settings section boundaries
                    var trimmed = line.trim()
                    if (trimmed === "Audio" || trimmed === "Video" || trimmed === "Settings") {
                        inAudioSection = (trimmed === "Audio")
                        inSinksSection = false
                        continue
                    }

                    // Detect Sinks header (only in Audio section)
                    if (inAudioSection && trimmed.indexOf("Sinks:") !== -1) {
                        inSinksSection = true
                        continue
                    }

                    // If we're in sinks section, look for sink entries
                    if (inSinksSection) {
                        // Check if we've hit another subsection (Sources, Filters, Streams)
                        if (trimmed.indexOf("Sources:") !== -1 ||
                            trimmed.indexOf("Filters:") !== -1 ||
                            trimmed.indexOf("Streams:") !== -1) {
                            inSinksSection = false
                            continue
                        }

                        // Skip tree drawing chars, extract meaningful content
                        // Match patterns like: " *  43. Built-in Audio Analog Stereo  [vol: 1.00]"
                        // Or without volume: " *  43. Built-in Audio Analog Stereo"
                        // The line may have ├─ or └─ or spaces before the content
                        var content = line.replace(/^[\s\u2502\u251c\u2514\u2500]*/g, "").trim()
                        if (content.length === 0) continue

                        // Match sink entry: optional *, then ID. description [vol: X.XX]
                        var match = content.match(/^([*]?)\s*(\d+)\.\s+(.+?)(?:\s+\[vol:\s*([\d.]+)\])?\s*$/)
                        if (match) {
                            var sinkId = parseInt(match[2])
                            var sinkDesc = match[3].trim()
                            var sinkVol = match[4] ? parseFloat(match[4]) : -1
                            var isDefault = match[1] === "*"

                            result.push({
                                id: sinkId,
                                name: sinkDesc,
                                description: sinkDesc,
                                isDefault: isDefault,
                                volume: sinkVol
                            })

                            currentIds.push(sinkId)

                            if (isDefault) {
                                root.defaultSinkId = sinkId
                                root.defaultSinkName = sinkDesc
                                if (!isBluetoothSink(sinkDesc)) {
                                    root._fallbackSinkId = sinkId
                                }
                            }
                        }
                    }
                }

                // Detect newly connected bluetooth sinks
                if (root._prevSinkIds.length > 0) {
                    var newIds = []
                    for (var j = 0; j < currentIds.length; j++) {
                        if (root._prevSinkIds.indexOf(currentIds[j]) === -1) {
                            newIds.push(currentIds[j])
                        }
                    }

                    // Auto-switch to newest bluetooth sink
                    if (newIds.length > 0) {
                        for (var k = 0; k < result.length; k++) {
                            if (newIds.indexOf(result[k].id) !== -1 && isBluetoothSink(result[k].name)) {
                                root.setDefaultSink(result[k].id)
                                break
                            }
                        }
                    }

                    // Revert if current default disappeared
                    if (currentIds.length > 0 && currentIds.indexOf(root.defaultSinkId) === -1 && root._fallbackSinkId !== -1) {
                        if (currentIds.indexOf(root._fallbackSinkId) !== -1) {
                            root.setDefaultSink(root._fallbackSinkId)
                        }
                    }
                }

                root._prevSinkIds = currentIds
                root.sinks = result
            }
        }
    }

    function setDefaultSink(sinkId) {
        Quickshell.execDetached(["wpctl", "set-default", sinkId.toString()])
        defaultSwitchTimer.running = true
    }

    Timer {
        id: defaultSwitchTimer
        interval: 300
        repeat: false
        onTriggered: statusProc.running = true
    }

    function isBluetoothSink(name) {
        var n = name.toLowerCase()
        return n.indexOf("bluetooth") !== -1 || n.indexOf("a2dp") !== -1 || n.indexOf("bluez") !== -1
    }

    function sinkName(sinkId) {
        for (var i = 0; i < sinks.length; i++) {
            if (sinks[i].id === sinkId) return sinks[i].name
        }
        return "Unknown"
    }

    function sinkIcon(sinkName) {
        var name = sinkName.toLowerCase()
        if (name.indexOf("headphone") !== -1 || name.indexOf("headset") !== -1 || name.indexOf("earphone") !== -1 || name.indexOf("earbud") !== -1 || name.indexOf("soundcore") !== -1)
            return "\uF025"
        if (name.indexOf("bluetooth") !== -1 || name.indexOf("a2dp") !== -1 || name.indexOf("bluez") !== -1)
            return "\uF293"
        if (name.indexOf("hdmi") !== -1 || name.indexOf("displayport") !== -1)
            return "\uF03D"
        if (name.indexOf("usb") !== -1)
            return "\uF025"
        return "\uF028"
    }

    Component.onCompleted: {
        statusProc.running = true
    }
}
