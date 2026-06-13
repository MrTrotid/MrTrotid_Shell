-- Window rules and layer rules for Trotid Shell

-- Float utility windows
hl.window_rule({
    match = { class = "^pavucontrol$" },
    float = true,
    size = { width = 800, height = 600 },
    center = true,
})

hl.window_rule({
    match = { class = "^nm-connection-editor$" },
    float = true,
    size = { width = 600, height = 400 },
    center = true,
})

hl.window_rule({
    match = { class = "^blueman-manager$" },
    float = true,
    size = { width = 600, height = 400 },
    center = true,
})

hl.window_rule({
    match = { class = "^file-roller$" },
    float = true,
})

hl.window_rule({
    match = { title = "^Picture-in-Picture$" },
    float = true,
})

hl.window_rule({
    match = { title = "^Open File$" },
    float = true,
})

hl.window_rule({
    match = { title = "^Save File$" },
    float = true,
})

-- Opacity rules
hl.window_rule({
    match = { class = "^kitty$" },
    opacity = 0.95,
    opacity_active = 0.90,
})

hl.window_rule({
    match = { class = "^code$" },
    opacity = 0.95,
    opacity_active = 0.90,
})

hl.window_rule({
    match = { class = "^firefox$" },
    opacity = 0.95,
    opacity_active = 0.90,
})

-- IDE tool windows (jetbrains / android-studio)
hl.window_rule({
    match = {
        class = "^(jetbrains-.*|android-studio)$",
        title = "^(win[0-9]+)$",
    },
    float = true,
    no_focus = true,
    rounding = 20,
    decorate = true,
    border_size = 2,
})

-- Desktop Editors
hl.window_rule({
    match = { class = "^(DesktopEditors)$" },
    float = true,
    center = true,
    workspace = "unset",
})

-- OpenBoard no blur
hl.window_rule({
    match = { class = "org.oe-f.openboard" },
    no_blur = true,
})

-- Layer rules
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.7 })

hl.layer_rule({ match = { namespace = "quickshell" }, blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "quickshell" }, no_anim = true })

hl.layer_rule({ match = { namespace = "quickshell:overview" }, blur = true, ignore_alpha = 0.2 })
