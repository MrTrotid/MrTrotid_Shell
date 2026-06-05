pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property int brightnessPercent: 100
    property int maxBrightness: 100

    // Debounce timer for immediate refresh after user action
    Timer {
        id: brightRefresh
        interval: 150
        repeat: false
        onTriggered: {
            getBrightness.running = true
            getMaxBrightness.running = true
        }
    }

    // Independent poll — catches changes from keybinds (exec brightnessctl externally)
    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: if (!getBrightness.running) getBrightness.running = true
    }

    Process {
        id: getBrightness
        command: ["brightnessctl", "g"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(text.trim())
                if (!isNaN(val) && root.maxBrightness > 0)
                    root.brightnessPercent = Math.round(val / root.maxBrightness * 100)
            }
        }
    }

    Process {
        id: getMaxBrightness
        command: ["brightnessctl", "m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(text.trim())
                if (!isNaN(val)) root.maxBrightness = val
            }
        }
    }

    function increaseBrightness() {
        Quickshell.execDetached(["brightnessctl", "s", "+5%"])
        brightRefresh.running = true
    }

    function decreaseBrightness() {
        Quickshell.execDetached(["brightnessctl", "s", "5%-"])
        brightRefresh.running = true
    }

    Component.onCompleted: {
        getBrightness.running = true
        getMaxBrightness.running = true
    }
}
