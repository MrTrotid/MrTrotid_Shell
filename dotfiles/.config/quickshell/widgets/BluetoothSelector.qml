import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property color _base:    "#131514"
    readonly property color _crust:   "#1c1e1d"
    readonly property color _surf1:   "#232524"
    readonly property color _surf2:   "#2b2d2c"
    readonly property color _text:    "#c5cbc9"
    readonly property color _sub:     "#757d7b"
    readonly property color _over0:   "#353937"
    readonly property color _accent:  "#81d5ca"
    readonly property color _red:     "#ffb4ab"
    readonly property color _green:   "#92d5ab"
    readonly property color accentLight: Qt.lighter(_accent, 1.15)

    property bool btEnabled: false
    property var connectedDevices: []
    property var devices: []
    property bool scanning: false
    property int scanCountdown: 0
    property string deviceBattery: ""

    property string viewMode: "home"
    property var selectedDevice: null

    // ── Intro animation ──
    property real introMain: 0
    property real introBg: 0
    property real introCore: 0
    property real introCards: 0
    property real introFooter: 0

    function show() {
        introMain = 0; introBg = 0; introCore = 0; introCards = 0; introFooter = 0
        introAnim.start()
    }

    SequentialAnimation {
        id: introAnim
        running: false
        PauseAnimation { duration: 20 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "introMain"; from: 0; to: 1.0; duration: 400; easing.type: Easing.OutQuart }
            SequentialAnimation {
                PauseAnimation { duration: 50 }
                NumberAnimation { target: root; property: "introBg"; from: 0; to: 1.0; duration: 600; easing.type: Easing.OutSine }
            }
            SequentialAnimation {
                PauseAnimation { duration: 120 }
                NumberAnimation { target: root; property: "introCore"; from: 0; to: 1.0; duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            }
            SequentialAnimation {
                PauseAnimation { duration: 200 }
                NumberAnimation { target: root; property: "introCards"; from: 0; to: 1.0; duration: 500; easing.type: Easing.OutQuint }
            }
            SequentialAnimation {
                PauseAnimation { duration: 300 }
                NumberAnimation { target: root; property: "introFooter"; from: 0; to: 1.0; duration: 400; easing.type: Easing.OutQuint }
            }
        }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: root; property: "introMain"; to: 0; duration: 250; easing.type: Easing.InQuart }
        NumberAnimation { target: root; property: "introBg"; to: 0; duration: 200; easing.type: Easing.InQuart }
        NumberAnimation { target: root; property: "introCore"; to: 0; duration: 200; easing.type: Easing.InQuart }
        NumberAnimation { target: root; property: "introCards"; to: 0; duration: 200; easing.type: Easing.InQuart }
        NumberAnimation { target: root; property: "introFooter"; to: 0; duration: 200; easing.type: Easing.InQuart }
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 200000; loops: Animation.Infinite; running: true
    }

    readonly property bool hasConn: connectedDevices.length > 0
    readonly property bool isPowered: btEnabled
    readonly property bool hasPaired: pairedMacs.length > 0

    readonly property var _btIconMap: ({
        "audio-card": "\uF025", "audio-headset": "\uF025", "audio-headphones": "\uF025",
        "audio-speakers": "\uF028", "audio": "\uF025",
        "input-keyboard": "\uF11C", "input-mouse": "\uF345", "input-tablet": "\uF10B",
        "input-gaming": "\uF11B", "input-gamingpad": "\uF11B",
        "phone": "\uF3CD", "smartphone": "\uF3CD", "mobile": "\uF3CD",
        "computer": "\uF109", "desktop": "\uF109", "laptop": "\uF109",
        "camera": "\uF030", "video-display": "\uF108", "tv": "\uF108",
        "network-wireless": "\uF0E8", "wearable-headset": "\uF025",
        "headphones": "\uF025", "headset": "\uF025", "earbuds": "\uF025",
        "speaker": "\uF028", "keyboard": "\uF11C", "mouse": "\uF345",
        "tablet": "\uF10B", "gaming": "\uF11B", "controller": "\uF11B",
        "car": "\uF1B9", "watch": "\uF017", "fitness": "\uF4BC"
    })

    function _btIcon(type) { return _btIconMap[type] || "\uF49A" }

    function _detectIcon(name, btIcon) {
        if (btIcon && _btIconMap[btIcon]) return _btIconMap[btIcon]
        var n = name.toLowerCase()
        if (n.match(/headphone|headset|earbuds?|airpods?|buds|q\d|soundcore|jbl|sony|bose|beats|earphone|inear|wireless.*audio|audio.*wireless/)) return "\uF025"
        if (n.match(/speaker|homepod|echo|nest.*audio|jbl.*flip|boombox|soundbar/)) return "\uF028"
        if (n.match(/keyboard|keybird|mx.*keys|logitech.*k/)) return "\uF11C"
        if (n.match(/mouse|mx.*master|g pro|logitech.*g/)) return "\uF345"
        if (n.match(/phone|iphone|galaxy|pixel|oneplus|xiaomi|redmi|realme|vivo|oppo/)) return "\uF3CD"
        if (n.match(/ipad|tab|tablet|galaxy.*tab/)) return "\uF10B"
        if (n.match(/macbook|laptop|thinkpad|surface|dell|hp.*elite|asus/)) return "\uF109"
        if (n.match(/watch|band|fitbit|mi.*band|galaxy.*watch/)) return "\uF017"
        if (n.match(/controller|ps[45]|xbox|switch|gamepad/)) return "\uF11B"
        if (n.match(/car|aux|bmw|mercedes|toyota|honda/)) return "\uF1B9"
        if (n.match(/tv|roku|fire.*tv|chromecast|apple.*tv/)) return "\uF108"
        return "\uF49A"
    }

    property var connectedMacs: []
    property var pairedMacs: []

    function goHome() { viewMode = "home"; selectedDevice = null }
    function goDevices(listType) { viewMode = "devices"; selectedDevice = null; _deviceListType = listType }
    function goDetail(device) {
        viewMode = "detail"; selectedDevice = device
        deviceBattery = ""
        if (device) {
            batCheckCmd.command = ["sh", "-c", "bluetoothctl info '" + device.mac + "' 2>/dev/null"]
            batCheckCmd.running = false; batCheckCmd.running = true
        }
    }
    property string _deviceListType: "connected"

    Timer { interval: 6000; running: true; repeat: true; onTriggered: {
        _pendingListAll = false; _pendingListConnected = false; _pendingListPaired = false
        btPoll.running = false; btPoll.running = true
    }}

    Process {
        id: btPoll
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'enabled' || echo 'disabled'"]
        stdout: StdioCollector {
            onStreamFinished: {
                btEnabled = text.trim() === "enabled"
                if (btEnabled) {
                    _pendingListAll = false; _pendingListConnected = false; _pendingListPaired = false
                    btListAll.running = false; btListAll.running = true
                    btListConnected.running = false; btListConnected.running = true
                    btListPaired.running = false; btListPaired.running = true
                }
            }
        }
    }

    Process {
        id: btListAll
        command: ["sh", "-c", "bluetoothctl devices 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split('\n').filter(function(l) { return l && l.trim() && l.startsWith("Device ") })
                if (lines.length === 0) { devices = []; connectedDevices = []; return }
                devices = lines.map(function(line) {
                    var parts = line.trim().split(/\s+/)
                    var mac = parts[1]
                    var name = parts.slice(2).join(' ') || mac
                    return {mac: mac.trim(), name: name.trim(), connected: false, paired: false, icon: _detectIcon(name.trim(), "")}
                })
                _pendingListAll = true
                _tryUpdateStatus()
            }
        }
    }

    property bool _pendingListAll: false
    property bool _pendingListConnected: false
    property bool _pendingListPaired: false

    function _tryUpdateStatus() {
        if (_pendingListAll && _pendingListConnected && _pendingListPaired) {
            _pendingListAll = false; _pendingListConnected = false; _pendingListPaired = false
            updateConnectionStatus()
        }
    }

    Process {
        id: btListConnected
        command: ["sh", "-c", "bluetoothctl devices Connected 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split('\n').filter(function(l) { return l && l.trim() && l.startsWith("Device ") })
                connectedMacs = lines.map(function(line) {
                    var parts = line.trim().split(/\s+/)
                    return parts[1].trim()
                })
                _pendingListConnected = true
                _tryUpdateStatus()
            }
        }
    }

    Process {
        id: btListPaired
        command: ["sh", "-c", "bluetoothctl devices Paired 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split('\n').filter(function(l) { return l && l.trim() && l.startsWith("Device ") })
                pairedMacs = lines.map(function(line) {
                    var parts = line.trim().split(/\s+/)
                    return parts[1].trim()
                })
                _pendingListPaired = true
                _tryUpdateStatus()
            }
        }
    }

    function updateConnectionStatus() {
        if (!devices || devices.length === 0) return
        for (var i = 0; i < devices.length; i++) {
            var mac = devices[i].mac
            devices[i].connected = connectedMacs.indexOf(mac) >= 0
            devices[i].paired = pairedMacs.indexOf(mac) >= 0
            if (devices[i].connected) devices[i].paired = true
        }
        updateConnected()
    }

    function updateConnected() {
        var conn = []
        for (var i = 0; i < devices.length; i++) { if (devices[i].connected) conn.push(devices[i]) }
        connectedDevices = conn
    }

    function toggleBt() {
        var on = !btEnabled
        Quickshell.execDetached(["sh", "-c", "bluetoothctl " + (on ? "power on" : "power off")])
        btEnabled = on
        if (on) btPoll.running = true
    }

    function connectDevice(mac) {
        Quickshell.execDetached(["sh", "-c", "bluetoothctl trust '" + mac + "' >/dev/null 2>&1; bluetoothctl connect '" + mac + "'"])
        deviceBattery = ""
        batCheckCmd.command = ["sh", "-c", "bluetoothctl info '" + mac + "' 2>/dev/null"]
        batCheckCmd.running = false; batCheckCmd.running = true
    }

    function disconnectDevice(mac) {
        Quickshell.execDetached(["sh", "-c", "bluetoothctl disconnect '" + mac + "'"])
    }

    function triggerScan() {
        if (scanning) { stopScan(); return }
        scanning = true; scanCountdown = 30; viewMode = "scanning"
        scanProcess.running = false
        scanTimer.restart(); scanCountdownTimer.restart()
        scanProcess.running = true
    }

    function stopScan() {
        scanning = false; scanCountdown = 0
        scanTimer.stop(); scanCountdownTimer.stop()
        Quickshell.execDetached(["sh", "-c", "bluetoothctl scan off 2>/dev/null"])
        viewMode = "home"
        _pendingListAll = false; _pendingListConnected = false; _pendingListPaired = false
        btPoll.running = false; btPoll.running = true
    }

    function removeDevice(mac) {
        Quickshell.execDetached(["sh", "-c", "bluetoothctl remove '" + mac + "'"])
        viewMode = "home"
        _pendingListAll = false; _pendingListConnected = false; _pendingListPaired = false
        btPoll.running = false; btPoll.running = true
    }

    Process {
        id: scanProcess
        command: ["sh", "-c", "bluetoothctl --timeout 30 scan on 2>/dev/null"]
        onExited: {
            scanning = false; scanCountdown = 0
            _pendingListAll = false; _pendingListConnected = false; _pendingListPaired = false
            btPoll.running = false; btPoll.running = true
        }
    }

    Process {
        id: batCheckCmd
        command: ["sh", "-c", "echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text
                var batMatch = raw.match(/Battery Percentage:\s*0x([0-9a-fA-F]+)\s*\((\d+)\)/)
                if (batMatch) {
                    deviceBattery = batMatch[2] + "%"
                } else {
                    var batMatch2 = raw.match(/Battery Percentage:\s*(\d+)/)
                    if (batMatch2) deviceBattery = batMatch2[1] + "%"
                    else deviceBattery = ""
                }
                var iconMatch = raw.match(/Icon:\s*(.+)/)
                if (iconMatch && selectedDevice) {
                    var newIcon = _detectIcon(selectedDevice.name, iconMatch[1].trim())
                    selectedDevice.icon = newIcon
                    for (var i = 0; i < devices.length; i++) {
                        if (devices[i].mac === selectedDevice.mac) { devices[i].icon = newIcon; break }
                    }
                }
            }
        }
    }

    Timer { id: scanTimer; interval: 31000; onTriggered: { stopScan() } }
    Timer { id: scanCountdownTimer; interval: 1000; running: root.scanning; repeat: true; onTriggered: { if (scanCountdown > 0) scanCountdown--; else stopScan() } }
    Timer { interval: 2000; running: root.scanning; repeat: true; onTriggered: {
        _pendingListAll = false; _pendingListConnected = false; _pendingListPaired = false
        btListAll.running = false; btListAll.running = true
        btListConnected.running = false; btListConnected.running = true
        btListPaired.running = false; btListPaired.running = true
    }}
    Timer { id: scanFastPoll; interval: 3000; running: root.scanning; repeat: true; onTriggered: { if (root.isPowered) { btListAll.running = true; btListConnected.running = true; btListPaired.running = true } } }

    Component.onCompleted: { btPoll.running = true }

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

        Rectangle {
            width: parent.width * 0.8; height: width; radius: width / 2
            x: (parent.width / 2 - width / 2) + Math.cos(root.globalOrbitAngle * 2) * 150
            y: (parent.height / 2 - height / 2) + Math.sin(root.globalOrbitAngle * 2) * 100
            opacity: (root.isPowered ? 0.08 : 0.02) * root.introBg
            color: root.hasConn ? accentLight : _surf1
            Behavior on color { ColorAnimation { duration: 1000 } }
            Behavior on opacity { NumberAnimation { duration: 1000 } }
            visible: opacity > 0.01
        }
        Rectangle {
            width: parent.width * 0.9; height: width; radius: width / 2
            x: (parent.width / 2 - width / 2) + Math.sin(root.globalOrbitAngle * 1.5) * -150
            y: (parent.height / 2 - height / 2) + Math.cos(root.globalOrbitAngle * 1.5) * -100
            opacity: (root.isPowered ? 0.06 : 0.01) * root.introBg
            color: root.hasConn ? Qt.darker(_accent, 1.25) : _surf1
            Behavior on color { ColorAnimation { duration: 1000 } }
            Behavior on opacity { NumberAnimation { duration: 1000 } }
            visible: opacity > 0.01
        }

        Item {
            id: radarItem
            anchors.fill: parent
            opacity: (root.isPowered ? 1.0 : 0.0) * root.introBg
            scale: root.isPowered ? 1.0 : 1.05
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }
            Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

            Repeater {
                model: 3
                Rectangle {
                    anchors.centerIn: parent
                    width: 120 + (index * 80); height: width; radius: width / 2
                    color: "transparent"
                    border.color: _accent; border.width: 1
                    opacity: root.hasConn ? 0.08 - (index * 0.02) : 0.03
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }

        Item {
            id: orbitContainer
            anchors.fill: parent

            // ── Central core ──
            Item {
                id: coreItem
                anchors.centerIn: parent
                width: 140; height: 140
                opacity: root.introCore
                scale: 0.85 + (0.15 * root.introCore)
                transform: Translate { y: 20 * (1.0 - root.introCore) }

                MultiEffect {
                    source: centralCore
                    anchors.fill: centralCore
                    shadowEnabled: true; shadowColor: "#000000"
                    shadowOpacity: root.isPowered ? 0.5 : 0.0
                    shadowBlur: 1.2; shadowVerticalOffset: 6; z: -1
                    Behavior on shadowOpacity { NumberAnimation { duration: 600 } }
                }

                Rectangle {
                    id: centralCore
                    anchors.fill: parent; radius: width / 2

                    property bool isDanger: coreMa.containsMouse && root.hasConn && root.viewMode === "home"
                    property real disconnectFill: 0.0
                    property real flashOpacity: 0.0

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0.0
                            color: {
                                if (root.viewMode === "scanning") return accentLight;
                                if (!root.isPowered) return _base;
                                if (centralCore.isDanger) return Qt.lighter(_red, 1.15);
                                return root.hasConn ? accentLight : _surf1;
                            }
                            Behavior on color { ColorAnimation { duration: 400 } }
                        }
                        GradientStop {
                            position: 1.0
                            color: {
                                if (root.viewMode === "scanning") return _accent;
                                if (!root.isPowered) return _crust;
                                if (centralCore.isDanger) return _red;
                                return root.hasConn ? _accent : _base;
                            }
                            Behavior on color { ColorAnimation { duration: 400 } }
                        }
                    }

                    border.color: {
                        if (root.viewMode === "scanning") return Qt.lighter(_accent, 1.1);
                        if (!root.isPowered) return _crust;
                        if (centralCore.isDanger) return Qt.darker(_red, 1.1);
                        return root.hasConn ? Qt.lighter(_accent, 1.1) : _surf1;
                    }
                    border.width: 2
                    Behavior on border.color { ColorAnimation { duration: 300 } }

                    Rectangle {
                        anchors.fill: parent; radius: parent.radius; color: "#ffffff"
                        opacity: centralCore.flashOpacity
                        PropertyAnimation on opacity { id: coreFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo }
                    }

                    // Pulse ring
                    Rectangle {
                        anchors.centerIn: parent; width: parent.width + 40; height: width; radius: width / 2
                        color: "transparent"; border.color: _accent; border.width: 3; z: -2
                        opacity: (root.hasConn || root.viewMode === "scanning") ? 0.15 : 0.0
                        SequentialAnimation on scale {
                            loops: Animation.Infinite; running: root.hasConn || root.viewMode === "scanning"
                            NumberAnimation { to: 1.1; duration: 2000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 2000; easing.type: Easing.InOutSine }
                        }
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite; running: root.hasConn || root.viewMode === "scanning"
                            NumberAnimation { to: 0.0; duration: 2000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.15; duration: 2000; easing.type: Easing.InOutSine }
                        }
                    }

                    // Scanning ripple
                    Item {
                        anchors.fill: parent; opacity: root.viewMode === "scanning" ? 1.0 : 0.0; visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: 400 } }
                        Repeater {
                            model: 3
                            Rectangle {
                                anchors.centerIn: parent; width: parent.width * 0.4; height: width; radius: width / 2
                                color: "transparent"; border.color: _accent; border.width: 2
                                SequentialAnimation on scale {
                                    running: root.viewMode === "scanning"; loops: Animation.Infinite
                                    PauseAnimation { duration: index * 400 }
                                    NumberAnimation { from: 1.0; to: 2.5; duration: 2000; easing.type: Easing.OutSine }
                                }
                                SequentialAnimation on opacity {
                                    running: root.viewMode === "scanning"; loops: Animation.Infinite
                                    PauseAnimation { duration: index * 400 }
                                    NumberAnimation { from: 0.8; to: 0.0; duration: 2000; easing.type: Easing.OutSine }
                                }
                            }
                        }
                    }

                    // Core content
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 4

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 32
                            color: (root.viewMode === "scanning" || root.viewMode === "detail") ? _crust : (root.hasConn ? _crust : (root.isPowered ? _accent : _over0))
                            text: {
                                if (root.viewMode === "scanning" && coreMa.containsMouse) return "\uF04D"
                                if (root.viewMode === "scanning") return "\uF002"
                                if (root.viewMode === "detail" && root.selectedDevice) return root.selectedDevice.icon
                                if (root.viewMode === "devices") return "\uF502"
                                return root.isPowered ? "\uF293" : "\uF019"
                            }
                            scale: root.viewMode === "scanning" && !coreMa.containsMouse ? coreScanBounce.scale : 1.0
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: 120
                            visible: root.viewMode !== "home"
                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Black; font.pixelSize: 13
                            color: (root.viewMode === "scanning" || root.viewMode === "detail") ? _crust : (root.hasConn ? _crust : _over0)
                            wrapMode: Text.WordWrap; maximumLineCount: 2; horizontalAlignment: Text.AlignHCenter
                            text: {
                                if (root.viewMode === "scanning" && coreMa.containsMouse) return "Stop Scan"
                                if (root.viewMode === "scanning") return "Scanning..."
                                if (root.viewMode === "detail" && root.selectedDevice) return root.selectedDevice.name ?? root.selectedDevice.mac
                                if (root.viewMode === "devices") return _deviceListType === "connected" ? "Connected Devices" : "Paired Devices"
                                return ""
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: 120
                            visible: root.viewMode !== "home"
                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 10
                            color: (root.viewMode === "scanning" || root.viewMode === "detail") ? Qt.rgba(0, 0, 0, 0.5) : (root.hasConn ? Qt.rgba(0, 0, 0, 0.5) : _over0)
                            wrapMode: Text.WordWrap; maximumLineCount: 1; horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: {
                                if (root.viewMode === "scanning" && !coreMa.containsMouse) return scanCountdown + "s"
                                if (root.viewMode === "scanning") return "Tap to stop"
                                if (root.viewMode === "detail" && root.selectedDevice) return root.deviceBattery ? root.deviceBattery : ""
                                if (root.viewMode === "devices") return "Tap to inspect"
                                return ""
                            }
                        }
                    }

                    SequentialAnimation {
                        id: coreScanBounce
                        property real scale: 1.0
                        running: root.viewMode === "scanning"; loops: Animation.Infinite
                        NumberAnimation { target: coreScanBounce; property: "scale"; from: 1.0; to: 1.3; duration: 500; easing.type: Easing.OutBack }
                        NumberAnimation { target: coreScanBounce; property: "scale"; from: 1.3; to: 1.0; duration: 500; easing.type: Easing.InOutSine }
                    }

                    Canvas {
                        id: coreWave; anchors.fill: parent
                        visible: centralCore.disconnectFill > 0; opacity: 0.95
                        property real wavePhase: 0.0
                        NumberAnimation on wavePhase { running: centralCore.disconnectFill > 0.0 && centralCore.disconnectFill < 1.0; loops: Animation.Infinite; from: 0; to: Math.PI * 2; duration: 800 }
                        onWavePhaseChanged: update()
                        Connections { target: centralCore; function onDisconnectFillChanged() { coreWave.update() } }
                        onPaint: {
                            var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                            if (centralCore.disconnectFill <= 0.001) return;
                            var r = width / 2; var fillY = height * (1.0 - centralCore.disconnectFill);
                            ctx.save(); ctx.beginPath(); ctx.arc(r, r, r, 0, 2 * Math.PI); ctx.clip();
                            ctx.beginPath(); ctx.moveTo(0, fillY);
                            if (centralCore.disconnectFill < 0.99) {
                                var waveAmp = 10 * Math.sin(centralCore.disconnectFill * Math.PI);
                                var cp1y = fillY + Math.sin(wavePhase) * waveAmp;
                                var cp2y = fillY + Math.cos(wavePhase + Math.PI) * waveAmp;
                                ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, fillY);
                                ctx.lineTo(width, height); ctx.lineTo(0, height);
                            } else { ctx.lineTo(width, 0); ctx.lineTo(width, height); ctx.lineTo(0, height); }
                            ctx.closePath();
                            var grad = ctx.createLinearGradient(0, 0, 0, height);
                            grad.addColorStop(0, _surf1.toString()); grad.addColorStop(1, _crust.toString());
                            ctx.fillStyle = grad; ctx.fill(); ctx.restore();
                        }
                    }

                    MouseArea {
                        id: coreMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.viewMode === "scanning") { stopScan(); return }
                            if (root.viewMode === "detail") { goHome(); return }
                            if (root.viewMode === "devices") { goHome(); return }
                            if (root.viewMode === "home" && root.hasConn) { goDevices("connected"); return }
                        }
                        onPressed: { if (root.viewMode === "home" && root.hasConn) { coreDrainAnim.stop(); coreFillAnim.start() } }
                        onReleased: { if (!coreFillAnim.running) coreDrainAnim.start() }
                    }

                    NumberAnimation {
                        id: coreFillAnim; target: centralCore; property: "disconnectFill"; to: 1.0; duration: 700; easing.type: Easing.InSine
                        onFinished: {
                            if (!coreMa.pressed) { centralCore.disconnectFill = 0.0; return }
                            centralCore.flashOpacity = 0.6; coreFlashAnim.start()
                            if (connectedDevices.length > 0) disconnectDevice(connectedDevices[0].mac)
                            centralCore.disconnectFill = 0.0
                        }
                    }
                    NumberAnimation { id: coreDrainAnim; target: centralCore; property: "disconnectFill"; to: 0.0; duration: 1000; easing.type: Easing.OutQuad }
                }
            }

            // ── Orbiting cards ──
            Repeater {
                id: orbitRepeater
                model: {
                    if (root.viewMode === "scanning") {
                        return root.devices.filter(function(d) { return root.connectedMacs.indexOf(d.mac) < 0 && root.pairedMacs.indexOf(d.mac) < 0 }).map(function(d) { return {type: "device", icon: d.icon, name: d.name || d.mac, subtitle: "New", mac: d.mac, deviceData: d} })
                    }
                    if (root.viewMode === "home") {
                        var items = []
                        items.push({type: "scan", icon: "\uF002", name: "Scan Devices", subtitle: "Tap to scan"})
                        if (root.hasConn) items.push({type: "nav-connected", icon: "\uF502", name: "Connected Devices", subtitle: connectedDevices.length + " device" + (connectedDevices.length !== 1 ? "s" : "")})
                        if (root.hasPaired) items.push({type: "nav-paired", icon: "\uF502", name: "Paired Devices", subtitle: pairedMacs.length + " device" + (pairedMacs.length !== 1 ? "s" : "")})
                        return items
                    }
                    if (root.viewMode === "devices") {
                        if (_deviceListType === "connected") {
                            return connectedDevices.map(function(d) { return {type: "device", icon: d.icon, name: d.name || d.mac, subtitle: "Connected", mac: d.mac, deviceData: d} })
                        } else {
                            return pairedMacs.map(function(mac) {
                                var found = null
                                for (var i = 0; i < root.devices.length; i++) { if (root.devices[i].mac === mac) { found = root.devices[i]; break } }
                                var name = found ? (found.name || mac) : mac
                                var icon = found ? found.icon : "\uF49A"
                                return {type: "device", icon: icon, name: name, subtitle: "Paired", mac: mac}
                            })
                        }
                    }
                    if (root.viewMode === "detail" && root.selectedDevice) {
                        var d = root.selectedDevice
                        var isConn = root.connectedMacs.indexOf(d.mac) >= 0
                        var detailItems = []
                        if (isConn) detailItems.push({type: "disconnect", icon: "\uF019", name: "Disconnect", subtitle: "Tap to disconnect", mac: d.mac})
                        detailItems.push({type: "forget", icon: "\uF2ED", name: "Forget Device", subtitle: "Remove from paired", mac: d.mac})
                        detailItems.push({type: "info", icon: "\uF49A", name: d.mac, subtitle: "MAC Address"})
                        if (root.deviceBattery) detailItems.push({type: "battery", icon: "\uF241", name: root.deviceBattery, subtitle: "Battery Level"})
                        return detailItems
                    }
                    return null
                }

                delegate: Item {
                    id: cardOrbit
                    required property var modelData
                    required property int index
                    width: 160; height: 56

                    property bool isLoaded: false
                    opacity: (isLoaded ? 1.0 : 0.0) * root.introCards
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                    Timer { running: true; interval: 40 + (cardOrbit.index * 30); onTriggered: cardOrbit.isLoaded = true }

                    property bool isConn: modelData.type === "device" && modelData.subtitle === "Connected"
                    property bool isFailed: false
                    property real flashOpacity: 0.0
                    property real bumpScale: 1.0
                    SequentialAnimation on bumpScale {
                        id: cardBumpAnim; running: false
                        NumberAnimation { to: 1.15; duration: 200; easing.type: Easing.OutBack }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.OutQuint }
                    }

                    property int totalCards: orbitRepeater.count
                    property real baseAngle: (cardOrbit.index / Math.max(1, totalCards)) * Math.PI * 2
                    property real liveAngle: (root.globalOrbitAngle * 1.5) + baseAngle
                    property real orbitRadiusX: 200 + (cardOrbit.index % 2) * 30
                    property real orbitRadiusY: 140 + (cardOrbit.index % 2) * 20
                    property real bobOffset: Math.sin(root.globalOrbitAngle * 6) * 8

                    x: orbitContainer.width / 2 - width / 2 + Math.cos(liveAngle) * orbitRadiusX
                    y: orbitContainer.height / 2 - height / 2 + Math.sin(liveAngle) * orbitRadiusY + bobOffset
                    z: Math.sin(liveAngle) > 0 ? 10 + index : index

                    scale: (cardOrbitMa.pressed ? 0.95 : (cardOrbitMa.containsMouse ? 1.05 : 1.0)) * bumpScale
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                    MultiEffect {
                        source: floatCard; anchors.fill: floatCard
                        shadowEnabled: true; shadowColor: "#000000"; shadowOpacity: 0.3; shadowBlur: 0.8; shadowVerticalOffset: 4; z: -1
                    }

                    Rectangle {
                        id: floatCard; anchors.fill: parent; radius: 14
                        property bool locksList: cardOrbitMa.containsMouse || cardOrbitMa.pressed
                        color: (modelData.type === "disconnect" || modelData.type === "forget") ? (locksList ? Qt.lighter(_red, 1.15) : Qt.darker(_red, 1.1)) : (locksList ? Qt.rgba(0xff, 0xff, 0xff, 0.13) : Qt.rgba(0xff, 0xff, 0xff, 0.05))
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            anchors.fill: parent; radius: 14; color: "transparent"
                            border.width: 1; border.color: (modelData.type === "disconnect" || modelData.type === "forget") ? _red : (cardOrbit.isConn ? _accent : _surf2)
                            Behavior on border.color { ColorAnimation { duration: 300 } }
                        }

                        Rectangle {
                            anchors.fill: parent; radius: 14; color: "#ffffff"
                            opacity: cardOrbit.flashOpacity; z: 5
                            PropertyAnimation on opacity { id: cardFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo }
                        }

                        RowLayout {
                            id: baseTextRow; anchors.fill: parent; anchors.margins: 10; spacing: 8
                            Text {
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
                                color: (modelData.type === "disconnect" || modelData.type === "forget") ? _crust : (cardOrbit.isConn ? _accent : (modelData.type === "scan" ? _accent : _text))
                                text: modelData.icon
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; Layout.minimumWidth: 80; spacing: 1
                                Text {
                                    Layout.fillWidth: true; text: modelData.name
                                    font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 11
                                    color: (modelData.type === "disconnect" || modelData.type === "forget") ? _crust : (cardOrbit.isConn ? _accent : _text)
                                    wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                                }
                                Text {
                                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                                    color: (modelData.type === "disconnect" || modelData.type === "forget") ? Qt.rgba(0, 0, 0, 0.6) : (cardOrbit.isConn ? _green : _over0)
                                    text: modelData.subtitle
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: cardOrbitMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cardOrbit.flashOpacity = 0.6; cardFlashAnim.start(); cardBumpAnim.start()
                            if (modelData.type === "scan") { triggerScan() }
                            else if (modelData.type === "nav-connected") { goDevices("connected") }
                            else if (modelData.type === "nav-paired") { goDevices("paired") }
                            else if (modelData.type === "device" && modelData.subtitle !== "Connected") {
                                goDetail(modelData.deviceData || {mac: modelData.mac, name: modelData.name, icon: modelData.icon})
                            }
                            else if (modelData.type === "device" && modelData.subtitle === "Connected") {
                                goDetail(modelData.deviceData || {mac: modelData.mac, name: modelData.name, icon: modelData.icon})
                            }
                            else if (modelData.type === "disconnect") {
                                disconnectDevice(modelData.mac)
                                goHome()
                            }
                            else if (modelData.type === "forget") {
                                removeDevice(modelData.mac)
                            }
                        }
                        onPressAndHold: {
                            if (modelData.type === "device") {
                                cardOrbit.flashOpacity = 0.6; cardFlashAnim.start(); cardBumpAnim.start()
                                connectDevice(modelData.mac)
                                var devData = modelData.deviceData || {mac: modelData.mac, name: modelData.name, icon: modelData.icon}
                                goDetail(devData)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            width: 160; height: 40; radius: 12
            color: _surf1
            opacity: root.introFooter
            transform: Translate { y: 20 * (1.0 - root.introFooter) }

            Rectangle {
                height: parent.height - 8; radius: 10; y: 4
                width: root.isPowered ? parent.width - 8 : 52
                x: root.isPowered ? 4 : (parent.width - 52) / 2
                color: root.isPowered ? _accent : _surf2
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                Behavior on color { ColorAnimation { duration: 200 } }

                RowLayout {
                    anchors.centerIn: parent; spacing: 6
                    Text { font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; color: root.isPowered ? _crust : _text; text: root.isPowered ? "\uF293" : "\uF019" }
                    Text { visible: root.isPowered; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold; color: _crust; text: "ON" }
                }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: toggleBt() }
        }
    }
    } // end wrapping Item
}
