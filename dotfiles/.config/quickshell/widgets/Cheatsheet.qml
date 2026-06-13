import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    readonly property color _base:    "#131514"
    readonly property color _crust:   "#1c1e1d"
    readonly property color _surf1:   "#232524"
    readonly property color _surf2:   "#2b2d2c"
    readonly property color _surf3:   "#353937"
    readonly property color _text:    "#c5cbc9"
    readonly property color _sub:     "#757d7b"
    readonly property color _over0:   "#353937"
    readonly property color _accent:  "#81d5ca"

    property string searchQuery: ""
    property bool showConfirm: false
    property string confirmCommand: ""
    property string confirmLabel: ""

    property var categories: [
        {
            name: "Shell",
            icon: "\uF011",
            binds: [
                { keys: "Super + A",        desc: "Toggle notification panel" },
                { keys: "Super + J",        desc: "Toggle quick actions HUD" },
                { keys: "Super + O",        desc: "Toggle bar" },
                { keys: "Super + M",        desc: "Toggle media card" },
                { keys: "Ctrl + Super + T", desc: "Toggle wallpaper picker" },
                { keys: "Super + /",        desc: "Toggle cheatsheet" },
                { keys: "Super + .",        desc: "Toggle emoji picker" },
                { keys: "Super + ,",        desc: "Toggle GIF picker" },
                { keys: "Ctrl + Super + R", desc: "Restart shell" }
            ]
        },
        {
            name: "Apps",
            icon: "\uF120",
            binds: [
                { keys: "Super + Enter",     desc: "Terminal (Ghostty)",  action: "ghostty" },
                { keys: "Super + Space",     desc: "App launcher (Rofi)", action: "bash ~/.config/rofi/launchers/type-1/launcher.sh" },
                { keys: "Super + V",         desc: "Clipboard manager" },
                { keys: "Super + W",         desc: "Browser (Zen)",       action: "zen-browser" },
                { keys: "Super + Shift + W", desc: "Browser (Brave)",     action: "brave-browser" },
                { keys: "Super + E",         desc: "File manager",        action: "thunar" },
                { keys: "Super + C",         desc: "Editor (nvim)",       action: "nvim" }
            ]
        },
        {
            name: "Windows",
            icon: "\uF2D2",
            binds: [
                { keys: "Super + H / L",          desc: "Focus left / right" },
                { keys: "Super + Arrows",          desc: "Focus direction" },
                { keys: "Super + Shift + Arrows",  desc: "Move window" },
                { keys: "Super + Q",               desc: "Close window" },
                { keys: "Super + G",               desc: "Toggle floating" },
                { keys: "Super + F",               desc: "Fullscreen (workspace)" },
                { keys: "Super + Shift + F",       desc: "Fullscreen (real)" }
            ]
        },
        {
            name: "Workspaces",
            icon: "\uF24B",
            binds: [
                { keys: "Super + 1-0",              desc: "Switch to workspace 1-10" },
                { keys: "Super + Shift + 1-0",      desc: "Move window to workspace" },
                { keys: "Super + Tab",              desc: "Next workspace" },
                { keys: "Super + Shift + Tab",      desc: "Previous workspace" },
                { keys: "Super + Page Up/Down",     desc: "Cycle workspaces" },
                { keys: "Super + =/-",              desc: "Cycle workspaces" },
                { keys: "Ctrl + Super + ←/→",      desc: "Move to adjacent workspace" },
                { keys: "Super + S",                desc: "Toggle scratchpad" }
            ]
        },
        {
            name: "Session",
            icon: "\uF0AC",
            binds: [
                { keys: "Super + P",                desc: "Power menu",       action: "pkill wlogout || wlogout --protocol layer-shell --buttons-per-row 5" },
                { keys: "Super + Shift + P",        desc: "Lock screen",      action: "loginctl lock-session" },
                { keys: "Super + Shift + L",        desc: "Suspend",          action: "systemctl suspend || loginctl suspend" },
                { keys: "Ctrl+Shift+Alt+Super+Del", desc: "Power off",        action: "systemctl poweroff || loginctl poweroff" },
                { keys: "Ctrl+Shift+Alt+Super+End", desc: "Reboot",           action: "systemctl reboot || loginctl reboot" }
            ]
        },
        {
            name: "Screenshots",
            icon: "\uF030",
            binds: [
                { keys: "Print",              desc: "Full screen (clipboard)", action: "bash ~/.config/scripts/screenshots/screenshot.sh full" },
                { keys: "Ctrl + Print",       desc: "Region select",          action: "bash ~/.config/scripts/screenshots/screenshot.sh region" },
                { keys: "Shift + Print",      desc: "Window select",          action: "bash ~/.config/scripts/screenshots/screenshot.sh window" },
                { keys: "Alt + Print",        desc: "Monitor select",         action: "bash ~/.config/scripts/screenshots/screenshot.sh monitor" },
                { keys: "Ctrl + Shift + Print", desc: "Annotate (swappy)",     action: "bash ~/.config/scripts/screenshots/screenshot.sh annotate" },
                { keys: "Super + Shift + C",  desc: "Color picker",           action: "hyprpicker -a" }
            ]
        },
        {
            name: "Recording",
            icon: "\uF03D",
            binds: [
                { keys: "Ctrl + Shift + R", desc: "Region record / stop", action: "bash ~/.config/scripts/recording/recording.sh region" },
                { keys: "Ctrl + Alt + R",   desc: "Full record / stop",   action: "bash ~/.config/scripts/recording/recording.sh full" }
            ]
        },
        {
            name: "Hardware",
            icon: "\uF028",
            binds: [
                { keys: "Brightness Up/Down", desc: "Adjust brightness" },
                { keys: "Volume Up/Down",     desc: "Adjust volume" },
                { keys: "Mute",               desc: "Toggle mute" },
                { keys: "Mic Mute",           desc: "Toggle mic mute" },
                { keys: "Super + Shift + N",  desc: "Toggle night light", action: "if pgrep -x hyprsunset > /dev/null; then pkill hyprsunset; else hyprsunset -t 3200; fi" },
                { keys: "Media Keys",         desc: "Play / Pause / Next / Prev" }
            ]
        }
    ]

    property var filteredCategories: {
        if (searchQuery === "") return categories
        var q = searchQuery.toLowerCase()
        var result = []
        for (var i = 0; i < categories.length; i++) {
            var cat = categories[i]
            var matchedBinds = []
            for (var j = 0; j < cat.binds.length; j++) {
                var b = cat.binds[j]
                if (b.keys.toLowerCase().indexOf(q) >= 0 || b.desc.toLowerCase().indexOf(q) >= 0) {
                    matchedBinds.push(b)
                }
            }
            if (matchedBinds.length > 0) {
                result.push({ name: cat.name, icon: cat.icon, binds: matchedBinds })
            }
        }
        return result
    }

    // ── Intro animation ──
    property real introMain: 0
    property real introContent: 0

    function show() {
        introMain = 0; introContent = 0
        searchQuery = ""
        searchField.text = ""
        introAnim.start()
        focusTimer.start()
    }

    Timer {
        id: focusTimer
        interval: 100
        repeat: false
        onTriggered: searchField.forceActiveFocus()
    }

    SequentialAnimation {
        id: introAnim
        running: false
        PauseAnimation { duration: 20 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "introMain"; from: 0; to: 1.0; duration: 400; easing.type: Easing.OutQuart }
            SequentialAnimation {
                PauseAnimation { duration: 80 }
                NumberAnimation { target: root; property: "introContent"; from: 0; to: 1.0; duration: 500; easing.type: Easing.OutQuint }
            }
        }
    }

    Item {
        anchors.fill: parent
        scale: 0.95 + (0.05 * root.introMain)
        opacity: root.introMain

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: _base
            border.color: "#303635"
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // ── Header ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: _accent
                        text: "\uF0AC"
                    }

                    Text {
                        Layout.fillWidth: true
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: _text
                        text: "Keybind Reference"
                    }

                    Rectangle {
                        width: 28; height: 28; radius: 8
                        color: closeMa.containsMouse ? _surf2 : "transparent"
                        Text {
                            anchors.centerIn: parent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: _sub
                            text: "\uF00D"
                        }
                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellState.closePopup()
                        }
                    }
                }

                // ── Search bar ──
                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: _text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    placeholderText: "Search keybinds..."
                    placeholderTextColor: _over0
                    leftPadding: 36
                    rightPadding: 10
                    background: Rectangle {
                        radius: 12
                        color: _surf1
                        border.color: searchField.activeFocus ? _accent : _surf2
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        Text {
                            x: 12; anchors.verticalCenter: parent.verticalCenter
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: _sub
                            text: "\uF002"
                        }
                    }
                    onTextChanged: root.searchQuery = text
                    Keys.onEscapePressed: { text = ""; ShellState.closePopup() }
                }

                // ── Horizontal content with wheel scroll ──
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Flickable {
                        id: flickable
                        anchors.fill: parent
                        contentWidth: categoriesRow.width
                        clip: true
                        opacity: root.introContent
                        flickableDirection: Flickable.HorizontalFlick
                        boundsBehavior: Flickable.StopAtBounds

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            onWheel: function(wheel) {
                                var delta = wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.angleDelta.y
                                flickable.contentX = Math.max(0, Math.min(flickable.contentWidth - flickable.width, flickable.contentX - delta))
                            }
                        }

                        ScrollBar.horizontal: ScrollBar {
                            parent: flickable.parent
                            anchors.left: flickable.left
                            anchors.right: flickable.right
                            anchors.bottom: flickable.bottom
                            policy: flickable.contentWidth > flickable.width ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                            contentItem: Rectangle {
                                implicitHeight: 6
                                radius: 3
                                color: _surf3
                                opacity: hScrollBarMa.containsMouse || parent.parent.pressed ? 0.9 : 0.5
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                            background: Rectangle {
                                color: _surf1
                                radius: 3
                            }
                        }

                        Row {
                            id: categoriesRow
                            height: flickable.height
                            spacing: 0

                            Repeater {
                                model: root.filteredCategories

                                delegate: Item {
                                    required property var modelData
                                    required property int index
                                    width: 240
                                    height: flickable.height

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        spacing: 0

                                        // Category header
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 8
                                            Layout.rightMargin: 8
                                            Layout.topMargin: 4
                                            Layout.bottomMargin: 8
                                            spacing: 8

                                            Text {
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 13
                                                color: _accent
                                                text: modelData.icon
                                            }

                                            Text {
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 13
                                                font.weight: Font.Bold
                                                color: _accent
                                                text: modelData.name.toUpperCase()
                                            }
                                        }

                                        // Separator
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 8
                                            Layout.rightMargin: 8
                                            Layout.bottomMargin: 8
                                            height: 1
                                            color: _surf2
                                        }

                                        // Keybind rows
                                        Repeater {
                                            model: modelData.binds

                                            delegate: ColumnLayout {
                                                required property var modelData
                                                required property int index
                                                Layout.fillWidth: true
                                                Layout.leftMargin: 8
                                                Layout.rightMargin: 8
                                                spacing: 6

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 26
                                                    radius: 6
                                                    color: bindRowMa.containsMouse ? _surf3 : _surf1

                                                    Row {
                                                        anchors.left: parent.left
                                                        anchors.leftMargin: 8
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        spacing: 6

                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            font.family: "JetBrainsMono Nerd Font"
                                                            font.pixelSize: 11
                                                            font.weight: Font.Medium
                                                            color: bindRowMa.containsMouse ? _accent : _text
                                                            text: modelData.keys
                                                        }

                                                        // Play icon for executable keybinds
                                                        Text {
                                                            visible: !!modelData.action
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            font.family: "JetBrainsMono Nerd Font"
                                                            font.pixelSize: 9
                                                            color: bindRowMa.containsMouse ? _accent : _sub
                                                            text: "\uF04B"
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: bindRowMa
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (modelData.action) {
                                                                var cmd = modelData.action
                                                                if (cmd.indexOf("poweroff") !== -1 || cmd.indexOf("reboot") !== -1 || cmd.indexOf("suspend") !== -1) {
                                                                    root.confirmCommand = cmd
                                                                    root.confirmLabel = modelData.desc
                                                                    root.showConfirm = true
                                                                } else {
                                                                    var parts = cmd.split(/\s+/)
                                                                    Quickshell.execDetached(parts)
                                                                    ShellState.closePopup()
                                                                }
                                                            } else {
                                                                Quickshell.execDetached(["sh", "-c", "echo -n '" + modelData.keys.replace(/'/g, "'\\''") + "' | wl-copy"])
                                                            }
                                                        }
                                                    }
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    Layout.leftMargin: 8
                                                    Layout.rightMargin: 8
                                                    font.family: "JetBrainsMono Nerd Font"
                                                    font.pixelSize: 10
                                                    color: _sub
                                                    text: modelData.desc
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
                                                }

                                                Item { Layout.preferredHeight: index < modelData.binds.length - 1 ? 4 : 0 }
                                            }
                                        }

                                        Item { Layout.fillHeight: true }
                                    }

                                    // Right separator between categories
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.topMargin: 8
                                        anchors.bottomMargin: 8
                                        width: 1
                                        visible: index < root.filteredCategories.length - 1
                                        color: _surf2
                                    }
                                }
                            }

                            // Empty state
                            Text {
                                visible: root.filteredCategories.length === 0
                                width: flickable.width
                                height: flickable.height
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: _over0
                                text: "No matching keybinds"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                // ── Footer hint ──
                Text {
                    Layout.fillWidth: true
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: _over0
                    text: "Click to run  |  Click key to copy  |  Esc to close"
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    // ── Confirmation Dialog ──
    Rectangle {
        id: confirmDialog
        anchors.centerIn: parent
        width: 280
        height: 140
        radius: 16
        color: _base
        border.width: 1
        border.color: _surf2
        visible: root.showConfirm
        z: 100

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Confirm " + root.confirmLabel
                color: _text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: "Are you sure?"
                color: _sub
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: cancelMa.containsMouse ? _surf2 : _surf1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: _text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: cancelMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showConfirm = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: confirmMa.containsMouse ? "#b83b3b" : "#8b3535"

                    Text {
                        anchors.centerIn: parent
                        text: "Confirm"
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: confirmMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var parts = root.confirmCommand.split(/\s+/)
                            Quickshell.execDetached(parts)
                            root.showConfirm = false
                            ShellState.closePopup()
                        }
                    }
                }
            }
        }
    }
}
