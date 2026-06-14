# Contributing to Trotid Shell

First off, thanks for taking the time to contribute! 🎉

The following is a set of guidelines for contributing to Trotid Shell. These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
  - [QML Style](#qml-style)
  - [Lua Style](#lua-style)
  - [Bash Style](#bash-style)
- [Commit Messages](#commit-messages)

## Code of Conduct

This project and everyone participating in it is governed by a simple rule: **be excellent to each other**. Harassment, trolling, and other disrespectful behavior will not be tolerated.

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report, please:
1. Check the [Troubleshooting](README.md#troubleshooting) section in the README
2. Search existing issues to see if it's already been reported
3. Check if the bug is specific to your hardware (VM vs physical, GPU model, etc.)

When creating a bug report, include:
- Your system info (OS, kernel, Hyprland version, Quickshell version)
- Whether you're on a VM or physical hardware
- Steps to reproduce
- Relevant logs (`quickshell -c mrtrotid-shell log`, `journalctl --user -u quickshell -f`)
- Any relevant error messages

### Suggesting Features

Feature suggestions are welcome! When suggesting, please:
- Describe the feature and why it would be useful
- If applicable, include examples from other projects
- Consider whether it fits the [design philosophy](README.md#design-philosophy)

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run lint/validation if available
5. Commit with a clear message (see [Commit Messages](#commit-messages))
6. Push to your fork
7. Open a Pull Request

**Before submitting:**
- Test your changes on both a VM and physical hardware if possible
- If you changed QML files, test with `quickshell -c mrtrotid-shell -v`
- If you changed Lua files, validate with `lua ~/.config/hypr/hyprland.lua`
- If you changed the installer, run through a test install
- Update documentation if needed

## Development Setup

```bash
# Clone with symlinks for live development
git clone https://github.com/MrTrotid/MrTrotid_Shell ~/Desktop/MrTrotid_Shell
cd ~/Desktop/MrTrotid_Shell

# Run installer (choose symlink option for quickshell)
./install.sh

# After install, edit QML files and reload:
./reload.sh

# Or for Hyprland config changes:
hyprctl reload
```

### Quick Reload
```bash
./reload.sh    # Restarts quickshell for QML changes
```

## Coding Guidelines

### QML Style

- Use 4-space indentation
- Prefer `id:` over `objectName` for referencing elements
- Use `pragma Singleton` + `qmldir` for services
- Use `required property` for delegate modelData
- Bind to `ColorService.*` for themed colors (not hardcoded values)
- Follow existing patterns in similar components

```qml
Item {
    id: root
    property string label: "Example"

    Rectangle {
        color: ColorService.surfaceContainer
        Text {
            text: root.label
            color: ColorService.surfaceText
        }
    }
}
```

### Lua Style

- Use 4-space indentation
- Use `hl.*` API functions (not raw config strings)
- Keep keybinds in `configurations/keybinds.lua`
- Keep window rules in `windowrules.lua`
- Use `dofile()` for modular includes

### Bash Style

- Use `#!/usr/bin/env bash`
- Use `set -uo pipefail` in scripts
- Prefer `pkill -x` over `killall` (killall matches partial names)
- Quote all variable expansions
- Use `[[ ]]` for test conditions
- Use `$(cmd)` over backticks

## Commit Messages

Follow the conventional commits format:

```
<type>: <short description>

<optional body>
```

Types:
- `feat` — New feature
- `fix` — Bug fix
- `docs` — Documentation changes
- `style` — Formatting, styling
- `refactor` — Code restructuring
- `perf` — Performance improvement
- `test` — Adding/updating tests
- `chore` — Maintenance, tooling

Examples:
```
fix: resolve quickshell config path for -c flag
feat: add VM detection with per-hypervisor monitor fallbacks
docs: update README with troubleshooting section
```

---

*Thank you for contributing to Trotid Shell!*
