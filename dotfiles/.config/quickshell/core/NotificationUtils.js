.pragma library

function getAppIconCandidates(appName, appIcon) {
    var candidates = []
    if (appIcon && appIcon !== "") {
        candidates.push(appIcon)
    }
    
    var home = Quickshell.env("HOME")
    var appLower = (appName || "").toLowerCase()
    var appDirs = [
        home + "/.local/share/icons",
        home + "/.icons",
        "/usr/share/icons",
        "/usr/share/pixmaps"
    ]
    
    var sizes = ["scalable", "48x48", "64x64", "128x128", "256x256"]
    var themes = ["hicolor", "Adwaita", "Papirus", "Tela", "Nord", "Dracula"]
    
    for (var d = 0; d < appDirs.length; d++) {
        for (var t = 0; t < themes.length; t++) {
            for (var s = 0; s < sizes.length; s++) {
                candidates.push("file://" + appDirs[d] + "/" + themes[t] + "/" + sizes[s] + "/apps/" + appName + ".png")
                candidates.push("file://" + appDirs[d] + "/" + themes[t] + "/" + sizes[s] + "/applications/" + appName + ".png")
            }
        }
    }
    
    return candidates
}

function findSuitableIcon(text) {
    var t = (text || "").toLowerCase()
    if (t.indexOf("error") >= 0 || t.indexOf("fail") >= 0) return "\uF00D"
    if (t.indexOf("warn") >= 0) return "\uF071"
    if (t.indexOf("success") >= 0 || t.indexOf("done") >= 0) return "\uF00C"
    if (t.indexOf("battery") >= 0 || t.indexOf("power") >= 0) return "\uF0E7"
    if (t.indexOf("wifi") >= 0 || t.indexOf("network") >= 0) return "\uF1EB"
    if (t.indexOf("bluetooth") >= 0) return "\uF293"
    if (t.indexOf("volume") >= 0 || t.indexOf("audio") >= 0) return "\uF028"
    if (t.indexOf("music") >= 0 || t.indexOf("song") >= 0) return "\uF001"
    if (t.indexOf("image") >= 0 || t.indexOf("photo") >= 0 || t.indexOf("screenshot") >= 0) return "\uF030"
    if (t.indexOf("video") >= 0 || t.indexOf("record") >= 0) return "\uF03D"
    if (t.indexOf("message") >= 0 || t.indexOf("chat") >= 0 || t.indexOf("discord") >= 0) return "\uF075"
    if (t.indexOf("mail") >= 0 || t.indexOf("email") >= 0) return "\uF0E0"
    if (t.indexOf("calendar") >= 0 || t.indexOf("event") >= 0 || t.indexOf("meeting") >= 0) return "\uF073"
    if (t.indexOf("download") >= 0) return "\uF019"
    if (t.indexOf("upload") >= 0) return "\uF093"
    if (t.indexOf("update") >= 0 || t.indexOf("upgrade") >= 0) return "\uF021"
    if (t.indexOf("lock") >= 0 || t.indexOf("security") >= 0) return "\uF023"
    if (t.indexOf("notification") >= 0 || t.indexOf("alert") >= 0) return "\uF0F3"
    return "\uF128"
}

function getFriendlyTimeString(timestamp) {
    var now = Date.now()
    var diff = now - timestamp
    var seconds = Math.floor(diff / 1000)
    var minutes = Math.floor(seconds / 60)
    var hours = Math.floor(minutes / 60)
    var days = Math.floor(hours / 24)
    
    if (seconds < 60) return "just now"
    if (minutes < 60) return minutes + "m ago"
    if (hours < 24) return hours + "h ago"
    if (days < 7) return days + "d ago"
    
    var d = new Date(timestamp)
    var month = d.getMonth() + 1
    var day = d.getDate()
    return month + "/" + day
}