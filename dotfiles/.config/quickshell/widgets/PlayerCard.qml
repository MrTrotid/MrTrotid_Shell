import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    property MprisPlayer player: null
    property list<var> visualizerPoints: []
    property bool isPlaying: player?.isPlaying ?? false
    property string trackTitle: player?.trackTitle ?? "No media"
    property string trackArtist: player?.trackArtist ?? ""
    property string trackArtUrl: player?.trackArtUrl ?? ""
    property real position: player?.position ?? 0
    property real length: player?.length ?? 0

    property string artCacheDir: Quickshell.configPath + "/cache/art"
    property string artFileName: Qt.md5(trackArtUrl)
    property string artFilePath: artCacheDir + "/" + artFileName
    property bool artDownloaded: false

    onTrackArtUrlChanged: downloadArt()

    function downloadArt() {
        if (!trackArtUrl || trackArtUrl === "") {
            artDownloaded = false
            return
        }
        if (trackArtUrl.startsWith("file://")) {
            artFilePath = trackArtUrl.replace("file://", "")
            artDownloaded = true
            return
        }
        Quickshell.execDetached(["mkdir", "-p", artCacheDir])
        artDownloadProc.running = true
    }

    Process {
        id: artDownloadProc
        command: ["bash", "-c", `[ -f "${artFilePath}" ] || curl -sSL "${trackArtUrl}" -o "${artFilePath}"`]
        onExited: artDownloaded = true
    }

    ColorQuantizer {
        id: colorQuantizer
        source: artDownloaded ? Qt.resolvedUrl(artFilePath) : ""
        depth: 0
        rescaleSize: 1
    }

    implicitHeight: 120
    implicitWidth: 320

    Rectangle {
        anchors.fill: parent
        radius: 12
        clip: true

        Image {
            id: artBlurBg
            anchors.fill: parent
            source: artDownloaded ? Qt.resolvedUrl(artFilePath) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: artDownloaded && artFilePath !== ""

            Rectangle {
                anchors.fill: parent
                color: "#80000000"
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                Layout.alignment: Qt.AlignVCenter
                radius: 8
                color: "#2a2a3e"

                Image {
                    anchors.fill: parent
                    source: artDownloaded ? Qt.resolvedUrl(artFilePath) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: artDownloaded && artFilePath !== ""
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰓇"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 28
                    color: "#ffffff"
                    visible: !artDownloaded || artFilePath === ""
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: 14
                    color: Qt.rgba(0, 0, 0, 0.5)

                    Text {
                        anchors.centerIn: parent
                        text: root.isPlaying ? "" : ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.player) root.player.togglePlaying()
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: root.trackTitle
                    color: "#ffffff"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    Layout.fillWidth: true
                    text: root.trackArtist
                    color: "#aaaaaa"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: "#cccccc"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.player) root.player.previous()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        radius: 2
                        color: "#3a3a5e"

                        Rectangle {
                            width: parent.width * (root.length > 0 ? root.position / root.length : 0)
                            height: parent.height
                            radius: 2
                            color: "#7c3aed"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.player && root.length > 0) {
                                    root.player.position = mouseX / width * root.length
                                }
                            }
                        }
                    }

                    Text {
                        text: ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: "#cccccc"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.player) root.player.next()
                            }
                        }
                    }
                }
            }
        }
    }
}
