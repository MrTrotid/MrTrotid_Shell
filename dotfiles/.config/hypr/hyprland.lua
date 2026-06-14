-- hyprland.lua — Trotid Shell
-- https://wiki.hypr.land/Configuring/Start/

local home = os.getenv("HOME")

-- Include modular configs
dofile(home .. "/.config/hypr/colors/colors.lua")
dofile(home .. "/.config/hypr/monitors.lua")
dofile(home .. "/.config/hypr/configurations/keybinds.lua")
dofile(home .. "/.config/hypr/windowrules.lua")

-- Environment variables
hl.env("XCURSOR_THEME", "breeze")
hl.env("XCURSOR_SIZE", "24")
hl.env("XDG_MENU_PREFIX", "arch-")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")
hl.env("GTK_THEME", "Adwaita:dark")

-- Input
hl.config({
    input = {
        kb_layout = "us",
        kb_options = "compose:ralt",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
})

-- General
hl.config({
    general = {
        gaps_in = 8,
        gaps_out = 16,
        border_size = 1,
        ["col.active_border"] = primary,
        ["col.inactive_border"] = "0xff444444",
        layout = "scrolling",
        extend_border_grab_area = 50,
        resize_on_border = false,
    },
})

-- Decoration
hl.config({
    decoration = {
        rounding = 11,
        rounding_power = 2.0,
        active_opacity = 0.99,
        inactive_opacity = 0.96,
        fullscreen_opacity = 0.9,
        dim_special = 0.25,
        dim_strength = 0.25,
        blur = {
            enabled = true,
            size = 2,
            passes = 3,
            brightness = 0.77,
            contrast = 0.84,
            noise = 0.007,
        },
        shadow = {
            enabled = true,
            range = 14,
            render_power = 4,
            color = "0xac090202",
            color_inactive = "0xac090202",
            offset = "1 2",
        },
    },
})

-- Layout: Dwindle (default)
hl.config({
    dwindle = {
        preserve_split = true,
    },
})

-- Layout: Scrolling (PaperWM-like infinite tape)
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.8,
        direction = "right",
        follow_focus = true,
        wrap_focus = true,
    },
})

-- Misc
hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 0,
    },
})

-- Bezier curves (from gui.conf)
hl.curve("MySmooth", { type = "bezier", points = { {0.125, 0.706}, {0.245, 0.955} } })
hl.curve("smooth", { type = "bezier", points = { {0.05, 0.82}, {0.28, 0.97} } })

-- Animations (from gui.conf)
hl.animation({ leaf = "windows", enabled = true, speed = 4.0, bezier = "MySmooth", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.0, bezier = "MySmooth", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4.0, bezier = "MySmooth", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4.0, bezier = "smooth", style = "slide" })
hl.animation({ leaf = "layers", enabled = true, speed = 8.0, bezier = "MySmooth", style = "slide" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4.5, bezier = "MySmooth", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4.0, bezier = "MySmooth", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.0, bezier = "default", style = "slidefade" })

-- Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("/usr/bin/gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hyprpm reload")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprsunset")
    hl.exec_cmd("setxkbmap -option compose:ralt")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("wallset-backend-startup")
    hl.exec_cmd("quickshell -c mrtrotid-shell")
end)

