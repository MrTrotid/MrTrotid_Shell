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

    // ── Colors ──
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

    // ── Local state (UI only) ──
    property string currentTime: "00:00"
    property string activeWindowTitle: ""
    property var mprisPlayer: (Mpris.mprisList && Mpris.mprisList.length > 0) ? Mpris.mprisList[0] : null
    readonly property var focusedWorkspaceId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1

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

    // ── Time ──
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var d = new Date()
            var hh = String(d.getHours()).padStart(2, "0")
            var mm = String(d.getMinutes()).padStart(2, "0")
            currentTime = hh + ":" + mm + " "
        }
    }

    Component.onCompleted: {
        refreshActiveWindow.running = true
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
                        text: ""
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
                    height: 18
                    radius: 6
                    color: {
                        if (!BatteryService.hasBattery || !BatteryService.batteryDevice.ready) return "transparent"
                        var pct = BatteryService.batteryPercent
                        if (pct <= 20) return colRed
                        if (pct <= 70) return colYellow
                        return colSuccess
                    }
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

                // Network (WiFi)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: NetworkService.networkConnected ? "󰤨" : "󰤭"
                    color: NetworkService.networkConnected ? colError : colColor4
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.toggleWifiSelector()
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
