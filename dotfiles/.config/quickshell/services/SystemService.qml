pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Item {
    id: root

    property int cpuPercent: 0
    property int cpuTemp: 0
    property int memoryPercent: 0
    property var previousCpuStats: null

    // Poll every 2s — with running guard to prevent process leaks
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (!memInfo.running) memInfo.running = true
            if (!cpuStat.running) cpuStat.running = true
            if (!tempRead.running) tempRead.running = true
        }
    }

    Process {
        id: tempRead
        command: ["sh", "-c", "for f in /sys/class/hwmon/hwmon*/temp1_input; do d=$(dirname $f); [ \"$(cat $d/name 2>/dev/null)\" = \"coretemp\" ] && cat $f && break; done"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(text.trim())
                if (!isNaN(val)) root.cpuTemp = Math.round(val / 1000)
            }
        }
    }

    Process {
        id: memInfo
        command: ["cat", "/proc/meminfo"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var total = Number(text.match(/MemTotal:\s*(\d+)/)?.[1] ?? 1)
                var available = Number(text.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0)
                root.memoryPercent = Math.round((total - available) / total * 100)
            }
        }
    }

    Process {
        id: cpuStat
        command: ["cat", "/proc/stat"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
                if (!match) return

                var user = parseInt(match[1])
                var nice = parseInt(match[2])
                var system = parseInt(match[3])
                var idle = parseInt(match[4])
                var total = user + nice + system + idle

                if (root.previousCpuStats) {
                    var totalDiff = total - root.previousCpuStats.total
                    var idleDiff = idle - root.previousCpuStats.idle
                    if (totalDiff > 0)
                        root.cpuPercent = Math.round((1 - idleDiff / totalDiff) * 100)
                }

                root.previousCpuStats = { total: total, idle: idle }
            }
        }
    }

    Component.onCompleted: {
        memInfo.running = true
        cpuStat.running = true
        tempRead.running = true
    }
}
