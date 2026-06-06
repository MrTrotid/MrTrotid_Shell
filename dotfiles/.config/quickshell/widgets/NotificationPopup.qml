import QtQuick
import Quickshell
import "../services"

Item {
    id: root

    width: 320
    height: 64

    Repeater {
        id: repeater
        model: NotificationService.notifications

        delegate: Item {
            id: notif

            required property int index
            required property string title
            required property string body
            required property string icon

            width: 320
            height: 64
            z: 100 - index

            property bool exiting: false

            // ── app-based accent color ──
            readonly property color appAccent: {
                var t = notif.title.toLowerCase()
                if (t.indexOf("firefox") >= 0 || t.indexOf("chrome") >= 0 || t.indexOf("brave") >= 0 || t.indexOf("browser") >= 0)
                    return Qt.rgba(0.35, 0.55, 0.95, 1.0)   // blue
                if (t.indexOf("discord") >= 0 || t.indexOf("telegram") >= 0 || t.indexOf("signal") >= 0)
                    return Qt.rgba(0.55, 0.40, 0.95, 1.0)   // indigo
                if (t.indexOf("spotify") >= 0 || t.indexOf("music") >= 0 || t.indexOf("mpv") >= 0 || t.indexOf("player") >= 0)
                    return Qt.rgba(0.30, 0.85, 0.50, 1.0)   // green
                if (t.indexOf("kitty") >= 0 || t.indexOf("terminal") >= 0 || t.indexOf("shell") >= 0)
                    return Qt.rgba(0.30, 0.80, 0.75, 1.0)   // teal
                if (t.indexOf("thunar") >= 0 || t.indexOf("nautilus") >= 0 || t.indexOf("file") >= 0)
                    return Qt.rgba(0.90, 0.65, 0.30, 1.0)   // orange
                if (t.indexOf("screenshot") >= 0 || t.indexOf("grim") >= 0 || t.indexOf("slurp") >= 0)
                    return Qt.rgba(0.40, 0.70, 0.95, 1.0)   // light blue
                if (t.indexOf("recording") >= 0 || t.indexOf("wf-recorder") >= 0)
                    return Qt.rgba(0.95, 0.40, 0.40, 1.0)   // red
                if (t.indexOf("clipboard") >= 0 || t.indexOf("cliphist") >= 0)
                    return Qt.rgba(0.60, 0.80, 0.50, 1.0)   // lime
                if (t.indexOf("network") >= 0 || t.indexOf("wifi") >= 0 || t.indexOf("bluetooth") >= 0)
                    return Qt.rgba(0.50, 0.65, 0.95, 1.0)   // soft blue
                if (t.indexOf("battery") >= 0 || t.indexOf("power") >= 0)
                    return Qt.rgba(0.90, 0.80, 0.35, 1.0)   // yellow
                if (t.indexOf("volume") >= 0 || t.indexOf("audio") >= 0 || t.indexOf("sound") >= 0)
                    return Qt.rgba(0.80, 0.55, 0.90, 1.0)   // purple
                return Qt.rgba(0.65, 0.70, 0.80, 1.0)       // neutral glass
            }

            opacity: 0
            y: -100

            Behavior on y {
                enabled: !entrySlide.running && !exitAnim.running
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            Component.onCompleted: {
                entrySlide.to = notif.index * 10
                entrySlide.start()
                entryFade.start()
                dismissTimer.start()
            }

            onIndexChanged: {
                if (!notif.exiting) {
                    reposition.to = notif.index * 10
                    reposition.start()
                }
            }

            NumberAnimation {
                id: reposition
                target: notif
                property: "y"
                duration: 250
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                id: entrySlide
                target: notif
                property: "y"
                from: -100; to: 0
                duration: 350
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                id: entryFade
                target: notif
                property: "opacity"
                from: 0; to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }

            Timer {
                id: dismissTimer
                interval: 3500
                repeat: false
                onTriggered: {
                    notif.exiting = true
                    exitAnim.start()
                    exitFade.start()
                }
            }

            NumberAnimation {
                id: exitAnim
                target: notif
                property: "y"
                to: -100
                duration: 300
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                id: exitFade
                target: notif
                property: "opacity"
                to: 0
                duration: 250
                easing.type: Easing.InCubic
                onFinished: {
                    NotificationService.removeNotification(notif.index)
                }
            }

            // ── glassy card ──
            Rectangle {
                anchors.fill: parent
                radius: 16
                color: "#1a1c1e"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                // top highlight edge
                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.top: parent.top
                    height: 1
                    radius: 1
                    color: Qt.rgba(1, 1, 1, 0.12)
                }

                // accent glow behind icon
                Rectangle {
                    id: glowBg
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 44
                    radius: 12
                    color: Qt.rgba(notif.appAccent.r, notif.appAccent.g, notif.appAccent.b, 0.12)

                    // subtle border around icon
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(notif.appAccent.r, notif.appAccent.g, notif.appAccent.b, 0.18)
                    }
                }

                Rectangle {
                    id: iconBg
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 10
                    color: Qt.rgba(notif.appAccent.r, notif.appAccent.g, notif.appAccent.b, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: {
                            var ic = notif.icon
                            if (ic === "screenshot") return "\uF030"
                            if (ic === "recording") return "\uF03D"
                            if (ic === "clipboard") return "\uF0EA"
                            if (ic === "success") return "\uF00C"
                            if (ic === "error") return "\uF00D"
                            return "\uF130"
                        }
                        color: notif.appAccent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                    }
                }

                Column {
                    anchors.left: iconBg.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: notif.title
                        color: "#e8ecef"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: notif.body
                        color: "#8c9198"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        width: parent.width
                        visible: text.length > 0
                    }
                }
            }
        }
    }
}
