import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: popup

    readonly property string scriptsDir: Qt.resolvedUrl("../calendar/").toString().replace("file://", "")

    // ── Colors (match bar theme) ──
    readonly property color _base: "#1a2120"
    readonly property color _mantle: "#151c1b"
    readonly property color _crust: "#0d1211"
    readonly property color _text: "#dde4e2"
    readonly property color _sub1: "#b0b8b6"
    readonly property color _sub0: "#8a9290"
    readonly property color _surf2: "#575f5d"
    readonly property color _surf1: "#3b4341"
    readonly property color _surf0: "#303635"
    readonly property color _over2: "#757d7b"
    readonly property color _over1: "#575f5d"
    readonly property color _over0: "#434b49"
    readonly property color _accent: "#81d5ca"
    readonly property color _accentLight: "#b2ebe3"
    readonly property color _green: "#92d5ab"
    readonly property color _red: "#ffb4ab"
    readonly property color _peach: "#e8a87c"
    readonly property color _lavender: "#cdb4db"

    // ── Time of day colors ──
    readonly property color timeColor: {
        let h = currentTime.getHours();
        if (h >= 5 && h < 12) return _peach;
        if (h >= 12 && h < 17) return _accent;
        if (h >= 17 && h < 21) return _lavender;
        return _accent;
    }

    // ── State ──
    property var currentTime: new Date()
    property var weatherData: null
    property int weatherView: 0
    property int targetWeatherView: 0
    property real weatherContentOpacity: 1.0
    property real weatherContentOffset: 0.0
    property int weatherAnimDirection: 1
    property real transitionSpin: 0.0
    property real transitionScale: 1.0
    property bool visible_: false

    // ── Intro animation ──
    property real introMain: 0
    property real introAmbient: 0
    property real introClock: 0
    property real introCalendar: 0
    property real introWeather: 0

    // ── Orbit ──
    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    // ── Second pulse ──
    property real secondPulse: 1.0
    NumberAnimation on secondPulse {
        id: pulseReset; to: 1.0; duration: 600; easing.type: Easing.OutQuint; running: false
    }

    Timer {
        interval: 1000; running: popup.visible_; repeat: true
        onTriggered: {
            popup.currentTime = new Date();
            popup.secondPulse = 1.06;
            pulseReset.start();
            if (popup.currentTime.getHours() === 0 && popup.currentTime.getMinutes() === 0) {
                updateCalendarGrid();
            }
        }
    }

    function show() {
        visible_ = true
        introMain = 0; introAmbient = 0; introClock = 0; introCalendar = 0; introWeather = 0
        introAnim.start()
        weatherPoller.running = true
        updateCalendarGrid()
    }
    function hide() {
        exitAnim.start()
    }

    SequentialAnimation {
        id: introAnim
        running: false
        PauseAnimation { duration: 20 }
        ParallelAnimation {
            NumberAnimation { target: popup; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart }
            SequentialAnimation {
                PauseAnimation { duration: 150 }
                NumberAnimation { target: popup; property: "introAmbient"; from: 0; to: 1.0; duration: 1000; easing.type: Easing.OutSine }
            }
            SequentialAnimation {
                PauseAnimation { duration: 250 }
                NumberAnimation { target: popup; property: "introClock"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
            }
            SequentialAnimation {
                PauseAnimation { duration: 350 }
                NumberAnimation { target: popup; property: "introCalendar"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuint }
            }
            SequentialAnimation {
                PauseAnimation { duration: 400 }
                NumberAnimation { target: popup; property: "introWeather"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuint }
            }
        }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: popup; property: "introMain"; to: 0; duration: 400; easing.type: Easing.InQuart }
        NumberAnimation { target: popup; property: "introAmbient"; to: 0; duration: 250; easing.type: Easing.InQuart }
        NumberAnimation { target: popup; property: "introClock"; to: 0; duration: 300; easing.type: Easing.InQuart }
        NumberAnimation { target: popup; property: "introCalendar"; to: 0; duration: 350; easing.type: Easing.InQuart }
        NumberAnimation { target: popup; property: "introWeather"; to: 0; duration: 350; easing.type: Easing.InQuart }
        onFinished: popup.visible_ = false
    }

    // ── Weather transitions ──
    readonly property color activeWeatherHex: {
        if (!weatherData) return _accent;
        if (weatherView === 0 && weatherData.current_hex) return weatherData.current_hex;
        if (weatherData.forecast && weatherData.forecast[weatherView]) return weatherData.forecast[weatherView].hex;
        return _accent;
    }

    property real targetTemp: {
        if (!weatherData) return 0;
        if (targetWeatherView === 0 && weatherData.current_temp !== undefined) return Number(weatherData.current_temp);
        if (weatherData.forecast && weatherData.forecast[targetWeatherView]) return Number(weatherData.forecast[targetWeatherView].max);
        return 0;
    }
    property real displayedTemp: targetTemp
    Behavior on displayedTemp { NumberAnimation { duration: 800; easing.type: Easing.OutQuart } }

    SequentialAnimation {
        id: weatherTransitionAnim
        ParallelAnimation {
            NumberAnimation { target: popup; property: "weatherContentOpacity"; to: 0.0; duration: 250; easing.type: Easing.InSine }
            NumberAnimation { target: popup; property: "weatherContentOffset"; to: -40 * weatherAnimDirection; duration: 250; easing.type: Easing.InSine }
            NumberAnimation { target: popup; property: "transitionSpin"; to: 180 * weatherAnimDirection; duration: 300; easing.type: Easing.InBack }
            NumberAnimation { target: popup; property: "transitionScale"; to: 0.8; duration: 300; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                weatherView = targetWeatherView;
                weatherContentOffset = 40 * weatherAnimDirection;
                transitionSpin = -180 * weatherAnimDirection;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: popup; property: "weatherContentOpacity"; to: 1.0; duration: 450; easing.type: Easing.OutQuart }
            NumberAnimation { target: popup; property: "weatherContentOffset"; to: 0.0; duration: 450; easing.type: Easing.OutQuart }
            NumberAnimation { target: popup; property: "transitionSpin"; to: 0.0; duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            NumberAnimation { target: popup; property: "transitionScale"; to: 1.0; duration: 500; easing.type: Easing.OutBack }
        }
    }

    function setWeatherView(idx) {
        if (idx < 0 || idx > 4 || !weatherData) return;
        if (idx === targetWeatherView) return;
        if (weatherTransitionAnim.running) {
            weatherTransitionAnim.stop();
            weatherView = targetWeatherView;
        }
        weatherAnimDirection = idx > weatherView ? 1 : -1;
        targetWeatherView = idx;
        weatherTransitionAnim.start();
    }

    property int activeHourIndex: {
        if (weatherView !== 0 || !weatherData || !weatherData.forecast || !weatherData.forecast[0] || !weatherData.forecast[0].hourly) return -1;
        let ch = currentTime.getHours();
        let hrArr = weatherData.forecast[0].hourly.slice(0, 8);
        let bestIdx = -1; let minDiff = 999;
        for (let i = 0; i < hrArr.length; i++) {
            let h = parseInt((hrArr[i].time || "00:00").split(":")[0]);
            let diff = Math.abs(h - ch);
            if (diff < minDiff) { minDiff = diff; bestIdx = i; }
        }
        return bestIdx !== -1 ? bestIdx : 0;
    }

    // ── Weather polling ──
    Process {
        id: weatherPoller
        command: ["bash", popup.scriptsDir + "weather.sh", "--json"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") { try { popup.weatherData = JSON.parse(txt); } catch(e) {} }
            }
        }
    }

    Timer {
        interval: 150000; running: popup.visible_; repeat: true
        onTriggered: weatherPoller.running = true
    }

    // ── Calendar ──
    property int monthOffset: 0
    property int targetMonthOffset: 0
    property string targetMonthName: ""
    ListModel { id: calendarModel }

    property real calendarContentOpacity: 1.0
    property real calendarContentOffset: 0.0
    property int calendarAnimDirection: 1

    SequentialAnimation {
        id: calendarTransitionAnim
        ParallelAnimation {
            NumberAnimation { target: popup; property: "calendarContentOpacity"; to: 0.0; duration: 200; easing.type: Easing.InSine }
            NumberAnimation { target: popup; property: "calendarContentOffset"; to: -20 * calendarAnimDirection; duration: 200; easing.type: Easing.InSine }
        }
        ScriptAction { script: { monthOffset = targetMonthOffset; calendarContentOffset = 20 * calendarAnimDirection; } }
        ParallelAnimation {
            NumberAnimation { target: popup; property: "calendarContentOpacity"; to: 1.0; duration: 350; easing.type: Easing.OutQuart }
            NumberAnimation { target: popup; property: "calendarContentOffset"; to: 0.0; duration: 350; easing.type: Easing.OutQuart }
        }
    }

    function setMonthOffset(newOffset) {
        if (newOffset === targetMonthOffset) return;
        if (calendarTransitionAnim.running) { calendarTransitionAnim.stop(); monthOffset = targetMonthOffset; }
        calendarAnimDirection = newOffset > targetMonthOffset ? 1 : -1;
        targetMonthOffset = newOffset;
        calendarTransitionAnim.start();
    }

    function updateCalendarGrid() {
        let d = new Date(currentTime.getTime());
        d.setDate(1);
        d.setMonth(d.getMonth() + monthOffset);
        let targetMonth = d.getMonth();
        let targetYear = d.getFullYear();
        let actualToday = new Date();
        let isRealCurrentMonth = (actualToday.getMonth() === targetMonth && actualToday.getFullYear() === targetYear);
        let todayDate = actualToday.getDate();
        targetMonthName = Qt.formatDateTime(d, "MMMM yyyy");
        let firstDay = new Date(targetYear, targetMonth, 1).getDay();
        firstDay = (firstDay === 0) ? 6 : firstDay - 1;
        let daysInMonth = new Date(targetYear, targetMonth + 1, 0).getDate();
        let daysInPrevMonth = new Date(targetYear, targetMonth, 0).getDate();
        calendarModel.clear();
        for (let i = firstDay - 1; i >= 0; i--) {
            calendarModel.append({ dayNum: (daysInPrevMonth - i).toString(), isCurrentMonth: false, isToday: false });
        }
        for (let i = 1; i <= daysInMonth; i++) {
            calendarModel.append({ dayNum: i.toString(), isCurrentMonth: true, isToday: (isRealCurrentMonth && i === todayDate) });
        }
        let remaining = 35 - calendarModel.count;
        for (let i = 1; i <= remaining; i++) {
            calendarModel.append({ dayNum: i.toString(), isCurrentMonth: false, isToday: false });
        }
    }

    onMonthOffsetChanged: updateCalendarGrid()
    Component.onCompleted: updateCalendarGrid()

    // ======================================================================
    // UI
    // ======================================================================
    Item {
        anchors.fill: parent
        scale: 0.95 + (0.05 * popup.introMain)
        opacity: popup.introMain

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: popup._base
            border.color: popup._surf0
            border.width: 1
            clip: true

            // ── Ambient blobs ──
            Rectangle {
                width: parent.width * 0.5; height: width; radius: width / 2
                x: (parent.width * 0.75 - width / 2) + Math.cos(popup.globalOrbitAngle * 1.5) * 350
                y: (parent.height * 0.3 - height / 2) + Math.sin(popup.globalOrbitAngle * 1.5) * 200
                opacity: 0.025 * popup.introAmbient
                color: popup.activeWeatherHex
                Behavior on color { ColorAnimation { duration: 1000 } }
            }
            Rectangle {
                width: parent.width * 0.6; height: width; radius: width / 2
                x: (parent.width * 0.25 - width / 2) + Math.sin(popup.globalOrbitAngle * 1.2) * -300
                y: (parent.height * 0.7 - height / 2) + Math.cos(popup.globalOrbitAngle * 1.2) * -250
                opacity: 0.02 * popup.introAmbient
                color: popup.timeColor
                Behavior on color { ColorAnimation { duration: 1000 } }
            }

            // ============================================================
            // CENTRAL HUB: Clock + 3D orbital hourly
            // ============================================================
            Item {
                id: centralHub
                anchors.centerIn: parent
                width: 1; height: 1
                z: 5
                opacity: introClock
                scale: 0.85 + (0.15 * introClock)

                property real levitation: 0
                SequentialAnimation on levitation {
                    loops: Animation.Infinite
                    NumberAnimation { to: -15; duration: 4000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0; duration: 4000; easing.type: Easing.InOutSine }
                }

                property real orbitBreath: 1.0
                SequentialAnimation on orbitBreath {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 1.035; duration: 3500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 3500; easing.type: Easing.InOutSine }
                }

                property real pitchBreath: 0
                SequentialAnimation on pitchBreath { loops: Animation.Infinite; running: true
                    NumberAnimation { to: 3.5; duration: 4200; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -3.5; duration: 4200; easing.type: Easing.InOutSine }
                }
                property real yawBreath: 0
                SequentialAnimation on yawBreath { loops: Animation.Infinite; running: true
                    NumberAnimation { to: 2.5; duration: 5100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -2.5; duration: 5100; easing.type: Easing.InOutSine }
                }
                property real rollBreath: 0
                SequentialAnimation on rollBreath { loops: Animation.Infinite; running: true
                    NumberAnimation { to: 1.5; duration: 5800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -1.5; duration: 5800; easing.type: Easing.InOutSine }
                }

                transform: [
                    Translate { y: 25 * (1.0 - introClock) },
                    Translate { y: centralHub.levitation },
                    Rotation { axis { x: 1; y: 0; z: 0 } angle: centralHub.pitchBreath },
                    Rotation { axis { x: 0; y: 1; z: 0 } angle: centralHub.yawBreath },
                    Rotation { axis { x: 0; y: 0; z: 1 } angle: centralHub.rollBreath }
                ]

                // Orbit ring canvas
                Canvas {
                    id: orbitCanvas
                    z: -10; x: -400; y: -200; width: 800; height: 400
                    opacity: 0.25
                    scale: centralHub.orbitBreath
                    onWidthChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.beginPath();
                        var rx = 320, ry = 140;
                        for (var i = 0; i <= Math.PI * 2; i += 0.05) {
                            var xx = width/2 + Math.cos(i) * rx;
                            var yy = height/2 + Math.sin(i) * ry;
                            if (i === 0) ctx.moveTo(xx, yy); else ctx.lineTo(xx, yy);
                        }
                        ctx.strokeStyle = popup._over0;
                        ctx.lineWidth = 1.5;
                        ctx.setLineDash([4, 10]);
                        ctx.stroke();
                    }
                    Behavior on opacity { NumberAnimation { duration: 1500 } }
                }

                // Core clock
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0; z: 0
                    scale: 0.95 + (0.05 * popup.secondPulse)

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2
                        Text {
                            text: Qt.formatTime(popup.currentTime, "HH:mm")
                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Black; font.pixelSize: 84
                            color: popup._text
                            style: Text.Outline; styleColor: Qt.alpha(popup._crust, 0.4)
                        }
                        Text {
                            text: Qt.formatTime(popup.currentTime, ":ss")
                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 32
                            color: popup._over0
                            Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 15
                            opacity: popup.secondPulse > 1.02 ? 1.0 : 0.6
                            style: Text.Outline; styleColor: Qt.alpha(popup._crust, 0.4)
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(popup.currentTime, "dddd, MMMM dd")
                        font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 16
                        color: popup._sub0; opacity: 0.9
                    }
                }

                // 3D orbital hourly forecast
                Item {
                    anchors.fill: parent
                    opacity: popup.weatherContentOpacity
                    scale: popup.transitionScale
                    transform: Translate { x: popup.weatherContentOffset * 1.5 }

                    Repeater {
                        id: hourRepeater
                        model: popup.weatherData && popup.weatherData.forecast[popup.weatherView] && popup.weatherData.forecast[popup.weatherView].hourly ? popup.weatherData.forecast[popup.weatherView].hourly.slice(0, 8) : []

                        delegate: Item {
                            property int mCount: hourRepeater.count
                            property bool isToday: popup.weatherView === 0
                            property bool isHighlighted: isToday && index === popup.activeHourIndex
                            property real rx: 320 * centralHub.orbitBreath
                            property real ry: 140 * centralHub.orbitBreath
                            property int relIdx: isToday ? (index - popup.activeHourIndex) : index
                            property real targetAngleDeg: isToday ? (65 + (relIdx * 30)) : (index * (360 / Math.max(1, mCount)))
                            property real orbitOffset: isToday ? 0 : (popup.globalOrbitAngle * (180 / Math.PI) * -1.5)
                            property real osc: isToday ? (Math.sin(popup.globalOrbitAngle * 10 + index) * 5) : 0
                            property real rad: (targetAngleDeg + orbitOffset + osc + popup.transitionSpin) * (Math.PI / 180)

                            x: Math.cos(rad) * rx - width/2
                            y: Math.sin(rad) * ry - height/2
                            z: Math.sin(rad) * 100
                            scale: isHighlighted ? 1.4 : (isToday ? (0.95 + 0.20 * Math.sin(rad)) : (0.90 + 0.25 * Math.sin(rad)))
                            opacity: isHighlighted ? 1.0 : (isToday ? (0.7 + 0.3 * ((Math.sin(rad) + 1) / 2)) : (0.65 + 0.35 * ((Math.sin(rad) + 1) / 2)))
                            width: 56; height: 95

                            Rectangle {
                                anchors.fill: parent; radius: 28
                                color: isHighlighted ? popup._accent : (hrMa.containsMouse ? popup._surf2 : popup._surf0)
                                border.color: isHighlighted ? "transparent" : (hrMa.containsMouse ? popup._accent : popup._surf1)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 200 } }

                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: 4
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.time
                                        font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 12
                                        color: isHighlighted ? popup._base : (hrMa.containsMouse ? popup._text : popup._over2)
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.icon || ""
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
                                        color: isHighlighted ? popup._base : (modelData.hex || popup._text)
                                        transform: Translate { y: hrMa.containsMouse ? -3 : 0 }
                                        Behavior on transform { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter; text: modelData.temp + "°"
                                        font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Black; font.pixelSize: 14
                                        color: isHighlighted ? popup._base : popup._text
                                    }
                                }
                            }
                            MouseArea { id: hrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

            // ============================================================
            // LEFT WING: Calendar
            // ============================================================
            Rectangle {
                id: calendarRect
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 20
                width: 280; height: 360
                color: Qt.alpha(popup._surf0, 0.2)
                radius: 14
                border.color: Qt.alpha(popup._surf1, 0.4); border.width: 1
                z: 10
                opacity: introCalendar
                transform: Translate { x: -40 * (1.0 - introCalendar) }

                HoverHandler { id: calHover }

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 25; spacing: 15

                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16
                            color: prevMa.containsMouse ? popup._surf1 : "transparent"
                            Text { anchors.centerIn: parent; text: "\uF053"; font.family: "JetBrainsMono Nerd Font"; color: popup._text; font.pixelSize: 16 }
                            MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; onClicked: popup.setMonthOffset(popup.targetMonthOffset - 1) }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: popup.targetMonthName.toUpperCase()
                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Black; font.pixelSize: 16
                            fontSizeMode: Text.Fit; minimumPixelSize: 8
                            color: popup._text; horizontalAlignment: Text.AlignHCenter
                            opacity: popup.calendarContentOpacity
                            transform: Translate { x: popup.calendarContentOffset }
                        }

                        Rectangle {
                            Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16
                            color: nextMa.containsMouse ? popup._surf1 : "transparent"
                            Text { anchors.centerIn: parent; text: "\uF054"; font.family: "JetBrainsMono Nerd Font"; color: popup._text; font.pixelSize: 16 }
                            MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; onClicked: popup.setMonthOffset(popup.targetMonthOffset + 1) }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Repeater {
                            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                            Text {
                                Layout.fillWidth: true; text: modelData
                                font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Black; font.pixelSize: 14
                                color: popup._over0; horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        columns: 7; rowSpacing: 4; columnSpacing: 4
                        opacity: popup.calendarContentOpacity
                        transform: Translate { x: popup.calendarContentOffset }

                        Repeater {
                            model: calendarModel
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                color: isToday ? popup._accent : (dayMa.containsMouse ? Qt.alpha(popup._surf2, 0.4) : "transparent")
                                radius: 10
                                scale: dayMa.containsMouse ? 1.2 : 1.0
                                border.color: isToday ? popup._surf0 : (dayMa.containsMouse ? popup._over0 : "transparent")
                                border.width: isToday || dayMa.containsMouse ? 1 : 0
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                Text {
                                    anchors.centerIn: parent; text: dayNum
                                    font.family: "JetBrainsMono Nerd Font"; font.weight: isToday ? Font.Black : Font.Bold; font.pixelSize: 14
                                    color: isToday ? popup._base : (isCurrentMonth ? popup._text : popup._surf0)
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                                MouseArea { id: dayMa; anchors.fill: parent; hoverEnabled: true }
                            }
                        }
                    }
                }
            }

            // ============================================================
            // RIGHT WING: Weather stats
            // ============================================================
            Item {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.rightMargin: 20
                width: 280; height: 420
                z: 10
                opacity: introWeather
                transform: Translate { x: 40 * (1.0 - introWeather) }

                ColumnLayout {
                    anchors.fill: parent; spacing: 20

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        spacing: 20

                        MouseArea {
                            id: wPrevMa; Layout.preferredWidth: 30; Layout.preferredHeight: 30; hoverEnabled: true
                            onClicked: popup.setWeatherView(popup.targetWeatherView - 1)
                            property real pulseOffset: 0
                            SequentialAnimation on pulseOffset { loops: Animation.Infinite; running: true
                                NumberAnimation { to: -3; duration: 1000; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0; duration: 1000; easing.type: Easing.InOutSine }
                            }
                            Text {
                                anchors.centerIn: parent; text: "\uF053"
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
                                color: parent.containsMouse ? popup._accent : popup._over1
                                transform: Translate { x: parent.containsMouse ? -5 : wPrevMa.pulseOffset }
                                Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            }
                        }

                        Text {
                            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                            text: popup.weatherData && popup.weatherData.forecast[popup.weatherView] ? popup.weatherData.forecast[popup.weatherView].day_full.toUpperCase() : "LOADING..."
                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Black; font.pixelSize: 16
                            fontSizeMode: Text.Fit; minimumPixelSize: 8; color: popup._text
                        }

                        MouseArea {
                            id: wNextMa; Layout.preferredWidth: 30; Layout.preferredHeight: 30; hoverEnabled: true
                            onClicked: popup.setWeatherView(popup.targetWeatherView + 1)
                            property real pulseOffset: 0
                            SequentialAnimation on pulseOffset { loops: Animation.Infinite; running: true
                                NumberAnimation { to: 3; duration: 1000; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0; duration: 1000; easing.type: Easing.InOutSine }
                            }
                            Text {
                                anchors.centerIn: parent; text: "\uF054"
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
                                color: parent.containsMouse ? popup._accent : popup._over1
                                transform: Translate { x: parent.containsMouse ? 5 : wNextMa.pulseOffset }
                                Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignRight; spacing: -5

                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: Math.round(popup.displayedTemp) + "°"
                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Black; font.pixelSize: 84
                            color: popup._text
                            style: Text.Outline; styleColor: Qt.alpha(popup._crust, 0.4)
                        }
                        Text {
                            Layout.alignment: Qt.AlignRight; Layout.maximumWidth: 320
                            horizontalAlignment: Text.AlignRight
                            text: popup.weatherData && popup.weatherData.forecast[popup.weatherView] ? popup.weatherData.forecast[popup.weatherView].desc : ""
                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 16
                            wrapMode: Text.WordWrap; color: popup._over0
                            opacity: popup.weatherContentOpacity
                            transform: Translate { x: popup.weatherContentOffset }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Weather gauges
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        Repeater {
                            model: 4
                            Item {
                                id: gaugeWrapper
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                scale: gaugeMa.containsMouse ? 1.15 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                property var forecast: popup.weatherData && popup.weatherData.forecast[popup.targetWeatherView] ? popup.weatherData.forecast[popup.targetWeatherView] : null
                                property string gaugeIcon: index === 0 ? "\uF062" : index === 1 ? "\uF041" : index === 2 ? "\uF043" : "\uF524"
                                property string gaugeLbl: index === 0 ? "WIND" : index === 1 ? "HUMID" : index === 2 ? "RAIN" : "FEELS"
                                property string gaugeVal: forecast ? (
                                    index === 0 ? forecast.wind + "m/s" :
                                    index === 1 ? forecast.humidity + "%" :
                                    index === 2 ? forecast.pop + "%" :
                                    forecast.feels_like + "°"
                                ) : ""
                                property real gaugeFill: forecast ? (
                                    index === 0 ? Math.min(1.0, forecast.wind / 25.0) :
                                    index === 1 ? forecast.humidity / 100.0 :
                                    index === 2 ? forecast.pop / 100.0 :
                                    Math.max(0.0, Math.min(1.0, (forecast.feels_like + 15) / 55.0))
                                ) : 0.0

                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: 6

                                    Item {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: 60; Layout.preferredHeight: 60

                                        Rectangle {
                                            anchors.fill: parent; radius: width / 2
                                            color: popup._accent; opacity: gaugeMa.containsMouse ? 0.3 : 0.0
                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                        }

                                        Canvas {
                                            anchors.fill: parent; rotation: -90
                                            property real animProgress: gaugeWrapper.gaugeFill
                                            Behavior on animProgress { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }
                                            onAnimProgressChanged: requestPaint()
                                            onWidthChanged: requestPaint()
                                            Component.onCompleted: requestPaint()
                                            onPaint: {
                                                var ctx = getContext("2d");
                                                ctx.clearRect(0, 0, width, height);
                                                var r = width / 2;
                                                ctx.beginPath();
                                                ctx.arc(r, r, r - 4, 0, 2 * Math.PI);
                                                ctx.strokeStyle = Qt.alpha(popup._text, 0.1);
                                                ctx.lineWidth = 3; ctx.stroke();
                                                if (animProgress > 0) {
                                                    ctx.beginPath();
                                                    ctx.arc(r, r, r - 4, 0, animProgress * 2 * Math.PI);
                                                    ctx.strokeStyle = popup._accent;
                                                    ctx.lineWidth = 4; ctx.lineCap = "round"; ctx.stroke();
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: gaugeWrapper.gaugeVal
                                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Black; font.pixelSize: 12
                                            color: popup._text
                                        }
                                    }

                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter; Layout.fillWidth: true; spacing: 4
                                        Text {
                                            text: gaugeWrapper.gaugeIcon
                                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                                            color: gaugeMa.containsMouse ? popup._accent : popup._over0
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }
                                        Text {
                                            text: gaugeWrapper.gaugeLbl; Layout.fillWidth: true
                                            font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 11
                                            fontSizeMode: Text.Fit; minimumPixelSize: 6
                                            color: popup._over0
                                        }
                                    }
                                }
                                MouseArea { id: gaugeMa; anchors.fill: parent; hoverEnabled: true }
                            }
                        }
                    }
                }
            }
        }
    }
}
