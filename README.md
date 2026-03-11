# hyprkarl
Work in progress configurations and scripts for CachyOS + Hyprland.

> **Warning:** The setup process is largely untested. Use at your own risk.

## Requirements
- Base CachyOS (Hyprland) install
- Btrfs filesystem (with LUKS encryption) and Limine boot loader are strongly recommended. Hyprkarl may implement changes involving either one in the future.
- Make sure Hyprland is running under UWSM (it should be default). SDDM autologin is configured to run hyprland-uwsm.desktop.

## Warnings
- The setup script enables SDDM autologin. If you don't like that, you can re-enable it yourself or edit setup-system.sh. The intention is to rely on LUKS encryption for authentication on boot instead of requiring two passwords.
- If you want a multi-user setup, you'll have to figure that out on your own

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
- When editing configs, you should just directly edit the files in `~/.local/share/hyprkarl/`
- I would recommend creating a branch and using git to track your changes, especially if you intend to make substantial changes and/or pull in updates.
- Pull updates at your own risk if you have edited configs.
- Themes are located in the `themes/` directory. You are encouraged to make your own theme; it will be recognized automatically by the theme switcher.
- User-created themes need to have all of the same files as the default themes, or you might run into problems. I recommend copying an existing theme in its entirety and editing from there.

## Keybindings
These are the basic keybinds to get you started. You can search  for keybinds in the keybinds menu, or create your own in the hyprland configs.
```
SUPER + K               ->  Searchable list of keybinds
SUPER + ALT + SPACE     ->  Hyprkarl menu
SUPER + SPACE           ->  App launcher
SUPER + SHIFT + F       ->  File manager (yazi)
SUPER + ENTER           ->  Terminal
SUPER + [0-9]           ->  Navigate to workspace
SUPER + SHIFT +  [0-9]  ->  Move window to workspace
SUPER + F               ->  Fullscreen
SUPER + T               ->  Toggle tiling/floating
```