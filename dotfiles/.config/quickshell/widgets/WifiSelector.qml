import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var serviceContext

    readonly property color _base:    "#1a2120"
    readonly property color _mantle:  "#1a2120"
    readonly property color _crust:   "#303635"
    readonly property color _surf0:   "#303635"
    readonly property color _surf1:   "#303635"
    readonly property color _surf2:   "#303635"
    readonly property color _text:    "#dde4e2"
    readonly property color _sub:     "#aec9e6"
    readonly property color _over0:   "#578466"
    readonly property color _accent:  "#81d5ca"
    readonly property color _red:     "#ffb4ab"
    readonly property color _green:   "#92d5ab"

    readonly property color accentLight: Qt.lighter(_accent, 1.15)

    property bool wifiEnabled: false
    property bool wifiPresent: true
    property var connectedNetwork: null
    property var networks: []
    property var savedNetworks: []
    property bool scanning: false
    property string pendingSsid: ""
    property bool showPassword: false

    property string viewMode: "home"
    property var selectedNetwork: null

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 200000; loops: Animation.Infinite; running: true
    }

    readonly property bool hasConn: connectedNetwork !== null
    readonly property bool isPowered: wifiEnabled
    readonly property var strongNetworks: networks.filter(function(n) { return n.active === "yes" || n.signal >= 40 })

    readonly property var _wifiIco: [
        "\uDB82\uDD2F", "\uDB82\uDD1F", "\uDB82\uDD22", "\uDB82\uDD25", "\uDB82\uDD28"
    ]

    function _wifiIcon(sig) {
        if (sig >= 80) return _wifiIco[4]
        if (sig >= 60) return _wifiIco[3]
        if (sig >= 40) return _wifiIco[2]
        if (sig >= 20) return _wifiIco[1]
        return _wifiIco[0]
    }

    function goHome() { viewMode = "home"; selectedNetwork = null; showPassword = false }
    function goNetworks() { viewMode = "devices"; selectedNetwork = null }
    function goSaved() { viewMode = "saved"; selectedNetwork = null }
    function goDetail(network) { viewMode = "detail"; selectedNetwork = network }

    function isNetworkSaved(ssid) {
        for (var i = 0; i < savedNetworks.length; i++) {
            if (savedNetworks[i].name === ssid) return true
        }
        return false
    }

    Timer { interval: 6000; running: true; repeat: true; onTriggered: {
        wifiPoll.running = false; wifiPoll.running = true
        wifiPowerCheck.running = false; wifiPowerCheck.running = true
        savedListProc.running = false; savedListProc.running = true
    }}

    Process {
        id: wifiPowerCheck
        command: ["sh", "-c", "nmcli radio wifi 2>/dev/null || echo 'disabled'"]
        stdout: StdioCollector { onStreamFinished: { wifiEnabled = text.trim() === "enabled" } }
    }

    Process {
        id: wifiPoll
        command: ["sh", "-c", "nmcli -t -f active,ssid,signal,security device wifi list 2>/dev/null || echo ''"]
        stdout: StdioCollector { onStreamFinished: { parseNetworks(text.trim()) } }
    }

    Process {
        id: savedListProc
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep '802-11-wireless' | cut -d: -f1 | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split('\n').filter(function(l) { return l && l.trim() })
                savedNetworks = lines.map(function(name) { return {name: name.trim()} })
            }
        }
    }

    Process {
        id: wifiRescan; running: false
        onExited: { scanning = false; wifiPoll.running = true }
    }

    Process {
        id: connectProcess
        property string targetSsid: ""
        stdout: StdioCollector { onStreamFinished: { wifiPoll.running = true } }
    }

    function parseNetworks(output) {
        if (!output || output === "") { networks = []; connectedNetwork = null; return }
        var lines = output.split('\n')
        var list = []; var conn = null
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim(); if (!line) continue
            var parts = line.split(':'); if (parts.length < 4) continue
            var active = parts[0]
            var ssid = parts.slice(1, parts.length - 2).join(':') || parts[1]
            var signal = parseInt(parts[parts.length - 2]) || 0
            var security = parts[parts.length - 1] || ""
            if (!ssid) continue
            var entry = {active: active, ssid: ssid, signal: signal, security: security, icon: _wifiIcon(signal), secured: security !== "" && security !== "--" && security.toLowerCase() !== "open"}
            list.push(entry)
            if (active === "yes") conn = entry
        }
        networks = list; connectedNetwork = conn
    }

    function toggleWifi() {
        if (wifiEnabled) { Quickshell.execDetached(["nmcli", "radio", "wifi", "off"]); wifiEnabled = false }
        else { Quickshell.execDetached(["nmcli", "radio", "wifi", "on"]); wifiEnabled = true; wifiPoll.running = true }
    }

    function connectToNetwork(ssid, password) {
        var cmd = ["nmcli", "device", "wifi", "connect", ssid]
        if (password && password !== "") cmd.push("password", password)
        connectProcess.targetSsid = ssid; connectProcess.command = cmd; connectProcess.running = true
        showPassword = false; pendingSsid = ""
    }

    function disconnectWifi() {
        Quickshell.execDetached(["sh", "-c", "nmcli device disconnect $(nmcli -t -f DEVICE,TYPE d | grep wifi | cut -d: -f1 | head -n1)"])
        wifiPoll.running = true
    }

    function doScan() {
        if (scanning) return; scanning = true; viewMode = "scanning"
        wifiRescan.command = ["sh", "-c", "nmcli device wifi list --rescan yes 2>/dev/null"]; wifiRescan.running = true
    }

    Component.onCompleted: {
        wifiPowerCheck.running = true
        wifiRescan.command = ["sh", "-c", "nmcli device wifi list --rescan yes 2>/dev/null"]
        wifiRescan.running = true
        savedListProc.running = true
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: _base
        border.color: _surf0
        border.width: 1
        clip: true

        // ── Background blobs ──
        Rectangle {
            width: parent.width * 0.8; height: width; radius: width / 2
            x: (parent.width / 2 - width / 2) + Math.cos(root.globalOrbitAngle * 2) * 150
            y: (parent.height / 2 - height / 2) + Math.sin(root.globalOrbitAngle * 2) * 100
            opacity: root.isPowered ? 0.08 : 0.02
            color: root.hasConn ? accentLight : _surf2
            Behavior on color { ColorAnimation { duration: 1000 } }
            Behavior on opacity { NumberAnimation { duration: 1000 } }
            visible: opacity > 0.01
        }
        Rectangle {
            width: parent.width * 0.9; height: width; radius: width / 2
            x: (parent.width / 2 - width / 2) + Math.sin(root.globalOrbitAngle * 1.5) * -150
            y: (parent.height / 2 - height / 2) + Math.cos(root.globalOrbitAngle * 1.5) * -100
            opacity: root.isPowered ? 0.06 : 0.01
            color: root.hasConn ? Qt.darker(_accent, 1.25) : _surf1
            Behavior on color { ColorAnimation { duration: 1000 } }
            Behavior on opacity { NumberAnimation { duration: 1000 } }
            visible: opacity > 0.01
        }

        // ── Radar rings ──
        Item {
            id: radarItem
            anchors.fill: parent
            opacity: root.isPowered ? 1.0 : 0.0
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
                    border.color: _accent
                    border.width: 1
                    opacity: root.hasConn ? 0.08 - (index * 0.02) : 0.03
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }

        // ── Orbit container ──
        Item {
            id: orbitContainer
            anchors.fill: parent

            // ── Central core ──
            Item {
                id: coreItem
                anchors.centerIn: parent
                width: 140; height: 140

                MultiEffect {
                    source: centralCore
                    anchors.fill: centralCore
                    shadowEnabled: true
                    shadowColor: "#000000"
                    shadowOpacity: root.isPowered ? 0.5 : 0.0
                    shadowBlur: 1.2
                    shadowVerticalOffset: 6
                    z: -1
                    Behavior on shadowOpacity { NumberAnimation { duration: 600 } }
                }

                Rectangle {
                    id: centralCore
                    anchors.fill: parent
                    radius: width / 2

                    property bool isDanger: coreMa.containsMouse && root.hasConn && root.viewMode === "home"
                    property real disconnectFill: 0.0
                    property real flashOpacity: 0.0
                    property real bumpScale: 1.0

                    SequentialAnimation on bumpScale {
                        id: coreBumpAnim; running: false
                        NumberAnimation { to: 1.15; duration: 200; easing.type: Easing.OutBack }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.OutQuint }
                    }

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0.0
                            color: {
                                if (root.viewMode === "scanning") return accentLight;
                                if (!root.isPowered) return _mantle;
                                if (centralCore.isDanger) return Qt.lighter(_red, 1.15);
                                return root.hasConn ? accentLight : _surf0;
                            }
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                        GradientStop {
                            position: 1.0
                            color: {
                                if (root.viewMode === "scanning") return _accent;
                                if (!root.isPowered) return _crust;
                                if (centralCore.isDanger) return _red;
                                return root.hasConn ? _accent : _base;
                            }
                            Behavior on color { ColorAnimation { duration: 300 } }
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
                        anchors.fill: parent; radius: parent.radius
                        color: "#ffffff"; opacity: centralCore.flashOpacity
                        PropertyAnimation on opacity { id: coreFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo }
                    }

                    // ── Pulse ring ──
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 40; height: width; radius: width / 2
                        color: "transparent"
                        border.color: _accent
                        border.width: 3
                        z: -2
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

                    // ── Scanning ripple ──
                    Item {
                        anchors.fill: parent
                        opacity: root.viewMode === "scanning" ? 1.0 : 0.0
                        visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: 400 } }
                        Repeater {
                            model: 3
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.4; height: width; radius: width / 2
                                color: "transparent"
                                border.color: _accent; border.width: 2
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

                    // ── Core content ──
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        visible: !showPassword && root.viewMode !== "home"
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 300 } }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 32
                            color: {
                                if (root.viewMode === "scanning") return _crust;
                                if (root.viewMode === "detail" && root.selectedNetwork) return _crust;
                                if (root.viewMode === "devices") return _crust;
                                return root.hasConn ? _crust : (root.isPowered ? _accent : _over0)
                            }
                            text: {
                                if (root.viewMode === "scanning" && coreMa.containsMouse) return "\uF04D"
                                if (root.viewMode === "scanning") return "\uF06EB"
                                if (root.viewMode === "detail" && root.selectedNetwork) return root.selectedNetwork.icon
                                if (root.viewMode === "devices") return "\uF06EB"
                                if (root.viewMode === "saved") return "\uF02C"
                                return root.hasConn ? (connectedNetwork?.icon ?? "\uF06EB") : (root.isPowered ? "\uF06EB" : "\uF019")
                            }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 120
                            visible: root.viewMode !== "home"
                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Black; font.pixelSize: 13
                            color: {
                                if (root.viewMode === "scanning") return _crust;
                                if (root.viewMode === "detail") return _crust;
                                return root.hasConn ? _crust : _over0
                            }
                            wrapMode: Text.WordWrap; maximumLineCount: 2; horizontalAlignment: Text.AlignHCenter
                            text: {
                                if (root.viewMode === "scanning" && coreMa.containsMouse) return "Stop Scan"
                                if (root.viewMode === "scanning") return "Scanning..."
                                if (root.viewMode === "detail" && root.selectedNetwork) return root.selectedNetwork.ssid
                                if (root.viewMode === "devices") return "Available Networks"
                                if (root.viewMode === "saved") return "Saved Networks"
                                return ""
                            }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 120
                            visible: root.viewMode !== "home"
                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 10
                            color: {
                                if (root.viewMode === "scanning") return Qt.rgba(0, 0, 0, 0.5);
                                if (root.viewMode === "detail") return Qt.rgba(0, 0, 0, 0.5);
                                return _over0
                            }
                            wrapMode: Text.WordWrap; maximumLineCount: 1; horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: {
                                if (root.viewMode === "scanning" && !coreMa.containsMouse) return ""
                                if (root.viewMode === "scanning") return "Tap to stop"
                                if (root.viewMode === "detail" && root.selectedNetwork) return root.selectedNetwork.signal + "% " + (root.selectedNetwork.secured ? "Secured" : "Open")
                                if (root.viewMode === "devices") return "Tap to inspect"
                                if (root.viewMode === "saved") return root.savedNetworks.length + " network" + (root.savedNetworks.length !== 1 ? "s" : "")
                                return ""
                            }
                        }
                    }

                    // ── Home core content ──
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        visible: !showPassword && root.viewMode === "home"
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 300 } }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 32
                            color: root.hasConn ? _crust : (root.isPowered ? _accent : _over0)
                            text: root.hasConn ? (connectedNetwork?.icon ?? "\uF06EB") : (root.isPowered ? "\uF06EB" : "\uF019")
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 120
                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Black; font.pixelSize: 13
                            color: root.hasConn ? _crust : _over0
                            text: root.hasConn ? (connectedNetwork?.ssid ?? "") : (root.isPowered ? "No Connection" : "Disabled")
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 10
                            color: root.hasConn ? Qt.rgba(0, 0, 0, 0.5) : _over0
                            text: root.hasConn ? "Hold to disconnect" : ""
                        }
                    }

                    // ── Password layer ──
                    Item {
                        id: pwdLayer
                        anchors.fill: parent
                        opacity: showPassword ? 1.0 : 0.0
                        visible: opacity > 0.01
                        scale: showPassword ? 1.0 : 0.8
                        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutSine } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 24; color: _crust; text: "\uF06EB" }
                            Text {
                                Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: 110
                                font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 11
                                color: _crust; text: pendingSsid; elide: Text.ElideRight
                            }
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 110; height: 30; radius: 15
                                color: _surf0
                                border.color: pwdField.activeFocus ? _crust : "transparent"; border.width: 1
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                TextInput {
                                    id: pwdField
                                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: _text
                                    echoMode: TextInput.Password; clip: true
                                    onAccepted: {
                                        if (text.trim() !== "") { connectToNetwork(pendingSsid, text); text = ""; root.forceActiveFocus() }
                                    }
                                    Keys.onEscapePressed: { pendingSsid = ""; showPassword = false; text = "" }
                                }
                            }
                        }
                        Timer { id: deferFocus; interval: 50; onTriggered: pwdField.forceActiveFocus() }
                        onVisibleChanged: { if (visible) { pwdField.text = ""; deferFocus.start() } }
                    }

                    // ── Hold-to-disconnect wave ──
                    Canvas {
                        id: coreWave
                        anchors.fill: parent
                        visible: centralCore.disconnectFill > 0
                        opacity: 0.95
                        property real wavePhase: 0.0
                        NumberAnimation on wavePhase {
                            running: centralCore.disconnectFill > 0.0 && centralCore.disconnectFill < 1.0
                            loops: Animation.Infinite; from: 0; to: Math.PI * 2; duration: 800
                        }
                        onWavePhaseChanged: update()
                        Connections { target: centralCore; function onDisconnectFillChanged() { coreWave.update() } }
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            if (centralCore.disconnectFill <= 0.001) return;
                            var r = width / 2;
                            var fillY = height * (1.0 - centralCore.disconnectFill);
                            ctx.save();
                            ctx.beginPath(); ctx.arc(r, r, r, 0, 2 * Math.PI); ctx.clip();
                            ctx.beginPath(); ctx.moveTo(0, fillY);
                            if (centralCore.disconnectFill < 0.99) {
                                var waveAmp = 10 * Math.sin(centralCore.disconnectFill * Math.PI);
                                var cp1y = fillY + Math.sin(wavePhase) * waveAmp;
                                var cp2y = fillY + Math.cos(wavePhase + Math.PI) * waveAmp;
                                ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, fillY);
                                ctx.lineTo(width, height); ctx.lineTo(0, height);
                            } else {
                                ctx.lineTo(width, 0); ctx.lineTo(width, height); ctx.lineTo(0, height);
                            }
                            ctx.closePath();
                            var grad = ctx.createLinearGradient(0, 0, 0, height);
                            grad.addColorStop(0, _surf1.toString()); grad.addColorStop(1, _crust.toString());
                            ctx.fillStyle = grad; ctx.fill(); ctx.restore();
                        }
                    }

                    // ── Pulse ring glow ──
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 15; height: width; radius: width / 2
                        color: "transparent"
                        border.color: _accent; border.width: 3
                        z: -2
                        property real pulseOp: 0.0
                        property real pulseSc: 1.0
                        opacity: root.hasConn ? pulseOp : 0.0
                        scale: pulseSc
                        Timer {
                            interval: 45; running: parent.opacity > 0.01; repeat: true
                            onTriggered: {
                                var t = Date.now() / 1000;
                                parent.pulseOp = 0.3 + Math.sin(t * 2.5) * 0.15;
                                parent.pulseSc = 1.02 + Math.cos(t * 3.0) * 0.02;
                            }
                        }
                    }

                    MouseArea {
                        id: coreMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.viewMode === "scanning") { wifiRescan.running = false; scanning = false; viewMode = "home"; return }
                            if (root.viewMode === "detail") { goHome(); return }
                            if (root.viewMode === "devices") { goHome(); return }
                            if (root.viewMode === "saved") { goHome(); return }
                            if (root.viewMode === "home") { goNetworks(); return }
                        }
                        onPressed: { if (root.viewMode === "home") { coreDrainAnim.stop(); coreFillAnim.start() } }
                        onReleased: { if (!coreFillAnim.running) coreDrainAnim.start() }
                    }

                    NumberAnimation {
                        id: coreFillAnim
                        target: centralCore; property: "disconnectFill"
                        to: 1.0; duration: 700; easing.type: Easing.InSine
                        onFinished: {
                            if (!coreMa.pressed) { centralCore.disconnectFill = 0.0; return }
                            centralCore.flashOpacity = 0.6; coreFlashAnim.start(); coreBumpAnim.start()
                            disconnectWifi()
                            centralCore.disconnectFill = 0.0
                        }
                    }
                    NumberAnimation {
                        id: coreDrainAnim
                        target: centralCore; property: "disconnectFill"
                        to: 0.0; duration: 1000; easing.type: Easing.OutQuad
                    }
                }
            }

            // ── Orbiting cards ──
            Repeater {
                id: orbitRepeater
                model: {
                    if (root.viewMode === "scanning") {
                        return root.strongNetworks.filter(function(n) { return n.active !== "yes" }).map(function(n) { return {type: "network", icon: n.icon, ssid: n.ssid, signal: n.signal, secured: n.secured, active: n.active, security: n.security} })
                    }
                    if (root.viewMode === "home") {
                        var items = []
                        items.push({type: "nav-networks", icon: "\uF06EB", name: "Networks", subtitle: root.strongNetworks.length + " available"})
                        items.push({type: "nav-saved", icon: "\uF02C", name: "Saved Networks", subtitle: root.savedNetworks.length + " saved"})
                        return items
                    }
                    if (root.viewMode === "devices") {
                        return root.strongNetworks.filter(function(n) { return n.active !== "yes" }).map(function(n) { return {type: "network", icon: n.icon, ssid: n.ssid, signal: n.signal, secured: n.secured, active: n.active, security: n.security, saved: root.isNetworkSaved(n.ssid)} })
                    }
                    if (root.viewMode === "saved") {
                        return root.savedNetworks.map(function(n) {
                            var isConnected = root.connectedNetwork && root.connectedNetwork.ssid === n.name
                            return {type: "saved-net", icon: "\uF02C", name: n.name, subtitle: isConnected ? "Connected" : "Tap to connect", active: isConnected ? "yes" : "no"}
                        })
                    }
                    if (root.viewMode === "detail" && root.selectedNetwork) {
                        var d = root.selectedNetwork
                        var detailItems = []
                        if (d.active === "yes") detailItems.push({type: "disconnect", icon: "\uF019", name: "Disconnect", subtitle: "Tap to disconnect", ssid: d.ssid})
                        if (root.isNetworkSaved(d.ssid)) detailItems.push({type: "forget", icon: "\uF2ED", name: "Forget Network", subtitle: "Remove saved profile", ssid: d.ssid})
                        detailItems.push({type: "info", icon: "\uF06EB", name: d.ssid, subtitle: d.signal + "% " + (d.secured ? "Secured" : "Open")})
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
                    opacity: isLoaded ? 1.0 : 0.0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                    Timer { running: true; interval: 40 + (cardOrbit.index * 30); onTriggered: cardOrbit.isLoaded = true }

                    property bool isActive: modelData.active === "yes"
                    property bool isHighlighted: isActive
                    property bool isSecured: modelData.secured ?? false
                    property bool isFailed: false
                    property real fillLevel: 0.0
                    property bool triggered: false
                    property real flashOpacity: 0.0
                    property real renderFill: isActive ? 1.0 : fillLevel

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
                        source: floatCard
                        anchors.fill: floatCard
                        shadowEnabled: true
                        shadowColor: "#000000"
                        shadowOpacity: 0.3
                        shadowBlur: 0.8
                        shadowVerticalOffset: 4
                        z: -1
                    }

                    Rectangle {
                        id: floatCard
                        anchors.fill: parent
                        radius: 14

                        property bool locksList: cardOrbitMa.containsMouse || cardOrbitMa.pressed

                        color: (modelData.type === "disconnect" || modelData.type === "forget") ? (locksList ? Qt.lighter(_red, 1.15) : Qt.darker(_red, 1.1)) : (locksList ? Qt.rgba(0xff, 0xff, 0xff, 0.13) : Qt.rgba(0xff, 0xff, 0xff, 0.05))
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle { anchors.fill: parent; radius: parent.radius; color: _red; opacity: cardOrbit.isFailed ? 0.3 : 0.0; Behavior on opacity { NumberAnimation { duration: 300 } } }

                        Rectangle {
                            anchors.fill: parent; radius: 14; color: "transparent"
                            border.width: 1; border.color: (modelData.type === "disconnect" || modelData.type === "forget") ? _red : (cardOrbit.isHighlighted ? _accent : _surf2)
                            visible: !floatCard.locksList
                            Behavior on border.color { ColorAnimation { duration: 300 } }
                        }

                        Rectangle {
                            anchors.fill: parent; radius: 14
                            opacity: floatCard.locksList || cardOrbit.isHighlighted ? 1.0 : 0.0
                            color: "transparent"
                            border.width: cardOrbit.isHighlighted && !floatCard.locksList ? 1 : 2
                            border.color: cardOrbit.isFailed ? _red : "transparent"
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                            Rectangle { anchors.fill: parent; anchors.margins: cardOrbit.isHighlighted && !floatCard.locksList ? 1 : 2; radius: 12; color: _base; opacity: floatCard.locksList ? 0.9 : 1.0 }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: cardOrbit.isFailed ? Qt.lighter(_red, 1.15) : accentLight }
                                GradientStop { position: 1.0; color: cardOrbit.isFailed ? _red : _accent }
                            }
                            z: -1
                        }

                        Rectangle {
                            anchors.fill: parent; radius: 14; color: "#ffffff"
                            opacity: cardOrbit.flashOpacity; z: 5
                            PropertyAnimation on opacity { id: cardFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo }
                        }

                        Canvas {
                            id: waveCanvas
                            anchors.fill: parent
                            property real wavePhase: 0.0
                            NumberAnimation on wavePhase {
                                running: cardOrbit.renderFill > 0.0 && cardOrbit.renderFill < 1.0
                                loops: Animation.Infinite; from: 0; to: Math.PI * 2; duration: 800
                            }
                            onWavePhaseChanged: update()
                            Connections { target: cardOrbit; function onRenderFillChanged() { waveCanvas.update() } }
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                if (cardOrbit.renderFill <= 0.001) return;
                                var currentW = width * cardOrbit.renderFill; var r = 14;
                                ctx.save(); ctx.beginPath(); ctx.moveTo(0, 0);
                                if (cardOrbit.renderFill < 0.99) {
                                    var waveAmp = 12 * Math.sin(cardOrbit.renderFill * Math.PI);
                                    if (currentW - waveAmp < 0) waveAmp = currentW;
                                    var cp1x = currentW + Math.sin(wavePhase) * waveAmp;
                                    var cp2x = currentW + Math.cos(wavePhase + Math.PI) * waveAmp;
                                    ctx.lineTo(currentW, 0);
                                    ctx.bezierCurveTo(cp2x, height * 0.33, cp1x, height * 0.66, currentW, height);
                                    ctx.lineTo(0, height);
                                } else { ctx.lineTo(width, 0); ctx.lineTo(width, height); ctx.lineTo(0, height); }
                                ctx.closePath(); ctx.clip();
                                ctx.beginPath(); ctx.moveTo(r, 0); ctx.lineTo(width - r, 0); ctx.arcTo(width, 0, width, r, r);
                                ctx.lineTo(width, height - r); ctx.arcTo(width, height, width - r, height, r);
                                ctx.lineTo(r, height); ctx.arcTo(0, height, 0, height - r, r);
                                ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r); ctx.closePath();
                                var grad = ctx.createLinearGradient(0, 0, currentW, 0);
                                grad.addColorStop(0, accentLight.toString()); grad.addColorStop(1, _accent.toString());
                                ctx.fillStyle = grad; ctx.fill(); ctx.restore();
                            }
                        }

                        Rectangle {
                            anchors.fill: parent; radius: parent.radius; color: "transparent"
                            border.color: _accent; border.width: 2
                            visible: cardOrbit.isActive && !floatCard.locksList && !cardOrbit.isFailed
                            SequentialAnimation on scale {
                                loops: Animation.Infinite; running: cardOrbit.isActive && !floatCard.locksList
                                NumberAnimation { to: 1.08; duration: 2000; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 2000; easing.type: Easing.InOutSine }
                            }
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite; running: cardOrbit.isActive && !floatCard.locksList
                                NumberAnimation { to: 0.0; duration: 2000; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0.5; duration: 2000; easing.type: Easing.InOutSine }
                            }
                        }

                        RowLayout {
                            id: baseTextRow
                            anchors.fill: parent; anchors.margins: 10; spacing: 8
                            Text {
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
                                color: (modelData.type === "disconnect" || modelData.type === "forget") ? _crust : (cardOrbit.isFailed ? _red : (floatCard.locksList ? _text : _accent))
                                text: modelData.icon; Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; Layout.minimumWidth: 80; spacing: 1
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.type === "saved-net" ? modelData.name : (modelData.ssid ?? modelData.name ?? "")
                                    font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 11
                                    color: (modelData.type === "disconnect" || modelData.type === "forget") ? _crust : (cardOrbit.isFailed ? _red : (cardOrbit.isHighlighted ? _accent : _text))
                                    elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                                Text {
                                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                                    color: (modelData.type === "disconnect" || modelData.type === "forget") ? Qt.rgba(0, 0, 0, 0.6) : (cardOrbit.isFailed ? _red : (cardOrbit.isActive ? _green : _over0))
                                    text: {
                                        if (modelData.type === "disconnect") return "Tap to disconnect"
                                        if (modelData.type === "forget") return "Remove saved profile"
                                        if (modelData.type === "saved-net") return modelData.subtitle
                                        if (modelData.type === "nav-networks" || modelData.type === "nav-saved") return modelData.subtitle
                                        if (cardOrbit.isActive) return "Connected"
                                        if (modelData.saved) return "Saved"
                                        return modelData.secured ? "Secured" : "Open"
                                    }
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }
                            Text {
                                visible: modelData.type === "network" || modelData.type === "info"
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: _over0
                                text: (modelData.signal ?? 0) + "%"
                            }
                        }

                        Item {
                            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                            width: parent.width * cardOrbit.renderFill; clip: true; visible: cardOrbit.renderFill > 0.001
                            RowLayout {
                                x: baseTextRow.x; y: baseTextRow.y; width: baseTextRow.width; height: baseTextRow.height; spacing: 8
                                Text { font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; color: _crust; text: modelData.icon }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 1
                                    Text { Layout.fillWidth: true; text: modelData.ssid ?? modelData.name ?? ""; font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 11; color: _crust; elide: Text.ElideRight }
                                    Text { font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: _crust; text: cardOrbit.isActive ? "Connected" : (root.isNetworkSaved(modelData.ssid) ? "Saved" : "Hold...") }
                                }
                                Text { visible: modelData.type === "network"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: _crust; text: (modelData.signal ?? 0) + "%" }
                            }
                        }

                        NumberAnimation {
                            id: fillAnim; target: cardOrbit; property: "fillLevel"; to: 1.0
                            duration: 600 * (1.0 - cardOrbit.fillLevel); easing.type: Easing.InSine
                            onFinished: {
                                cardOrbit.triggered = true; cardOrbit.flashOpacity = 0.6; cardFlashAnim.start(); cardBumpAnim.start()
                                if (cardOrbit.isActive) disconnectWifi()
                                else if (modelData.type === "network") {
                                    if (root.isNetworkSaved(modelData.ssid)) {
                                        connectToNetwork(modelData.ssid, "")
                                    } else if (modelData.secured) {
                                        pendingSsid = modelData.ssid; showPassword = true
                                    } else {
                                        connectToNetwork(modelData.ssid, "")
                                    }
                                }
                                cardOrbit.triggered = false; drainAnim.start()
                            }
                        }
                        NumberAnimation { id: drainAnim; target: cardOrbit; property: "fillLevel"; to: 0.0; duration: 1500 * cardOrbit.fillLevel; easing.type: Easing.OutQuad }

                        MouseArea {
                            id: cardOrbitMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                cardOrbit.flashOpacity = 0.6; cardFlashAnim.start(); cardBumpAnim.start()
                                if (modelData.type === "nav-networks") { goNetworks() }
                                else if (modelData.type === "nav-saved") { goSaved() }
                                else if (modelData.type === "network") { goDetail(modelData) }
                                else if (modelData.type === "saved-net") {
                                    connectToNetwork(modelData.name, "")
                                }
                                else if (modelData.type === "disconnect") {
                                    disconnectWifi(); goHome()
                                }
                                else if (modelData.type === "forget") {
                                    Quickshell.execDetached(["sh", "-c", "nmcli connection delete '" + modelData.ssid + "' 2>/dev/null"])
                                    savedListProc.running = false; savedListProc.running = true
                                    goHome()
                                }
                            }
                            onPressed: { if (modelData.type === "network" && cardOrbit.fillLevel === 0.0) { drainAnim.stop(); fillAnim.start() } }
                            onReleased: { if (modelData.type === "network" && cardOrbit.fillLevel < 1.0) { fillAnim.stop(); drainAnim.start() } }
                        }
                    }
                }
            }
        }

        // ── Toggle bar ──
        Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: 160; height: 40; radius: 12
            color: _surf1

            Rectangle {
                id: wifiTogglePill
                height: parent.height - 8; radius: 10; y: 4
                width: root.isPowered ? parent.width - 8 : 52
                x: root.isPowered ? 4 : (parent.width - 52) / 2
                color: root.isPowered ? _accent : _surf2
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                Behavior on color { ColorAnimation { duration: 200 } }

                RowLayout {
                    anchors.centerIn: parent; spacing: 6
                    Text {
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                        color: root.isPowered ? _crust : _text
                        text: root.isPowered ? "\uF06EB" : "\uF019"
                    }
                    Text {
                        visible: root.isPowered
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold
                        color: _crust; text: "ON"
                    }
                }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: toggleWifi() }
        }
    }
}
