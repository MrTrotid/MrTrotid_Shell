pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Item {
    id: root

    // Default fallback colors (dark theme)
    property color background: "#1a1c1e"
    property color backgroundText: "#e2e2e6"
    property color surface: "#1a1c1e"
    property color surfaceContainer: "#1a2120"
    property color surfaceContainerHigh: "#2b3130"
    property color surfaceContainerHighest: "#303635"
    property color surfaceContainerLow: "#131514"
    property color surfaceText: "#dde4e2"
    property color surfaceVariantText: "#a0a4a2"
    property color primary: "#81d5ca"
    property color primaryText: "#003732"
    property color primaryContainer: "#005047"
    property color primaryContainerText: "#a0f2e5"
    property color secondary: "#8b9099"
    property color secondaryText: "#1c1f26"
    property color secondaryContainer: "#33373e"
    property color tertiary: "#aec9e6"
    property color tertiaryText: "#1a2c44"
    property color tertiaryContainer: "#32435b"
    property color error: "#ffb4ab"
    property color errorText: "#690005"
    property color errorContainer: "#93000a"
    property color outline: "#6a7170"
    property color outlineVariant: "#4a4e4d"
    property color shadow: "#000000"
    property color scrim: "#000000"
    property color inverseSurface: "#e2e2e6"
    property color inverseSurfaceText: "#1a1c1e"
    property color inversePrimary: "#006b60"
    property color success: "#81c995"
    property color blue: "#8ab4f8"
    property color red: "#f28b82"
    property color yellow: "#fdd663"

    property bool _loaded: false
    property string _lastJson: ""

    FileView {
        id: colorFile
        path: Quickshell.env("HOME") + "/.config/quickshell/mrtrotid-shell/colors.json"
        onTextChanged: root._parseColors(colorFile.text())
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: colorFile.reload()
    }

    function _parseColors(jsonText) {
        if (jsonText === _lastJson) return
        _lastJson = jsonText
        try {
            var colors = JSON.parse(jsonText)
            root.background = Qt.rgba(_hexToR(colors.background), _hexToG(colors.background), _hexToB(colors.background), 1.0)
            root.backgroundText = Qt.rgba(_hexToR(colors.on_background), _hexToG(colors.on_background), _hexToB(colors.on_background), 1.0)
            root.surface = Qt.rgba(_hexToR(colors.surface), _hexToG(colors.surface), _hexToB(colors.surface), 1.0)
            root.surfaceContainer = Qt.rgba(_hexToR(colors.surface_container), _hexToG(colors.surface_container), _hexToB(colors.surface_container), 1.0)
            root.surfaceContainerHigh = Qt.rgba(_hexToR(colors.surface_container_high), _hexToG(colors.surface_container_high), _hexToB(colors.surface_container_high), 1.0)
            root.surfaceContainerHighest = Qt.rgba(_hexToR(colors.surface_container_highest), _hexToG(colors.surface_container_highest), _hexToB(colors.surface_container_highest), 1.0)
            root.surfaceContainerLow = Qt.rgba(_hexToR(colors.surface_container_low), _hexToG(colors.surface_container_low), _hexToB(colors.surface_container_low), 1.0)
            root.surfaceText = Qt.rgba(_hexToR(colors.on_surface), _hexToG(colors.on_surface), _hexToB(colors.on_surface), 1.0)
            root.surfaceVariantText = Qt.rgba(_hexToR(colors.on_surface_variant), _hexToG(colors.on_surface_variant), _hexToB(colors.on_surface_variant), 1.0)
            root.primary = Qt.rgba(_hexToR(colors.primary), _hexToG(colors.primary), _hexToB(colors.primary), 1.0)
            root.primaryText = Qt.rgba(_hexToR(colors.on_primary), _hexToG(colors.on_primary), _hexToB(colors.on_primary), 1.0)
            root.primaryContainer = Qt.rgba(_hexToR(colors.primary_container), _hexToG(colors.primary_container), _hexToB(colors.primary_container), 1.0)
            root.primaryContainerText = Qt.rgba(_hexToR(colors.on_primary_container), _hexToG(colors.on_primary_container), _hexToB(colors.on_primary_container), 1.0)
            root.secondary = Qt.rgba(_hexToR(colors.secondary), _hexToG(colors.secondary), _hexToB(colors.secondary), 1.0)
            root.secondaryText = Qt.rgba(_hexToR(colors.on_secondary), _hexToG(colors.on_secondary), _hexToB(colors.on_secondary), 1.0)
            root.secondaryContainer = Qt.rgba(_hexToR(colors.secondary_container), _hexToG(colors.secondary_container), _hexToB(colors.secondary_container), 1.0)
            root.tertiary = Qt.rgba(_hexToR(colors.tertiary), _hexToG(colors.tertiary), _hexToB(colors.tertiary), 1.0)
            root.tertiaryText = Qt.rgba(_hexToR(colors.on_tertiary), _hexToG(colors.on_tertiary), _hexToB(colors.on_tertiary), 1.0)
            root.tertiaryContainer = Qt.rgba(_hexToR(colors.tertiary_container), _hexToG(colors.tertiary_container), _hexToB(colors.tertiary_container), 1.0)
            root.error = Qt.rgba(_hexToR(colors.error), _hexToG(colors.error), _hexToB(colors.error), 1.0)
            root.errorText = Qt.rgba(_hexToR(colors.on_error), _hexToG(colors.on_error), _hexToB(colors.on_error), 1.0)
            root.errorContainer = Qt.rgba(_hexToR(colors.error_container), _hexToG(colors.error_container), _hexToB(colors.error_container), 1.0)
            root.outline = Qt.rgba(_hexToR(colors.outline), _hexToG(colors.outline), _hexToB(colors.outline), 1.0)
            root.outlineVariant = Qt.rgba(_hexToR(colors.outline_variant), _hexToG(colors.outline_variant), _hexToB(colors.outline_variant), 1.0)
            root.shadow = Qt.rgba(_hexToR(colors.shadow), _hexToG(colors.shadow), _hexToB(colors.shadow), 1.0)
            root.scrim = Qt.rgba(_hexToR(colors.scrim), _hexToG(colors.scrim), _hexToB(colors.scrim), 1.0)
            root.inverseSurface = Qt.rgba(_hexToR(colors.inverse_surface), _hexToG(colors.inverse_surface), _hexToB(colors.inverse_surface), 1.0)
            root.inverseSurfaceText = Qt.rgba(_hexToR(colors.inverse_on_surface), _hexToG(colors.inverse_on_surface), _hexToB(colors.inverse_on_surface), 1.0)
            root.inversePrimary = Qt.rgba(_hexToR(colors.inverse_primary), _hexToG(colors.inverse_primary), _hexToB(colors.inverse_primary), 1.0)
            root.success = Qt.rgba(_hexToR(colors.success), _hexToG(colors.success), _hexToB(colors.success), 1.0)
            root.blue = Qt.rgba(_hexToR(colors.blue), _hexToG(colors.blue), _hexToB(colors.blue), 1.0)
            root.red = Qt.rgba(_hexToR(colors.red), _hexToG(colors.red), _hexToB(colors.red), 1.0)
            root.yellow = Qt.rgba(_hexToR(colors.yellow), _hexToG(colors.yellow), _hexToB(colors.yellow), 1.0)
            root._loaded = true
        } catch(e) {
            console.log("ColorService: Failed to parse colors.json:", e)
        }
    }

    function _hexToR(hex) {
        if (!hex) return 0
        hex = hex.replace("#", "")
        if (hex.length === 3) hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2]
        return parseInt(hex.substring(0, 2), 16) / 255
    }

    function _hexToG(hex) {
        if (!hex) return 0
        hex = hex.replace("#", "")
        if (hex.length === 3) hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2]
        return parseInt(hex.substring(2, 4), 16) / 255
    }

    function _hexToB(hex) {
        if (!hex) return 0
        hex = hex.replace("#", "")
        if (hex.length === 3) hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2]
        return parseInt(hex.substring(4, 6), 16) / 255
    }
}
