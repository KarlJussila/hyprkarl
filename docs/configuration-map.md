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

Hyprland is configured in **Lua** (`hyprland.lua`), required since Hyprland 0.55
(hyprlang `.conf` is deprecated). `config/hypr/hyprland.lua` is the main
entrypoint. It only `require()`s the rest of the config (each module loads as a
separate Lua scope, so an error in one does not abort the others):

- `envs.lua`
  Hyprland environment variables (`hl.env()`)
- `autostart.lua`
  Startup commands (`hl.on("hyprland.start", …)`)
- `monitors.lua`
  Monitor layout plus the HiDPI scaling knobs that pair with it — `GDK_SCALE`
  and `xwayland.force_zero_scaling` (`hl.monitor{}`, `hl.env()`, `hl.config{}`)
- `permissions.lua`
  Permission rules (`hl.permission()`)
- `looknfeel.lua`
  General appearance and layout settings (`hl.config{}`)
- `animations.lua`
  Bezier curves and animation rules (`hl.curve()`, `hl.animation{}`)
- `gum.lua`
  GUM terminal UI color env vars (`hl.env()`)
- `windows.lua`
  Window rules, layer rules, floating behavior, opacity, and the per-category
  rule includes from `windows/` (`hl.window_rule{}` / `hl.layer_rule{}`). All
  windows receive the `default-opacity` tag, and the final window rule applies
  `opacity 1.0 0.8` (full focused, 80% unfocused) to anything still carrying it.
  Modules in `windows/` run before that final rule, so they can opt a window out
  by adding `tag = "-default-opacity"` (media and video windows do this to stay
  fully opaque). Rules are intentionally anonymous (no `name=`) so they evaluate
  strictly top-to-bottom.
- `input.lua`
  Input settings (`hl.config{ input = … }`, `hl.gesture{}`)
- `bindings.lua`
  Keybinding includes (`hl.bind()`)

`hyprland.lua` then loads the active theme last, by absolute path
(`loadfile` of `~/.config/hyprkarl/current/theme/hyprland.lua`), so theme colors
override. The theme dir lives outside `config/hypr/`, so `require()`'s relative
resolution can't reach it — hence `loadfile`.

`bindings.lua` then requires:

- `bindings/system.lua`
- `bindings/apps.lua`
- `bindings/windows.lua`
- `bindings/workspaces.lua`
- `bindings/media.lua`

`windows.lua` requires the per-category rule modules in `windows/`:

- `windows/browsers.lua`
- `windows/floating.lua`
- `windows/media.lua`
- `windows/terminals.lua`
- `windows/screenshots.lua`

Validate edits with `Hyprland --verify-config` (non-destructive: parses the config
and reports errors without launching). There is no automatic fallback if
`hyprland.lua` is broken.

For keybindings, start in `config/hypr/bindings/`. For app-specific window
rules, start in `config/hypr/windows/`.

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
