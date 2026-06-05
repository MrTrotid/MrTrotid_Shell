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
import "services"

ShellRoot {
    id: root

    readonly property real barTopMargin: 10
    readonly property real barHeight: 36
    readonly property real barGap: 4
    readonly property real popupGap: 2
    readonly property real sideMargin: 8
    readonly property real sw: Quickshell.screens[0]?.width ?? 1920

    // ═══════════════════════════════════════════════════════════════
    //  BAR (own layer shell surface, exclusiveZone reserves space)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: main
        screen: Quickshell.screens[0]
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: ShellState.barVisible ? (barTopMargin + barHeight + popupGap) : 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:bar"

        anchors.top: true
        anchors.left: true
        anchors.right: true

        margins.top: barTopMargin
        margins.left: sideMargin
        margins.right: sideMargin

        implicitHeight: ShellState.barVisible ? barHeight + barTopMargin : 0

        // ── BAR CONTENT ──
        BarContent {
            id: barContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: barHeight
        }

        // ── AUTO-HIDE ──
        property bool cursorNearTop: false

        Timer {
            interval: 100; running: true; repeat: true
            onTriggered: {
                var y = Hyprland.cursor?.pos?.y ?? -1
                if (y <= 2) {
                    if (!main.cursorNearTop) { main.cursorNearTop = true; ShellState.barVisible = true }
                    hideTimer.stop()
                } else if (y > 50 && main.cursorNearTop && !ShellState.keepBarVisible) {
                    if (ShellState.anyPopupOpen) ShellState.closePopup()
                    main.cursorNearTop = false
                    hideTimer.running = true
                }
            }
        }

        Timer { id: hideTimer; interval: 1500; repeat: false; onTriggered: {
            if (!main.cursorNearTop) {
                ShellState.barVisible = false
                ShellState.batteryTooltipVisible = false
            }
        }}
    }

    // ═══════════════════════════════════════════════════════════════
    //  BLUETOOTH POPUP (own layer shell surface, exclusiveZone 0)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: blPopup
        screen: Quickshell.screens[0]
        visible: ShellState.bluetoothPanelOpen
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:bl-popup"

        anchors.top: true
        anchors.right: true
        margins.right: 16
        implicitWidth: (sw - 16) * 0.4
        implicitHeight: visible ? 500 : 0

        BluetoothSelector {
            id: blInner
            anchors.fill: parent
        }

        onVisibleChanged: { if (visible) blInner.show() }
    }

    // ═══════════════════════════════════════════════════════════════
    //  WIFI POPUP (own layer shell surface, exclusiveZone 0)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: wifiPopup
        screen: Quickshell.screens[0]
        visible: ShellState.wifiSelectorOpen
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:wifi-popup"

        anchors.top: true
        anchors.right: true
        margins.right: 16
        implicitWidth: (sw - 16) * 0.4
        implicitHeight: visible ? 500 : 0

        WifiSelector {
            id: wifiSelInner
            anchors.fill: parent
        }

        onVisibleChanged: { if (visible) wifiSelInner.show() }
    }

    // ═══════════════════════════════════════════════════════════════
    //  NOTIFICATION PANEL (own layer shell surface, exclusiveZone 0)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: notifPopup
        screen: Quickshell.screens[0]
        visible: ShellState.notificationPanelOpen
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:notif-popup"

        anchors.top: true
        anchors.right: true
        margins.right: 16
        implicitWidth: 360
        implicitHeight: visible ? 590 : 0

        NotificationPanel {
            id: notifPanelInner
            anchors.fill: parent
        }

        onVisibleChanged: { if (visible) notifPanelInner.show() }
    }

    // ═══════════════════════════════════════════════════════════════
    //  CALENDAR POPUP (own layer shell surface, exclusiveZone 0)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: calPopup
        screen: Quickshell.screens[0]
        visible: ShellState.calendarPopupOpen
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:cal-popup"

        anchors.top: true
        anchors.left: true
        margins.left: (sw - ((sw - 16) * 0.70 + 20)) / 2
        implicitWidth: (sw - 16) * 0.70 + 20
        implicitHeight: visible ? 500 : 0

        CalendarPopup {
            id: calPopupInner
            anchors.fill: parent
        }

        onVisibleChanged: { if (visible) calPopupInner.show() }
    }

    // ═══════════════════════════════════════════════════════════════
    //  MEDIA CARD (separate Window, unchanged)
    // ═══════════════════════════════════════════════════════════════
    Window {
        id: mediaCard
        visible: ShellState.mediaCardOpen
        color: "transparent"
        width: 320; height: 200
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowTransparentForInput
        x: 0; y: 0
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
        MediaCard { anchors.fill: parent; anchors.margins: 4 }
    }

    // ═══════════════════════════════════════════════════════════════
    //  GLOBAL SHORTCUTS (matched by keybinds.conf global IPC)
    // ═══════════════════════════════════════════════════════════════
    GlobalShortcut {
        name: "barToggle"
        description: "Toggle bar visibility"
        onPressed: ShellState.toggleBar()
    }

    GlobalShortcut {
        name: "notificationPanelToggle"
        description: "Toggle notification panel"
        onPressed: ShellState.toggleNotificationPanel()
    }

    GlobalShortcut {
        name: "mediaControlsToggle"
        description: "Toggle media card"
        onPressed: ShellState.toggleMediaCard()
    }
}
