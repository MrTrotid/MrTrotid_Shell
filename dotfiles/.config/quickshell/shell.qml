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

    readonly property real barTopMargin: 5
    readonly property real barHeight: 28
    readonly property real barGap: 4
    readonly property real popupGap: 1
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
                    // Close popups when cursor is away from top
                    if (ShellState.anyPopupOpen) ShellState.closePopup()
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
        implicitHeight: {
            var count = Math.min(NotificationService.toastList.count, 3)
            if (count === 0) return 0
            var h = 0
            for (var i = 0; i < count; i++) {
                var entry = NotificationService.toastList.get(i)
                h += (entry && entry.actions && entry.actions.length > 0) ? 92 : 64
                if (i > 0) h += 10
            }
            return h
        }

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

        onVisibleChanged: {
            if (visible && ShellState.quickActionsOpen) {
                qaFocusTimer.start()
            }
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
    //  CLIPBOARD POPUP (left side, slides in from left)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: clipPopup
        screen: Quickshell.screens[0]
        visible: ShellState.clipboardPopupOpen || clipLoader.opacity > 0
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: (ShellState.clipboardPopupOpen || clipLoader.opacity > 0) ? WlrLayer.Top : WlrLayer.Background
        WlrLayershell.namespace: "custom:clipboard"
        WlrLayershell.keyboardFocus: ShellState.clipboardPopupOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.left: true
        margins.top: Math.round((Quickshell.screens[0].height - 700) / 2) - 10
        margins.left: 0
        implicitWidth: 420
        implicitHeight: 700

        Item {
            id: clipFocusCatcher
            anchors.fill: parent
            focus: true
            activeFocusOnTab: true
            Keys.onEscapePressed: ShellState.closePopup()
        }

        Loader {
            id: clipLoader
            anchors.fill: parent
            active: true
            visible: opacity > 0
            enabled: ShellState.clipboardPopupOpen

            transform: Translate { id: clipTransform }

            states: [
                State {
                    name: "open"
                    when: ShellState.clipboardPopupOpen
                    PropertyChanges { target: clipLoader; opacity: 1 }
                    PropertyChanges { target: clipTransform; x: 0 }
                },
                State {
                    name: "closed"
                    when: !ShellState.clipboardPopupOpen
                    PropertyChanges { target: clipLoader; opacity: 0 }
                    PropertyChanges { target: clipTransform; x: -clipLoader.width - 20 }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation { target: clipTransform; property: "x"; duration: 350; easing.type: Easing.OutCubic }
                        NumberAnimation { target: clipLoader; property: "opacity"; duration: 250; easing.type: Easing.OutCubic }
                    }
                },
                Transition {
                    from: "open"; to: "closed"
                    ParallelAnimation {
                        NumberAnimation { target: clipTransform; property: "x"; duration: 300; easing.type: Easing.InCubic }
                        NumberAnimation { target: clipLoader; property: "opacity"; duration: 200; easing.type: Easing.InCubic }
                    }
                }
            ]

            sourceComponent: Item {
                ClipboardManager {
                    id: clipInner
                    anchors.fill: parent
                }

                Connections {
                    target: ShellState
                    function onClipboardPopupOpenChanged() {
                        if (ShellState.clipboardPopupOpen) {
                            clipInner.show()
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  EMOJI POPUP (left side, slides in from left)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: emojiPopup
        screen: Quickshell.screens[0]
        visible: ShellState.emojiPopupOpen || emojiLoader.opacity > 0
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: (ShellState.emojiPopupOpen || emojiLoader.opacity > 0) ? WlrLayer.Top : WlrLayer.Background
        WlrLayershell.namespace: "custom:emoji"
        WlrLayershell.keyboardFocus: ShellState.emojiPopupOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.left: true
        margins.top: Math.round((Quickshell.screens[0].height - 560) / 2) - 10
        margins.left: 0
        implicitWidth: 380
        implicitHeight: 560

        Item {
            id: emojiFocusCatcher
            anchors.fill: parent
            focus: true
            activeFocusOnTab: true
            Keys.onEscapePressed: ShellState.closePopup()
        }

        Loader {
            id: emojiLoader
            anchors.fill: parent
            active: true
            visible: opacity > 0
            enabled: ShellState.emojiPopupOpen

            transform: Translate { id: emojiTransform }

            states: [
                State {
                    name: "open"
                    when: ShellState.emojiPopupOpen
                    PropertyChanges { target: emojiLoader; opacity: 1 }
                    PropertyChanges { target: emojiTransform; x: 0 }
                },
                State {
                    name: "closed"
                    when: !ShellState.emojiPopupOpen
                    PropertyChanges { target: emojiLoader; opacity: 0 }
                    PropertyChanges { target: emojiTransform; x: -emojiLoader.width - 20 }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation { target: emojiTransform; property: "x"; duration: 350; easing.type: Easing.OutCubic }
                        NumberAnimation { target: emojiLoader; property: "opacity"; duration: 250; easing.type: Easing.OutCubic }
                    }
                },
                Transition {
                    from: "open"; to: "closed"
                    ParallelAnimation {
                        NumberAnimation { target: emojiTransform; property: "x"; duration: 300; easing.type: Easing.InCubic }
                        NumberAnimation { target: emojiLoader; property: "opacity"; duration: 200; easing.type: Easing.InCubic }
                    }
                }
            ]

            sourceComponent: Item {
                EmojiPicker {
                    id: emojiInner
                    anchors.fill: parent
                }

                Connections {
                    target: ShellState
                    function onEmojiPopupOpenChanged() {
                        if (ShellState.emojiPopupOpen) {
                            emojiInner.show()
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  GIF POPUP (left side, slides in from left)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: gifPopup
        screen: Quickshell.screens[0]
        visible: ShellState.gifPopupOpen || gifLoader.opacity > 0
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: (ShellState.gifPopupOpen || gifLoader.opacity > 0) ? WlrLayer.Top : WlrLayer.Background
        WlrLayershell.namespace: "custom:gif"
        WlrLayershell.keyboardFocus: ShellState.gifPopupOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.left: true
        margins.top: Math.round((Quickshell.screens[0].height - 600) / 2) - 10
        margins.left: 0
        implicitWidth: 420
        implicitHeight: 600

        Item {
            id: gifFocusCatcher
            anchors.fill: parent
            focus: true
            activeFocusOnTab: true
            Keys.onEscapePressed: ShellState.closePopup()
        }

        Loader {
            id: gifLoader
            anchors.fill: parent
            active: true
            visible: opacity > 0
            enabled: ShellState.gifPopupOpen

            transform: Translate { id: gifTransform }

            states: [
                State {
                    name: "open"
                    when: ShellState.gifPopupOpen
                    PropertyChanges { target: gifLoader; opacity: 1 }
                    PropertyChanges { target: gifTransform; x: 0 }
                },
                State {
                    name: "closed"
                    when: !ShellState.gifPopupOpen
                    PropertyChanges { target: gifLoader; opacity: 0 }
                    PropertyChanges { target: gifTransform; x: -gifLoader.width - 20 }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation { target: gifTransform; property: "x"; duration: 350; easing.type: Easing.OutCubic }
                        NumberAnimation { target: gifLoader; property: "opacity"; duration: 250; easing.type: Easing.OutCubic }
                    }
                },
                Transition {
                    from: "open"; to: "closed"
                    ParallelAnimation {
                        NumberAnimation { target: gifTransform; property: "x"; duration: 300; easing.type: Easing.InCubic }
                        NumberAnimation { target: gifLoader; property: "opacity"; duration: 200; easing.type: Easing.InCubic }
                    }
                }
            ]

            sourceComponent: Item {
                GifPicker {
                    id: gifInner
                    anchors.fill: parent
                }

                Connections {
                    target: ShellState
                    function onGifPopupOpenChanged() {
                        if (ShellState.gifPopupOpen) {
                            gifInner.show()
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  POWER MENU (centered overlay)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: powerPopup
        screen: Quickshell.screens[0]
        visible: ShellState.powerMenuOpen || powerLoader.opacity > 0
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: (ShellState.powerMenuOpen || powerLoader.opacity > 0) ? WlrLayer.Overlay : WlrLayer.Background
        WlrLayershell.namespace: "custom:power"
        WlrLayershell.keyboardFocus: ShellState.powerMenuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.left: true
        margins.top: 0
        margins.left: 0
        implicitWidth: Quickshell.screens[0].width
        implicitHeight: Quickshell.screens[0].height

        Item {
            anchors.fill: parent
            focus: true
            activeFocusOnTab: true
            Keys.onEscapePressed: ShellState.closePopup()
        }

        Loader {
            id: powerLoader
            anchors.fill: parent
            active: true
            visible: opacity > 0
            enabled: ShellState.powerMenuOpen

            states: [
                State {
                    name: "open"
                    when: ShellState.powerMenuOpen
                    PropertyChanges { target: powerLoader; opacity: 1 }
                },
                State {
                    name: "closed"
                    when: !ShellState.powerMenuOpen
                    PropertyChanges { target: powerLoader; opacity: 0 }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    NumberAnimation { target: powerLoader; property: "opacity"; duration: 200; easing.type: Easing.OutCubic }
                },
                Transition {
                    from: "open"; to: "closed"
                    NumberAnimation { target: powerLoader; property: "opacity"; duration: 150; easing.type: Easing.InCubic }
                }
            ]

            sourceComponent: PowerMenu {}
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  OSD POPUP (volume/brightness feedback)
    // ═══════════════════════════════════════════════════════════════
    PanelWindow {
        id: osdPopup
        screen: main.screen
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

    GlobalShortcut {
        name: "clipboardToggle"
        description: "Toggle clipboard manager"
        onPressed: ShellState.toggleClipboardPopup()
    }

    GlobalShortcut {
        name: "emojiToggle"
        description: "Toggle emoji picker"
        onPressed: ShellState.toggleEmojiPopup()
    }

    GlobalShortcut {
        name: "gifToggle"
        description: "Toggle GIF picker"
        onPressed: ShellState.toggleGifPopup()
    }

    GlobalShortcut {
        name: "powerMenuToggle"
        description: "Toggle power menu"
        onPressed: ShellState.togglePowerMenu()
    }

    // Restore last wallpaper on startup
    Process {
        id: wpRestore
        running: false
        command: ["sh", "-c", "WP=\"$HOME/.cache/quickshell/wallpaper_picker/current_wallpaper.png\"; if [ -f \"$WP\" ]; then killall swaybg 2>/dev/null; nohup swaybg -i \"$WP\" -m fill >/dev/null 2>&1 & disown; (matugen image \"$WP\" --prefer darkness 2>/dev/null || true); fi"]
    }

    // Check polkit agent on startup
    Timer {
        id: polkitCheck
        interval: 3000
        repeat: false
        running: false
        onTriggered: {
            polkitCheckProc.running = true;
        }
    }

    Process {
        id: polkitCheckProc
        running: false
        command: ["sh", "-c", "pgrep -x hyprpolkitagent || (hyprpolkitagent &)"]
    }

    Component.onCompleted: {
        wpRestore.running = true
        polkitCheck.running = true
    }
}
