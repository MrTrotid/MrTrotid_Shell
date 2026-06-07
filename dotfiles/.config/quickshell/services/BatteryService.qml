pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Item {
    id: root

    property var batteryDevice: UPower.displayDevice
    readonly property bool hasBattery: batteryDevice !== null
    readonly property bool isCharging: hasBattery ? (batteryDevice.state === UPowerDeviceState.Charging || batteryDevice.state === UPowerDeviceState.FullyCharged || batteryDevice.state === UPowerDeviceState.PendingCharge) : false
    readonly property int batteryPercent: hasBattery ? Math.round(batteryDevice.percentage * 100) : 0

    property int warnThreshold: 20
    property int _prevBatteryPercent: -1

    onBatteryPercentChanged: {
        if (!hasBattery || isCharging) { _prevBatteryPercent = batteryPercent; return }
        if (_prevBatteryPercent >= 0 && _prevBatteryPercent > warnThreshold && batteryPercent <= warnThreshold) {
            NotificationService.addNotification("Battery", "Low Battery", batteryPercent + "% remaining — plug in power", "critical")
        }
        _prevBatteryPercent = batteryPercent
    }

    property real batteryHealth: -1

    readonly property string batteryTooltipText: {
        if (!hasBattery || !batteryDevice.ready) return ""
        var health = root.batteryHealth > 0 ? root.batteryHealth.toFixed(1) + "%" : "?"
        var r = root.isCharging ? "Idle" : root.fmtTime(batteryDevice?.timeToEmpty ?? 0)
        return "Battery Health: " + health + "\nRemaining Time: " + r
    }

    function fmtTime(seconds) {
        if (seconds <= 0) return "Idle"
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        return (h > 0 ? h + "h " : "") + m + "m"
    }

    // Read battery health from sysfs (refreshes every hour)
    Process {
        id: healthProc
        command: ["sh", "-c", "for d in /sys/class/power_supply/BAT*; do if [ -f \"$d/energy_full_design\" ] && [ -f \"$d/energy_full\" ]; then ef=$(cat \"$d/energy_full\"); efd=$(cat \"$d/energy_full_design\"); elif [ -f \"$d/charge_full_design\" ] && [ -f \"$d/charge_full\" ]; then ef=$(cat \"$d/charge_full\"); efd=$(cat \"$d/charge_full_design\"); else continue; fi; if [ \"$efd\" -gt 0 ] 2>/dev/null; then int=$(( ef * 100 / efd )); dec=$(( (ef * 1000 / efd) % 10 )); echo \"$int.$dec\"; exit 0; fi; done; echo \"?\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var v = text.trim()
                if (v !== "?" && v !== "") {
                    root.batteryHealth = parseFloat(v)
                } else {
                    root.batteryHealth = -1
                }
            }
        }
    }

    Timer {
        interval: 3600000 // 1 hour
        repeat: true
        running: root.hasBattery
        triggeredOnStart: true
        onTriggered: if (!healthProc.running) healthProc.running = true
    }
}
