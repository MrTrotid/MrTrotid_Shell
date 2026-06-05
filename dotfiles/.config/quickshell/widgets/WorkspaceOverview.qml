import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Rectangle {
    id: root
    property var serviceContext
    color: "#1a2120"
    radius: 20

    property var workspaces: []
    property int activeWsId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: wsPoll.running = true
    }

    Process {
        id: wsPoll
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(text.trim())
                    root.workspaces = arr.sort((a, b) => a.id - b.id)
                } catch(e) {}
            }
        }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            activeWsId = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 6
        padding: 8

        Repeater {
            model: root.workspaces

            Rectangle {
                required property var modelData
                property bool isActive: modelData.id === root.activeWsId
                property bool hasWindows: modelData.windows > 0

                width: isActive ? 40 : 12
                height: 12
                radius: 6
                color: isActive ? "#81d5ca" : hasWindows ? "#303635" : "#252a29"

                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
                }

                Text {
                    anchors.centerIn: parent
                    visible: isActive
                    text: modelData.id
                    color: "#003732"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
            }
        }
    }

    function show() {}
}
