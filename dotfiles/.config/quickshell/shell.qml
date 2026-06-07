//@ pragma UseQApplication
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
    readonly property real sw: main.screen?.width ?? Quickshell.screens[0]?.width ?? 1920

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
            property var trayMenuWindow: menuAnchor
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
                } else if (y > 50 && !ShellState.keepBarVisible) {
                    // Hide bar on cursor away — do NOT close popups here.
                    // Each popup handles its own dismissal (Escape, click-outside, or explicit close).
                    // Closing popups from here causes a race: clicking a bar item opens a popup,
                    // then cursor check fires and immediately closes it.
                    if (main.cursorNearTop) {
                        main.cursorNearTop = false
                        hideTimer.running = true
                    }
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
    //  MENU ANCHOR (hidden Window for tray menu display)
    // ═══════════════════════════════════════════════════════════════
    Window {
        id: menuAnchor
        visible: false
        width: 1; height: 1
        x: -100; y: -100
        flags: Qt.Popup | Qt.FramelessWindowHint
    }

    // ═══════════════════════════════════════════════════════════════
    //  NOTIFICATION TOASTS (below bar, macOS-style)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: toastPopup
        screen: Quickshell.screens[0]
        visible: NotificationService.toastList.count > 0
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:toast"

        anchors.top: true
        anchors.left: true
        margins.top: barTopMargin + barHeight - 6
        margins.left: (sw - 340) / 2

        implicitWidth: 340
        implicitHeight: 64 + (Math.min(NotificationService.toastList.count, 3) - 1) * 10

        NotificationPopup {
            id: toastContent
            anchors.left: parent.left
            anchors.top: parent.top
        }
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
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.right: true
        margins.right: 16
        implicitWidth: (sw - 16) * 0.4
        implicitHeight: visible ? 500 : 0

        Item {
            id: blFocusCatcher
            anchors.fill: parent
            focus: true
            activeFocusOnTab: true
            Keys.onEscapePressed: ShellState.closePopup()
        }

        Timer {
            id: blFocusTimer
            interval: 100
            repeat: false
            onTriggered: blFocusCatcher.forceActiveFocus()
        }

        BluetoothSelector {
            id: blInner
            anchors.fill: parent
        }

        onVisibleChanged: {
            if (visible) {
                blFocusTimer.start()
                blInner.show()
            }
        }
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
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.right: true
        margins.right: 16
        implicitWidth: (sw - 16) * 0.4
        implicitHeight: visible ? 500 : 0

        Item {
            id: wifiFocusCatcher
            anchors.fill: parent
            focus: true
            activeFocusOnTab: true
            Keys.onEscapePressed: ShellState.closePopup()
        }

        Timer {
            id: wifiFocusTimer
            interval: 100
            repeat: false
            onTriggered: wifiFocusCatcher.forceActiveFocus()
        }

        WifiSelector {
            id: wifiSelInner
            anchors.fill: parent
        }

        onVisibleChanged: {
            if (visible) {
                wifiFocusTimer.start()
                wifiSelInner.show()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  NOTIFICATION PANEL (own layer shell surface, exclusiveZone 0)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: notifPopup
        screen: Quickshell.screens[0]
        visible: ShellState.notificationPanelOpen || notifLoader.opacity > 0
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: (ShellState.notificationPanelOpen || notifLoader.opacity > 0) ? WlrLayer.Top : WlrLayer.Background
        WlrLayershell.namespace: "custom:notif-popup"
        WlrLayershell.keyboardFocus: ShellState.notificationPanelOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.right: true
        margins.right: 16
        implicitWidth: 365
        implicitHeight: 590

        Item {
            id: notifFocusCatcher
            anchors.fill: parent
            focus: true
            activeFocusOnTab: true
            Keys.onEscapePressed: ShellState.closePopup()
        }

        Timer {
            id: notifFocusTimer
            interval: 100
            repeat: false
            onTriggered: notifFocusCatcher.forceActiveFocus()
        }

        Loader {
            id: notifLoader
            anchors.fill: parent
            active: true
            visible: opacity > 0
            enabled: ShellState.notificationPanelOpen

            transform: Translate { id: notifTransform }

            states: [
                State {
                    name: "open"
                    when: ShellState.notificationPanelOpen
                    PropertyChanges { target: notifLoader; opacity: 1 }
                    PropertyChanges { target: notifTransform; x: 0; y: 0 }
                },
                State {
                    name: "closed"
                    when: !ShellState.notificationPanelOpen
                    PropertyChanges { target: notifLoader; opacity: 0 }
                    PropertyChanges { target: notifTransform; x: notifLoader.width + 20; y: 0 }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation { target: notifTransform; properties: "x,y"; duration: 350; easing.type: Easing.OutCubic }
                        NumberAnimation { target: notifLoader; property: "opacity"; duration: 250; easing.type: Easing.OutCubic }
                    }
                },
                Transition {
                    from: "open"; to: "closed"
                    ParallelAnimation {
                        NumberAnimation { target: notifTransform; properties: "x,y"; duration: 300; easing.type: Easing.InCubic }
                        NumberAnimation { target: notifLoader; property: "opacity"; duration: 200; easing.type: Easing.InCubic }
                    }
                }
            ]

            sourceComponent: Item {
                NotificationPanel {
                    id: notifPanelInner
                    anchors.fill: parent
                }

                Connections {
                    target: ShellState
                    function onNotificationPanelOpenChanged() {
                        if (ShellState.notificationPanelOpen) {
                            notifFocusTimer.start()
                            notifPanelInner.show()
                        }
                    }
                }
            }
        }
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
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.left: true
        margins.left: (sw - ((sw - 16) * 0.70 + 20)) / 2
        implicitWidth: (sw - 16) * 0.70 + 20
        implicitHeight: visible ? 500 : 0

        Item {
            id: calFocusCatcher
            anchors.fill: parent
            focus: true
            activeFocusOnTab: true
            Keys.onEscapePressed: ShellState.closePopup()
        }

        Timer {
            id: calFocusTimer
            interval: 100
            repeat: false
            onTriggered: calFocusCatcher.forceActiveFocus()
        }

        CalendarPopup {
            id: calPopupInner
            anchors.fill: parent
        }

        onVisibleChanged: {
            if (visible) {
                calFocusTimer.start()
                calPopupInner.show()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  CHEATSHEET POPUP (own layer shell surface, exclusiveZone 0)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: csPopup
        screen: Quickshell.screens[0]
        visible: ShellState.cheatsheetOpen
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:cheatsheet"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.left: true
        margins.left: (sw - ((sw - 16) * 0.85 + 20)) / 2
        implicitWidth: (sw - 16) * 0.85 + 20
        implicitHeight: visible ? 750 : 0

        Cheatsheet {
            id: csInner
            anchors.fill: parent
        }

        onVisibleChanged: { if (visible) csInner.show() }
    }

    // ═══════════════════════════════════════════════════════════════
//  QUICK ACTIONS HUD (bottom-center floating bar)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: qaPopup
        screen: Quickshell.screens[0]
        visible: ShellState.quickActionsOpen || qaLoader.opacity > 0
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: (ShellState.quickActionsOpen || qaLoader.opacity > 0) ? WlrLayer.Overlay : WlrLayer.Background
        WlrLayershell.namespace: "custom:quickactions"
        WlrLayershell.keyboardFocus: ShellState.quickActionsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.left: true
        anchors.right: true
        anchors.bottom: true
        implicitWidth: sw
        implicitHeight: 120

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closePopup()
        }

        Loader {
            id: qaLoader
            anchors.fill: parent
            active: true
            visible: opacity > 0
            enabled: ShellState.quickActionsOpen

            states: [
                State {
                    name: "open"
                    when: ShellState.quickActionsOpen
                    PropertyChanges { target: qaLoader; opacity: 1 }
                    PropertyChanges { target: qaLoader; anchors.bottomMargin: 0 }
                },
                State {
                    name: "closed"
                    when: !ShellState.quickActionsOpen
                    PropertyChanges { target: qaLoader; opacity: 0 }
                    PropertyChanges { target: qaLoader; anchors.bottomMargin: -80 }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation { target: qaLoader; property: "anchors.bottomMargin"; duration: 300; easing.type: Easing.OutCubic }
                        NumberAnimation { target: qaLoader; property: "opacity"; duration: 200; easing.type: Easing.OutCubic }
                    }
                },
                Transition {
                    from: "open"; to: "closed"
                    ParallelAnimation {
                        NumberAnimation { target: qaLoader; property: "anchors.bottomMargin"; duration: 250; easing.type: Easing.InCubic }
                        NumberAnimation { target: qaLoader; property: "opacity"; duration: 200; easing.type: Easing.InCubic }
                    }
                }
            ]

            sourceComponent: QuickActions {
                id: qaInner
                anchors.fill: parent
                onClosed: ShellState.closePopup()
            }
        }

        Timer {
            id: qaFocusTimer
            interval: 50
            repeat: false
            onTriggered: {
                if (qaLoader.item) {
                    qaLoader.item.forceActiveFocus()
                }
            }
        }

        onVisibleChanged: {
            if (visible && ShellState.quickActionsOpen) {
                qaFocusTimer.start()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  WALLPAPER PICKER (full-screen overlay)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: wpPopup
        screen: Quickshell.screens[0]
        visible: ShellState.wallpaperPickerOpen
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "custom:wallpaper-picker"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.left: true
        anchors.right: true
        anchors.bottom: true
        implicitWidth: sw
        implicitHeight: main.screen?.height ?? 1080

        WallpaperPicker {
            id: wpInner
            anchors.fill: parent
            onClosed: ShellState.closePopup()
        }

        onVisibleChanged: {
            if (visible) {
                wpInner.forceActiveFocus()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  MEDIA CARD (separate Window, unchanged)
    // ═══════════════════════════════════════════════════════════════
    Window {
        id: mediaCard
        visible: ShellState.mediaCardOpen
        color: "transparent"
        width: 320; height: 200
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
        x: 0; y: 0
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
        MediaCard { anchors.fill: parent; anchors.margins: 4 }
    }

    // ═══════════════════════════════════════════════════════════════
    //  OSD POPUP (volume/brightness feedback)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: osdPopup
        screen: Quickshell.screens[0]
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "custom:osd"
        exclusiveZone: 0

        anchors.bottom: true
        anchors.left: true
        margins.left: (sw - 200) / 2
        margins.bottom: 60

        implicitWidth: 200
        implicitHeight: 60

        OsdPopup {
            id: osdContent
            anchors.fill: parent
        }
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

    GlobalShortcut {
        name: "cheatsheetToggle"
        description: "Toggle cheatsheet"
        onPressed: ShellState.toggleCheatsheet()
    }

    GlobalShortcut {
        name: "wallpaperToggle"
        description: "Toggle wallpaper picker"
        onPressed: ShellState.toggleWallpaperPicker()
    }

    GlobalShortcut {
        name: "quickActionsToggle"
        description: "Toggle quick actions HUD"
        onPressed: ShellState.toggleQuickActions()
    }
}
