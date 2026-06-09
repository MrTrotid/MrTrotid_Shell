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
    readonly property color colSecondaryContainer: ColorService.secondaryContainer
    readonly property color colOutline: ColorService.outlineVariant
    readonly property color colOnOutline: ColorService.outline

    property var clipItems: []
    property int selectedIndex: 0
    property string filterText: ""
    property var imageCache: ({})
    property string lastCopiedId: ""

    readonly property var filteredItems: {
        if (filterText === "") return clipItems;
        var lower = filterText.toLowerCase();
        var result = [];
        for (var i = 0; i < clipItems.length; i++) {
            if (clipItems[i].toLowerCase().indexOf(lower) !== -1)
                result.push(clipItems[i]);
        }
        return result;
    }

    function close() {
        ShellState.closePopup()
    }

    function refreshHistory() {
        _clipOutput = "";
        cliphistProc.running = true
    }

    function isImageEntry(entry) {
        if (entry.indexOf("[[ binary data") === -1) return false;
        return entry.indexOf("png") !== -1 || entry.indexOf("jpg") !== -1 || entry.indexOf("jpeg") !== -1 || entry.indexOf("svg") !== -1;
    }

    function getImagePreview(entry) {
        if (imageCache[entry] !== undefined) return imageCache[entry];
        var parts = entry.split("\t");
        var id = parts[0];
        var tmpPath = "/tmp/cliphist_" + id + ".png";
        imageDecodeProc.command = ["sh", "-c", "printf '%s' '" + id.replace(/'/g, "'\\''") + "' | cliphist decode > " + tmpPath + " 2>/dev/null && echo " + tmpPath];
        imageDecodeProc.entryToDecode = entry;
        imageDecodeProc.tmpPath = tmpPath;
        imageDecodeProc.running = true;
        return "";
    }

    function copySelected() {
        if (filteredItems.length === 0) return;
        var idx = Math.min(selectedIndex, filteredItems.length - 1);
        var item = filteredItems[idx];
        if (!item) return;
        var parts = item.split("\t");
        var id = parts[0];
        lastCopiedId = id;
        decodeProc.command = ["sh", "-c", "printf '%s' '" + id.replace(/'/g, "'\\''") + "' | cliphist decode | wl-copy"];
        decodeProc.running = true;
        close();
    }

    property bool hasLoaded: false
    property string _clipOutput: ""

    Process {
        id: cliphistProc
        running: false
        command: ["sh", "-c", "cliphist list"]
        stdout: SplitParser {
            onRead: data => {
                _clipOutput += data + "\n";
            }
        }
        onRunningChanged: {
            if (!running) {
                // Parse all at once
                var lines = _clipOutput.trim().split("\n");
                var items = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    if (line === "") continue;
                    var parts = line.split("\t");
                    if (parts[0] === root.lastCopiedId) continue;
                    items.push(line);
                }
                // Only update if content actually changed
                var changed = items.length !== root.clipItems.length;
                if (!changed) {
                    for (var j = 0; j < items.length; j++) {
                        if (items[j] !== root.clipItems[j]) { changed = true; break; }
                    }
                }
                if (changed) {
                    root.clipItems = items;
                }
                _clipOutput = "";
                root.hasLoaded = true;
            }
        }
    }

    Process {
        id: decodeProc
        running: false
    }

    Process {
        id: imageDecodeProc
        running: false
        property string entryToDecode: ""
        property string tmpPath: ""
        stdout: SplitParser {
            onRead: data => {
                if (data !== "" && imageDecodeProc.entryToDecode !== "") {
                    root.imageCache[imageDecodeProc.entryToDecode] = imageDecodeProc.tmpPath;
                    var tmp = root.clipItems.slice();
                    root.clipItems = [];
                    root.clipItems = tmp;
                }
            }
        }
    }

    Component.onCompleted: refreshHistory()

    // Main container — flush with left edge, no border gap
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
                        text: "\uf0ca"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: colOnPrimaryContainer
                    }
                }

                Text {
                    text: "Clipboard"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    color: colOnSurface
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 24; height: 24; radius: 7
                    color: refreshArea.containsMouse ? colLayer3 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf021"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: colOnSurfaceVar
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: refreshHistory()
                    }
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
                color: searchInput.activeFocus ? Qt.alpha(colPrimary, 0.1) : colLayer2
                border.width: searchInput.activeFocus ? 1 : 0
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
                        color: searchInput.activeFocus ? colPrimary : colSubtext
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 22

                        TextInput {
                            id: searchInput
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

                            onTextChanged: {
                                root.filterText = text;
                                root.selectedIndex = 0;
                            }

                            Keys.onDownPressed: {
                                if (root.selectedIndex < root.filteredItems.length - 1)
                                    root.selectedIndex++;
                            }
                            Keys.onUpPressed: {
                                if (root.selectedIndex > 0)
                                    root.selectedIndex--;
                            }
                            Keys.onReturnPressed: root.copySelected()
                            Keys.onEnterPressed: root.copySelected()
                            Keys.onEscapePressed: root.close()
                        }

                        Text {
                            visible: searchInput.text === "" && !searchInput.activeFocus
                            text: "Search clipboard..."
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: colSubtext
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        visible: searchInput.text !== ""
                        width: 18; height: 18; radius: 9
                        color: clearArea.containsMouse ? colLayer3 : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf00d"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                            color: colSubtext
                        }

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // ── Clipboard List ──
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: colLayer1
                topLeftRadius: 14
                topRightRadius: 14
                bottomLeftRadius: 14
                bottomRightRadius: 14
                clip: true

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: root.filteredItems.length === 0
                    spacing: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignCenter
                        width: 48; height: 48; radius: 24
                        color: colLayer3

                        Text {
                            anchors.centerIn: parent
                            text: "\uf0ca"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 20
                            color: colOnSurfaceVar
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignCenter
                        text: "No items"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                        color: colOnSurfaceVar
                    }

                    Text {
                        Layout.alignment: Qt.AlignCenter
                        text: "Copy something to begin"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: colSubtext
                    }
                }

                // ListView
                ListView {
                    id: clipList
                    anchors.fill: parent
                    anchors.margins: 6
                    visible: root.filteredItems.length > 0
                    model: root.filteredItems
                    currentIndex: root.selectedIndex
                    highlightFollowsCurrentItem: false
                    clip: true
                    spacing: 2
                    pixelAligned: true

                    // Scroll 3 items at a time
                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: function(event) {
                            var itemHeight = 42; // approximate delegate height
                            var scrollAmount = itemHeight * 3;
                            var maxY = clipList.contentHeight - clipList.height;
                            clipList.contentY = Math.max(0, Math.min(maxY, clipList.contentY - event.angleDelta.y / 120 * scrollAmount));
                        }
                    }

                    delegate: Rectangle {
                        id: delegateRoot
                        width: clipList.width
                        height: isImage ? 80 : 40
                        radius: 10
                        color: {
                            if (index === clipList.currentIndex) return colPrimaryContainer;
                            if (delegateHover.containsMouse) return colLayer2;
                            return "transparent";
                        }

                        property bool isImage: root.isImageEntry(root.filteredItems[index] || "")
                        property string imageSrc: {
                            var entry = root.filteredItems[index] || "";
                            if (!root.isImageEntry(entry)) return "";
                            return root.imageCache[entry] || "";
                        }

                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            // Image preview or icon
                            Rectangle {
                                width: delegateRoot.isImage ? 68 : 26
                                height: delegateRoot.isImage ? 68 : 26
                                radius: delegateRoot.isImage ? 8 : 7
                                color: delegateRoot.isImage ? "transparent" : Qt.alpha(colPrimary, delegateRoot === clipList.currentItem ? 0.2 : 0.08)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: delegateRoot.imageSrc !== "" ? "file://" + delegateRoot.imageSrc : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: delegateRoot.isImage && source != ""
                                    asynchronous: true
                                    cache: false

                                    BusyIndicator {
                                        anchors.centerIn: parent
                                        running: delegateRoot.isImage && delegateRoot.imageSrc === ""
                                        width: 24; height: 24
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !delegateRoot.isImage
                                    text: "\uf15c"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    color: colPrimary
                                }
                            }

                            // Content
                            Text {
                                Layout.fillWidth: true
                                text: {
                                    var item = root.filteredItems[index] || "";
                                    if (root.isImageEntry(item)) {
                                        var match = item.match(/(\d+)x(\d+)/);
                                        if (match) return "Image " + match[1] + "x" + match[2];
                                        return "Image";
                                    }
                                    var parts = item.split("\t");
                                    var preview = parts.length > 1 ? parts[1] : parts[0];
                                    if (preview.length > 38) preview = preview.substring(0, 38) + "...";
                                    return preview;
                                }
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: index === clipList.currentIndex ? colOnPrimaryContainer : colOnSurface
                                elide: Text.ElideRight
                                maximumLineCount: delegateRoot.isImage ? 1 : 2
                                wrapMode: Text.NoWrap
                            }

                            Text {
                                visible: index === clipList.currentIndex
                                text: "\uf00c"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: colPrimary
                            }
                        }

                        MouseArea {
                            id: delegateHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = index;
                                root.copySelected();
                            }
                        }

                        Component.onCompleted: {
                            if (isImage && imageSrc === "") {
                                root.getImagePreview(root.filteredItems[index] || "");
                            }
                        }
                    }

                    highlight: Rectangle { color: "transparent" }

                    Keys.onDownPressed: {
                        if (root.selectedIndex < root.filteredItems.length - 1)
                            root.selectedIndex++;
                    }
                    Keys.onUpPressed: {
                        if (root.selectedIndex > 0)
                            root.selectedIndex--;
                    }
                    Keys.onReturnPressed: root.copySelected()
                    Keys.onEnterPressed: root.copySelected()
                    Keys.onEscapePressed: root.close()
                }
            }

            // ── Footer ──
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.filteredItems.length + " items"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: colSubtext
                    Layout.fillWidth: true
                }

                Text {
                    text: "\u21B5 copy"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Qt.alpha(colSubtext, 0.5)
                }
            }
        }
    }

    function show() {
        if (!hasLoaded) {
            refreshHistory();
        }
        searchInput.text = "";
        searchInput.cursorVisible = false;
        root.selectedIndex = 0;
        Qt.callLater(function() {
            searchInput.forceActiveFocus();
            searchInput.cursorVisible = true;
        });
        Qt.callLater(function() {
            Qt.callLater(function() {
                searchInput.forceActiveFocus();
                searchInput.cursorVisible = true;
            });
        });
    }
}