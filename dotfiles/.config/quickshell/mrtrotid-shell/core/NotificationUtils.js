.pragma library

function getFriendlyTimeString(timestamp) {
    if (!timestamp) return ''
    var messageTime = new Date(timestamp)
    var now = new Date()
    var diffMs = now.getTime() - messageTime.getTime()

    if (diffMs < 60000) return 'Now'

    if (messageTime.toDateString() === now.toDateString()) {
        var diffMinutes = Math.floor(diffMs / 60000)
        var diffHours = Math.floor(diffMs / 3600000)
        if (diffHours > 0) return diffHours + "h"
        return diffMinutes + "m"
    }

    if (messageTime.toDateString() === new Date(now.getTime() - 86400000).toDateString())
        return 'Yesterday'

    return Qt.formatDateTime(messageTime, "MMM dd")
}

function resolveAppIcon(appName, appIcon) {
    if (!appName && !appIcon) return ""

    var candidates = []

    if (appIcon && appIcon.length > 0) {
        if (appIcon.indexOf("/") === 0) {
            return appIcon
        }
        candidates.push(appIcon)
    }

    if (appName && appName.length > 0) {
        var lower = appName.toLowerCase()
            .replace(/\s+/g, "-")
            .replace(/[^\w\-\.]/g, "")
        candidates.push(lower)
        candidates.push(lower + "-browser")
        candidates.push(lower + "-icon")
    }

    var sizes = ["48x48", "64x64", "scalable"]
    var exts = [".png", ".svg", ".svgz"]
    var bases = [
        "/usr/share/icons/hicolor",
        "/usr/share/pixmaps"
    ]

    for (var c = 0; c < candidates.length; c++) {
        var name = candidates[c]
        for (var b = 0; b < bases.length; b++) {
            for (var s = 0; s < sizes.length; s++) {
                for (var e = 0; e < exts.length; e++) {
                    candidates.push(bases[b] + "/" + sizes[s] + "/apps/" + name + exts[e])
                }
            }
            for (var p = 0; p < exts.length; p++) {
                candidates.push(bases[b] + "/" + name + exts[p])
            }
        }
    }

    return candidates.length > 0 ? candidates[0] : ""
}

function getAppIconCandidates(appName, appIcon) {
    var candidates = []

    if (appIcon && appIcon.length > 0) {
        if (appIcon.indexOf("/") === 0) {
            candidates.push(appIcon)
            return candidates
        }
        candidates.push(appIcon)
    }

    if (appName && appName.length > 0) {
        var lower = appName.toLowerCase()
            .replace(/\s+/g, "-")
            .replace(/[^\w\-\.]/g, "")
        candidates.push(lower)
        candidates.push(lower + "-browser")
        candidates.push(lower + "-icon")
    }

    var sizes = ["48x48", "64x64", "scalable"]
    var exts = [".png", ".svg", ".svgz"]
    var bases = [
        "/usr/share/icons/hicolor",
        "/usr/share/pixmaps"
    ]

    var resolved = []
    for (var c = 0; c < candidates.length; c++) {
        var name = candidates[c]
        if (name.indexOf("/") === 0) {
            resolved.push(name)
            continue
        }
        for (var b = 0; b < bases.length; b++) {
            for (var s = 0; s < sizes.length; s++) {
                for (var e = 0; e < exts.length; e++) {
                    resolved.push(bases[b] + "/" + sizes[s] + "/apps/" + name + exts[e])
                }
            }
            for (var p = 0; p < exts.length; p++) {
                resolved.push(bases[b] + "/" + name + exts[p])
            }
        }
    }

    return resolved
}

function findSuitableIcon(summary) {
    if (!summary || summary.length === 0) return '\uF0E6'
    var lower = summary.toLowerCase()
    if (lower.indexOf('screenshot') >= 0) return '\uF123'
    if (lower.indexOf('battery') >= 0 || lower.indexOf('power') >= 0) return '\uF0E7'
    if (lower.indexOf('update') >= 0) return '\uF019'
    if (lower.indexOf('music') >= 0 || lower.indexOf('media') >= 0) return '\uF001'
    if (lower.indexOf('install') >= 0) return '\uF019'
    if (lower.indexOf('error') >= 0 || lower.indexOf('unable') >= 0) return '\uF071'
    if (lower.indexOf('config') >= 0) return '\uF013'
    if (lower.indexOf('restart') >= 0 || lower.indexOf('reboot') >= 0) return '\uF021'
    if (lower.indexOf('record') >= 0) return '\uF03D'
    if (lower.indexOf('clipboard') >= 0) return '\uF0EA'
    if (lower.indexOf('welcome') >= 0) return '\uF0F3'
    if (lower.indexOf('download') >= 0) return '\uF019'
    return '\uF0E6'
}
