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
import "services"

Item {
    id: root

    // ── Colors (bound to matugen via ColorService) ──
    property color colSurfaceContainer: ColorService.surfaceContainer
    property color colSurfaceContainerHighest: ColorService.surfaceContainerHighest
    property color colOnSurface: ColorService.surfaceText
    property color colOnPrimary: ColorService.primaryText
    property color colPrimary: ColorService.primary
    property color colTertiary: ColorService.tertiary
    property color colError: ColorService.error
    property color colColor3: ColorService.outline
    property color colColor4: ColorService.primaryContainer
    property color colSuccess: ColorService.success
    property color colBlue: ColorService.blue
    property color colYellow: ColorService.yellow
    property color colRed: ColorService.red
    property color colForeground: ColorService.surfaceText

    // ── Local state (UI only) ──
    property string currentTime: "00:00"
    property var mprisPlayer: (Mpris.mprisList && Mpris.mprisList.length > 0) ? Mpris.mprisList[0] : null
    readonly property var focusedWorkspaceId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1

    // ── Time ──
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var d = new Date()
            var hh = String(d.getHours()).padStart(2, "0")
            var mm = String(d.getMinutes()).padStart(2, "0")
            currentTime = hh + ":" + mm
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  LAYOUT
    // ═══════════════════════════════════════════════════════════════

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
                onClicked: ShellState.toggleCalendarPopup()
            }
        }

        Item { width: 5; height: 1 }

        // Active window
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(winTitle.implicitWidth + 16, 416)
            height: 26
            radius: 20
            color: colSurfaceContainer
            visible: winTitle.text.length > 0

            Text {
                id: winTitle
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.displayTitle
                color: colOnSurface
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                elide: Text.ElideRight
                width: 400
                maximumLineCount: 1
            }
        }
    }

    property string displayTitle: ""

    function updateDisplayTitle() {
        var toplevel = Hyprland.activeToplevel
        if (!toplevel || !toplevel.activated) {
            root.displayTitle = ""
            return
        }
        var ws = toplevel.workspace
        var focused = Hyprland.focusedMonitor?.activeWorkspace?.id
        if (!ws || ws.id !== focused) {
            root.displayTitle = ""
            return
        }
        root.displayTitle = toplevel.title ?? ""
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            root.updateDisplayTitle()
        }
        function onActiveToplevelChanged() {
            root.updateDisplayTitle()
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
                            color: wsId === root.focusedWorkspaceId ? colOnPrimary : colSurfaceContainerHighest
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
                    text: BrightnessService.brightnessPercent + "% " + (BrightnessService.brightnessPercent > 50 ? "\uF185" : "\uF186")
                    color: colOnSurface
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    padding: 6
                }

                WheelHandler {
                    onWheel: (event) => {
                        if (event.angleDelta.y < 0) BrightnessService.decreaseBrightness()
                        else BrightnessService.increaseBrightness()
                    }
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BrightnessService.increaseBrightness()
                }
            }

            // Volume + Sink switching
            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: volRow.implicitWidth + 20
                implicitHeight: parent.height

                Row {
                    id: volRow
                    anchors.centerIn: parent
                    spacing: 8

                    // Volume text
                    Text {
                        id: volText
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            var vol = VolumeService.volumeMuted ? "MUTE" : VolumeService.volumePercent + "%"
                            if (volMouseArea.containsMouse && AudioService.defaultSinkName)
                                return vol + "  " + AudioService.defaultSinkName
                            return vol
                        }
                        color: VolumeService.volumeMuted ? colColor4 : colTertiary
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }

                    // Sink icon
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: AudioService.sinkIcon(AudioService.defaultSinkName)
                        color: colOnSurface
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                WheelHandler {
                    onWheel: (event) => {
                        if (event.angleDelta.y < 0) VolumeService.decreaseVolume()
                        else VolumeService.increaseVolume()
                    }
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                }

                MouseArea {
                    id: volMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        var sinks = AudioService.sinks
                        if (sinks.length <= 1) return
                        var currentIdx = -1
                        for (var i = 0; i < sinks.length; i++) {
                            if (sinks[i].isDefault) { currentIdx = i; break }
                        }
                        var nextIdx = (currentIdx + 1) % sinks.length
                        AudioService.setDefaultSink(sinks[nextIdx].id)
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
                        text: SystemService.cpuPercent + "%"
                        color: colOnSurface
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uF2DB"
                        color: colOnSurface
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                }

                // CPU Temperature
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    visible: SystemService.cpuTemp > 0
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: SystemService.cpuTemp + "°"
                        color: SystemService.cpuTemp >= 80 ? colError : SystemService.cpuTemp >= 65 ? colTertiary : colOnSurface
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uF0E4"
                        color: SystemService.cpuTemp >= 80 ? colError : SystemService.cpuTemp >= 65 ? colTertiary : colOnSurface
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
                        text: SystemService.memoryPercent + "%"
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
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.RightButton) {
                                        if (modelData.hasMenu) {
                                            modelData.display(trayMenuWindow, mouse.x, mouse.y)
                                        } else {
                                            modelData.secondaryActivate()
                                        }
                                    } else {
                                        modelData.activate()
                                    }
                                }
                            }
                        }
                    }
                }

                // Battery pill
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: ShellState.batteryTooltipVisible ? batExpandedRow.implicitWidth + 16 : batRow.implicitWidth + 12
                    height: 16
                    radius: 5
                    property color batColor: {
                        if (!BatteryService.hasBattery || !BatteryService.batteryDevice.ready) return "transparent"
                        if (BatteryService.isCharging) return "#7dd3fc"
                        var pct = BatteryService.batteryPercent
                        if (pct >= 60) return "#4ade80"
                        if (pct >= 30) return "#facc15"
                        return "#f87171"
                    }
                    color: batColor
                    visible: BatteryService.hasBattery && BatteryService.batteryDevice.ready
                    Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                    MouseArea {
                        id: batHover
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        propagateComposedEvents: true
                        onClicked: {
                            ShellState.batteryTooltipText = BatteryService.batteryTooltipText
                            ShellState.batteryTooltipVisible = !ShellState.batteryTooltipVisible
                        }
                    }

                    // Collapsed view
                    Row {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: 4
                        visible: !ShellState.batteryTooltipVisible
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 1
                            text: {
                                if (!BatteryService.hasBattery || !BatteryService.batteryDevice.ready) return ""
                                var pct = BatteryService.batteryPercent
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
                            text: BatteryService.hasBattery ? BatteryService.batteryPercent + "%" : ""
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
                        visible: ShellState.batteryTooltipVisible
                        Repeater {
                            model: BatteryService.batteryTooltipText.split("\n")
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

                // Mic indicator
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: true
                    text: AudioService.micMuted ? "\uF131" : "\uF130"
                    color: AudioService.micMuted ? colError : colPrimary
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed: function(mouse) {
                            if (mouse.button === Qt.LeftButton) {
                                var wasMuted = AudioService.micMuted
                                AudioService.toggleMicMute()
                                // toggleMicMute is async (200ms poll), so OSD shows what it's BECOMING
                                osdContent.triggerMic(
                                    wasMuted ? "\uF130" : "\uF131",
                                    wasMuted ? "Unmuted" : "Muted"
                                )
                            } else if (mouse.button === Qt.RightButton) {
                                var name = AudioService.cycleMicSource()
                                if (name) {
                                    osdContent.triggerMic("\uF130", name)
                                }
                            }
                        }
                    }
                }

                // Bluetooth
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Bluetooth.adapters.values.length > 0
                    text: Bluetooth.defaultAdapter?.enabled ? "\uF293" : "\uF294"
                    color: colPrimary
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.toggleBluetoothPanel()
                    }
                }

                // Network (WiFi) + Speed
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: -2
                        visible: NetworkService.networkConnected

                        property string downText: {
                            if (NetworkService.netDown >= 1024) return "↓" + (NetworkService.netDown / 1024).toFixed(1) + "M"
                            return "↓" + NetworkService.netDown + "K"
                        }
                        property string upText: {
                            if (NetworkService.netUp >= 1024) return "↑" + (NetworkService.netUp / 1024).toFixed(1) + "M"
                            return "↑" + NetworkService.netUp + "K"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.downText
                            color: NetworkService.netDown > 0 ? colPrimary : colTertiary
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.upText
                            color: NetworkService.netUp > 0 ? colTertiary : colTertiary
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: NetworkService.networkConnected ? "󰤨" : "󰤭"
                        color: colPrimary
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellState.toggleWifiSelector()
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
                            ShellState.barVisible = true
                            ShellState.keepBarTemporarily()
                            ShellState.toggleNotificationPanel()
                        }
                    }
                }
            }
        }
    }
}
