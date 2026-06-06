import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

Item {
    id: root

    property bool showOsd: false
    property string osdType: ""
    property int osdValue: 0
    property string osdIcon: ""
    property int _lastVolume: -1
    property int _lastBrightness: -1

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: exitAnim.start()
    }

    NumberAnimation {
        id: entryAnim
        target: osdRect
        property: "opacity"
        from: 0; to: 1
        duration: 150
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: exitAnim
        target: osdRect
        property: "opacity"
        to: 0
        duration: 200
        easing.type: Easing.InCubic
        onFinished: root.showOsd = false
    }

    function trigger(type, value, icon) {
        root.osdType = type
        root.osdValue = value
        root.osdIcon = icon

        if (root.showOsd) {
            hideTimer.restart()
            return
        }

        root.showOsd = true
        osdRect.opacity = 1
        entryAnim.start()
        hideTimer.restart()
    }

    Connections {
        target: VolumeService
        function onVolumePercentChanged() {
            var v = VolumeService.volumePercent
            if (v !== root._lastVolume) {
                var icon = v === 0 ? "\uF6A9" : (v < 50 ? "\uF027" : "\uF028")
                root.trigger("volume", v, icon)
            }
            root._lastVolume = v
        }
    }

    Connections {
        target: BrightnessService
        function onBrightnessPercentChanged() {
            var b = BrightnessService.brightnessPercent
            if (b !== root._lastBrightness) {
                root.trigger("brightness", b, "\uF183")
            }
            root._lastBrightness = b
        }
    }

    Rectangle {
        id: osdRect
        visible: root.showOsd
        width: 200
        height: 60
        radius: 16
        color: ColorService.surfaceContainerHigh
        border.width: 1
        border.color: Qt.alpha(ColorService.outlineVariant, 0.3)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Rectangle {
                width: 36
                height: 36
                radius: 10
                color: Qt.alpha(ColorService.primary, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: root.osdIcon
                    color: ColorService.primary
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: root.osdType === "volume" ? "Volume" : "Brightness"
                    color: ColorService.surfaceVariantText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 4
                    radius: 2
                    color: ColorService.surfaceContainerHighest

                    Rectangle {
                        width: parent.width * (root.osdValue / 100)
                        height: parent.height
                        radius: parent.radius
                        color: ColorService.primary

                        Behavior on width {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            Text {
                text: root.osdValue + "%"
                color: ColorService.surfaceText
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
            }
        }
    }
}
