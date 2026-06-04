import QtQuick
import "functions"

Item {
    // Expose self as "shellState" so existing code accessing serviceContext.shellState works
    readonly property var shellState: this

    // ShellState properties
    property bool mediaCardOpen: false
    property bool barVisible: true
    property bool keepBarVisible: false
    property bool quickSettingsOpen: false
    property bool bluetoothPanelOpen: false
    property bool wifiSelectorOpen: false
    property bool batteryTooltipVisible: false
    property string batteryTooltipText: ""
    property bool calendarPopupOpen: false
    property bool notificationPanelOpen: false

    // ShellState functions
    function toggleBar() { barVisible = !barVisible }
    function toggleMediaCard() { mediaCardOpen = !mediaCardOpen }
    function toggleQuickSettings() {
        console.log("STATE: toggleQuickSettings() called, was:", quickSettingsOpen)
        quickSettingsOpen = !quickSettingsOpen
        bluetoothPanelOpen = false
        wifiSelectorOpen = false
        notificationPanelOpen = false
    }
    function toggleBluetoothPanel() {
        console.log("STATE: toggleBluetoothPanel() called, was:", bluetoothPanelOpen)
        bluetoothPanelOpen = !bluetoothPanelOpen
        quickSettingsOpen = false
        wifiSelectorOpen = false
        notificationPanelOpen = false
    }
    function toggleWifiSelector() {
        console.log("STATE: toggleWifiSelector() called, was:", wifiSelectorOpen)
        wifiSelectorOpen = !wifiSelectorOpen
        quickSettingsOpen = false
        bluetoothPanelOpen = false
        notificationPanelOpen = false
    }
    function toggleCalendarPopup() {
        calendarPopupOpen = !calendarPopupOpen
        quickSettingsOpen = false
        bluetoothPanelOpen = false
        wifiSelectorOpen = false
        notificationPanelOpen = false
    }
    function toggleNotificationPanel() {
        notificationPanelOpen = !notificationPanelOpen
        quickSettingsOpen = false
        bluetoothPanelOpen = false
        wifiSelectorOpen = false
        calendarPopupOpen = false
    }
    function keepBarTemporarily() {
        keepBarVisible = true
        keepBarTimer.running = true
    }

    Timer {
        id: keepBarTimer
        interval: 5000
        repeat: false
        onTriggered: keepBarVisible = false
    }

    property var colorUtils: ColorUtils {}

    Component.onCompleted: {
        console.log("CTX: shellState = this, bluetoothPanelOpen:", bluetoothPanelOpen, "barVisible:", barVisible)
    }
}
