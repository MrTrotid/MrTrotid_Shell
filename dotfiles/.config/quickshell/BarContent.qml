import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import Quickshell.Bluetooth

Item {
    id: root

    property var serviceContext

    property color colSurfaceContainer: "#1a2120"
    property color colSurfaceContainerHighest: "#303635"
    property color colOnSurface: "#dde4e2"
    property color colOnPrimary: "#003732"
    property color colPrimary: "#81d5ca"
    property color colTertiary: "#aec9e6"
    property color colError: "#ffb4ab"
    property color colColor3: "#578466"
    property color colColor4: "#2D8948"
    property color colSuccess: "#92d5ab"
    property color colBlue: "#96ccf8"
    property color colYellow: "#bccf81"
    property color colRed: "#ffb59f"
    property color colForeground: "#DDDCD0"

    // ── State ──
    property string currentTime: "00:00"
    property int brightnessPercent: 100
    property int maxBrightness: 100
    property int cpuPercent: 0
    property int memoryPercent: 0
    property var previousCpuStats: null
    property var mprisPlayer: (Mpris.mprisList && Mpris.mprisList.length > 0) ? Mpris.mprisList[0] : null

    readonly property var focusedWorkspaceId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool isCharging: batteryDevice ? (batteryDevice.state === UPowerDeviceState.Charging || batteryDevice.state === UPowerDeviceState.FullyCharged || batteryDevice.state === UPowerDeviceState.PendingCharge) : false

    property real batteryHealth: -1

    Process {
        command: ["sh", "-c", "for d in /sys/class/power_supply/BAT*; do if [ -f \"$d/energy_full_design\" ] && [ -f \"$d/energy_full\" ]; then ef=$(cat \"$d/energy_full\"); efd=$(cat \"$d/energy_full_design\"); elif [ -f \"$d/charge_full_design\" ] && [ -f \"$d/charge_full\" ]; then ef=$(cat \"$d/charge_full\"); efd=$(cat \"$d/charge_full_design\"); else continue; fi; if [ \"$efd\" -gt 0 ] 2>/dev/null; then int=$(( ef * 100 / efd )); dec=$(( (ef * 1000 / efd) % 10 )); echo \"$int.$dec\"; exit 0; fi; done; echo \"?\""]
        running: true
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

    readonly property string batteryTooltipText: {
        if (!batteryDevice || !batteryDevice.ready) return ""
        var health = root.batteryHealth > 0 ? root.batteryHealth.toFixed(1) + "%" : "?"
        var r = root.isCharging ? "Idle" : root.fmtTime(batteryDevice?.timeToEmpty ?? 0)
        return "Battery Health: " + health + "\nRemaining Time: " + r + "\nPower Plan: " + root.powerPlanLabel
    }
    onBatteryTooltipTextChanged: {
        if (serviceContext?.shellState?.batteryTooltipVisible)
            serviceContext.shellState.batteryTooltipText = batteryTooltipText
    }

    function fmtTime(seconds) {
        if (seconds <= 0) return "Idle"
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        return (h > 0 ? h + "h " : "") + m + "m"
    }

    readonly property string powerPlanLabel: {
        if (PowerProfiles.profile === PowerProfile.PowerSaver) return "Power Saver"
        if (PowerProfiles.profile === PowerProfile.Performance) return "Performance"
        return "Balanced"
    }
    property string activeWindowTitle: ""
    property int volumePercent: Math.min(150, Math.round(currentVolume * 100))
    property bool volumeMuted: false
    property real currentVolume: 0.5

    // ── Active window tracking ──
    Connections {
        target: Hyprland
        function onActiveToplevelChanged() { refreshActiveWindow.running = true }
        function onFocusedWorkspaceChanged() { refreshActiveWindow.running = true }
    }

    Process {
        id: refreshActiveWindow
        command: ["sh", "-c", "hyprctl activewindow -j 2>/dev/null || echo null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim()
                if (!out || out === "null") {
                    activeWindowTitle = ""
                } else {
                    try {
                        var json = JSON.parse(out)
                        activeWindowTitle = json.title ?? ""
                    } catch(e) {
                        activeWindowTitle = ""
                    }
                }
            }
        }
    }

    // ── Time Timer ──
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var d = new Date()
            var hh = String(d.getHours()).padStart(2, "0")
            var mm = String(d.getMinutes()).padStart(2, "0")
            currentTime = hh + ":" + mm + " "
        }
    }

    // ── Brightness ──
    Timer {
        id: brightRefresh
        interval: 150
        repeat: false
        onTriggered: {
            getBrightness.running = true
            getMaxBrightness.running = true
        }
    }

    // Independent brightness poll — catches changes from keybinds (exec brightnessctl)
    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: getBrightness.running = true
    }

    Process {
        id: getBrightness
        command: ["brightnessctl", "g"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(text.trim())
                if (!isNaN(val) && maxBrightness > 0)
                    brightnessPercent = Math.round(val / maxBrightness * 100)
            }
        }
    }

    Process {
        id: getMaxBrightness
        command: ["brightnessctl", "m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(text.trim())
                if (!isNaN(val)) maxBrightness = val
            }
        }
    }

    // ── Volume ──
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: getVolumeCmd.running = true
    }

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
                    currentVolume = parseFloat(match[1])
                    volumePercent = Math.min(150, Math.round(currentVolume * 100))
                }
                volumeMuted = line.includes("[MUTED]")
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

    // ── CPU / Memory via /proc ──
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            memInfo.reload()
            cpuStat.reload()
        }
    }

    FileView {
        id: memInfo
        path: "/proc/meminfo"
        onTextChanged: {
            var text = memInfo.text()
            var total = Number(text.match(/MemTotal:\s*(\d+)/)?.[1] ?? 1)
            var available = Number(text.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0)
            memoryPercent = Math.round((total - available) / total * 100)
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

            if (previousCpuStats) {
                var totalDiff = total - previousCpuStats.total
                var idleDiff = idle - previousCpuStats.idle
                if (totalDiff > 0)
                    cpuPercent = Math.round((1 - idleDiff / totalDiff) * 100)
            }

            previousCpuStats = { total: total, idle: idle }
        }
    }

    // ── Network status ──
    property bool networkConnected: false
    property string networkSsid: ""
    property int networkStrength: 0

    Process {
        id: nmMonitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: nmPoll.running = true
        }
    }

    Timer {
        id: nmPoll
        interval: 500
        repeat: false
        onTriggered: nmUpdate.running = true
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: nmUpdate.running = true
    }

    Process {
        id: nmUpdate
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SIGNAL,SSID device wifi list --rescan no | grep '^yes:' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (!line) {
                    networkConnected = false
                    return
                }
                var parts = line.split(":")
                if (parts.length >= 3 && parts[0] === "yes") {
                    networkConnected = true
                    networkStrength = parseInt(parts[1]) || 0
                    networkSsid = parts[2]
                } else {
                    networkConnected = false
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("BARCONTENT: my serviceContext:", !!serviceContext, "type:", typeof serviceContext)
        if (serviceContext) console.log("BARCONTENT: shellState thru SC:", !!serviceContext.shellState, "type:", typeof serviceContext.shellState, "bluetoothPanelOpen:", serviceContext.shellState?.bluetoothPanelOpen)
        nmUpdate.running = true
        getVolumeCmd.running = true
        getBrightness.running = true
        getMaxBrightness.running = true
        refreshActiveWindow.running = true
    }

    // ── LAYOUT ──

    // ── LEFT SECTION ──
    Row {
        id: leftSection
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0

        // Nix icon capsule
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: nixText.implicitWidth + 24
            height: 26
            radius: 20
            color: colSurfaceContainer

            Text {
                id: nixText
                anchors.centerIn: parent
                text: "󰣇"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 20
                color: colOnSurface
            }
        }

        Item { width: 5; height: 1 }

        // Clock capsule
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: clockText.implicitWidth + 24
            height: 26
            radius: 20
            color: clockMa.containsMouse ? Qt.lighter(colColor3, 1.1) : colColor3
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                id: clockText
                anchors.centerIn: parent
                text: currentTime
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.weight: Font.Bold
                color: colOnPrimary
            }

            MouseArea {
                id: clockMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: serviceContext?.toggleCalendarPopup()
            }
        }

        Item { width: 5; height: 1 }

        // Active window
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: activeWindowTitle
            color: colForeground
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            elide: Text.ElideRight
            visible: activeWindowTitle.length > 0
        }
    }

    // ── CENTER SECTION CAPSULE ──
    Rectangle {
        id: centerCapsule
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: centerRow.implicitWidth + 12
        height: 26
        radius: 20
        color: colSurfaceContainer

        Row {
            id: centerRow
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 2

            // Workspaces
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                padding: 2

                Repeater {
                    model: 6

                    Rectangle {
                        id: wsBtn
                        required property int index
                        property int wsId: index + 1
                        width: wsId === root.focusedWorkspaceId ? 50 : 20
                    height: 18
                        radius: 10
                        color: wsId === root.focusedWorkspaceId ? colColor4 : colSurfaceContainerHighest

                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

                        Text {
                            anchors.centerIn: parent
                            text: wsBtn.wsId
                            color: wsId === root.focusedWorkspaceId ? "#00201d" : colSurfaceContainerHighest
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            visible: wsId === root.focusedWorkspaceId
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("workspace " + wsBtn.wsId)
                        }
                    }
                }

                WheelHandler {
                    onWheel: (event) => {
                        if (event.angleDelta.y < 0)
                            Hyprland.dispatch("workspace r+1")
                        else
                            Hyprland.dispatch("workspace r-1")
                    }
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                }
            }

            // Backlight
            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: blText.implicitWidth
                implicitHeight: blText.implicitHeight

                Text {
                    id: blText
                    text: brightnessPercent + "% " + (brightnessPercent > 50 ? "" : "")
                    color: colOnSurface
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    padding: 6
                }

                WheelHandler {
                    onWheel: (event) => {
                        if (event.angleDelta.y < 0) decreaseBrightness()
                        else increaseBrightness()
                    }
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: increaseBrightness()
                }
            }

            // PulseAudio / Volume
            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: volText.implicitWidth + 20
                implicitHeight: parent.height

                Text {
                    id: volText
                    anchors.centerIn: parent
                    text: volumeMuted ? "" : volumePercent + "% " + (volumePercent > 50 ? "" : "")
                    color: volumeMuted ? colColor4 : colTertiary
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                }

                WheelHandler {
                    onWheel: (event) => {
                        if (event.angleDelta.y < 0)
                            currentVolume = Math.max(0, currentVolume - 0.05)
                        else
                            currentVolume = Math.min(1.5, currentVolume + 0.05)
                        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", currentVolume.toFixed(2)])
                        volRefresh.running = true
                    }
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                        volRefresh.running = true
                    }
                }
            }
        }
    }

    // ── RIGHT SECTION ──
    Row {
        id: rightSection
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 4

        // Right capsule
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: rightRow.implicitWidth + 24
            height: 26
            radius: 20
            color: colSurfaceContainer

            Row {
                id: rightRow
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                // CPU
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: cpuPercent + "%"
                        color: colOnSurface
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""
                        color: colOnSurface
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                }

                // Memory
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: memoryPercent + "%"
                        color: colOnSurface
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 1
                        text: "\uF0C9"
                        color: colOnSurface
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                }

                // System Tray (monochrome)
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    visible: SystemTray.items.values.length > 0

                    Repeater {
                        model: SystemTray.items.values

                        delegate: Item {
                            required property SystemTrayItem modelData
                            width: 18
                            height: 18
                            visible: {
                                var t = (modelData?.title ?? "").toLowerCase()
                                return t.indexOf("bluetooth") === -1 &&
                                       t.indexOf("blueman") === -1
                            }

                            Image {
                                id: trayIcon
                                anchors.fill: parent
                                source: modelData.icon
                                sourceSize.width: 18
                                sourceSize.height: 18
                                visible: false
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: trayIcon
                                colorization: 1.0
                                colorizationColor: colOnSurface
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.activate()
                            }
                        }
                    }
                }

                // Battery pill
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: serviceContext?.shellState?.batteryTooltipVisible ? batExpandedRow.implicitWidth + 16 : batRow.implicitWidth + 12
                    height: 18
                    radius: 6
                    color: {
                        if (!batteryDevice || !batteryDevice.ready) return "transparent"
                        var pct = batteryDevice.percentage * 100
                        if (pct <= 20) return colRed
                        if (pct <= 70) return colYellow
                        return colSuccess
                    }
                    visible: batteryDevice !== null && batteryDevice.ready
                    Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                    MouseArea {
                        id: batHover
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        propagateComposedEvents: true
                        onClicked: {
                            if (!serviceContext?.shellState) return
                            serviceContext.shellState.batteryTooltipText = root.batteryTooltipText
                            serviceContext.shellState.batteryTooltipVisible = !serviceContext.shellState.batteryTooltipVisible
                        }
                    }

                    // Collapsed view
                    Row {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: 4
                        visible: !serviceContext?.shellState?.batteryTooltipVisible
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 1
                            text: {
                                if (!batteryDevice || !batteryDevice.ready) return ""
                                var pct = batteryDevice.percentage * 100
                                return pct >= 80 ? "\uF240" :
                                       pct >= 60 ? "\uF241" :
                                       pct >= 40 ? "\uF242" :
                                       pct >= 20 ? "\uF243" : "\uF244"
                            }
                            color: colOnPrimary
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (!batteryDevice || !batteryDevice.ready) return ""
                                return Math.round(batteryDevice.percentage * 100) + "%"
                            }
                            color: colOnPrimary
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }

                    // Expanded view (single line)
                    Row {
                        id: batExpandedRow
                        anchors.centerIn: parent
                        spacing: 8
                        visible: serviceContext?.shellState?.batteryTooltipVisible
                        Repeater {
                            model: root.batteryTooltipText.split("\n")
                            Text {
                                required property string modelData
                                text: modelData
                                color: colOnPrimary
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                // Bluetooth
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Bluetooth.adapters.values.length > 0
                    text: Bluetooth.defaultAdapter?.enabled ? "" : ""
                    color: colPrimary
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("CLICK: Bluetooth icon clicked, shellState:", !!serviceContext?.shellState)
                            if (serviceContext?.shellState)
                                serviceContext.shellState.toggleBluetoothPanel()
                        }
                    }
                }

                // Network (WiFi)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: networkConnected ? "󰤨" : "󰤭"
                    color: networkConnected ? colError : colColor4
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (serviceContext?.shellState)
                                serviceContext.shellState.toggleWifiSelector()
                        }
                    }
                }

                // Notifications
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰂚"
                    color: colOnSurface
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (serviceContext?.shellState) {
                                serviceContext.shellState.barVisible = true
                                serviceContext.shellState.keepBarTemporarily()
                                serviceContext.shellState.toggleNotificationPanel()
                            }
                        }
                    }
                }
            }
        }
    }
}
