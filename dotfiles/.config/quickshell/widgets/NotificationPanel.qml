import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../services"
import "../core/NotificationUtils.js" as Utils

Item {
    id: root

    implicitWidth: 365

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

    property bool _triggeredByClear: false

    function close() {
        ShellState.closePopup()
    }

    // Background
    Rectangle {
        anchors.fill: parent
        color: colLayer0
        radius: 20
        border.width: 1
        border.color: Qt.alpha(colOnOutline, 0.12)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // ── Notification Island ──
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: colLayer1
                radius: 20

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // ── Main Content (List or Placeholder) ──
                    Item {
                        id: listContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        implicitHeight: NotificationService.notifications.length === 0 ? placeholderCol.implicitHeight : listView.implicitHeight

                        // Placeholder (No Notifications)
                        ColumnLayout {
                            id: placeholderCol
                            anchors.centerIn: parent
                            visible: NotificationService.notifications.length === 0
                            spacing: 8

                            Rectangle {
                                Layout.alignment: Qt.AlignCenter
                                width: 80
                                height: 80
                                radius: 40
                                color: colLayer3

                                Text {
                                    id: bellIcon
                                    anchors.centerIn: parent
                                    text: "\uF0F3"
                                    color: colOnSurfaceVar
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 36

                                    SequentialAnimation {
                                        id: bellSwingAnim
                                        running: false
                                        NumberAnimation { target: bellIcon; property: "rotation"; from: 0; to: 20; duration: 250; easing.type: Easing.OutBack }
                                        NumberAnimation { target: bellIcon; property: "rotation"; from: 20; to: -20; duration: 400; easing.type: Easing.InOutSine }
                                        NumberAnimation { target: bellIcon; property: "rotation"; from: -20; to: 15; duration: 300; easing.type: Easing.InOutSine }
                                        NumberAnimation { target: bellIcon; property: "rotation"; from: 15; to: -10; duration: 250; easing.type: Easing.InOutSine }
                                        NumberAnimation { target: bellIcon; property: "rotation"; from: -10; to: 0; duration: 200; easing.type: Easing.OutSine }
                                    }

                                    Connections {
                                        target: NotificationService
                                        function onNotificationsChanged() {
                                            if (NotificationService.notifications.length === 0 && !root._triggeredByClear) {
                                                bellSwingAnim.restart()
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No notifications"
                                color: colOnSurfaceVar
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                            }
                        }

                        // Notification List
                        ListView {
                            id: listView
                            anchors.fill: parent
                            visible: NotificationService.notifications.length > 0
                            clip: true
                            spacing: 4

                            opacity: root._triggeredByClear ? 0 : 1
                            Behavior on opacity {
                                NumberAnimation { duration: 250; easing.type: Easing.OutSine }
                            }

                            model: NotificationService.appNameList

                            delegate: Rectangle {
                                id: groupDelegate
                                required property string modelData
                                required property int index
                                property string appName: modelData
                                property var groupData: NotificationService.groupsByAppName[modelData] || ({notifications: []})
                                property var notifs: groupData.notifications || []
                                property int notifCount: notifs.length
                                property bool isExpanded: false

                                width: ListView.view.width
                                height: groupContent.implicitHeight + 16
                                radius: 16
                                color: colLayer2

                                ColumnLayout {
                                    id: groupContent
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    // ── App Group Header ──
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        // App Icon
                                        Rectangle {
                                            Layout.alignment: Qt.AlignTop
                                            width: 38
                                            height: 38
                                            radius: 19
                                            color: colSecondaryContainer

                                            property var firstNotif: groupDelegate.notifs.length > 0 ? groupDelegate.notifs[0] : null
                                            property var iconCandidates: firstNotif ? Utils.getAppIconCandidates(firstNotif.appName || groupDelegate.appName, firstNotif.appIcon || "") : []
                                            property int iconIdx: 0

                                            Image {
                                                id: panelIconImg
                                                anchors.fill: parent
                                                anchors.margins: 5
                                                source: {
                                                    var c = parent.iconCandidates
                                                    var idx = parent.iconIdx
                                                    if (c.length === 0 || idx >= c.length) return ""
                                                    return c[idx]
                                                }
                                                sourceSize.width: 28
                                                sourceSize.height: 28
                                                fillMode: Image.PreserveAspectFit
                                                visible: status === Image.Ready
                                                asynchronous: true
                                                onStatusChanged: {
                                                    if (status === Image.Error && parent.iconIdx < parent.iconCandidates.length - 1) {
                                                        parent.iconIdx++
                                                    }
                                                }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                visible: panelIconImg.status !== Image.Ready
                                                text: Utils.findSuitableIcon(groupDelegate.notifs.length > 0 ? groupDelegate.notifs[0].summary : "")
                                                color: colOnPrimaryContainer
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 18
                                            }
                                        }

                                        // Content Column
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: expandedColumn.visible ? 5 : 3

                                            // ── Top Row (app name or summary + time + expand) ──
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 5

                                                // App name or first notification summary
                                                Text {
                                                    id: topText
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                    text: groupDelegate.notifCount > 1 ? groupDelegate.appName : (groupDelegate.notifs.length > 0 ? groupDelegate.notifs[0].summary : "")
                                                    color: colOnSurfaceVar
                                                    font.family: "JetBrainsMono Nerd Font"
                                                    font.pixelSize: groupDelegate.notifCount > 1 ? 10 : 11
                                                }

                                                // Time
                                                Text {
                                                    text: groupDelegate.notifs.length > 0 ? Utils.getFriendlyTimeString(groupDelegate.groupData.time) : ""
                                                    color: colSubtext
                                                    font.family: "JetBrainsMono Nerd Font"
                                                    font.pixelSize: 10
                                                    Layout.rightMargin: 4
                                                }

                                                // Expand button
                                                Rectangle {
                                                    visible: groupDelegate.notifCount > 1
                                                    width: expandRow.implicitWidth + 12
                                                    height: 24
                                                    radius: 12
                                                    color: expandMa.containsMouse ? Qt.alpha(colOnOutline, 0.12) : "transparent"

                                                    Row {
                                                        id: expandRow
                                                        anchors.centerIn: parent
                                                        spacing: 3

                                                        Text {
                                                            text: groupDelegate.notifCount.toString()
                                                            color: colOnSurfaceVar
                                                            font.family: "JetBrainsMono Nerd Font"
                                                            font.pixelSize: 10
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }

                                                        Text {
                                                            text: groupDelegate.isExpanded ? "\uF077" : "\uF078"
                                                            color: colOnSurfaceVar
                                                            font.family: "JetBrainsMono Nerd Font"
                                                            font.pixelSize: 10
                                                            rotation: groupDelegate.isExpanded ? 180 : 0
                                                            Behavior on rotation {
                                                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                                            }
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: expandMa
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: groupDelegate.isExpanded = !groupDelegate.isExpanded
                                                    }
                                                }
                                            }

                                            // ── Notification Items ──
                                            ColumnLayout {
                                                id: expandedColumn
                                                Layout.fillWidth: true
                                                spacing: groupDelegate.isExpanded ? 5 : 3
                                                visible: groupDelegate.notifCount > 0

                                                Repeater {
                                                    model: groupDelegate.isExpanded ? groupDelegate.notifs.slice().reverse() : groupDelegate.notifs.slice().reverse().slice(0, 2)

                                                    delegate: Rectangle {
                                                        id: notifItem
                                                        required property var modelData
                                                        required property int index
                                                        property bool isLast: index === (groupDelegate.isExpanded ? groupDelegate.notifs.length - 1 : Math.min(1, groupDelegate.notifs.length - 1))

                                                        Layout.fillWidth: true
                                                        implicitHeight: groupDelegate.isExpanded ? (notifContent.implicitHeight + 16) : notifContent.implicitHeight
                                                        radius: 12
                                                        color: notifMa.containsMouse ? Qt.alpha(colPrimary, 0.08) : "transparent"

                                                        ColumnLayout {
                                                            id: notifContent
                                                            anchors.left: parent.left
                                                            anchors.right: parent.right
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            anchors.leftMargin: 8
                                                            anchors.rightMargin: 8
                                                            anchors.topMargin: groupDelegate.isExpanded ? 8 : 0
                                                            anchors.bottomMargin: groupDelegate.isExpanded ? 8 : 0
                                                            spacing: 3

                                                            // Summary (only when multiple notifs or expanded)
                                                            Text {
                                                                Layout.fillWidth: true
                                                                visible: groupDelegate.notifCount > 1
                                                                text: notifItem.modelData.summary || ""
                                                                color: colOnSurface
                                                                font.family: "JetBrainsMono Nerd Font"
                                                                font.pixelSize: 11
                                                                font.weight: Font.Bold
                                                                elide: Text.ElideRight
                                                            }

                                                            // Body preview
                                                            Text {
                                                                Layout.fillWidth: true
                                                                visible: (notifItem.modelData.body || "") !== ""
                                                                text: (notifItem.modelData.body || "").replace(/\n/g, " ")
                                                                color: colSubtext
                                                                font.family: "JetBrainsMono Nerd Font"
                                                                font.pixelSize: 10
                                                                elide: Text.ElideRight
                                                                maximumLineCount: groupDelegate.isExpanded ? 100 : 1
                                                                opacity: 0.8
                                                            }

                                                            // Action buttons (expanded only)
                                                            Row {
                                                                visible: groupDelegate.isExpanded && notifItem.modelData.actions && notifItem.modelData.actions.length > 0
                                                                spacing: 6
                                                                Layout.topMargin: 4

                                                                Repeater {
                                                                    model: groupDelegate.isExpanded ? (notifItem.modelData.actions || []) : []

                                                                    delegate: Rectangle {
                                                                        required property var modelData
                                                                        width: Math.max(panelActionLabel.implicitWidth + 20, 50)
                                                                        height: 22
                                                                        radius: 6
                                                                        color: panelActionMouse.containsMouse ? Qt.alpha(colPrimary, 0.3) : Qt.alpha(colPrimary, 0.08)
                                                                        border.width: 1
                                                                        border.color: Qt.alpha(colPrimary, 0.15)

                                                                        Text {
                                                                            id: panelActionLabel
                                                                            anchors.centerIn: parent
                                                                            text: modelData.text || "Action"
                                                                            color: colPrimary
                                                                            font.family: "JetBrainsMono Nerd Font"
                                                                            font.pixelSize: 10
                                                                            font.bold: true
                                                                        }

                                                                        MouseArea {
                                                                            id: panelActionMouse
                                                                            anchors.fill: parent
                                                                            hoverEnabled: true
                                                                            cursorShape: Qt.PointingHandCursor
                                                                            onClicked: NotificationService.attemptInvokeAction(notifItem.modelData.notificationId, modelData.identifier)
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        MouseArea {
                                                            id: notifMa
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: NotificationService.discardNotification(notifItem.modelData.notificationId)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Bottom Action Row ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Silent toggle
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 20
                            color: silentMa.containsMouse
                                ? (NotificationService.silent ? Qt.alpha(colOnPrimaryContainer, 0.2) : Qt.alpha(colOnOutline, 0.15))
                                : (NotificationService.silent ? colPrimaryContainer : colLayer3)

                            Text {
                                anchors.centerIn: parent
                                text: NotificationService.silent ? "\uF1F6" : "\uF0F3"
                                color: NotificationService.silent ? colOnPrimaryContainer : colOnSurfaceVar
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: silentMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.silent = !NotificationService.silent
                            }
                        }

                        // Notification count
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: 20
                            color: colLayer3

                            Text {
                                anchors.centerIn: parent
                                text: NotificationService.notifications.length > 0
                                    ? NotificationService.notifications.length + " notifications"
                                    : "No notifications"
                                color: colOnSurfaceVar
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }
                        }

                        // Clear all
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 20
                            color: clearMa.containsMouse ? Qt.alpha(colOutline, 0.2) : colLayer3
                            opacity: NotificationService.notifications.length > 0 ? 1 : 0.5

                            Text {
                                anchors.centerIn: parent
                                text: "\uF12D"
                                color: clearMa.containsMouse ? colOutline : colOnSurfaceVar
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: clearMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: NotificationService.notifications.length > 0
                                onClicked: {
                                    root._triggeredByClear = true
                                    clearDelayTimer.restart()
                                }
                            }
                        }
                    }

                    Timer {
                        id: clearDelayTimer
                        interval: 250
                        repeat: false
                        onTriggered: {
                            NotificationService.discardAllNotifications()
                            if (root._triggeredByClear) {
                                bellSwingAnim.restart()
                                root._triggeredByClear = false
                            }
                        }
                    }
                }
            }
        }
    }

    function show() {}
}
