pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    // ── UI Visibility ──
    property bool barVisible: true
    property bool keepBarVisible: false
    property bool batteryTooltipVisible: false
    property string batteryTooltipText: ""
    property bool mediaCardOpen: false

    // ── Active popup (mutual exclusion via string) ──
    property string activePopup: ""  // "bluetooth" | "wifi" | "calendar" | "notification" | "cheatsheet" | "wallpaper" | "quickactions" | ""

    // Derived booleans — backward-compat with existing bindings
    readonly property bool bluetoothPanelOpen: activePopup === "bluetooth"
    readonly property bool wifiSelectorOpen: activePopup === "wifi"
    readonly property bool calendarPopupOpen: activePopup === "calendar"
    readonly property bool notificationPanelOpen: activePopup === "notification"
    readonly property bool cheatsheetOpen: activePopup === "cheatsheet"
    readonly property bool wallpaperPickerOpen: activePopup === "wallpaper"
    readonly property bool quickActionsOpen: activePopup === "quickactions"
    readonly property bool anyPopupOpen: activePopup !== ""

    // ── Toggle functions ──
    function toggleBar() { barVisible = !barVisible }

    function toggleMediaCard() { mediaCardOpen = !mediaCardOpen }

    function togglePopup(name) {
        activePopup = (activePopup === name) ? "" : name
        if (activePopup !== "") barVisible = true
        batteryTooltipVisible = false
    }

    function openPopup(name) {
        activePopup = name
        barVisible = true
        batteryTooltipVisible = false
    }

    function closePopup() {
        activePopup = ""
    }

    // Backward-compat wrappers
    function toggleBluetoothPanel() { togglePopup("bluetooth") }
    function toggleWifiSelector() { togglePopup("wifi") }
    function toggleCalendarPopup() { togglePopup("calendar") }
    function toggleNotificationPanel() { togglePopup("notification") }
    function toggleCheatsheet() { togglePopup("cheatsheet") }
    function toggleWallpaperPicker() { togglePopup("wallpaper") }
    function toggleQuickActions() { togglePopup("quickactions") }

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
}
