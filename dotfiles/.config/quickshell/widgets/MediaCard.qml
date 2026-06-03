import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    property var serviceContext
    property var player: (Mpris.mprisList ?? [])[0] ?? null
    property list<var> visualizerPoints

    Process {
        id: cavaProc
        running: root.visible
        command: ["sh", "-c", "cava -p \"$HOME/.config/quickshell/custom/cava/config\""]
        stdout: SplitParser {
            onRead: data => {
                var points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    onVisibleChanged: {
        cavaProc.running = root.visible
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PlayerCard {
            id: playerCard
            serviceContext: serviceContext
            Layout.fillWidth: true
            Layout.preferredHeight: 120
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "transparent"
            clip: true

            WaveVisualizer {
                anchors.fill: parent
                points: root.visualizerPoints
                color: "#7c3aed"
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const list = Mpris.mprisList
            if (list && list.length > 0 && !root.player)
                root.player = list[0]
        }
    }
}
