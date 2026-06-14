import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

FocusScope {
    id: root
    signal closed()

    implicitHeight: 72
    implicitWidth: bgRect.width

    property int currentIndex: 0
    property int totalItems: 7

    focus: true

    Component.onCompleted: forceActiveFocus()

    Keys.onLeftPressed: (event) => {
        currentIndex = (currentIndex - 1 + totalItems) % totalItems;
        event.accepted = true;
    }

    Keys.onRightPressed: (event) => {
        currentIndex = (currentIndex + 1) % totalItems;
        event.accepted = true;
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_H) {
            currentIndex = (currentIndex - 1 + totalItems) % totalItems;
            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            currentIndex = (currentIndex + 1) % totalItems;
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            executeItem(currentIndex);
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            ShellState.closePopup();
            root.closed();
            event.accepted = true;
        }
    }

    function close() {
        ShellState.closePopup();
        root.closed();
    }

    function executeItem(index) {
        switch(index) {
            case 0: close(); Qt.callLater(() => Quickshell.execDetached(["bash", "~/.config/scripts/screenshots/screenshot.sh", "full"])); break;
            case 1: close(); Qt.callLater(() => Quickshell.execDetached(["bash", "~/.config/scripts/screenshots/screenshot.sh", "region"])); break;
            case 2: close(); Qt.callLater(() => Quickshell.execDetached(["bash", "-c", "xdg-open $(xdg-user-dir PICTURES)/Screenshots"])); break;
            case 3: close(); Qt.callLater(() => Quickshell.execDetached(["bash", "~/.config/scripts/recording/recording.sh", "region"])); break;
            case 4: close(); Qt.callLater(() => Quickshell.execDetached(["bash", "~/.config/scripts/recording/recording.sh", "full"])); break;
            case 5: close(); Qt.callLater(() => Quickshell.execDetached(["bash", "-c", "xdg-open $(xdg-user-dir VIDEOS)/Recordings"])); break;
            case 6: close(); Qt.callLater(() => Quickshell.execDetached(["hyprpicker", "-a"])); break;
        }
    }

    // Background pill
    Rectangle {
        id: bgRect
        color: ColorService.surfaceContainerHigh
        radius: height / 2
        anchors.bottom: parent.bottom
        height: 64
        width: layout.implicitWidth + 40
        anchors.horizontalCenter: parent.horizontalCenter

        // Flatten bottom edge
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.radius
            color: ColorService.surfaceContainerHigh
        }

        // Tab highlight
        Rectangle {
            id: tabHighlight
            z: -1
            property real targetX: 0
            property real buttonWidth: 44

            x: targetX
            width: buttonWidth
            height: 44
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -2
            radius: 22
            color: ColorService.primary

            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Component.onCompleted: updatePosition()

            function updatePosition() {
                var child = layout.children[root.currentIndex]
                if (child) {
                    targetX = child.x + layout.x
                }
            }
        }

        // Buttons
        RowLayout {
            id: layout
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -2
            spacing: 8

            onXChanged: tabHighlight.updatePosition()

            Repeater {
                model: [
                    { icon: "\uF030", tip: "Full Screenshot" },
                    { icon: "\uF125", tip: "Region Screenshot" },
                    { icon: "\uF07B", tip: "Open Screenshots" },
                    { icon: "\uF03D", tip: "Record Region" },
                    { icon: "\uF130", tip: "Record Fullscreen" },
                    { icon: "\uF07B", tip: "Open Recordings" },
                    { icon: "\uF121", tip: "Color Picker" }
                ]

                delegate: Item {
                    id: toolBtn
                    required property int index
                    required property var modelData
                    width: 44
                    height: 44

                    property bool isActive: root.currentIndex === index

                    Rectangle {
                        anchors.fill: parent
                        radius: 22
                        color: toolBtn.isActive ? Qt.alpha(ColorService.primary, 0.15) : (btnMa.containsMouse ? Qt.alpha(ColorService.surfaceText, 0.08) : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: toolBtn.modelData.icon
                            color: toolBtn.isActive ? ColorService.primary : ColorService.surfaceText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                        }
                    }

                    MouseArea {
                        id: btnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            root.currentIndex = toolBtn.index
                            tabHighlight.updatePosition()
                        }
                        onClicked: root.executeItem(toolBtn.index)
                    }
                }
            }
        }
    }
}
