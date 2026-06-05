pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Item {
    id: root

    property int cpuPercent: 0
    property int memoryPercent: 0
    property var previousCpuStats: null

    // Poll every 2s — with running guard to prevent process leaks
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (!memInfo.running) memInfo.reload()
            if (!cpuStat.running) cpuStat.reload()
        }
    }

    FileView {
        id: memInfo
        path: "/proc/meminfo"
        onTextChanged: {
            var text = memInfo.text()
            var total = Number(text.match(/MemTotal:\s*(\d+)/)?.[1] ?? 1)
            var available = Number(text.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0)
            root.memoryPercent = Math.round((total - available) / total * 100)
        }
    }

    FileView {
        id: cpuStat
        path: "/proc/stat"
        onTextChanged: {
            var text = cpuStat.text()
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
