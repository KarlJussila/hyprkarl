# Configuration Map

This page shows where Hyprkarl keeps config, state, and the main files you
would edit.

## Top-Level Layout

- `bin/`
  Commands meant to be run directly. Dispatchers (`hk-theme`, `hk-pkg`, …) route to top-level `hk-<noun>-<action>` commands.
- `bin/lib/`
  Shared sourced helpers (`docker.sh`, `update.sh`). Reserved for utilities used by more than one command, not single-use implementations.
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

## AGS Bar

The AGS bar lives under `config/ags/bar/`. The main editing surfaces are:

- `config/ags/bar/config/layout.config.ts`
  Bar edge, widget order, corner curves, autohide, and exclusive mode
- `config/ags/bar/config/widgets.config.ts`
  Widget instances: each key is a widget ID, `kind` picks the implementation
- `themes/<theme>/bar.scss`
  Theme-specific bar colors, spacing, radii, and typography

`config/ags/bar/theme.scss` is a symlink managed by `hk-theme set`; it points to the active theme's `bar.scss`. Switching themes with `hk-theme set` updates the symlink and restarts AGS.

The bar can also be controlled at runtime via `hk-ags`:

```bash
hk-ags autohide on|off|toggle
hk-ags exclusive on|off|toggle
hk-ags show|hide|toggle
hk-ags status
```

See `config/ags/bar/README.md` for full widget configuration reference.

## Themes

Theme files live under `themes/<theme-name>/`.

See [Themes](themes.md) for the full theme layout and how
`config/hyprkarl/current/` selects the active theme.

## Scripts and Commands

Use this rule of thumb:

- put a command in `bin/` if it should be run directly. Subcommands of a dispatcher (e.g. `hk-theme set`) live as their own top-level commands (`hk-theme-set`); the dispatcher just `exec`s them.
- put a sourced helper in `bin/lib/` only if it is shared by more than one command (`docker.sh`, `update.sh`).
- put a support script in `scripts/` if it supports something else
