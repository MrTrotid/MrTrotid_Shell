import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../services"
import ".."

Item {
    id: window

    Caching { id: paths }

    property bool initialFocusSet: false
    property int visibleItemCount: -1
    property int scrollAccum: 0
    property real scrollThreshold: 300

    property string currentFilter: "All"
    property string targetWallName: ""
    property var colorMap: ({})
    property int cacheVersion: 0
    property bool isApplying: false
    property bool isModelChanging: false
    property bool allowAddAnimation: false

    Timer {
        id: applyUnlockTimer
        interval: 250
        onTriggered: window.isApplying = false
    }

    property bool isStartup: localFolderModel.status === FolderListModel.Loading
    property bool isReady: visible && localFolderModel.status === FolderListModel.Ready

    property bool isFilterAnimating: false
    Timer {
        id: filterAnimationTimer
        interval: 800
        onTriggered: window.isFilterAnimating = false
    }

    property bool isItemAnimating: false
    Timer {
        id: itemAnimationTimer
        interval: 500
        onTriggered: window.isItemAnimating = false
    }

    property string currentNotification: {
        if (isLoading) return "Generating thumbnails...";
        if (visibleItemCount === 0) return "No wallpapers found";
        if (currentFilter === "All") return "";
        return currentFilter;
    }
    property bool showNotification: !isStartup && currentNotification !== ""
    property bool isLoading: localFolderModel.status === FolderListModel.Loading

    readonly property var filterData: [
        { name: "All", hex: "", label: "All" },
        { name: "Red", hex: "#FF4500", label: "" },
        { name: "Orange", hex: "#FFA500", label: "" },
        { name: "Yellow", hex: "#FFD700", label: "" },
        { name: "Green", hex: "#32CD32", label: "" },
        { name: "Blue", hex: "#1E90FF", label: "" },
        { name: "Purple", hex: "#8A2BE2", label: "" },
        { name: "Pink", hex: "#FF69B4", label: "" },
        { name: "Monochrome", hex: "#A9A9A9", label: "" }
    ]

    readonly property string thumbDir: "file://" + paths.getCacheDir("wallpaper_picker") + "/thumbs"
    readonly property string srcDir: {
        const dir = Quickshell.env("WALLPAPER_DIR")
        return (dir && dir !== "") ? dir : Quickshell.env("HOME") + "/.config/wallpapers"
    }

    readonly property var transitions: ["simple", "fade", "left", "right", "top", "bottom", "wipe", "grow", "center", "outer", "wave"]

    readonly property real itemWidth: 400
    readonly property real itemHeight: 420
    readonly property real borderWidth: 3
    readonly property real spacing: 10
    readonly property real skewFactor: -0.35

    Timer { id: scrollThrottle; interval: 150 }

    function getCleanName(name) {
        if (!name) return "";
        return String(name);
    }

    function applyWallpaper(safeFileName) {
        if (!safeFileName || window.isApplying) return;
        window.isApplying = true;
        applyUnlockTimer.restart();
        window.targetWallName = safeFileName;

        const escapeBash = (str) => String(str).replace(/(["\\$`])/g, '\\$1');
        const originalFile = srcDir + "/" + safeFileName;
        const thumbFile = paths.getCacheDir("wallpaper_picker") + "/thumbs/" + safeFileName;

        const escOriginal = escapeBash(originalFile);
        const escThumb = escapeBash(thumbFile);

        const script = "cp \"" + escThumb + "\" " + paths.getCacheDir("wallpaper_picker") + "/current_wallpaper.png || true\n"
            + "killall swaybg 2>/dev/null\n"
            + "nohup swaybg -i \"" + escOriginal + "\" -m fill >/dev/null 2>&1 & disown\n"
            + "(matugen image \"" + escThumb + "\" --prefer darkness 2>/dev/null || true)"

        Quickshell.execDetached(["bash", "-c", script]);
    }

    function getHexBucket(hexStr) {
        if (!hexStr) return "Monochrome";
        hexStr = String(hexStr).trim().replace(/#/g, '');
        if (hexStr.length !== 6) return "Monochrome";

        let r = parseInt(hexStr.substring(0,2), 16) / 255;
        let g = parseInt(hexStr.substring(2,4), 16) / 255;
        let b = parseInt(hexStr.substring(4,6), 16) / 255;
        if (isNaN(r) || isNaN(g) || isNaN(b)) return "Monochrome";

        let max = Math.max(r, g, b), min = Math.min(r, g, b);
        let d = max - min;
        let h = 0;
        let s = max === 0 ? 0 : d / max;
        let v = max;

        if (max !== min) {
            if (max === r) h = (g - b) / d + (g < b ? 6 : 0);
            else if (max === g) h = (b - r) / d + 2;
            else h = (r - g) / d + 4;
            h /= 6;
        }
        h = h * 360;

        if (s < 0.05 || v < 0.08) return "Monochrome";
        if (h >= 345 || h < 15) return "Red";
        if (h >= 15 && h < 45) return "Orange";
        if (h >= 45 && h < 75) return "Yellow";
        if (h >= 75 && h < 165) return "Green";
        if (h >= 165 && h < 260) return "Blue";
        if (h >= 260 && h < 315) return "Purple";
        if (h >= 315 && h < 345) return "Pink";
        return "Monochrome";
    }

    function checkItemMatchesFilter(fileName, cv, filter) {
        if (filter === "All") return true;
        let hexColor = colorMap[String(fileName)];
        if (!hexColor) return filter === "Monochrome";
        return getHexBucket(hexColor) === filter;
    }

    function triggerColorExtraction() {
        const extractScript = "COLOR_DIR=\"" + paths.getCacheDir("wallpaper_picker") + "/colors_markers\"\n"
            + "THUMBS=\"" + paths.getCacheDir("wallpaper_picker") + "/thumbs\"\n"
            + "mkdir -p \"$COLOR_DIR\"\n"
            + "if command -v magick &> /dev/null; then CMD=\"magick\"; else CMD=\"convert\"; fi\n"
            + "for file in \"$THUMBS\"/*; do\n"
            + "  if [ -f \"$file\" ]; then\n"
            + "    filename=$(basename \"$file\")\n"
            + "    found=0\n"
            + "    for marker in \"$COLOR_DIR/$filename\"_HEX_*; do if [ -e \"$marker\" ]; then found=1; break; fi; done\n"
            + "    if [ $found -eq 0 ]; then\n"
            + "      hex=$($CMD \"$file\" -modulate 100,200 -resize \"1x1^\" -gravity center -extent 1x1 -depth 8 -format \"%[hex:p{0,0}]\" info:- 2>/dev/null | grep -oE '[0-9A-Fa-f]{6}' | head -n 1)\n"
            + "      if [ -n \"$hex\" ]; then touch \"$COLOR_DIR/$filename\"_HEX_$hex; fi\n"
            + "    fi\n"
            + "  fi\n"
            + "done"
        Quickshell.execDetached(["bash", "-c", extractScript]);
    }

    FolderListModel {
        id: markerModel
        folder: "file://" + paths.getCacheDir("wallpaper_picker") + "/colors_markers"
        showDirs: false
        nameFilters: ["*_HEX_*"]
        onCountChanged: window.processMarkers()
        onStatusChanged: { if (status === FolderListModel.Ready) window.processMarkers() }
    }

    function processMarkers() {
        let newMap = {};
        for (let i = 0; i < markerModel.count; i++) {
            let markerName = markerModel.get(i, "fileName") || "";
            if (!markerName) continue;
            let splitIdx = markerName.lastIndexOf("_HEX_");
            if (splitIdx !== -1) {
                let fName = markerName.substring(0, splitIdx);
                let hexCode = markerName.substring(splitIdx + 5);
                newMap[fName] = "#" + hexCode;
            }
        }
        colorMap = newMap;
        cacheVersion++;
        updateVisibleCount();
    }

    function updateVisibleCount() {
        let count = 0;
        for (let i = 0; i < localProxyModel.count; i++) {
            let fname = localProxyModel.get(i).fileName || "";
            if (checkItemMatchesFilter(fname, cacheVersion, currentFilter)) count++;
        }
        visibleItemCount = count;
    }

    function stepToNextValidIndex(direction) {
        if (!localProxyModel || localProxyModel.count === 0) return;
        let start = view.currentIndex;
        let found = -1;

        if (direction === 1) {
            for (let i = start + 1; i < localProxyModel.count; i++) {
                let fname = localProxyModel.get(i).fileName || "";
                if (checkItemMatchesFilter(fname, cacheVersion, currentFilter)) { found = i; break; }
            }
        } else {
            for (let i = start - 1; i >= 0; i--) {
                let fname = localProxyModel.get(i).fileName || "";
                if (checkItemMatchesFilter(fname, cacheVersion, currentFilter)) { found = i; break; }
            }
        }

        if (found !== -1) {
            view.currentIndex = found;
        } else {
            let current = start;
            for (let i = 0; i < localProxyModel.count; i++) {
                current = (current + direction + localProxyModel.count) % localProxyModel.count;
                let fname = localProxyModel.get(current).fileName || "";
                if (checkItemMatchesFilter(fname, cacheVersion, currentFilter)) {
                    view.currentIndex = current;
                    return;
                }
            }
        }
    }

    function applyFilters() {
        if (!localProxyModel || localProxyModel.count === 0) return;
        let firstValid = -1;
        for (let i = 0; i < localProxyModel.count; i++) {
            let fname = localProxyModel.get(i).fileName || "";
            if (checkItemMatchesFilter(fname, cacheVersion, currentFilter)) {
                if (firstValid === -1) firstValid = i;
                if (targetWallName !== "" && getCleanName(fname) === getCleanName(targetWallName)) {
                    executeFocusRestore(i, true);
                    return;
                }
            }
        }
        if (firstValid !== -1) executeFocusRestore(firstValid, true);
        updateVisibleCount();
    }

    function executeFocusRestore(targetIndex, requirePositioning) {
        if (targetIndex < 0 || targetIndex >= localProxyModel.count) return;
        isModelChanging = true;
        if (requirePositioning) { view.forceLayout(); view.positionViewAtIndex(targetIndex, ListView.Center); }
        view.currentIndex = targetIndex;
        isModelChanging = false;
        initialFocusSet = true;
        allowAddAnimationTimer.restart();
    }

    Timer { id: allowAddAnimationTimer; interval: 600; onTriggered: window.allowAddAnimation = true }

    function tryFocus() {
        if (initialFocusSet) return;
        if (localProxyModel.count > 0) {
            let foundIndex = -1;
            if (targetWallName !== "") {
                for (let i = 0; i < localProxyModel.count; i++) {
                    let fname = localProxyModel.get(i).fileName || "";
                    if (getCleanName(fname) === getCleanName(targetWallName)) { foundIndex = i; break; }
                }
            }
            executeFocusRestore(foundIndex !== -1 ? foundIndex : 0, true);
        }
    }

    ListModel { id: localProxyModel }

    FolderListModel {
        id: localFolderModel
        folder: window.thumbDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif"]
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: window.syncLocalModel()
        onStatusChanged: { if (status === FolderListModel.Ready) window.syncLocalModel() }
    }

    property int _localSyncedCount: 0

    function syncLocalModel() {
        let folderCount = localFolderModel.count;
        if (folderCount < _localSyncedCount) {
            localProxyModel.clear();
            _localSyncedCount = 0;
        }
        if (folderCount > _localSyncedCount) {
            let batch = [];
            for (let i = _localSyncedCount; i < folderCount; i++) {
                let fn = localFolderModel.get(i, "fileName");
                let fu = localFolderModel.get(i, "fileUrl");
                if (fn !== undefined) batch.push({ "fileName": fn, "fileUrl": String(fu) });
            }
            if (batch.length > 0) localProxyModel.append(batch);
            _localSyncedCount = folderCount;
        }
        if (currentFilter !== "All") updateVisibleCount();
        if (!initialFocusSet && localProxyModel.count > 0) tryFocus();
    }

    onCurrentFilterChanged: {
        isFilterAnimating = true;
        filterAnimationTimer.restart();
        isModelChanging = true;
        Qt.callLater(() => {
            view.forceActiveFocus();
            applyFilters();
            isModelChanging = false;
        });
    }

    Shortcut { sequence: "Left"; enabled: !window.isApplying; onActivated: stepToNextValidIndex(-1) }
    Shortcut { sequence: "Right"; enabled: !window.isApplying; onActivated: stepToNextValidIndex(1) }
    Shortcut { sequence: "Return"; enabled: !window.isApplying; onActivated: {
        if (view.currentIndex >= 0 && view.currentIndex < localProxyModel.count) {
            let fname = localProxyModel.get(view.currentIndex).fileName;
            if (fname) applyWallpaper(String(fname));
        }
    }}
    Shortcut { sequence: "Escape"; enabled: !window.isApplying; onActivated: window.closed() }

    signal closed()

    // ═══════════════════════════════════════════════════════════════
    //  BLUR BACKGROUND
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(ColorService.surfaceContainer.r, ColorService.surfaceContainer.g, ColorService.surfaceContainer.b, 0.65)
        z: -1
    }

    // ═══════════════════════════════════════════════════════════════
    //  CAROUSEL LISTVIEW
    // ═══════════════════════════════════════════════════════════════
    ListView {
        id: view
        anchors.fill: parent
        opacity: window.isReady ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }

        spacing: 0
        orientation: ListView.Horizontal
        clip: false
        interactive: false
        cacheBuffer: 2000

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width / 2) - ((window.itemWidth * 1.5 + window.spacing) / 2)
        preferredHighlightEnd: (width / 2) + ((window.itemWidth * 1.5 + window.spacing) / 2)
        highlightMoveDuration: initialFocusSet ? 500 : 0
        focus: true

        onCurrentIndexChanged: {
            window.isItemAnimating = true;
            itemAnimationTimer.restart();
        }

        add: Transition {
            enabled: window.allowAddAnimation
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.5; to: 1; duration: 400; easing.type: Easing.OutBack }
            }
        }
        addDisplaced: Transition {
            enabled: window.allowAddAnimation
            NumberAnimation { property: "x"; duration: 400; easing.type: Easing.OutCubic }
        }

        header: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2)) }
        footer: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2)) }

        model: localProxyModel

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                if (window.isApplying) { wheel.accepted = true; return; }
                if (scrollThrottle.running) { wheel.accepted = true; return; }
                let dx = wheel.angleDelta.x;
                let dy = wheel.angleDelta.y;
                let delta = Math.abs(dx) > Math.abs(dy) ? dx : dy;
                scrollAccum += delta;
                if (Math.abs(scrollAccum) >= scrollThreshold) {
                    stepToNextValidIndex(scrollAccum > 0 ? -1 : 1);
                    scrollAccum = 0;
                    scrollThrottle.start();
                }
                wheel.accepted = true;
            }
        }

        delegate: Item {
            id: delegateRoot

            required property int index
            required property string fileName
            required property string fileUrl

            readonly property string safeFileName: fileName !== undefined ? String(fileName) : ""
            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property bool matchesFilter: window.checkItemMatchesFilter(safeFileName, window.cacheVersion, window.currentFilter)

            readonly property real targetWidth: isCurrent ? (window.itemWidth * 1.5) : (window.itemWidth * 0.5)
            readonly property real targetHeight: isCurrent ? (window.itemHeight + 30) : window.itemHeight

            width: matchesFilter ? (targetWidth + window.spacing) : 0
            visible: width > 0.1 || opacity > 0.01
            opacity: matchesFilter ? (isCurrent ? 1.0 : 0.6) : 0.0
            scale: matchesFilter ? 1.0 : 0.5
            height: matchesFilter ? targetHeight : 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 15
            z: isCurrent ? 10 : 1

            Behavior on scale { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
            Behavior on width { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
            Behavior on height { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
            Behavior on opacity { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }

            Item {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: ((window.itemHeight - height) / 2) * window.skewFactor
                width: parent.width > 0 ? parent.width * (targetWidth / (targetWidth + window.spacing)) : 0
                height: parent.height

                transform: Matrix4x4 {
                    property real s: window.skewFactor
                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: delegateRoot.matchesFilter && !window.isApplying
                    onClicked: {
                        view.currentIndex = delegateRoot.index;
                        window.applyWallpaper(delegateRoot.safeFileName);
                    }
                }

                Image {
                    anchors.fill: parent
                    source: delegateRoot.fileUrl !== undefined ? delegateRoot.fileUrl : ""
                    sourceSize: Qt.size(1, 1)
                    fillMode: Image.Stretch
                    visible: true
                    asynchronous: true
                }

                Item {
                    anchors.fill: parent
                    anchors.margins: window.borderWidth
                    clip: true

                    Image {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -50
                        width: (window.itemWidth * 1.5) + ((window.itemHeight + 30) * Math.abs(window.skewFactor)) + 50
                        height: window.itemHeight + 30
                        fillMode: Image.PreserveAspectCrop
                        source: delegateRoot.fileUrl !== undefined ? delegateRoot.fileUrl : ""
                        asynchronous: true

                        transform: Matrix4x4 {
                            property real s: -window.skewFactor
                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }

                    Rectangle {
                        visible: delegateRoot.isCurrent
                        anchors.fill: parent
                        color: "transparent"
                        border.color: ColorService.primary
                        border.width: 2
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  FILTER BAR (top center)
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        id: filterBarBackground
        anchors.top: parent.top
        anchors.topMargin: window.isReady ? 180 : -100
        opacity: window.isReady ? 1.0 : 0.0
        Behavior on anchors.topMargin { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        anchors.horizontalCenter: parent.horizontalCenter
        z: 20
        height: 56
        width: filterRow.width + 24
        radius: 14
        color: Qt.rgba(ColorService.surfaceContainer.r, ColorService.surfaceContainer.g, ColorService.surfaceContainer.b, 0.90)
        border.color: ColorService.outlineVariant
        border.width: 1

        Row {
            id: filterRow
            anchors.centerIn: parent
            spacing: 12

            Rectangle {
                id: notifDrawer
                height: 44
                property real paddingLeft: showNotification ? 16 : 16
                property real targetWidth: showNotification ? Math.min(notifTextDrawer.implicitWidth + paddingLeft + 20, 300) : 0
                width: targetWidth
                visible: width > 0.1
                radius: 10
                clip: true
                anchors.verticalCenter: parent.verticalCenter
                color: showNotification ? ColorService.surfaceContainerHigh : "transparent"
                border.color: showNotification ? ColorService.outlineVariant : "transparent"
                border.width: 1

                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }

                Text {
                    id: notifTextDrawer
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 300 - 16 - 16)
                    text: window.currentNotification
                    color: ColorService.surfaceText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                    opacity: showNotification ? 0.9 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
                }
            }

            Repeater {
                model: window.filterData

                delegate: Item {
                    width: (modelData.name === "All") ? 44 : (modelData.hex === "" ? filterText.contentWidth + 24 : 36)
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: modelData.hex === ""
                                ? (window.currentFilter === modelData.name ? ColorService.surfaceContainerHigh : "transparent")
                                : modelData.hex
                        border.color: window.currentFilter === modelData.name ? ColorService.surfaceText : ColorService.outlineVariant
                        border.width: window.currentFilter === modelData.name ? 2 : 1
                        scale: window.currentFilter === modelData.name ? 1.15 : (filterMouse.containsMouse ? 1.08 : 1.0)

                        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                        Behavior on border.color { ColorAnimation { duration: 300 } }

                        Text {
                            id: filterText
                            visible: modelData.hex === "" && modelData.name !== "All"
                            text: modelData.label
                            anchors.centerIn: parent
                            color: window.currentFilter === modelData.name ? ColorService.surfaceText : ColorService.surfaceVariantText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.bold: window.currentFilter === modelData.name
                            Behavior on color { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
                        }

                        Canvas {
                            visible: modelData.name === "All"
                            width: 14; height: 14
                            anchors.centerIn: parent
                            property string activeColor: window.currentFilter === modelData.name ? ColorService.surfaceText : ColorService.surfaceVariantText

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = activeColor;
                                ctx.fillRect(0, 0, 6, 6);
                                ctx.fillRect(8, 0, 6, 6);
                                ctx.fillRect(0, 8, 6, 6);
                                ctx.fillRect(8, 8, 6, 6);
                            }
                        }
                    }

                    MouseArea {
                        id: filterMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !window.isApplying
                        onClicked: window.currentFilter = modelData.name
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  CLOSE BUTTON (top right)
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: window.isReady ? 180 : -100
        anchors.right: parent.right
        anchors.rightMargin: 20
        width: 36; height: 36; radius: 10
        opacity: window.isReady ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
        z: 20
        color: closeMa.containsMouse ? ColorService.error : ColorService.surfaceContainerHigh
        border.color: ColorService.outlineVariant
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "\uF00D"
            color: closeMa.containsMouse ? ColorService.errorText : ColorService.surfaceText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
        }

        MouseArea {
            id: closeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: window.closed()
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  BOTTOM CENTER STACK: count → name → apply (bottom up)
    // ═══════════════════════════════════════════════════════════════
    Text {
        id: countLabel
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 150
        anchors.horizontalCenter: parent.horizontalCenter
        text: localProxyModel.count > 0 ? (view.currentIndex + 1) + " / " + localProxyModel.count : "No wallpapers found"
        color: ColorService.surfaceVariantText
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        z: 20
    }

    Text {
        id: wallNameLabel
        anchors.bottom: countLabel.top
        anchors.bottomMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        text: localProxyModel.count > 0 && view.currentIndex >= 0 && view.currentIndex < localProxyModel.count
              ? (localProxyModel.get(view.currentIndex).fileName || "") : ""
        color: ColorService.surfaceText
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        elide: Text.ElideRight
        width: 400
        horizontalAlignment: Text.AlignHCenter
        z: 20
    }

    // ═══════════════════════════════════════════════════════════════
    //  APPLY BUTTON (above name)
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        id: applyBtn
        anchors.bottom: wallNameLabel.top
        anchors.bottomMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        width: applyRow.implicitWidth + 32
        height: 36
        radius: 18
        color: applyMa.containsMouse ? ColorService.primary : ColorService.surfaceContainerHigh
        border.color: ColorService.outlineVariant
        border.width: 1
        z: 20

        Behavior on color { ColorAnimation { duration: 200 } }

        Row {
            id: applyRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\uF005"
                color: applyMa.containsMouse ? ColorService.primaryText : ColorService.primary
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Apply Wallpaper"
                color: applyMa.containsMouse ? ColorService.primaryText : ColorService.primary
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: applyMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (localProxyModel.count > 0 && view.currentIndex >= 0 && view.currentIndex < localProxyModel.count) {
                    let fname = localProxyModel.get(view.currentIndex).fileName;
                    if (fname) window.applyWallpaper(String(fname));
                }
            }
        }
    }

    Component.onCompleted: {
        view.forceActiveFocus();
        processMarkers();
        triggerColorExtraction();
    }
}
