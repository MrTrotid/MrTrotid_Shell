import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import Quickshell.Bluetooth
import "widgets"

ShellRoot {
    id: root

    ServiceContext { id: ctx }

    // ── SINGLE PANEL WINDOW (fixed 400px height → no flicker) ──
    PanelWindow {
        id: main

        screen: Quickshell.screens[0]
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 36
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:bar"

        anchors.top: true
        anchors.left: true
        anchors.right: true

        margins.top: 10
        margins.left: 8
        margins.right: 8

        implicitHeight: 600

        // ── BAR ──
        BarContent {
            id: barContent
            serviceContext: ctx
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 36
        }

        // ── BLUETOOTH POPUP ──
        Item {
            id: bl
            visible: ctx?.bluetoothPanelOpen ?? false
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: barContent.bottom
            anchors.topMargin: 4
            width: parent.width * 0.4
            implicitHeight: Math.max(300, 500)

            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            BluetoothSelector {
                anchors.fill: parent
                serviceContext: ctx
            }
        }

        // ── WIFI SELECTOR POPUP ──
        Item {
            id: wifiSel
            visible: ctx?.wifiSelectorOpen ?? false
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: barContent.bottom
            anchors.topMargin: 4
            width: parent.width * 0.4
            implicitHeight: Math.max(300, 500)

            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            WifiSelector {
                anchors.fill: parent
                serviceContext: ctx
            }
        }

        // ── QUICK SETTINGS POPUP ──
        Item {
            id: qs
            visible: ctx?.quickSettingsOpen ?? false
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: barContent.bottom
            anchors.topMargin: 4
            width: 340
            implicitHeight: Math.max(180, qsCol.implicitHeight + 20)

            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            property color _surf: "#1a2120"
            property color _surfVar: "#303635"
            property color _onSurf: "#dde4e2"
            property color _prim: "#81d5ca"
            property color _onPrim: "#003732"
            property color _tert: "#aec9e6"
            property color _err: "#ffb4ab"
            property color _outline: "#606866"
            property color _bri: "#578466"
            property color _suc: "#92d5ab"
            property int _briPct: 100
            property int _maxBri: 100
            property bool _audMute: false
            property int _audVol: 50

            Timer { id: briRef; interval: 150; repeat: false; onTriggered: { gb.running = true; gmb.running = true } }
            Timer { interval: 2000; running: true; repeat: true; onTriggered: ap.running = true }

            Process { id: gb; command: ["brightnessctl", "g"]; stdout: StdioCollector { onStreamFinished: { var v = parseInt(text.trim()); if (!isNaN(v) && qs._maxBri > 0) qs._briPct = Math.round(v / qs._maxBri * 100) } } }
            Process { id: gmb; command: ["brightnessctl", "m"]; stdout: StdioCollector { onStreamFinished: { var v = parseInt(text.trim()); if (!isNaN(v)) qs._maxBri = v } } }
            Process { id: ap; command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]; stdout: StdioCollector { onStreamFinished: { var l = text.trim(); var m = l.match(/Volume:\s*(\d+\.\d+)/); if (m) qs._audVol = Math.round(Math.min(1.5, parseFloat(m[1])) * 100); qs._audMute = l.includes("[MUTED]") } } }
            function incBri() { Quickshell.execDetached(["brightnessctl", "s", "+5%"]); briRef.running = true }
            function decBri() { Quickshell.execDetached(["brightnessctl", "s", "5%-"]); briRef.running = true }

            Rectangle {
                anchors.fill: parent; radius: 12; color: qs._surf; border.color: qs._surfVar; border.width: 1
                ColumnLayout {
                    id: qsCol; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 10; spacing: 10
                    Text { text: "Quick Settings"; color: qs._onSurf; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.weight: Font.Bold }
                    Rectangle { Layout.fillWidth: true; height: 1; color: qs._surfVar }

                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 48; radius: 8; color: qs._surfVar
                        RowLayout { anchors.fill: parent; anchors.margins: 10; spacing: 10
                            Text { text: qs._briPct > 50 ? "" : ""; color: qs._bri; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                            Item { Layout.fillWidth: true; height: 1 }
                            Text { text: qs._briPct + "%"; color: qs._onSurf; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                        }
                        WheelHandler { onWheel: (e) => { if (e.angleDelta.y < 0) decBri(); else incBri() }; acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: incBri() }
                    }

                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 48; radius: 8; color: qs._surfVar
                        RowLayout { anchors.fill: parent; anchors.margins: 10; spacing: 10
                            Text { text: qs._audMute ? "" : (qs._audVol > 50 ? "" : ""); color: qs._audMute ? qs._err : qs._tert; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                            Item { Layout.fillWidth: true; height: 1 }
                            Text { text: qs._audVol + "%"; color: qs._onSurf; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                        }
                        WheelHandler { onWheel: (e) => { if (e.angleDelta.y < 0) Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]); else Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]); ap.running = true }; acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]) }
                    }

                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: grid.implicitHeight + 10; radius: 8; color: qs._surfVar
                        Grid { id: grid; anchors.centerIn: parent; columns: 4; spacing: 6
                            Repeater {
                                model: [{ icon: "", label: "WiFi", active: true }, { icon: "", label: "BT", active: Bluetooth.defaultAdapter?.enabled ?? false }, { icon: "󰂛", label: "DND", active: false }, { icon: "󰛨", label: "Dark", active: false }]
                                delegate: Rectangle {
                                    required property var modelData
                                    width: 64; height: 64; radius: 8
                                    color: modelData.active ? qs._prim : "transparent"
                                    border.color: qs._outline; border.width: modelData.active ? 0 : 1
                                    ColumnLayout { anchors.centerIn: parent; spacing: 4
                                        Text { text: modelData.icon; color: modelData.active ? qs._onPrim : qs._onSurf; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; Layout.alignment: Qt.AlignHCenter }
                                        Text { text: modelData.label; color: modelData.active ? qs._onPrim : qs._outline; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── BATTERY TOOLTIP ──
        Item {
            id: tt
            visible: ctx?.batteryTooltipVisible ?? false
            anchors.right: parent.right
            anchors.rightMargin: 120
            anchors.top: barContent.bottom
            anchors.topMargin: 4
            width: 180
            implicitHeight: 72

            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 100 } }

            Rectangle {
                anchors.fill: parent; radius: 8
                color: "#1a2120"; border.color: "#303635"; border.width: 1
                Column {
                    anchors.centerIn: parent; anchors.margins: 8; spacing: 4
                    Repeater {
                        model: ctx?.batteryTooltipText?.split("\n") ?? []
                        delegate: Text {
                            required property string modelData
                            text: modelData; color: "#dde4e2"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                        }
                    }
                }
            }
        }

        // ── Auto-hide ──
        property bool cursorNearTop: false

        Timer {
            interval: 100; running: true; repeat: true
            onTriggered: {
                if (!ctx?.shellState) return
                var y = Hyprland.cursor?.pos?.y ?? -1
                if (y <= 2) {
                    if (!main.cursorNearTop) { main.cursorNearTop = true; ctx.barVisible = true }
                    hideTimer.stop()
                } else if (y > 50 && main.cursorNearTop && !ctx.keepBarVisible) {
                    main.cursorNearTop = false; hideTimer.running = true
                }
            }
        }

        Timer { id: hideTimer; interval: 1500; repeat: false; onTriggered: { if (!main.cursorNearTop && ctx?.shellState) ctx.barVisible = false } }

        // ── Calendar/Weather/Time Popup ──
        Item {
            id: calPopup
            visible: ctx?.calendarPopupOpen ?? false
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: barContent.bottom
            anchors.topMargin: 4
            width: parent.width * 0.70 + 20
            implicitHeight: 500

            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            CalendarPopup {
                id: calPopupInner
                anchors.fill: parent
            }

            onVisibleChanged: {
                if (visible) calPopupInner.show()
            }
        }
    }

    // ── Media Card ──
    Window {
        id: mediaCard
        visible: ctx?.mediaCardOpen ?? false
        color: "transparent"
        width: 320; height: 200
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowTransparentForInput
        x: 0; y: 0
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
        MediaCard { serviceContext: ctx; anchors.fill: parent; anchors.margins: 4 }
    }

    // ── Keybinds ──
    Shortcut { sequence: "Super+O"; onActivated: ctx?.toggleBar() }
    Shortcut { sequence: "Super+M"; onActivated: ctx?.toggleMediaCard() }
    Shortcut { sequence: "Super+N"; onActivated: ctx?.toggleWifiSelector() }
    Shortcut { sequence: "Super+B"; onActivated: ctx?.toggleBluetoothPanel() }
}
