import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../services"

Item {
    id: root

    implicitWidth: 420

    readonly property color colLayer0: ColorService.surface
    readonly property color colLayer1: ColorService.surfaceContainer
    readonly property color colLayer2: ColorService.surfaceContainerHigh
    readonly property color colLayer3: ColorService.surfaceContainerHighest
    readonly property color colOnSurface: ColorService.surfaceText
    readonly property color colOnSurfaceVar: ColorService.surfaceVariantText
    readonly property color colSubtext: ColorService.surfaceVariantText
    readonly property color colPrimary: ColorService.primary
    readonly property color colPrimaryContainer: ColorService.primaryContainer
    readonly property color colOnPrimaryContainer: ColorService.primaryContainerText
    readonly property color colOutline: ColorService.outlineVariant

    property string filterText: ""
    property var gifResults: []
    property bool isLoading: false
    property string nextPos: ""

    // Tenor API key (free tier)
    readonly property string apiKey: "AIzaSyAyimkuYQYF_FXVALexPuGQctUWRURdCYQ"
    readonly property string baseUrl: "https://tenor.googleapis.com/v2"

    function close() {
        ShellState.closePopup()
    }

    function searchGifs(query, position) {
        if (query.trim() === "" && !position) {
            gifResults = [];
            return;
        }
        isLoading = true;
        var url = baseUrl + "/search?key=" + apiKey + "&q=" + encodeURIComponent(query) + "&limit=20&media_filter=gif,tinygif,mediumgif";
        if (position) url += "&pos=" + position;

        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    parseResponse(xhr.responseText);
                } else {
                    isLoading = false;
                }
            }
        };
        xhr.send();
    }

    function loadMore() {
        if (isLoading || !nextPos || filterText.trim() === "") return;
        searchGifs(filterText, nextPos);
    }

    function parseResponse(jsonStr) {
        try {
            var json = JSON.parse(jsonStr);
            if (!json || !json.results) {
                isLoading = false;
                return;
            }
            nextPos = json.next || "";
            var results = [];
            for (var i = 0; i < json.results.length; i++) {
                var item = json.results[i];
                var media = item.media_formats;
                if (media) {
                    var gifUrl = media.gif ? media.gif.url : "";
                    var tinyUrl = media.tinygif ? media.tinygif.url : gifUrl;
                    var medUrl = media.mediumgif ? media.mediumgif.url : gifUrl;
                    if (gifUrl) {
                        results.push({
                            url: gifUrl,
                            thumb: tinyUrl,
                            preview: medUrl,
                            title: item.title || item.content_description || ""
                        });
                    }
                }
            }
            // Append if loading more, otherwise replace
            if (nextPos && gifResults.length > 0) {
                var combined = gifResults.slice();
                for (var j = 0; j < results.length; j++) {
                    combined.push(results[j]);
                }
                gifResults = combined;
            } else {
                gifResults = results;
            }
        } catch (e) {
            console.log("GIF parse error:", e);
        }
        isLoading = false;
    }

    function copyGif(url) {
        copyProc.command = ["sh", "-c", "printf '%s' '" + url + "' | wl-copy"];
        copyProc.running = true;
        close();
    }

    Process {
        id: copyProc
        running: false
    }

    // Search timer to debounce
    Timer {
        id: searchTimer
        interval: 350
        repeat: false
        onTriggered: {
            nextPos = "";
            root.searchGifs(root.filterText, "");
        }
    }

    onFilterTextChanged: {
        searchTimer.restart();
    }

    // Main container
    Rectangle {
        anchors.fill: parent
        color: colLayer0
        topLeftRadius: 0
        bottomLeftRadius: 0
        topRightRadius: 20
        bottomRightRadius: 20

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            anchors.leftMargin: 16
            spacing: 12

            // ── Header ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 30; height: 30; radius: 9
                    color: colPrimaryContainer

                    Text {
                        anchors.centerIn: parent
                        text: "\uf03e"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: colOnPrimaryContainer
                    }
                }

                Text {
                    text: "GIFs"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    color: colOnSurface
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 24; height: 24; radius: 7
                    color: closeArea.containsMouse ? colLayer3 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: colOnSurfaceVar
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: close()
                    }
                }
            }

            // ── Search ──
            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 12
                color: gifSearch.activeFocus ? Qt.alpha(colPrimary, 0.1) : colLayer2
                border.width: gifSearch.activeFocus ? 1 : 0
                border.color: Qt.alpha(colPrimary, 0.35)

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "\uf002"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: gifSearch.activeFocus ? colPrimary : colSubtext
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 22

                        TextInput {
                            id: gifSearch
                            anchors.fill: parent
                            color: colOnSurface
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            clip: true
                            selectByMouse: true
                            selectionColor: Qt.alpha(colPrimary, 0.3)
                            focus: true
                            cursorVisible: false
                            verticalAlignment: TextInput.AlignVCenter

                            onActiveFocusChanged: {
                                if (activeFocus) cursorVisible = true;
                            }

                            onTextChanged: root.filterText = text

                            Keys.onEscapePressed: root.close()
                        }

                        Text {
                            visible: gifSearch.text === "" && !gifSearch.activeFocus
                            text: "Search GIFs..."
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: colSubtext
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Loading indicator
                    Text {
                        visible: root.isLoading
                        text: "\uf110"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: colPrimary

                        RotationAnimation on rotation {
                            running: root.isLoading
                            from: 0; to: 360
                            duration: 800
                            loops: Animation.Infinite
                        }
                    }
                }
            }

            // ── GIF Grid ──
            Rectangle {
                id: gifGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: colLayer1
                topLeftRadius: 14
                topRightRadius: 14
                bottomLeftRadius: 14
                bottomRightRadius: 14
                clip: true
                property int cols: Math.floor((width - 16) / 140)
                property real cellW: (width - 16) / Math.max(cols, 1)

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: root.gifResults.length === 0 && !root.isLoading
                    spacing: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignCenter
                        width: 48; height: 48; radius: 24
                        color: colLayer3

                        Text {
                            anchors.centerIn: parent
                            text: "\uf03e"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 20
                            color: colOnSurfaceVar
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignCenter
                        text: "Search for GIFs"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                        color: colOnSurfaceVar
                    }

                    Text {
                        Layout.alignment: Qt.AlignCenter
                        text: "Powered by Tenor"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: colSubtext
                    }
                }

                // Loading state
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: root.isLoading && root.gifResults.length === 0
                    spacing: 8

                    BusyIndicator {
                        Layout.alignment: Qt.AlignCenter
                        running: root.isLoading
                        width: 40; height: 40
                    }

                    Text {
                        Layout.alignment: Qt.AlignCenter
                        text: "Searching..."
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: colSubtext
                    }
                }

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    visible: root.gifResults.length > 0

                    Flickable {
                        contentHeight: gifFlow.childrenRect.height + 16

                        Flow {
                            id: gifFlow
                            width: parent.width
                            spacing: 8
                            padding: 0

                            Repeater {
                                model: root.gifResults

                                Rectangle {
                                    width: gifGrid.cellW - 8
                                    height: (gifGrid.cellW - 8) * 0.78
                                    radius: 10
                                    color: colLayer2
                                    clip: true

                                    AnimatedImage {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        source: modelData.url
                                        fillMode: Image.PreserveAspectFit
                                        playing: gifHover.containsMouse
                                        cache: true
                                        asynchronous: true
                                    }

                                    // Title overlay
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 24
                                        radius: 6
                                        color: Qt.alpha(colLayer0, 0.8)
                                        visible: gifHover.containsMouse

                                        Text {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            text: modelData.title || "Click to copy"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            color: colOnSurface
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    MouseArea {
                                        id: gifHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.copyGif(modelData.url)
                                    }
                                }
                            }
                        }

                        onContentYChanged: {
                            if (contentHeight - height - contentY < 200) {
                                root.loadMore();
                            }
                        }
                    }
                }
            }

            // ── Footer ──
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.gifResults.length + " GIFs"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: colSubtext
                    Layout.fillWidth: true
                }

                Text {
                    text: "Click to copy URL"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Qt.alpha(colSubtext, 0.5)
                }
            }
        }
    }

    function show() {
        filterText = "";
        gifSearch.text = "";
        gifSearch.cursorVisible = false;
        gifResults = [];
        nextPos = "";
        isLoading = false;
        Qt.callLater(function() {
            gifSearch.forceActiveFocus();
            gifSearch.cursorVisible = true;
        });
        Qt.callLater(function() {
            Qt.callLater(function() {
                gifSearch.forceActiveFocus();
                gifSearch.cursorVisible = true;
            });
        });
    }
}
