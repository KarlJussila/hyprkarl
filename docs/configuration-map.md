# Configuration Map

This page shows where Hyprkarl keeps config, state, and the main files you
would edit.

## Top-Level Layout

- `bin/`
  Commands meant to be run directly. Dispatchers (`hk-theme`, `hk-pkg`, …) route to top-level `hk-<noun>-<action>` commands.
- `bin/lib/`
  Shared sourced helpers (`docker.sh`, `shell.sh`, `update.sh`). Reserved for utilities used by more than one command, not single-use implementations.
- `config/`
  Application config and session behavior
- `defaults/`
  Upstream-owned shell data and Hyprland behavior
- `user/`
  Reserved user-owned configuration; upstream keeps only documentation here
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

Authoritative theme and wallpaper state lives under
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/`. `current/theme` selects an
immutable generated bundle under `themes/`; `current/theme.name`,
`current/theme.json`, and `current/wallpaper` carry the small selectors.

`config/hyprkarl/current/` contains fixed compatibility links to that state:

- `config/hyprkarl/current/theme`
  Link to the XDG-state active-theme link
- `config/hyprkarl/current/theme.name`
  Link to the XDG-state theme name
- `config/hyprkarl/current/wallpaper`
  Link to the XDG-state wallpaper

If theme or wallpaper behavior looks wrong, check this directory first.

`config/hyprkarl/update/` holds the last-applied commit per update category:

- `config/hyprkarl/update/dotfiles.commit`
- `config/hyprkarl/update/packages.commit`
- `config/hyprkarl/update/system.commit`

These files are machine-local and gitignored. They are written by `hk-update`
and the setup scripts. Delete one to force `hk-update` to re-run that category
regardless of whether anything changed.

Personal executable lifecycle hooks live under
`user/hooks/<event>.d/`. Hyprkarl supports `post-boot`, `post-update`,
`theme-set`, and `wallpaper-set`; files run in lexical order. See
[Extending Hyprkarl](extending-hyprkarl.md#add-a-lifecycle-hook).

The active bundle's `gtk-theme/` payload is materialized separately as a
managed real-file copy at `~/.local/share/themes/hyprkarl/`. Theme switches
replace that copy; GTK does not consume it through the runtime symlink tree.

## Hyprland

Hyprland is configured in **Lua** (`hyprland.lua`), required since Hyprland 0.55
(hyprlang `.conf` is deprecated). `config/hypr/hyprland.lua` is the stable live
bootstrap. Shipped behavior lives under `defaults/hypr/`; the bootstrap adds
that directory and `user/hypr/` to Lua's module path, then loads the shipped
modules in this order:

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

The bootstrap next loads the active theme from
`config/hyprkarl/current/theme/hyprland.lua`, then loads matching optional files
from `user/hypr/` in the same order. User calls therefore win over shipped and
theme values. Missing user files are skipped; syntax, read, and runtime errors
are reported.

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

For personal changes, create only the relevant `user/hypr/*.lua` files. The
files under `defaults/hypr/` are upstream-owned references and should not be
edited for ordinary personalization. See
[Extending Hyprkarl](extending-hyprkarl.md#customize-hyprland).

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
- sources `config/uwsm/env.local` if it exists

`config/uwsm/default` is the user-editable place for:

- `TERMINAL`
- `EDITOR`
- optional screenshot directory override
- optional screen recording directory override

The default terminal and editor commands update this file. Changes here require
a new session.

`config/uwsm/env.local` is for machine-local environment variables such as API
keys and personal settings. It is gitignored and never tracked. `setup-dotfiles.sh`
creates it from `config/uwsm/env.local.example` on first run if it doesn't exist.

## Quickshell Bar

The production bar lives under `config/quickshell/`. Its main editing surfaces
are:

- `defaults/shell.json`
  Shipped bar edge, widget order, and inline widget instances
- `user/shell.json`
  Optional sparse user-owned override for the shipped shell configuration
- `defaults/menu.json`
  Shipped command-menu hierarchy, dynamic providers, search roles, and actions
- `user/menu.json`
  Optional sparse user-owned menu additions and overrides
- `themes/<theme>/quickshell.json`
  Generated theme-specific semantic colors, typography, minimum bar thickness, natural widget
  padding, logical island corners and borders, radii, and
  screen/outer/content spacing, plus menu and OSD appearance

The shell watches both shell JSON paths. Ordinary user objects merge over
the default, arrays replace completely, and explicit widget-ID layout edits are
applied afterward. Deleting the user file returns to the default, while an
invalid live edit keeps the last valid configuration running. Version 1
supports top and bottom bars and built-in widget kinds. See
[Shell Configuration](shell-configuration.md) for the schema and extension
roadmap.

The shell watches the XDG-state `current/theme.json` selector, then reads the
named immutable artifact's `quickshell.json`. Theme switches apply without
restarting the shell.

Hyprland starts it with `hk-shell start`; use `hk-shell status`, `hk-shell
logs`, and `hk-shell stop` to inspect and manage it. A direct `qs -p
config/quickshell` launch remains useful for foreground development.
See `config/quickshell/README.md` for its structure, checks, and interactions.
The audio, network, Bluetooth, battery/power, and clock/calendar
panels share a per-monitor host under `config/quickshell/panels/`; their
feature-specific views and state live under `config/quickshell/features/`.
Network scanning and Bluetooth discovery use feature-owned singletons because
those operations are global to an adapter while panels are per monitor.
Network scanning follows panel activity; Bluetooth discovery begins only from
the panel's explicit scan action. Clock uses one application-wide current-time
singleton while viewed-month navigation remains local to each panel. There is
no separate feature-flyout boundary.

The shell-native command menu creates one full-screen overlay per output and
shows only the requested monitor's instance. `features/menu/MenuState.qml`
owns the watched, validated deep merge, navigation history, checked-state
probes, and short-lived dynamic menu sources; `MenuWindow.qml` owns keyboard
focus, in-process search, dismissal, and rendering. See
[Menu Configuration](menu-configuration.md).

The shell-native OSD uses one application-wide state owner and one
click-through window per output under `features/osd/`. `hk-shell osd` sends
typed volume, audio-output, microphone, display/keyboard brightness, or media
state; the state owner selects the focused monitor and resets one dismissal
timer. `defaults/shell.json` owns its edge, margin, and timeouts, while each
theme's `quickshell.json` owns its size, spacing, radius, indicator size,
progress height, and transition duration.

## Themes

Shipped bundles live under `themes/<theme-name>/`; complete personal themes and
same-name overlays live under `user/themes/<theme-name>/`.

See [Themes](themes.md) for the full theme layout and how
XDG state selects the active bundle; `config/hyprkarl/current/` provides stable
compatibility links for existing consumers.

## Scripts and Commands

Use this rule of thumb:

- put a command in `bin/` if it should be run directly. Subcommands of a dispatcher (e.g. `hk-theme set`) live as their own top-level commands (`hk-theme-set`); the dispatcher just `exec`s them.
- put a sourced helper in `bin/lib/` only if it is shared by more than one command (`docker.sh`, `shell.sh`, `update.sh`).
- put a support script in `scripts/` if it supports something else
