pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string defaultSinkName: ""
    property int defaultSinkId: -1
    property var sinks: []

    property bool micMuted: false
    property int micVolume: 0
    property var sources: []
    property int defaultSourceId: -1
    property var _deviceNames: ({})

    property var _prevSinkIds: []
    property int _fallbackSinkId: -1

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!statusProc.running) statusProc.running = true
            if (!micStatusProc.running) micStatusProc.running = true
        }
    }

    Process {
        id: micStatusProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                var match = line.match(/Volume:\s*(\d+\.\d+)/)
                if (match) root.micVolume = Math.round(parseFloat(match[1]) * 100)
                root.micMuted = line.includes("[MUTED]")
            }
        }
    }

    Process {
        id: statusProc
        command: ["wpctl", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                var result = []
                var currentIds = []

                var inSinksSection = false
                var inSourcesSection = false
                var inFiltersSection = false
                var inDevicesSection = false
                var inAudioSection = false
                var resultSources = []
                var deviceNames = {}

                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    var trimmed = line.trim()

                    // Detect section boundaries — use indexOf for forward-compat
                    if (trimmed.indexOf("Audio") === 0 && (trimmed.length === 5 || trimmed[5] === " " || trimmed[5] === "\t")) {
                        inAudioSection = true
                        inSinksSection = false
                        inSourcesSection = false
                        inDevicesSection = false
                        continue
                    }
                    if (trimmed.indexOf("Video") === 0 || trimmed.indexOf("Settings") === 0) {
                        inAudioSection = false
                        inSinksSection = false
                        inSourcesSection = false
                        inDevicesSection = false
                        continue
                    }

                    // Detect Devices header (only in Audio section)
                    if (inAudioSection && trimmed.indexOf("Devices:") !== -1) {
                        inDevicesSection = true
                        inSinksSection = false
                        inSourcesSection = false
                        inFiltersSection = false
                        continue
                    }

                    // Parse devices — build ID → friendly name map
                    if (inDevicesSection) {
                        if (trimmed.indexOf("Sinks:") !== -1 || trimmed.indexOf("Sources:") !== -1 ||
                            trimmed.indexOf("Filters:") !== -1 || trimmed.indexOf("Streams:") !== -1) {
                            inDevicesSection = false
                            // Fall through to section detection below
                        } else {
                            var devContent = line.replace(/^[\s\u2502\u251c\u2514\u2500]*/g, "").trim()
                            var devMatch = devContent.match(/^(\d+)\.\s+(.+?)\s+\[.+\]\s*$/)
                            if (devMatch) {
                                deviceNames[parseInt(devMatch[1])] = devMatch[2].trim()
                            }
                            continue
                        }
                    }

                    // Detect Sinks header (only in Audio section)
                    if (inAudioSection && trimmed.indexOf("Sinks:") !== -1) {
                        inSinksSection = true
                        inSourcesSection = false
                        continue
                    }

                    // Detect Sources header (only in Audio section)
                    if (inAudioSection && trimmed.indexOf("Sources:") !== -1) {
                        inSourcesSection = true
                        inSinksSection = false
                        inFiltersSection = false
                        continue
                    }

                    // Detect Filters header (only in Audio section)
                    if (inAudioSection && trimmed.indexOf("Filters:") !== -1) {
                        inFiltersSection = true
                        inSinksSection = false
                        inSourcesSection = false
                        continue
                    }

                    if (inSinksSection) {
                        if (trimmed.indexOf("Filters:") !== -1 ||
                            trimmed.indexOf("Streams:") !== -1) {
                            inSinksSection = false
                            continue
                        }
                        if (trimmed.indexOf("Sources:") !== -1) {
                            inSinksSection = false
                            inSourcesSection = true
                            continue
                        }

                        var content = line.replace(/^[\s\u2502\u251c\u2514\u2500]*/g, "").trim()
                        if (content.length === 0) continue

                        var match = content.match(/^([*]?)\s*(\d+)\.\s+(.+?)(?:\s+\[vol:\s*([\d.]+)\])?\s*$/)
                        if (match) {
                            var sinkId = parseInt(match[2])
                            var sinkDesc = match[3].trim()
                            var sinkVol = match[4] ? parseFloat(match[4]) : -1
                            var isDefault = match[1] === "*"

                            result.push({
                                id: sinkId,
                                name: sinkDesc,
                                description: sinkDesc,
                                isDefault: isDefault,
                                volume: sinkVol
                            })

                            currentIds.push(sinkId)

                            if (isDefault) {
                                root.defaultSinkId = sinkId
                                root.defaultSinkName = sinkDesc
                                if (!isBluetoothSink(sinkDesc)) {
                                    root._fallbackSinkId = sinkId
                                }
                            }
                        }
                    }

                    // Parse sources
                    if (inSourcesSection) {
                        if (trimmed.indexOf("Filters:") !== -1 ||
                            trimmed.indexOf("Streams:") !== -1) {
                            inSourcesSection = false
                            continue
                        }

                        var srcContent = line.replace(/^[\s\u2502\u251c\u2514\u2500]*/g, "").trim()
                        if (srcContent.length === 0) continue

                        var srcMatch = srcContent.match(/^([*]?)\s*(\d+)\.\s+(.+?)(?:\s+\[vol:\s*([\d.]+)\])?\s*$/)
                        if (srcMatch) {
                            var srcId = parseInt(srcMatch[2])
                            var srcDesc = srcMatch[3].trim()
                            var srcIsDefault = srcMatch[1] === "*"

                            resultSources.push({
                                id: srcId,
                                name: srcDesc,
                                description: srcDesc,
                                isDefault: srcIsDefault
                            })

                            if (srcIsDefault) {
                                root.defaultSourceId = srcId
                            }
                        }
                    }

                    // Parse filters — capture Audio/Source entries as mic sources
                    if (inFiltersSection) {
                        if (trimmed.indexOf("Streams:") !== -1 ||
                            trimmed === "" || trimmed.indexOf("├─") !== -1 || trimmed.indexOf("└─") !== -1) {
                            if (trimmed.indexOf("Streams:") !== -1) {
                                inFiltersSection = false
                            }
                            continue
                        }

                        var fltContent = line.replace(/^[\s\u2502\u251c\u2514\u2500]*/g, "").trim()
                        if (fltContent.length === 0) continue

                        // Match entries like: "68. bluez_input.xxx  [Audio/Source]"
                        var fltMatch = fltContent.match(/^(\d+)\.\s+(.+?)\s+\[(.+)\]\s*$/)
                        if (fltMatch) {
                            var fltType = fltMatch[3].trim()
                            if (fltType.indexOf("Audio/Source") !== -1) {
                                var fltId = parseInt(fltMatch[1])
                                var fltName = fltMatch[2].trim()
                                // Bluetooth sources always appear in Sources with friendly name — skip Filters duplicate
                                if (fltName.indexOf("bluez_") !== -1) continue
                                var exists = false
                                for (var fi = 0; fi < resultSources.length; fi++) {
                                    if (resultSources[fi].id === fltId) { exists = true; break }
                                }
                                if (!exists) {
                                    resultSources.push({
                                        id: fltId,
                                        name: fltName,
                                        description: fltName,
                                        isDefault: false
                                    })
                                }
                            }
                        }
                    }
                }

                // Detect newly connected bluetooth sinks
                if (root._prevSinkIds.length > 0) {
                    var newIds = []
                    for (var j = 0; j < currentIds.length; j++) {
                        if (root._prevSinkIds.indexOf(currentIds[j]) === -1) {
                            newIds.push(currentIds[j])
                        }
                    }

                    if (newIds.length > 0) {
                        for (var k = 0; k < result.length; k++) {
                            if (newIds.indexOf(result[k].id) !== -1 && isBluetoothSink(result[k].name)) {
                                root.setDefaultSink(result[k].id)
                                break
                            }
                        }
                    }

                    if (currentIds.length > 0 && currentIds.indexOf(root.defaultSinkId) === -1 && root._fallbackSinkId !== -1) {
                        if (currentIds.indexOf(root._fallbackSinkId) !== -1) {
                            root.setDefaultSink(root._fallbackSinkId)
                        }
                    }
                }

                root._prevSinkIds = currentIds
                root.sinks = result
                root.sources = resultSources

                // NOTE: VolumeService is single source of truth for volume
                // AudioService provides sink info, but volume updates come from AudioService
                // via the default sink parsing (mic mute poll) and VolumeService independently
                // monitors via wpctl get-volume @DEFAULT_SINK@
            }
        }
    }

    function setDefaultSink(sinkId) {
        Quickshell.execDetached(["wpctl", "set-default", sinkId.toString()])
        defaultSwitchTimer.running = true
    }

    function toggleMicMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
        // Quick re-poll to get actual state
        _quickMicPoll.start()
    }

    Timer {
        id: _quickMicPoll
        interval: 200
        repeat: false
        onTriggered: micStatusProc.running = true
    }

    function cycleMicSource() {
        if (sources.length === 0) {
            statusProc.running = false
            statusProc.running = true
        }
        if (sources.length === 0) return "No sources"
        if (sources.length === 1) return sources[0].name
        var curIdx = -1
        for (var i = 0; i < sources.length; i++) {
            if (sources[i].id === defaultSourceId) { curIdx = i; break }
        }
        var nextIdx = (curIdx + 1) % sources.length
        root.defaultSourceId = sources[nextIdx].id
        Quickshell.execDetached(["wpctl", "set-default", sources[nextIdx].id.toString()])
        return sources[nextIdx].name
    }

    Timer {
        id: defaultSwitchTimer
        interval: 300
        repeat: false
        onTriggered: statusProc.running = true
    }

    function isBluetoothSink(name) {
        var n = name.toLowerCase()
        return n.indexOf("bluetooth") !== -1 || n.indexOf("a2dp") !== -1 || n.indexOf("bluez") !== -1
    }

    function sinkName(sinkId) {
        for (var i = 0; i < sinks.length; i++) {
            if (sinks[i].id === sinkId) return sinks[i].name
        }
        return "Unknown"
    }

    function sinkIcon(sinkName) {
        var name = sinkName.toLowerCase()
        if (name.indexOf("headphone") !== -1 || name.indexOf("headset") !== -1 || name.indexOf("earphone") !== -1 || name.indexOf("earbud") !== -1 || name.indexOf("soundcore") !== -1)
            return "\uF025"
        if (name.indexOf("bluetooth") !== -1 || name.indexOf("a2dp") !== -1 || name.indexOf("bluez") !== -1)
            return "\uF293"
        if (name.indexOf("hdmi") !== -1 || name.indexOf("displayport") !== -1)
            return "\uF03D"
        if (name.indexOf("usb") !== -1)
            return "\uF025"
        return "\uF028"
    }

    Component.onCompleted: {
        statusProc.running = true
    }
}
