-- Keybindings for Trotid Shell
-- All binds in one file for cheatsheet generation

local mainMod = "SUPER"

-- === Shell: Panel toggles (Quickshell global IPC) ===
hl.bind(mainMod .. " + A", hl.dsp.global("quickshell:notificationPanelToggle"))
hl.bind(mainMod .. " + O", hl.dsp.global("quickshell:barToggle"))
hl.bind(mainMod .. " + M", hl.dsp.global("quickshell:mediaControlsToggle"))
hl.bind(mainMod .. " + J", hl.dsp.global("quickshell:quickActionsToggle"))

-- === Night Light ===
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("if pgrep -x hyprsunset > /dev/null; then pkill hyprsunset; else hyprsunset -t 3200; fi"))

-- === Wallpaper selector ===
hl.bind("CTRL + " .. mainMod .. " + T", hl.dsp.global("quickshell:wallpaperToggle"))

-- === Shell Toggles ===
hl.bind(mainMod .. " + V", hl.dsp.global("quickshell:clipboardToggle"))
hl.bind(mainMod .. " + period", hl.dsp.global("quickshell:emojiToggle"))
hl.bind(mainMod .. " + comma", hl.dsp.global("quickshell:gifToggle"))
hl.bind(mainMod .. " + slash", hl.dsp.global("quickshell:cheatsheetToggle"))

-- === Apps ===
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("bash ~/.config/rofi/launchers/type-1/launcher.sh"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("brave-browser"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("nvim"))

-- === Window: Focus ===
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- === Window: Move ===
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

-- === Window: Close / Float / Fullscreen ===
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + G", hl.dsp.togglefloating())
hl.bind(mainMod .. " + P", hl.dsp.window.pin())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("hyprctl dispatch fullscreen 1"))

-- === Window: Mouse resize / move ===
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- === Workspace: Switch by number ===
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
end

-- === Workspace: Move window to number ===
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- === Workspace: Cycle ===
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("qs ipc -c overview call overview toggle"))
hl.bind(mainMod .. " + Page_Up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + Page_Down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + equal", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + minus", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + " .. mainMod .. " + left", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("CTRL + " .. mainMod .. " + right", hl.dsp.window.move({ workspace = "r+1" }))

-- === Scrolling layout navigation ===
hl.bind(mainMod .. " + bracketleft", hl.dsp.layout("scroll l"), { description = "Scroll viewport left (scrolling layout)" })
hl.bind(mainMod .. " + bracketright", hl.dsp.layout("scroll r"), { description = "Scroll viewport right (scrolling layout)" })

-- === Special: Scratchpad ===
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("special"))
hl.bind("CTRL + " .. mainMod .. " + S", hl.dsp.workspace.toggle_special("special"))
hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special" }))

-- === Session ===
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"))
hl.bind("CTRL + SHIFT + ALT + " .. mainMod .. " + Delete", hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff"))
hl.bind("CTRL + SHIFT + ALT + " .. mainMod .. " + End", hl.dsp.exec_cmd("systemctl reboot || loginctl reboot"))

-- === Screenshots ===
hl.bind("Print", hl.dsp.exec_cmd("bash ~/.config/scripts/screenshots/screenshot.sh full"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("bash ~/.config/scripts/screenshots/screenshot.sh region"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("bash ~/.config/scripts/screenshots/screenshot.sh window"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("bash ~/.config/scripts/screenshots/screenshot.sh monitor"))
hl.bind("CTRL + SHIFT + Print", hl.dsp.exec_cmd("bash ~/.config/scripts/screenshots/screenshot.sh annotate"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))

-- === Screen Recording ===
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd("bash ~/.config/scripts/recording/recording.sh full"))
hl.bind("CTRL + SHIFT + R", hl.dsp.exec_cmd("bash ~/.config/scripts/recording/recording.sh region"))

-- === Brightness / Volume (locked = non-repeating while held) ===
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })

-- === Media keys ===
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

-- === Shell: Restart ===
hl.bind("CTRL + " .. mainMod .. " + R", hl.dsp.exec_cmd("pkill -x qs quickshell 2>/dev/null; quickshell -c mrtrotid-shell &"))
