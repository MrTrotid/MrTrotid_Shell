import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick.Effects

Item {
    id: panel

    readonly property color _base: "#111816"
    readonly property color _mantle: "#0d1211"
    readonly property color _crust: "#080c0b"
    property color _surface: "#111816"
    property color _surfaceVar: "#252c2a"
    property color _surfaceHigh: "#2f3836"
    property color _onSurface: "#dde4e2"
    property color _onSurfaceVar: "#b0b8b6"
    property color _outline: "#4a5250"
    property color _accent: "#81d5ca"
    property color _onAccent: "#003732"
    property color _error: "#ffb4ab"
    property color _success: "#92d5ab"
    readonly property color accentLight: "#b4ece2"
    readonly property color _orange: "#e8a87c"

    property bool micMuted: false
    property bool nightLight: false
    property bool dndEnabled: false

    property var groupedNotifications: ({})
    property real globalOrbitAngle: 0

    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true
        imageSupported: true
        onNotification: function(notification) {
            notification.tracked = true
            addNotification(notification)
        }
    }

    function addNotification(notification) {
        var app = notification.appName || "Unknown"
        if (!groupedNotifications[app]) groupedNotifications[app] = []
        groupedNotifications[app].push({
            "id": notification.id,
            "summary": notification.summary || "",
            "body": notification.body || "",
            "appName": app,
            "appIcon": notification.appIcon || "",
            "time": Qt.formatDateTime(new Date(), "HH:mm"),
            "notification": notification
        })
        groupedNotifications = Qt.Object.assign({}, groupedNotifications)
    }

    function dismissNotification(appName, index) {
        if (groupedNotifications[appName]) {
            var notif = groupedNotifications[appName][index]
            if (notif && notif.notification) notif.notification.dismiss()
            groupedNotifications[appName].splice(index, 1)
            if (groupedNotifications[appName].length === 0) delete groupedNotifications[appName]
            groupedNotifications = Qt.Object.assign({}, groupedNotifications)
        }
    }

    function clearAllNotifications() {
        for (var app in groupedNotifications) {
            for (var i = 0; i < groupedNotifications[app].length; i++) {
                var n = groupedNotifications[app][i]
                if (n && n.notification) n.notification.dismiss()
            }
        }
        groupedNotifications = {}
    }

    function notifCount() {
        var total = 0
        for (var k in groupedNotifications) total += groupedNotifications[k].length
        return total
    }

    Process {
        id: micCheck
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: { micMuted = text.trim().includes("[MUTED]") }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: micCheck.running = true }

    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: panel.globalOrbitAngle += 0.015
    }

    property real introBg: 0
    property real introCore: 0
    property real introTools: 0
    property real introNotifs: 0
    property real introPower: 0

    function show() {
        introBg = 0; introCore = 0; introTools = 0; introNotifs = 0; introPower = 0
        introAnim.start()
        micCheck.running = true
    }

    SequentialAnimation {
        id: introAnim
        running: false
        PauseAnimation { duration: 20 }
        ParallelAnimation {
            NumberAnimation { target: panel; property: "introBg"; from: 0; to: 1.0; duration: 600; easing.type: Easing.OutSine }
            SequentialAnimation {
                PauseAnimation { duration: 120 }
                NumberAnimation { target: panel; property: "introCore"; from: 0; to: 1.0; duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            }
            SequentialAnimation {
                PauseAnimation { duration: 200 }
                NumberAnimation { target: panel; property: "introTools"; from: 0; to: 1.0; duration: 500; easing.type: Easing.OutQuint }
            }
            SequentialAnimation {
                PauseAnimation { duration: 280 }
                NumberAnimation { target: panel; property: "introNotifs"; from: 0; to: 1.0; duration: 500; easing.type: Easing.OutQuint }
            }
            SequentialAnimation {
                PauseAnimation { duration: 350 }
                NumberAnimation { target: panel; property: "introPower"; from: 0; to: 1.0; duration: 400; easing.type: Easing.OutQuint }
            }
        }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: panel; property: "introBg"; to: 0; duration: 200; easing.type: Easing.InQuart }
        NumberAnimation { target: panel; property: "introCore"; to: 0; duration: 200; easing.type: Easing.InQuart }
        NumberAnimation { target: panel; property: "introTools"; to: 0; duration: 200; easing.type: Easing.InQuart }
        NumberAnimation { target: panel; property: "introNotifs"; to: 0; duration: 200; easing.type: Easing.InQuart }
        NumberAnimation { target: panel; property: "introPower"; to: 0; duration: 200; easing.type: Easing.InQuart }
    }

    // ══════════════════════════════════════════════════════════════
    // BACKGROUND BLOBS + RADAR
    // ══════════════════════════════════════════════════════════════
    Rectangle {
        width: parent.width * 0.8; height: width; radius: width / 2
        x: (parent.width / 2 - width / 2) + Math.cos(panel.globalOrbitAngle * 2) * 80
        y: (parent.height / 2 - height / 2) + Math.sin(panel.globalOrbitAngle * 2) * 60
        opacity: 0.06 * panel.introBg
        color: accentLight
        Behavior on color { ColorAnimation { duration: 1000 } }
        visible: opacity > 0.01
    }
    Rectangle {
        width: parent.width * 0.9; height: width; radius: width / 2
        x: (parent.width / 2 - width / 2) + Math.sin(panel.globalOrbitAngle * 1.5) * -80
        y: (parent.height / 2 - height / 2) + Math.cos(panel.globalOrbitAngle * 1.5) * -60
        opacity: 0.04 * panel.introBg
        color: Qt.darker(_accent, 1.25)
        Behavior on color { ColorAnimation { duration: 1000 } }
        visible: opacity > 0.01
    }

    Item {
        anchors.fill: parent
        opacity: panel.introBg
        Repeater {
            model: 3
            Rectangle {
                anchors.centerIn: parent
                width: 100 + (index * 70); height: width; radius: width / 2
                color: "transparent"
                border.color: _accent; border.width: 1
                opacity: 0.06 - (index * 0.015)
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    // MAIN CONTENT
    // ══════════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        radius: 14
        color: _surface
        border.color: _surfaceVar
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // ── CORE: Bell icon ──
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 100; Layout.preferredHeight: 100
                opacity: panel.introCore
                scale: 0.85 + (0.15 * panel.introCore)
                transform: Translate { y: 20 * (1.0 - panel.introCore) }

                Rectangle {
                    id: bellCore
                    anchors.fill: parent; radius: width / 2
                    color: _surfaceVar
                    border.color: Qt.alpha(_accent, 0.3)
                    border.width: 2

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: _surfaceHigh }
                        GradientStop { position: 1.0; color: _surfaceVar }
                    }
                }

                MultiEffect {
                    source: bellCore
                    anchors.fill: bellCore
                    shadowEnabled: true; shadowColor: "#000000"
                    shadowOpacity: 0.4; shadowBlur: 1.2
                    shadowVerticalOffset: 4; z: -1
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uF0F3"
                    color: _accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 32
                }

                Rectangle {
                    visible: notifCount() > 0
                    anchors.top: parent.top; anchors.right: parent.right
                    width: 22; height: 22; radius: width / 2
                    color: _error
                    Text {
                        anchors.centerIn: parent
                        text: {
                            var t = notifCount()
                            return t > 9 ? "9+" : t.toString()
                        }
                        color: "#fff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }
            }

            // ── TOOLS ROW ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                opacity: panel.introTools
                transform: Translate { y: 15 * (1.0 - panel.introTools) }

                // Mic
                Item {
                    Layout.preferredWidth: 44; Layout.preferredHeight: 44
                    Rectangle {
                        anchors.fill: parent; radius: width / 2
                        color: panel.micMuted ? Qt.alpha(_error, 0.12) : Qt.alpha(_accent, 0.15)
                        border.color: panel.micMuted ? _error : _accent
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: panel.micMuted ? "\uF131" : "\uF130"
                            color: panel.micMuted ? _error : _accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onEntered: parent.scale = 1.1; onExited: parent.scale = 1.0
                        onClicked: {
                            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
                            micCheck.running = true
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                }

                // Night Light
                Item {
                    Layout.preferredWidth: 44; Layout.preferredHeight: 44
                    Rectangle {
                        anchors.fill: parent; radius: width / 2
                        color: panel.nightLight ? Qt.alpha(_accent, 0.15) : _surfaceVar
                        border.color: panel.nightLight ? _accent : _outline
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "\uF186"
                            color: panel.nightLight ? _accent : _onSurfaceVar
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onEntered: parent.scale = 1.1; onExited: parent.scale = 1.0
                        onClicked: {
                            panel.nightLight = !panel.nightLight
                            if (panel.nightLight) Quickshell.execDetached(["hyprctl", "dispatch", "togglespecialworkspace", "nightlight"])
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                }

                // DND (bell-slash, U+F1F6 - available in font)
                Item {
                    Layout.preferredWidth: 44; Layout.preferredHeight: 44
                    Rectangle {
                        anchors.fill: parent; radius: width / 2
                        color: panel.dndEnabled ? Qt.alpha(_accent, 0.15) : _surfaceVar
                        border.color: panel.dndEnabled ? _accent : _outline
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "\uF1F6"
                            color: panel.dndEnabled ? _accent : _onSurfaceVar
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onEntered: parent.scale = 1.1; onExited: parent.scale = 1.0
                        onClicked: {
                            panel.dndEnabled = !panel.dndEnabled
                            Quickshell.execDetached(["swaync-client", panel.dndEnabled ? "-dn" : "-df"])
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                }

                // Screenshot (crosshairs, U+F05B)
                Item {
                    Layout.preferredWidth: 44; Layout.preferredHeight: 44
                    Rectangle {
                        anchors.fill: parent; radius: width / 2
                        color: scrMa.containsMouse ? Qt.alpha(_accent, 0.15) : _surfaceVar
                        border.color: scrMa.containsMouse ? _accent : _outline
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "\uF05B"
                            color: scrMa.containsMouse ? _accent : _onSurfaceVar
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                        }
                    }
                    MouseArea {
                        id: scrMa
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onEntered: parent.scale = 1.1; onExited: parent.scale = 1.0
                        onClicked: Quickshell.execDetached(["hyprshot", "region"])
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                }

                // Color Picker (palette, U+F04C2)
                Item {
                    Layout.preferredWidth: 44; Layout.preferredHeight: 44
                    Rectangle {
                        anchors.fill: parent; radius: width / 2
                        color: cpMa.containsMouse ? Qt.alpha(_accent, 0.15) : _surfaceVar
                        border.color: cpMa.containsMouse ? _accent : _outline
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "\uF04C2"
                            color: cpMa.containsMouse ? _accent : _onSurfaceVar
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                        }
                    }
                    MouseArea {
                        id: cpMa
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onEntered: parent.scale = 1.1; onExited: parent.scale = 1.0
                        onClicked: Quickshell.execDetached(["hyprpicker", "-a"])
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: _surfaceVar }

            // ── NOTIFICATIONS ──
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                opacity: panel.introNotifs
                transform: Translate { y: 15 * (1.0 - panel.introNotifs) }

                property var appKeys: Object.keys(groupedNotifications)
                property bool hasNotifs: appKeys.length > 0

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6

                    // Header — only show clear button when there are notifs
                    RowLayout {
                        Layout.fillWidth: true
                        visible: hasNotifs
                        Text {
                            text: "Notifications"
                            color: _onSurface
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            Layout.preferredHeight: 22; radius: 6
                            Layout.preferredWidth: clearNotifText.implicitWidth + 16
                            color: Qt.alpha(_error, 0.12)
                            border.color: Qt.alpha(_error, 0.3); border.width: 1
                            Text {
                                id: clearNotifText
                                anchors.centerIn: parent
                                text: "Clear All"
                                color: _error
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: clearAllNotifications()
                            }
                        }
                    }

                    // Notification list
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: hasNotifs
                        visible: hasNotifs
                        clip: true
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                        ListView {
                            model: appKeys
                            spacing: 8

                            delegate: ColumnLayout {
                                required property string modelData
                                required property int index
                                property string appName: modelData
                                property var notifs: groupedNotifications[modelData] || []
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 6
                                    Rectangle {
                                        Layout.preferredWidth: 20; Layout.preferredHeight: 20; radius: 5
                                        color: _surfaceHigh
                                        Text {
                                            anchors.centerIn: parent
                                            text: appName.charAt(0).toUpperCase()
                                            color: _accent
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                        }
                                    }
                                    Text {
                                        text: appName
                                        color: _onSurfaceVar
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: notifs.length.toString()
                                        color: _accent
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }

                                Repeater {
                                    model: notifs
                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index
                                        property int notifIndex: index

                                        Layout.fillWidth: true
                                        implicitHeight: notifInnerCol.implicitHeight + 14
                                        radius: 8
                                        color: notifCardHover.containsMouse ? Qt.alpha(_accent, 0.08) : _surfaceVar
                                        border.color: notifCardHover.containsMouse ? Qt.alpha(_accent, 0.25) : "transparent"
                                        border.width: 1

                                        ColumnLayout {
                                            id: notifInnerCol
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 3

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text {
                                                    text: modelData.summary
                                                    color: _onSurface
                                                    font.family: "JetBrainsMono Nerd Font"
                                                    font.pixelSize: 11
                                                    font.weight: Font.Bold
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Text {
                                                    text: modelData.time
                                                    color: _outline
                                                    font.family: "JetBrainsMono Nerd Font"
                                                    font.pixelSize: 9
                                                }
                                            }

                                            Text {
                                                text: modelData.body || ""
                                                visible: text !== ""
                                                color: _onSurfaceVar
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 10
                                                wrapMode: Text.WordWrap
                                                Layout.fillWidth: true
                                                maximumLineCount: 2
                                                elide: Text.ElideRight
                                                opacity: 0.8
                                            }
                                        }

                                        MouseArea {
                                            id: notifCardHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: dismissNotification(appName, notifIndex)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Empty state — centered vertically
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: !hasNotifs

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "\uF0F3"
                                color: _outline
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 28
                                opacity: 0.4
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No notifications"
                                color: _outline
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                opacity: 0.6
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: _surfaceVar }

            // ── POWER BUTTONS ──
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 12
                opacity: panel.introPower
                transform: Translate { y: 15 * (1.0 - panel.introPower) }

                // Hibernate
                Item {
                    Layout.preferredWidth: 44; Layout.preferredHeight: 44
                    Rectangle {
                        anchors.fill: parent; radius: width / 2
                        color: hibHover.containsMouse ? Qt.alpha(_orange, 0.15) : _surfaceVar
                        border.color: hibHover.containsMouse ? _orange : _outline
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "\uF0102"
                            color: hibHover.containsMouse ? _orange : _onSurfaceVar
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                        }
                    }
                    MouseArea {
                        id: hibHover
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: parent.scale = 1.1; onExited: parent.scale = 1.0
                        onClicked: Quickshell.execDetached(["systemctl", "hibernate"])
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                }

                // Logout
                Item {
                    Layout.preferredWidth: 44; Layout.preferredHeight: 44
                    Rectangle {
                        anchors.fill: parent; radius: width / 2
                        color: logHover.containsMouse ? Qt.alpha(_error, 0.15) : _surfaceVar
                        border.color: logHover.containsMouse ? _error : _outline
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "\uF0343"
                            color: logHover.containsMouse ? _error : _onSurfaceVar
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                        }
                    }
                    MouseArea {
                        id: logHover
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: parent.scale = 1.1; onExited: parent.scale = 1.0
                        onClicked: Quickshell.execDetached(["loginctl", "terminate-user", "mrtrotid-ssd"])
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                }

                // Reboot
                Item {
                    Layout.preferredWidth: 44; Layout.preferredHeight: 44
                    Rectangle {
                        anchors.fill: parent; radius: width / 2
                        color: rebHover.containsMouse ? Qt.alpha(_accent, 0.15) : _surfaceVar
                        border.color: rebHover.containsMouse ? _accent : _outline
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "\uF021A"
                            color: rebHover.containsMouse ? _accent : _onSurfaceVar
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                        }
                    }
                    MouseArea {
                        id: rebHover
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: parent.scale = 1.1; onExited: parent.scale = 1.0
                        onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                }

                // Power Off
                Item {
                    Layout.preferredWidth: 44; Layout.preferredHeight: 44
                    Rectangle {
                        anchors.fill: parent; radius: width / 2
                        color: pwrHover.containsMouse ? Qt.alpha(_error, 0.2) : _surfaceVar
                        border.color: pwrHover.containsMouse ? _error : _outline
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "\uF0116"
                            color: pwrHover.containsMouse ? _error : _onSurfaceVar
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                        }
                    }
                    MouseArea {
                        id: pwrHover
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: parent.scale = 1.1; onExited: parent.scale = 1.0
                        onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                }
            }
        }
    }
}
