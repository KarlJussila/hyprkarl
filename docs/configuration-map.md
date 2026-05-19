# Configuration Map

This page shows where Hyprkarl keeps config, state, and the main files you
would edit.

## Top-Level Layout

- `bin/`
  Commands meant to be run directly
- `bin/lib/`
  Internal shell helpers for `bin/`, kept as `*.sh` files
- `config/`
  Application config and session behavior
- `packages/`
  Package lists read by `setup-packages.sh` and `hk-update packages`
- `themes/`
  Theme files and per-theme overrides
- `scripts/`
  Support scripts and backend logic
- `docs/`
  Documentation for using and editing Hyprkarl
- `templates/`
  Files copied or rendered by setup and install commands
- `applications/`
  Desktop files exposed under `~/.local/share/applications/`

## Stateful Runtime Files

`config/hyprkarl/current/` holds the active theme and wallpaper state:

- `config/hyprkarl/current/theme`
  Symlink to the active theme directory
- `config/hyprkarl/current/theme.name`
  Active theme name
- `config/hyprkarl/current/wallpaper`
  Symlink to the current wallpaper

If theme or wallpaper behavior looks wrong, check this directory first.

`config/hyprkarl/update/` holds the last-applied commit per update category:

- `config/hyprkarl/update/dotfiles.commit`
- `config/hyprkarl/update/packages.commit`
- `config/hyprkarl/update/system.commit`

These files are machine-local and gitignored. They are written by `hk-update`
and the setup scripts. Delete one to force `hk-update` to re-run that category
regardless of whether anything changed.

## Hyprland

`config/hypr/hyprland.conf` is the main Hyprland entrypoint. It only sources the
rest of the config:

- `envs.conf`
  Hyprland environment variables
- `autostart.conf`
  Startup commands
- `monitors.conf`
  Monitor layout
- `permissions.conf`
  Permission rules
- `looknfeel.conf`
  General appearance, animations, layout, and related settings
- `windows.conf`
  Window rules, layer rules, floating behavior, opacity, and app-specific rule
  includes
- `input.conf`
  Input settings
- `bindings.conf`
  Keybinding includes
- `~/.config/hyprkarl/current/theme/hyprland.conf`
  Theme-specific Hyprland styling

`bindings.conf` then sources:

- `bindings/utilities.conf`
- `bindings/apps.conf`
- `bindings/tiling.conf`
- `bindings/media.conf`

`windows.conf` sources `apps.conf`, which then sources:

- `apps/browser.conf`
- `apps/hyprshot.conf`
- `apps/localsend.conf`
- `apps/pip.conf`
- `apps/steam.conf`
- `apps/system.conf`
- `apps/terminals.conf`

For keybindings, start in `config/hypr/bindings/`. For app-specific window
rules, start in `config/hypr/apps/`.

For Hyprland syntax and option reference, see the official Hyprland docs:
[Configuring](https://wiki.hypr.land/Configuring/) and
[Variables](https://wiki.hypr.land/Configuring/Variables/).

## UWSM and Session Defaults

`config/uwsm/env` sets the session-wide environment:

- exports `HYPRKARL_PATH`
- adds `bin/` to `PATH`
- extends `XDG_DATA_DIRS` for Flatpak desktop entries
- points `WIFITUI_THEME` at the active theme
- sets `QT_QPA_PLATFORMTHEME`
- sources `config/uwsm/default`

`config/uwsm/default` is the user-editable place for:

- `TERMINAL`
- `EDITOR`
- optional screenshot directory override
- optional screen recording directory override

The default terminal and editor commands update this file. Changes here require
a new session.

## Waybar

Waybar is split across these files:

- `config/waybar/config.jsonc`
  Module layout and module behavior
- `config/waybar/style.css`
  Shared structural CSS
- `themes/<theme>/waybar.css`
  Theme-specific Waybar colors
- `scripts/waybar/`
  Support scripts for custom modules

`config/waybar/style.css` imports the active theme's `waybar.css`.

## Themes

Theme files live under `themes/<theme-name>/`.

See [Themes](themes.md) for the full theme layout and how
`config/hyprkarl/current/` selects the active theme.

## Scripts and Commands

Use this rule of thumb:

- put a command in `bin/` if it should be run directly
- put a shell helper in `bin/lib/` if it supports another `bin/` command
- put a support script in `scripts/` if it supports something else
