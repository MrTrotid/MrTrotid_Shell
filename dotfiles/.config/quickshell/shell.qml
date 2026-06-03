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
            width: 320
            implicitHeight: Math.max(200, blCol.implicitHeight + 20)

            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            property color _surf: "#1a2120"
            property color _surfVar: "#303635"
            property color _onSurf: "#dde4e2"
            property color _prim: "#81d5ca"
            property color _onPrim: "#003732"
            property color _outline: "#606866"
            property color _suc: "#92d5ab"
            property color _err: "#ffb4ab"
            property var _adapter: Bluetooth.defaultAdapter
            property bool _scanning: _adapter?.discovering ?? false

            function toggleScan() {
                if (!_adapter) return
                _adapter.discovering = !_adapter.discovering
            }

            Rectangle {
                anchors.fill: parent; radius: 12
                color: bl._surf; border.color: bl._surfVar; border.width: 1

                ColumnLayout {
                    id: blCol
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                    anchors.margins: 10; spacing: 6

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Text { text: ""; color: bl._prim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                        Text { text: "Bluetooth"; color: bl._onSurf; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.weight: Font.Bold; Layout.fillWidth: true }

                        Rectangle {
                            id: blTog; width: 44; height: 24; radius: 12
                            color: (bl._adapter?.enabled ?? false) ? bl._prim : bl._outline
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Rectangle { width: 20; height: 20; radius: 10; color: "#ffffff"; x: (bl._adapter?.enabled ?? false) ? blTog.width - width - 2 : 2; y: 2; Behavior on x { NumberAnimation { duration: 150 } } }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (bl._adapter) bl._adapter.enabled = !bl._adapter.enabled } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Text { text: bl._adapter?.name ?? "No Adapter"; color: bl._onSurf; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                        Item { Layout.fillWidth: true }
                        Text { text: (bl._adapter?.enabled ?? false) ? "Enabled" : "Disabled"; color: (bl._adapter?.enabled ?? false) ? bl._suc : bl._err; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: bl._surfVar }

                    Text {
                        text: "Paired Devices"; color: bl._prim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold
                        visible: { if (!(bl._adapter?.enabled ?? false)) return false; var all = bl._adapter?.devices?.values ?? []; return all.some(function(d) { return d.paired }) }
                        Layout.topMargin: 2
                    }

                    Repeater {
                        model: { if (!(bl._adapter?.enabled ?? false)) return []; var all = bl._adapter?.devices?.values ?? []; return all.filter(function(d) { return d.paired }) }
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; implicitHeight: 36; radius: 8
                            color: modelData.connected ? Qt.rgba(129/255, 213/255, 202/255, 0.12) : "transparent"
                            border.color: modelData.connected ? bl._prim : bl._surfVar; border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 8; spacing: 8
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: modelData.name || modelData.address; color: bl._onSurf; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: modelData.connected ? Font.Bold : Font.Normal; elide: Text.ElideRight }
                                    Text { text: modelData.connected ? "Connected" : "Disconnected"; color: modelData.connected ? bl._suc : bl._outline; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                                }
                                Text { text: modelData.connected ? "" : ""; color: modelData.connected ? bl._prim : bl._outline; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.connected) modelData.disconnect(); else modelData.connect() } }
                        }
                    }

                    Text {
                        text: "Available Devices"; color: bl._outline; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                        visible: { if (!(bl._adapter?.enabled ?? false)) return false; var all = bl._adapter?.devices?.values ?? []; return all.some(function(d) { return !d.paired }) }
                    }

                    Repeater {
                        model: { if (!(bl._adapter?.enabled ?? false)) return []; var all = bl._adapter?.devices?.values ?? []; return all.filter(function(d) { return !d.paired }) }
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; implicitHeight: 36; radius: 8
                            color: "transparent"; border.color: bl._surfVar; border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 8; spacing: 8
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: modelData.name || modelData.address; color: bl._onSurf; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; elide: Text.ElideRight }
                                    Text { text: "Available"; color: bl._outline; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                                }
                                Text { text: ""; color: bl._prim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (!modelData.paired) modelData.connect() } }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 36; radius: 8
                        color: bl._scanning ? bl._prim : bl._surfVar
                        Behavior on color { ColorAnimation { duration: 150 } }
                        RowLayout { anchors.centerIn: parent; spacing: 8
                            Text { text: bl._scanning ? "" : ""; color: bl._scanning ? bl._onPrim : bl._onSurf; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            Text { text: bl._scanning ? "Scanning..." : "Scan for Devices"; color: bl._scanning ? bl._onPrim : bl._onSurf; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bl.toggleScan() }
                    }

                    Text {
                        Layout.fillWidth: true; Layout.preferredHeight: 36
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        text: !(bl._adapter?.enabled ?? false) ? "  Bluetooth is turned off" : "  No devices found"
                        color: bl._outline; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                        visible: { if (!(bl._adapter?.enabled ?? false)) return true; return (bl._adapter?.devices?.values?.length ?? 0) === 0 }
                    }
                }
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
    Shortcut { sequence: "Super+N"; onActivated: ctx?.toggleQuickSettings() }
    Shortcut { sequence: "Super+B"; onActivated: ctx?.toggleBluetoothPanel() }
}
