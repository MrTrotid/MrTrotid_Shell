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

    readonly property real barTopMargin: 10
    readonly property real barHeight: 36
    readonly property real barGap: 4
    readonly property real popupY: barTopMargin + barHeight + 10
    readonly property real sideMargin: 8
    readonly property real sw: Quickshell.screens[0]?.width ?? 1920

    // ═══════════════════════════════════════════════════════════════
    //  BAR (own layer shell surface, exclusiveZone reserves space)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: main
        screen: Quickshell.screens[0]
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: ctx?.barVisible ? 36 : 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:bar"

        anchors.top: true
        anchors.left: true
        anchors.right: true

        margins.top: barTopMargin
        margins.left: sideMargin
        margins.right: sideMargin

        implicitHeight: ctx?.barVisible ? barHeight + barTopMargin : 0

        // ── BAR CONTENT ──
        BarContent {
            id: barContent
            serviceContext: ctx
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
                if (!ctx?.shellState) return
                var y = Hyprland.cursor?.pos?.y ?? -1
                if (y <= 2) {
                    if (!main.cursorNearTop) { main.cursorNearTop = true; ctx.barVisible = true }
                    hideTimer.stop()
                } else if (y > 50 && main.cursorNearTop && !ctx.keepBarVisible) {
                    if (ctx.anyPopupOpen) {
                        ctx.bluetoothPanelOpen = false
                        ctx.wifiSelectorOpen = false
                        ctx.calendarPopupOpen = false
                        ctx.notificationPanelOpen = false
                    }
                    main.cursorNearTop = false
                    hideTimer.running = true
                }
            }
        }

        Timer { id: hideTimer; interval: 1500; repeat: false; onTriggered: {
            if (!main.cursorNearTop && ctx?.shellState) {
                ctx.barVisible = false
                ctx.batteryTooltipVisible = false
            }
        }}
    }

    // ═══════════════════════════════════════════════════════════════
    //  BLUETOOTH POPUP (own layer shell surface, exclusiveZone 0)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: blPopup
        screen: Quickshell.screens[0]
        visible: ctx?.bluetoothPanelOpen ?? false
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:bl-popup"

        anchors.top: true
        anchors.right: true
        margins.top: popupY
        margins.right: 16
        implicitWidth: (sw - 16) * 0.4
        implicitHeight: visible ? 500 : 0

        BluetoothSelector {
            id: blInner
            anchors.fill: parent
            serviceContext: ctx
        }

        onVisibleChanged: { if (visible) blInner.show() }
    }

    // ═══════════════════════════════════════════════════════════════
    //  WIFI POPUP (own layer shell surface, exclusiveZone 0)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: wifiPopup
        screen: Quickshell.screens[0]
        visible: ctx?.wifiSelectorOpen ?? false
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:wifi-popup"

        anchors.top: true
        anchors.right: true
        margins.top: popupY
        margins.right: 16
        implicitWidth: (sw - 16) * 0.4
        implicitHeight: visible ? 500 : 0

        WifiSelector {
            id: wifiSelInner
            anchors.fill: parent
            serviceContext: ctx
        }

        onVisibleChanged: { if (visible) wifiSelInner.show() }
    }

    // ═══════════════════════════════════════════════════════════════
    //  NOTIFICATION PANEL (own layer shell surface, exclusiveZone 0)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: notifPopup
        screen: Quickshell.screens[0]
        visible: ctx?.notificationPanelOpen ?? false
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:notif-popup"

        anchors.top: true
        anchors.right: true
        margins.top: popupY
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
        visible: ctx?.calendarPopupOpen ?? false
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:cal-popup"

        anchors.top: true
        anchors.left: true
        margins.top: popupY
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
        visible: ctx?.mediaCardOpen ?? false
        color: "transparent"
        width: 320; height: 200
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowTransparentForInput
        x: 0; y: 0
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
        MediaCard { serviceContext: ctx; anchors.fill: parent; anchors.margins: 4 }
    }

    // ═══════════════════════════════════════════════════════════════
    //  KEYBINDS
    // ═══════════════════════════════════════════════════════════════
    Shortcut { sequence: "Super+O"; onActivated: ctx?.toggleBar() }
    Shortcut { sequence: "Super+M"; onActivated: ctx?.toggleMediaCard() }
    Shortcut { sequence: "Super+N"; onActivated: ctx?.toggleWifiSelector() }
    Shortcut { sequence: "Super+B"; onActivated: ctx?.toggleBluetoothPanel() }
}
