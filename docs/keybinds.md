# Keybinds - Hyprland Keybinding Reference

## Purpose
All keybinds defined in a single file (`dotfiles/.config/hypr/keybinds.conf`) for cheatsheet generation and easy reference.

## File Location
`dotfiles/.config/hypr/keybinds.conf`

## Shell Toggles (Global IPC)
These use Quickshell's global shortcut system (`global, quickshell:<action>`):

| Key | Action | IPC Command |
|---|---|---|
| `Super + A` | Toggle notification panel | `quickshell:notificationPanelToggle` |
| `Super + O` | Toggle bar | `quickshell:barToggle` |
| `Super + M` | Toggle media card | `quickshell:mediaControlsToggle` |
| `Super + J` | Toggle quick actions HUD | `quickshell:quickActionsToggle` |
| `Super + /` | Toggle cheatsheet | `quickshell:cheatsheetToggle` |
| `Ctrl + Super + T` | Toggle wallpaper picker | `quickshell:wallpaperToggle` |

## Night Light
| Key | Action |
|---|---|
| `Super + Shift + N` | Toggle hyprsunset (night light, 3200K) |

## App Launchers
| Key | Application |
|---|---|
| `Super + Return` | Ghostty terminal |
| `Super + Space` | Rofi app launcher |
| `Super + V` | Clipboard history (cliphist + rofi) |
| `Super + W` | Zen browser |
| `Super + Shift + W` | Brave browser |
| `Super + E` | Thunar file manager |
| `Super + C` | Neovim |

## Window Management
| Key | Action |
|---|---|
| `Super + H / L` | Focus left / right |
| `Super + Arrows` | Focus direction |
| `Super + Shift + Arrows` | Move window |
| `Super + Q` | Close window |
| `Super + G` | Toggle floating |
| `Super + P` | Pin window |
| `Super + F` | Fullscreen (workspace) |
| `Super + Shift + F` | Fullscreen (real) |
| `Super + mouse:272` | Move window (mouse) |
| `Super + mouse:273` | Resize window (mouse) |

## Workspaces
| Key | Action |
|---|---|
| `Super + 1-0` | Switch to workspace 1-10 |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + Tab` | Next workspace |
| `Super + Shift + Tab` | Previous workspace |
| `Super + Page Up/Down` | Cycle workspaces |
| `Super + =/-` | Cycle workspaces |
| `Ctrl + Super + ←/→` | Move to adjacent workspace |
| `Super + S` | Toggle scratchpad |
| `Ctrl + Super + S` | Toggle scratchpad (alt) |
| `Super + Alt + S` | Move to scratchpad |

## Session
| Key | Action |
|---|---|
| `Super + Shift + P` | Lock screen (loginctl lock-session) |
| `Super + Shift + L` | Suspend (systemctl suspend) |
| `Ctrl+Shift+Alt+Super+Delete` | Power off |
| `Ctrl+Shift+Alt+Super+End` | Reboot |

## Screenshots (grim + slurp)
| Key | Mode | Script |
|---|---|---|
| `Print` | Full screen | `screenshot.sh full` |
| `Ctrl + Print` | Region select | `screenshot.sh region` |
| `Shift + Print` | Window select | `screenshot.sh window` |
| `Alt + Print` | Monitor select | `screenshot.sh monitor` |
| `Ctrl + Shift + Print` | Annotate (swappy) | `screenshot.sh annotate` |
| `Super + Shift + C` | Color picker (hyprpicker) | `hyprpicker -a` |

## Screen Recording (wf-recorder)
| Key | Mode |
|---|---|
| `Ctrl + Shift + R` | Region recording / stop |
| `Ctrl + Alt + R` | Full screen recording / stop |

## Hardware Keys
| Key | Action |
|---|---|
| `XF86MonBrightnessUp/Down` | Adjust brightness (brightnessctl) |
| `XF86AudioRaiseVolume/LowerVolume` | Adjust volume (wpctl, max 1.5) |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioMicMute` | Toggle mic mute |
| `XF86AudioNext/Prev/Play/Pause` | Media controls (playerctl) |

## Shell Restart
| Key | Action |
|---|---|
| `Ctrl + Super + R` | Kill all quickshell instances, restart `mrtrotid-shell` |

## Modifying This File
- Add new keybind: Add `bind = <mods>, <key>, <dispatcher>, <args>`
- Add global IPC: Add `bind = <mods>, <key>, global, quickshell:<action>`
- Remove keybind: Comment out with `#`
- All keybinds are in one file to enable cheatsheet generation
