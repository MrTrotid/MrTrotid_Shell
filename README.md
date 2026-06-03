# MrTrotid Shell

A minimal Hyprland + Quickshell dotfiles setup — capsule-nobg bar with inline service logic.

## Structure

```
MrTrotid_Shell/
├── dotfiles/
│   └── .config/
│       ├── hypr/            # Hyprland WM config
│       │   ├── hyprland.conf
│       │   ├── hypridle.conf
│       │   ├── hyprlock.conf
│       │   ├── hyprpaper.conf
│       │   ├── monitors.conf
│       │   ├── workspaces.conf
│       │   ├── configurations/keybinds.lua
│       │   └── env
│       └── quickshell/      # Quickshell bar config
│           ├── shell.qml
│           ├── BarContent.qml
│           ├── ServiceContext.qml
│           ├── functions/ColorUtils.qml
│           └── widgets/
├── install.sh               # One-command setup
├── assets/                  # Wallpapers / extras
└── README.md
```

## Dependencies

- Hyprland (+ hypridle, hyprlock, hyprpaper)
- Quickshell (`quickshell-git` from AUR)
- JetBrainsMono Nerd Font
- `brightnessctl` — backlight control
- `pipewire`/`wireplumber` — audio
- `nm-applet` — network indicator

## Installation

```bash
git clone https://github.com/your-username/MrTrotid_Shell.git
cd MrTrotid_Shell
./install.sh
```

Or manually:

```bash
ln -sf "$PWD/dotfiles/.config/hypr"      ~/.config/hypr
ln -sf "$PWD/dotfiles/.config/quickshell" ~/.config/quickshell
```

## Usage

```bash
quickshell -c mrtrotid-shell
```

Keybinds:
- `Super + O` — Toggle bar
- `Super + M` — Toggle media player
- `Super + N` — Toggle QuickSettings
- `Super + B` — Toggle Bluetooth panel

## Credits

Based on the original [linux-ricing-dotfiles](https://github.com/MrTrotid/linux-ricing-dotfiles) setup.
