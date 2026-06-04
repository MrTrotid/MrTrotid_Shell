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

            BluetoothSelector {
                id: blInner
                anchors.fill: parent
                serviceContext: ctx
            }

            onVisibleChanged: {
                if (visible) blInner.show()
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

            WifiSelector {
                id: wifiSelInner
                anchors.fill: parent
                serviceContext: ctx
            }

            onVisibleChanged: {
                if (visible) wifiSelInner.show()
            }
        }

        // ── NOTIFICATION PANEL ──
        Item {
            id: notifPanel
            visible: ctx?.notificationPanelOpen ?? false
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: barContent.bottom
            anchors.topMargin: 4
            width: 360
            implicitHeight: Math.max(400, 590)

            NotificationPanel {
                id: notifPanelInner
                anchors.fill: parent
            }

            onVisibleChanged: {
                if (visible) notifPanelInner.show()
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
