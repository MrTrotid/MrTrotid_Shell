import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"

Item {
    id: root

    function close() { ShellState.closePopup() }

    Process { id: shutdownProc; command: ["systemctl", "poweroff"] }
    Process { id: rebootProc; command: ["systemctl", "reboot"] }
    Process { id: logoutProc; command: ["loginctl", "terminate-user", Quickshell.env("USER")] }
    Process { id: hibernateProc; command: ["systemctl", "hibernate"] }
    Process { id: lockProc; command: ["loginctl", "lock-session"] }

    readonly property var actions: [
        { icon: "\uf011", label: "Shutdown", proc: shutdownProc },
        { icon: "\uf021", label: "Reboot",   proc: rebootProc },
        { icon: "\uf08b", label: "Logout",   proc: logoutProc },
        { icon: "\uf186", label: "Hibernate", proc: hibernateProc },
        { icon: "\uf023", label: "Lock",     proc: lockProc }
    ]

    // Full-screen dimmed background
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(ColorService.scrim, 0.6)

        MouseArea {
            anchors.fill: parent
            onClicked: close()
        }

        // Centered horizontal row of buttons
        Row {
            anchors.centerIn: parent
            spacing: 48

            Repeater {
                model: root.actions

                delegate: Item {
                    id: btn
                    width: 96
                    height: 96

                    property bool hovered: btnMouse.containsMouse

                    Rectangle {
                        anchors.centerIn: parent
                        width: 80
                        height: 80
                        radius: 40
                        color: btn.hovered ? ColorService.surfaceContainerHigh : ColorService.surfaceContainer
                        border.width: 2
                        border.color: btn.hovered ? Qt.alpha(ColorService.surfaceText, 0.35) : Qt.alpha(ColorService.surfaceText, 0.12)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 28
                            color: ColorService.surfaceText
                        }
                    }

                    // Label below icon
                    Text {
                        anchors.top: parent.bottom
                        anchors.topMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: ColorService.surfaceText
                        opacity: btn.hovered ? 1.0 : 0.7

                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modelData.proc.running = true;
                            close();
                        }
                    }
                }
            }
        }

        // Hint text at bottom
        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Click outside to cancel"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: Qt.alpha(ColorService.surfaceText, 0.35)
        }
    }
}
