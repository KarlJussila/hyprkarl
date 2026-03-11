# Hyprkarl: Hyprland Configuration for CachyOS

Hyprkarl is a modular and highly customized Hyprland configuration (dotfiles) project specifically tailored for CachyOS. It provides a suite of management scripts and a theming engine to create a cohesive desktop experience.

## Project Overview

- **Window Manager:** Hyprland
- **Status Bar:** Waybar (with custom expander modules and indicators)
- **Application Launcher:** Rofi
- **Notifications:** Mako
- **On-Screen Display (OSD):** SwayOSD
- **Shell:** Fish
- **File Manager:** Yazi (TUI), Nautilus (GUI)
- **Management Logic:** Custom Bash scripts located in `bin/`

## Architecture

The project follows a modular structure where configuration files are separated by application and functional areas.

- `bin/`: Contains the core logic for the environment. All scripts are prefixed with `hyprkarl-`.
- `config/`: Application-specific configurations. This directory mirrors the structure of `~/.config`.
- `themes/`: Defines visual themes. The active theme is symlinked to `config/hyprkarl/current/theme`.
- `scripts/`: Supplemental scripts, primarily for Waybar indicators (recording, caffeine).
- `applications/`: Custom `.desktop` files.

## Installation and Setup

The project is designed to be installed in `~/.local/share/hyprkarl`.

### Key Setup Scripts:
- `./setup-all.sh`: Runs all setup steps.
- `./setup-packages.sh`: Installs dependencies via `pacman` and `paru`, and removes conflicting defaults (like `dolphin` and `wofi`).
- `./setup-dotfiles.sh`: Uses `GNU Stow` to symlink configuration files into `~/.config` and `~/.local/share/applications`.
- `./setup-system.sh`: Configures system-level tweaks like dark mode and SDDM autologin.

## Key Management Commands

Most interaction with the system configuration is done through `hyprkarl-*` commands:

| Command | Description |
| :--- | :--- |
| `hyprkarl-theme-set <theme>` | Switches the global theme (Hyprland, Waybar, GTK, etc.). |
| `hyprkarl-restart-<app>` | Restarts specific components (e.g., `waybar`, `mako`, `hypridle`). |
| `hyprkarl-menu` | Launches the Rofi-based main menu. |
| `hyprkarl-caffeine` | Toggles the idle inhibitor. |
| `hyprkarl-pkg-install` | Custom wrapper for package installation. |
| `hyprkarl-record-screen` | Screen recording utility using `gpu-screen-recorder`. |

## Development Conventions

1.  **Script Naming:** All custom management scripts must be prefixed with `hyprkarl-` and placed in `bin/`.
2.  **Pathing:** Use the `HYPRKARL_PATH` environment variable (typically `~/.local/share/hyprkarl`) to reference project files.
3.  **Theming:** Themes must be self-contained within a folder in `themes/`. Core apps should source `~/.config/hyprkarl/current/theme/<app_config>` to stay in sync.
4.  **Configuration Sourcing:** The main `hyprland.conf` is a "source-only" file that pulls in modular configs from `config/hypr/`.

## Dependencies

Key dependencies managed by `setup-packages.sh`:
- `waybar`, `hyprpaper`, `hyprlock`, `hypridle`, `hyprsunset`
- `swayosd`, `mako`, `rofi`
- `stow`, `gum`, `yay-bin`/`paru`
- `ttf-jetbrains-mono-nerd`, `yaru-icon-theme`
