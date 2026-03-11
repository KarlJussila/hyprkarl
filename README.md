# hyprkarl
A curated configuration layer for CachyOS + Hyprland, inspired by Omarchy. Hyprkarl takes a fresh CachyOS Hyprland install and transforms it into a polished, unified desktop experience with a cohesive theme system, custom menus, and a suite of utility scripts.

> **Warning:** The setup process is largely untested. Use at your own risk.

## Requirements
- Base CachyOS (Hyprland) install
- Btrfs filesystem (with LUKS encryption) and Limine boot loader are strongly recommended. Hyprkarl may implement changes involving either one in the future.
- Hyprland must be running under UWSM (this is the default on CachyOS). SDDM autologin is configured to launch `hyprland-uwsm.desktop`.

## Warnings
- The setup script enables SDDM autologin. The intention is to rely on LUKS encryption for boot authentication instead of requiring two passwords. If you prefer to disable autologin, edit `setup-system.sh` before running it, or disable it manually afterward.
- Multi-user setups are not supported. You're on your own if you need one.

## Installation
Clone into `~/.local/share/` and cd into the directory:
```bash
git clone --depth=1 https://github.com/KarlJussila/hyprkarl.git ~/.local/share/hyprkarl
cd ~/.local/share/hyprkarl
```

Run the setup script:

> **Warning:** If you have existing configurations for **_anything_**, back them up. This script is only meant to be used on fresh installs. It should also be safe to run on existing (unmodified) hyprkarl systems.
```bash
./setup-all.sh
```

## Configuration
Hyprkarl's configs and scripts live in `~/.local/share/hyprkarl/` and are symlinked into `~/.config/` and `~/.local/share/applications/` automatically. To customize anything, edit the files directly in `~/.local/share/hyprkarl/`.

A few things worth knowing:
- Creating a git branch to track your changes is strongly recommended, especially if you plan to pull in future updates.
- Pulling updates carries some risk if you have edited configs; proceed with caution.
- User environment variables (default terminal, default editor, etc.) are set in `~/.config/uwsm/default`. Changes require a session restart to take effect.

## Themes
Themes live in the `themes/` directory and control the appearance of the terminal, waybar, rofi, mako, hyprlock, and more. You can switch themes from the Hyprkarl menu (`SUPER + ALT + SPACE` → Config → Theme).

To create your own theme, copy an existing theme directory in its entirety and edit from there. Custom themes are recognized automatically by the theme switcher. Make sure your theme includes all of the same files as the default themes, or you may run into problems.

## Keybindings
These are the basic keybinds to get you started. You can search for others in the keybinds menu, or define your own in the Hyprland configs.
```
SUPER + K              ->  Searchable list of keybinds
SUPER + ALT + SPACE    ->  Hyprkarl menu
SUPER + SPACE          ->  App launcher
SUPER + SHIFT + F      ->  File manager (yazi)
SUPER + ENTER          ->  Terminal
SUPER + [0-9]          ->  Navigate to workspace
SUPER + SHIFT + [0-9]  ->  Move window to workspace
SUPER + F              ->  Fullscreen
SUPER + T              ->  Toggle tiling/floating
```

## Updating
```bash
cd ~/.local/share/hyprkarl
git pull
```
Pull updates at your own risk if you have customized your configs. Consider keeping your changes on a separate branch and merging upstream changes in selectively.