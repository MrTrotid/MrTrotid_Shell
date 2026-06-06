import QtQuick
import Quickshell
import "../services"
import "../core/NotificationUtils.js" as Utils

Item {
    id: root

    width: 320
    height: 64

    Repeater {
        id: repeater
        model: NotificationService.toastList

        delegate: Item {
            id: notif

            required property int index
            required property int notificationId
            required property string summary
            required property string body
            required property string appIcon
            required property string appName

            width: 320
            height: 64
            z: 100 - index

            property string title: summary || ""
            property bool exiting: false
            property var iconCandidates: Utils.getAppIconCandidates(notif.appName, notif.appIcon)
            property int iconCandidateIdx: 0
            property string resolvedIcon: {
                var c = iconCandidates
                if (c.length === 0) return ""
                if (c.length === 1) return c[0]
                return c[0]
            }

            readonly property color appAccent: {
                var t = notif.appName.toLowerCase()
                if (t.indexOf("firefox") >= 0 || t.indexOf("chrome") >= 0 || t.indexOf("brave") >= 0 || t.indexOf("browser") >= 0)
                    return Qt.rgba(0.35, 0.55, 0.95, 1.0)
                if (t.indexOf("discord") >= 0 || t.indexOf("telegram") >= 0 || t.indexOf("signal") >= 0)
                    return Qt.rgba(0.55, 0.40, 0.95, 1.0)
                if (t.indexOf("spotify") >= 0 || t.indexOf("music") >= 0 || t.indexOf("mpv") >= 0 || t.indexOf("player") >= 0)
                    return Qt.rgba(0.30, 0.85, 0.50, 1.0)
                if (t.indexOf("kitty") >= 0 || t.indexOf("terminal") >= 0 || t.indexOf("shell") >= 0)
                    return Qt.rgba(0.30, 0.80, 0.75, 1.0)
                if (t.indexOf("thunar") >= 0 || t.indexOf("nautilus") >= 0 || t.indexOf("file") >= 0)
                    return Qt.rgba(0.90, 0.65, 0.30, 1.0)
                if (t.indexOf("screenshot") >= 0 || t.indexOf("grim") >= 0 || t.indexOf("slurp") >= 0)
                    return Qt.rgba(0.40, 0.70, 0.95, 1.0)
                if (t.indexOf("recording") >= 0 || t.indexOf("wf-recorder") >= 0)
                    return Qt.rgba(0.95, 0.40, 0.40, 1.0)
                if (t.indexOf("clipboard") >= 0 || t.indexOf("cliphist") >= 0)
                    return Qt.rgba(0.60, 0.80, 0.50, 1.0)
                if (t.indexOf("network") >= 0 || t.indexOf("wifi") >= 0 || t.indexOf("bluetooth") >= 0)
                    return Qt.rgba(0.50, 0.65, 0.95, 1.0)
                if (t.indexOf("battery") >= 0 || t.indexOf("power") >= 0)
                    return Qt.rgba(0.90, 0.80, 0.35, 1.0)
                if (t.indexOf("volume") >= 0 || t.indexOf("audio") >= 0 || t.indexOf("sound") >= 0)
                    return Qt.rgba(0.80, 0.55, 0.90, 1.0)
                return Qt.rgba(0.65, 0.70, 0.80, 1.0)
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
                    NotificationService.dismissToast(notif.notificationId)
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: "#1a1c1e"
                border.width: 1
                border.color: Qt.alpha(ColorService.outlineVariant, 0.3)

                Rectangle {
                    id: glowBg
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 44
                    radius: 12
                    color: Qt.rgba(notif.appAccent.r, notif.appAccent.g, notif.appAccent.b, 0.12)

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

                    Image {
                        id: iconImg
                        anchors.fill: parent
                        anchors.margins: 4
                        source: {
                            var c = notif.iconCandidates
                            var idx = notif.iconCandidateIdx
                            if (c.length === 0 || idx >= c.length) return ""
                            return c[idx]
                        }
                        sourceSize.width: 28
                        sourceSize.height: 28
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                        asynchronous: true
                        onStatusChanged: {
                            if (status === Image.Error && notif.iconCandidateIdx < notif.iconCandidates.length - 1) {
                                notif.iconCandidateIdx++
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: iconImg.status !== Image.Ready
                        text: Utils.findSuitableIcon(notif.title)
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
