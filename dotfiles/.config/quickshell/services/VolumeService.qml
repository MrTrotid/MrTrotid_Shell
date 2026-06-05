pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property real currentVolume: 0.5
    property int volumePercent: Math.min(150, Math.round(currentVolume * 100))
    property bool volumeMuted: false

    // Poll — catches changes from keybinds (exec wpctl externally)
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: if (!getVolumeCmd.running) getVolumeCmd.running = true
    }

    // Debounce timer for immediate refresh after user action
    Timer {
        id: volRefresh
        interval: 150
        repeat: false
        onTriggered: getVolumeCmd.running = true
    }

    Process {
        id: getVolumeCmd
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                var match = line.match(/Volume:\s*(\d+\.\d+)/)
                if (match) {
                    root.currentVolume = parseFloat(match[1])
                    root.volumePercent = Math.min(150, Math.round(root.currentVolume * 100))
                }
                root.volumeMuted = line.includes("[MUTED]")
            }
        }
    }

    function increaseVolume() {
        currentVolume = Math.min(1.5, currentVolume + 0.05)
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", currentVolume.toFixed(2)])
        volRefresh.running = true
    }

    function decreaseVolume() {
        currentVolume = Math.max(0, currentVolume - 0.05)
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", currentVolume.toFixed(2)])
        volRefresh.running = true
    }

    function toggleMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        volRefresh.running = true
    }

    Component.onCompleted: {
        getVolumeCmd.running = true
    }
}
