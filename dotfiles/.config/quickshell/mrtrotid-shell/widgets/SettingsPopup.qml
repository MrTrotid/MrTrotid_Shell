import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"

Item {
    id: root

    readonly property color colBase:   ColorService.surfaceContainerLow
    readonly property color colCard:   ColorService.surface
    readonly property color colLayer1: ColorService.surfaceContainer
    readonly property color colLayer2: ColorService.surfaceContainerHigh
    readonly property color colText:   ColorService.surfaceText
    readonly property color colSub:    ColorService.surfaceVariantText
    readonly property color colMuted:  ColorService.outline
    readonly property color colAccent: ColorService.primary
    readonly property color colOnAccent: ColorService.primaryText
    readonly property color colAccentBg: ColorService.primaryContainer
    readonly property color colBorder: ColorService.outlineVariant

    property string currentSection: "general"

    property string osInfo: ""
    property string kernelInfo: ""
    property string hostnameInfo: ""
    property string cpuInfo: ""
    property string gpuInfo: ""
    property string memInfo: ""
    property string uptimeInfo: ""
    property string shellVersion: ""
    property string cameraInfo: ""

    property string repoPath: ""
    property string branch: ""
    property string commit: ""
    property string behindInfo: ""
    property string dateInfo: ""
    property bool updateChecking: false
    property bool updateResultVisible: false
    property string updateResult: ""

    property bool animationsEnabled: true
    property bool notificationsEnabled: true

    function close() { ShellState.closePopup() }
    function show() {
        if (osInfo === "") sysInfoProc.running = true
        if (repoPath === "") detectRepoProc.running = true
    }

    function checkUpdates() {
        if (repoPath === "") return
        updateChecking = true
        updateResultVisible = false
        var repo = root.repoPath
        updateProc.command = ["sh", "-c",
            "cd \"" + repo + "\" 2>/dev/null && " +
            "git fetch origin 2>&1 && " +
            "BEHIND=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0) && " +
            "echo \"BEHIND=$BEHIND\" && " +
            "echo \"DATE=$(git log -1 --format=%cs 2>/dev/null)\" && " +
            "if [ \"$BEHIND\" = \"0\" ]; then echo 'RESULT=Up to date'; else echo \"RESULT=$BEHIND commits behind\"; fi"
        ]
        updateProc.running = true
    }

    function updateNow() {
        if (repoPath === "") return
        updateChecking = true
        updateResultVisible = false
        var repo = root.repoPath
        updateProc.command = ["sh", "-c",
            "cd \"" + repo + "\" 2>/dev/null && " +
            "OUT=$(git pull 2>&1) && " +
            "echo \"BRANCH=$(git branch --show-current 2>/dev/null)\" && " +
            "echo \"COMMIT=$(git rev-parse --short HEAD 2>/dev/null)\" && " +
            "echo \"DATE=$(git log -1 --format=%cs 2>/dev/null)\" && " +
            "if echo \"$OUT\" | grep -q 'Already up to date'; then echo 'RESULT=Already up to date'; else echo 'RESULT=Updated. Restart shell to apply.'; fi"
        ]
        updateProc.running = true
    }

    Process {
        id: updateProc
        running: false
        command: []  // set dynamically

        stdout: SplitParser {
            onRead: (data) => {
                var line = data.trim()
                if (line.startsWith("BEHIND=")) root.behindInfo = line.substring(7)
                else if (line.startsWith("DATE=")) root.dateInfo = line.substring(5)
                else if (line.startsWith("BRANCH=")) root.branch = line.substring(7)
                else if (line.startsWith("COMMIT=")) root.commit = line.substring(7)
                else if (line.startsWith("RESULT=")) {
                    root.updateResult = line.substring(7)
                    root.updateResultVisible = true
                    root.updateChecking = false
                }
            }
        }
    }

    Process {
        id: sysInfoProc
        running: false
        command: ["sh", "-c", "echo \"OS=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')\"; echo \"KERNEL=$(uname -r 2>/dev/null)\"; echo \"HOSTNAME=$(hostname 2>/dev/null)\"; echo \"CPU=$(lscpu 2>/dev/null | grep 'Model name' | cut -d: -f2 | xargs)\"; echo \"GPU=$(lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | sed 's/.*: //' | sed 's/ (rev.*)//' | awk \\\"{if(match(\\$0,/\\[([^\\]]+)\\]/)){n=substr(\\$0,RSTART+1,RLENGTH-2); if(\\$0~/Intel/) n=\\\"Intel \\\" n; print n}else{gsub(/^[A-Za-z]+ Corporation /,\\\"\\\");print}}\\\" | awk \\\"{if(NR>1)printf \\\" | \\\"; printf \\\"%s\\\", \\$0}\\\")\"; echo \"MEM=$(free -h 2>/dev/null | awk '/Mem:/{print $2}')\"; echo \"UPTIME=$(uptime -p 2>/dev/null | sed 's/^up //')\"; echo \"SHELL_VERSION=$(quickshell --version 2>/dev/null || echo 'Quickshell 0.3.0')\"; echo \"CAMERA=$(fuser /dev/video0 2>/dev/null && echo ACTIVE || echo IDLE)\""]

        stdout: SplitParser {
            onRead: (data) => {
                var line = data.trim()
                if (line.startsWith("OS="))      root.osInfo = line.substring(3)
                else if (line.startsWith("KERNEL="))   root.kernelInfo = line.substring(7)
                else if (line.startsWith("HOSTNAME=")) root.hostnameInfo = line.substring(9)
                else if (line.startsWith("CPU="))      root.cpuInfo = line.substring(4)
                else if (line.startsWith("GPU="))      root.gpuInfo = line.substring(4)
                else if (line.startsWith("MEM="))      root.memInfo = line.substring(4)
                else if (line.startsWith("UPTIME="))   root.uptimeInfo = line.substring(7)
                else if (line.startsWith("SHELL_VERSION=")) root.shellVersion = line.substring(14)
                else if (line.startsWith("CAMERA="))   root.cameraInfo = line.substring(7) === "ACTIVE" ? "IN USE" : "IDLE"
            }
        }
    }

    Process {
        id: detectRepoProc
        running: false
        command: ["sh", "-c",
            "CONFIG=$(readlink -f ~/.config/quickshell/mrtrotid-shell 2>/dev/null || readlink -f ~/.config/quickshell/custom 2>/dev/null); " +
            "if [ -z \"$CONFIG\" ]; then echo 'FOUND=false'; exit; fi; " +
            "DIR=\"$CONFIG\"; " +
            "while [ \"$DIR\" != \"/\" ]; do " +
            "  if [ -d \"$DIR/.git\" ]; then " +
            "    echo \"FOUND=true\"; " +
            "    echo \"REPO_PATH=$DIR\"; " +
            "    cd \"$DIR\"; " +
            "    echo \"BRANCH=$(git branch --show-current 2>/dev/null)\"; " +
            "    echo \"COMMIT=$(git rev-parse --short HEAD 2>/dev/null)\"; " +
            "    echo \"BEHIND=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)\"; " +
            "    echo \"DATE=$(git log -1 --format=%cs 2>/dev/null)\"; " +
            "    exit; " +
            "  fi; " +
            "  DIR=$(dirname \"$DIR\"); " +
            "done; " +
            "echo 'FOUND=false'"
        ]

        stdout: SplitParser {
            onRead: (data) => {
                var line = data.trim()
                if (line.startsWith("REPO_PATH=")) root.repoPath = line.substring(10)
                else if (line.startsWith("BRANCH="))   root.branch = line.substring(7)
                else if (line.startsWith("COMMIT="))   root.commit = line.substring(7)
                else if (line.startsWith("BEHIND="))   root.behindInfo = line.substring(7)
                else if (line.startsWith("DATE="))     root.dateInfo = line.substring(5)
            }
        }
    }

    // ── Scrim ──
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        MouseArea { anchors.fill: parent; onClicked: close() }
    }

    // ── Main window ──
    Rectangle {
        anchors.centerIn: parent
        width: 600
        height: 600
        radius: 16
        color: colBase

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── Title bar ──
            Rectangle {
                Layout.fillWidth: true
                height: 52
                color: colCard
                radius: 16

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: "\u2699"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: colAccent
                    }

                    Text {
                        text: "Settings"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: colText
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "\u2715"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: colSub
                        opacity: 0.5

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: parent.opacity = 1
                            onExited: parent.opacity = 0.5
                            onClicked: close()
                        }
                    }
                }
            }

            // ── Segmented control (General | About) ──
            Rectangle {
                Layout.fillWidth: true
                height: 40
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 12
                Layout.bottomMargin: 8
                radius: 8
                color: colLayer1

                RowLayout {
                    anchors.fill: parent
                    spacing: 2
                    anchors.margins: 3

                    Repeater {
                        model: [
                            { name: "General", section: "general" },
                            { name: "About",   section: "about" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6
                            color: currentSection === modelData.section ? colCard : "transparent"

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                font.weight: currentSection === modelData.section ? Font.Bold : Font.Normal
                                color: currentSection === modelData.section ? colText : colSub
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: currentSection = modelData.section
                            }
                        }
                    }
                }
            }

            // ── Content ──
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.bottomMargin: 16
                radius: 10
                color: colCard
                clip: true

                // ══════════════════════════════════════════
                //  GENERAL
                // ══════════════════════════════════════════
                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 2
                    visible: currentSection === "general"

                    Text {
                        text: "General"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: colSub
                        padding: 4
                    }

                    Item { height: 4 }

                    Repeater {
                        model: [
                            { icon: "\uF0C9", title: "Bar visibility", desc: "Show or hide the top bar", prop: "bar", },
                            { icon: "\uF0E7", title: "Animations", desc: "Enable transition effects", prop: "anim" },
                            { icon: "\uF0A2", title: "Notifications", desc: "Show desktop notifications", prop: "notif" }
                        ]

                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            width: parent.width
                            height: 48
                            radius: 8
                            color: index % 2 === 0 ? "transparent" : colLayer1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 12

                                Text {
                                    text: modelData.icon
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    color: colAccent
                                }

                                Column {
                                    spacing: 1
                                    Text {
                                        text: modelData.title
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: colText
                                    }
                                    Text {
                                        text: modelData.desc
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: colSub
                                    }
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    width: 36; height: 20; radius: 10
                                    color: {
                                        if (modelData.prop === "bar") return ShellState.barVisible ? colAccent : colBorder
                                        if (modelData.prop === "anim") return root.animationsEnabled ? colAccent : colBorder
                                        return root.notificationsEnabled ? colAccent : colBorder
                                    }

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Rectangle {
                                        x: {
                                            if (modelData.prop === "bar") return ShellState.barVisible ? 18 : 2
                                            if (modelData.prop === "anim") return root.animationsEnabled ? 18 : 2
                                            return root.notificationsEnabled ? 18 : 2
                                        }
                                        y: 2; width: 16; height: 16; radius: 8
                                        color: colOnAccent
                                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.prop === "bar") ShellState.barVisible = !ShellState.barVisible
                                            else if (modelData.prop === "anim") root.animationsEnabled = !root.animationsEnabled
                                            else root.notificationsEnabled = !root.notificationsEnabled
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { height: 8 }

                    Text {
                        text: "More settings coming soon\u2026"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: colSub
                        opacity: 0.4
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // ══════════════════════════════════════════
                //  ABOUT
                // ══════════════════════════════════════════
                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 0
                    visible: currentSection === "about"

                    // ── Shell identity ──
                    RowLayout {
                        width: parent.width
                        spacing: 14

                        Rectangle {
                            width: 44; height: 44; radius: 12
                            color: colAccentBg

                            Text {
                                anchors.centerIn: parent
                                text: "\u2699"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 22
                                color: colAccent
                            }
                        }

                        Column {
                            spacing: 1
                            Text {
                                text: "Trotid Shell"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                color: colText
                            }
                            Text {
                                text: root.shellVersion.length > 0 ? root.shellVersion : "\u2026"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: colSub
                            }
                        }
                    }

                    Item { height: 12 }

                    Rectangle {
                        width: parent.width; height: 1; color: colBorder; opacity: 0.4
                    }

                    Item { height: 10 }

                    // ── Info grid ──
                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 6

                        Repeater {
                            model: [
                                { icon: "\uF17C", label: "OS",      value: root.osInfo },
                                { icon: "\uF17C", label: "Kernel",  value: root.kernelInfo },
                                { icon: "\uF109", label: "Host",    value: root.hostnameInfo },
                                { icon: "\uF2DB", label: "CPU",     value: root.cpuInfo },
                                { icon: "\uF26C", label: "GPU(s)",  value: root.gpuInfo },
                                { icon: "\uF0C9", label: "Memory",  value: root.memInfo },
                                { icon: "\uF251", label: "Uptime",  value: root.uptimeInfo, span: 2 },
                                { icon: "\uF030", label: "Camera",  value: root.cameraInfo, span: 2 }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.columnSpan: modelData.span === 2 ? 2 : 1
                                height: modelData.label === "Camera" ? 36 : 32
                                radius: 6
                                color: modelData.label === "Camera" ? (root.cameraInfo === "IDLE" ? "#1a4ade80" : "#1af87171") : colLayer1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: (modelData.label === "Camera" && root.cameraInfo === "IDLE") ? "\uDB81\uDDDF" : modelData.icon
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: modelData.label === "Camera" ? (root.cameraInfo === "IDLE" ? "#4ade80" : "#f87171") : colAccent
                                    }

                                    Text {
                                        text: modelData.label
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: modelData.label === "Camera" ? (root.cameraInfo === "IDLE" ? "#4ade80" : "#f87171") : colSub
                                        font.weight: modelData.label === "Camera" ? Font.Bold : Font.Normal
                                        Layout.preferredWidth: modelData.label === "Camera" ? 44 : 44
                                    }

                                    Text {
                                        text: modelData.value.length > 0 ? modelData.value : "\u2026"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        color: modelData.label === "Camera" ? (root.cameraInfo === "IDLE" ? "#4ade80" : "#f87171") : colText
                                        font.weight: modelData.label === "Camera" ? Font.Bold : Font.Normal
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    Item { height: 10 }

                    Rectangle {
                        width: parent.width; height: 1; color: colBorder; opacity: 0.4
                    }

                    Item { height: 8 }

                    Text {
                        text: "\uF0E2  Update Shell"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: colText
                    }

                    Item { height: 6 }

                    Column {
                        width: parent.width
                        spacing: 4
                        visible: repoPath.length > 0

                        RowLayout {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: "Branch:"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: colSub
                                Layout.preferredWidth: 48
                            }
                            Text {
                                text: root.branch.length > 0 ? root.branch : "\u2026"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: colAccent
                                font.weight: Font.Bold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.commit.length > 0 ? root.commit : "\u2026"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: colSub
                            }
                        }

                        RowLayout {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: "Updated:"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: colSub
                                Layout.preferredWidth: 48
                            }
                            Text {
                                text: root.dateInfo.length > 0 ? root.dateInfo : "\u2026"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: colText
                            }
                        }

                        RowLayout {
                            width: parent.width
                            spacing: 6
                            visible: root.behindInfo.length > 0

                            Text {
                                text: "Behind:"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: colSub
                                Layout.preferredWidth: 48
                            }
                            Text {
                                text: root.behindInfo === "0" ? "Up to date" : "%1 commits".arg(root.behindInfo)
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: root.behindInfo === "0" ? "#4ade80" : "#facc15"
                                font.weight: Font.Bold
                            }
                        }

                        Item { height: 4 }

                        RowLayout {
                            width: parent.width
                            spacing: 8

                            Rectangle {
                                id: checkBtn
                                height: 28; radius: 6
                                color: colLayer1
                                Layout.fillWidth: true

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.updateChecking ? "\u25B6 Checking\u2026" : "\uF021  Check Updates"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    color: colText
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: checkBtn.color = colLayer2
                                    onExited: checkBtn.color = colLayer1
                                    onClicked: root.checkUpdates()
                                }
                            }

                            Rectangle {
                                id: pullBtn
                                height: 28; radius: 6
                                color: colAccentBg
                                Layout.fillWidth: true

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.updateChecking ? "\u25B6 \u2026" : "\uF01E  Update Now"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    color: colAccent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: pullBtn.color = Qt.lighter(colAccentBg, 1.1)
                                    onExited: pullBtn.color = colAccentBg
                                    onClicked: root.updateNow()
                                }
                            }

                            Rectangle {
                                id: restartBtn
                                height: 28; radius: 6
                                color: colLayer1
                                Layout.preferredWidth: 110

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u21BB  Restart Shell"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    color: colText
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: restartBtn.color = colLayer2
                                    onExited: restartBtn.color = colLayer1
                                    onClicked: {
                                        var home = Quickshell.env("HOME")
                                        Process.exec("sh", ["-c", "pkill -x qs; sleep 0.5; quickshell -c mrtrotid-shell &"])
                                    }
                                }
                            }
                        }

                        Item { height: 4 }

                        Text {
                            width: parent.width
                            text: root.updateResult
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: root.updateResult.indexOf("Up to date") >= 0 ? "#4ade80"
                                 : root.updateResult.indexOf("Updated") >= 0 ? "#60a5fa"
                                 : root.updateResult.length > 0 ? "#f87171" : "transparent"
                            visible: root.updateResultVisible
                            wrapMode: Text.WordWrap
                        }
                    }

                    Rectangle {
                        width: parent.width; height: 80
                        color: "transparent"
                        visible: repoPath.length === 0

                        Text {
                            anchors.centerIn: parent
                            text: "Shell not in a git repository.\nClone from github.com/Noro18/linux-ricing-dotfiles"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: colSub
                            opacity: 0.5
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Item { height: 8 }

                    Text {
                        text: "Built with Quickshell \u2665"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: colSub
                        opacity: 0.4
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
