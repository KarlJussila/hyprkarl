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
  Upstream-owned shell data, Hyprland behavior, and XDG defaults
  (`config/`, `share/`) that a user's own file replaces
- `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`
  User-owned Hyprland configuration, themes, and hooks
- `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/settings/`
  Personal `shell.json` and `menu.json`
- `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/custom/`
  Personal QML composition roots, widgets, and icon drawings
- `packages/`
  Package lists read by `hk-update packages`
- `migrations/`
  Numbered one-time changes that `hk-update apply` runs once per machine
- `themes/`
  Shipped theme sources, overrides, wallpapers, icons, and previews
- `theme-generator/`
  Integrated typed-theme compiler, shared defaults, templates, tests, and
  vendored Colloid source
- `scripts/`
  Support scripts and backend logic
- `docs/`
  Documentation for using and editing Hyprkarl
- `templates/`
  Files copied or rendered by setup and install commands

## Stateful Runtime Files

Theme and wallpaper state lives under
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/`. `current/theme` links to
the active build under the state directory's `themes/`, and `current/wallpaper`
links to the selected wallpaper inside it. Every consumer of the active theme,
including shipped and starting application configs, points at `current/theme`.
If theme or wallpaper behavior looks wrong, check this directory first.

Update records live under
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/update/`:

- `pending-source.revision`
  Exact fetched commit confirmed by `hk-update sync` but not yet applied
- `configuration.revision`
  Checkout revision whose configuration last completed the apply workflow
- `packages.json`
  Package lists as last applied, and removal changes already reviewed
- `migrations/<migration-id>`
  One file per migration that has run on this machine

These files describe this installation. They are not configuration or generated
source.

Personal executable lifecycle hooks live under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hooks/<event>.d/`. Hyprkarl supports `login`, `post-update`,
`theme-set`, and `wallpaper-set`; files run in lexical order. See
[Extending Hyprkarl](extending-hyprkarl.md#add-a-lifecycle-hook).

The active bundle's `gtk-theme/` payload is materialized separately as a
managed real-file copy at `~/.local/share/themes/hyprkarl/`. Theme switches
replace that copy; GTK does not consume it through the runtime symlink tree.

Display-panel layout state lives separately under
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/display/`:

- `layout.json`
  The backend's machine-readable enabled state and active mode, position,
  scale, and transform for known outputs
- `monitors.lua`
  The generated Hyprland rules loaded on configuration reload
- `pending.json`
  A temporary unconfirmed layout with its prior live and persistent state;
  removed when the ten-second trial is confirmed or reverted

`hk-display` is the only writer. These are machine state, not personal editing
surfaces; use the shell arranger for active-output positioning and rotation and
`~/.config/hypr/hyprland.local.lua` for explicit monitor rules.

The shell calculator keeps its five most recent expression/result pairs in
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/calculator-history.json`.
This is disposable interaction history, not an editing surface.

## Hyprland

Hyprland is configured in **Lua** (`hyprland.lua`), required since Hyprland 0.55
(hyprlang `.conf` is deprecated). `config/hypr/hyprland.lua` is the stable live
bootstrap. Shipped behavior lives under `defaults/hypr/`; the bootstrap adds
that directory, then `~/.config/hypr/`, to Lua's module path and loads the
shipped modules in this order:

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
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/current/theme/hyprland.lua`
(theme colors), the generated
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/display/monitors.lua`, then
`~/.config/hypr/hyprland.local.lua`. The generated layout wins over shipped monitor defaults, and your file
wins over everything. A missing generated or personal file is skipped;
syntax, read, and runtime errors are reported.

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

Personal changes go in `~/.config/hypr/hyprland.local.lua`. The files under `defaults/hypr/` are
upstream-owned references and should not be edited for ordinary
personalization. See
[Extending Hyprkarl](extending-hyprkarl.md#customize-hyprland).

For Hyprland syntax and option reference, see the official Hyprland docs:
[Configuring](https://wiki.hypr.land/Configuring/) and
[Variables](https://wiki.hypr.land/Configuring/Variables/).

## UWSM and Session Defaults

`config/uwsm/env` sets the session-wide environment:

- exports `HYPRKARL_PATH`
- adds `~/.local/bin` and Hyprkarl's `bin/` to `PATH`, in that order, so a
  personal command can replace an `hk-*` command of the same name
- puts `defaults/config/` first in `XDG_CONFIG_DIRS` and `defaults/share/`
  first in `XDG_DATA_DIRS`, after Flatpak's entries
- sets `EDITOR=nvim` and `QT_QPA_PLATFORMTHEME`
- points `WIFITUI_THEME` at the active theme
- sources `~/.config/uwsm/default`, which `hk-default-editor` writes, if it
  exists
- sources `~/.config/uwsm/env.local` if it exists

`~/.config/uwsm/env.local` is for machine-local environment variables such as
API keys, screenshot and recording folders, and any variable above you want to
change. Hyprkarl creates it once from an example. Changes need a new session.

## Application Configuration

Hyprkarl configures applications in one of four ways, chosen per application,
so its defaults keep updating wherever the application allows it.

**Shipped file plus a personal file.** Hyprkarl links its config into
`~/.config`; that file loads the active theme and Hyprkarl's settings, then a
personal file that Hyprkarl creates once and never replaces.

| Application | Personal file | Apply changes |
|---|---|---|
| Alacritty | `~/.config/alacritty/local.toml` | Automatic, or a new window |
| foot | `~/.config/foot/local.ini` | New window |
| Ghostty | `~/.config/ghostty/local.conf` | Reload Ghostty's config or open a new window |
| Kitty | `~/.config/kitty/local.conf` | `hk-terminal-reload` or a new window |
| Hypridle | `~/.config/hypr/hypridle.local.conf`; its timeouts and actions are variables you can redefine | Restart `hypridle.service` |
| Hyprpaper, Hyprsunset | `~/.config/hypr/hyprpaper.local.conf`, `hyprsunset.local.conf` | Restart the service |
| Hyprland | `~/.config/hypr/hyprland.local.lua`; see [Hyprland](#hyprland) | Automatic reload |

**Hyprkarl defaults with your own file winning.** These programs search
`XDG_CONFIG_DIRS` or `XDG_DATA_DIRS` after your own directories, so Hyprkarl's
file applies until you create one at the same path under `~/.config` or
`~/.local/share`. Yours then replaces it whole.

| Default | Purpose | Your override |
|---|---|---|
| `defaults/config/xdg-desktop-portal/portals.conf` | Portal backends, including the terminal file chooser | `~/.config/xdg-desktop-portal/portals.conf` |
| `defaults/config/xdg-terminals.list` | Terminal for `xdg-terminal-exec`; `hk-default-terminal` writes yours | `~/.config/xdg-terminals.list` |
| `defaults/share/applications/` | Terminal arguments for Alacritty and foot; Nautilus without D-Bus activation, which opened two windows | A desktop file of the same name in `~/.local/share/applications/` |

The launcher hides a few rarely used applications through
`applications.hidden` in `shell.json`.

**Owned by the theme.** These follow the active theme. Change them through a
[personal theme](themes.md), not in place.

| Application | How |
|---|---|
| GTK 3/4 | Linked `gtk.css` imports the theme copied to `~/.local/share/themes/hyprkarl/`; linked `settings.ini` selects it |
| Qt5ct / Qt6ct | `hk-theme set` writes `qt5ct.conf` and `qt6ct.conf` with the theme's palette, fonts, and icons; changes made in the qt6ct window last until the next theme switch |
| Hyprtoolkit | Linked `~/.config/hypr/hyprtoolkit.conf` |
| Cursor | `hk-theme set` writes `~/.local/share/icons/default/index.theme` |
| Desktop file chooser | Linked `xdg-desktop-portal-termfilechooser/config`, which opens Yazi in Hyprkarl's terminal |

**Starting configs.** Where an application has no way to load Hyprkarl's
defaults next to a personal file, `hk-config-seed` (run by every
`hk-update apply`) copies a complete starting config when you have none of its
files. It never overwrites a file, and the copy is yours from then on; updates
do not change it. Delete every file of one to get Hyprkarl's current version
on the next update.

| Application | Why it is copied | Theme |
|---|---|---|
| Btop (`~/.config/btop/`) | Btop rewrites its own config | Linked active theme; theme switches call `hk-btop-reload` |
| Fastfetch (`~/.config/fastfetch/`) | No includes | None |
| Neovim (`~/.config/nvim/`) | A Neovim config is personal code | Linked colorscheme |
| Yazi (`~/.config/yazi/`) | No includes for a second config | Linked flavor |

## Quickshell

The project lives under `config/quickshell/`. Its
[contributor map](../config/quickshell/README.md) explains `desktop/`, `bar/`,
`modules/`, `ui/`, and `config/`. `shell.qml` launches the desktop; `lock.qml`
launches its lock module in a separate process so bar restarts preserve locking.

| Personal file | Controls | Apply |
| --- | --- | --- |
| `~/.config/quickshell/settings/shell.json` | Module switches, bar layout, notification/OSD behavior, and the personal QML root | Ordinary settings reload live; module switches require `hk-shell restart` |
| `~/.config/quickshell/settings/menu.json` | Menu entries, providers, and actions | Reloads live |
| `~/.config/quickshell/custom/` | Explicitly referenced QML roots, widgets under `modules/`, and notification drawings under `icons/` | `hk-shell restart` |
| `~/.config/hyprkarl/themes/<name>/` | Appearance, including `shell.lock` | `hk-theme set <name>` |

`defaults/shell.json` and `defaults/menu.json` supply shipped behavior. Personal
JSON objects merge recursively over them; arrays replace completely, so to
change a bar layout section you copy and own it. A personal file that does not
parse leaves the shipped defaults running until you fix it.

The nine `modules` switches select the bar, panels, notifications, OSD, polkit,
menu, applications, calculator, and wallpaper. Disabled modules do not keep
services or polling processes running. A personal `userRoot.source` can replace
the bar or add independent interfaces, using `import ui.modal` for shared modal
windows. Locking runs on demand through `hk-lock`; Hypridle locks before any
suspend.

Use `hk-shell start`, `stop`, `restart`, `status`, and `logs` to manage the
desktop. The shell reloads the theme when `hk-theme set` switches builds.

See [shell configuration](shell-configuration.md),
[bar customization](customizing-bar.md), [menu configuration](menu-configuration.md),
and [authentication](authentication-surfaces.md) for the editing contracts.

## Themes

Shipped source lives under `themes/<theme-name>/`. New personal themes and
same-name sparse overlays live under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/<theme-name>/`. A personal-only
theme requires `theme.yaml`; an overlay for a built-in may omit it.

The integrated compiler under `theme-generator/` merges defaults, built-in
values, and personal values before expression resolution. It then applies
compiler templates, built-in overrides, and personal overrides in order;
assets use the same precedence. `hk-theme set` validates a complete bundle and
installs it under XDG state. Neither source directory contains generated
consumer output.

See [Themes](themes.md) for the full theme layout and how
XDG state selects the active bundle.

## Scripts and Commands

Use this rule of thumb:

- put a command in `bin/` if it should be run directly. Subcommands of a dispatcher (e.g. `hk-theme set`) live as their own top-level commands (`hk-theme-set`); the dispatcher just `exec`s them.
- put a sourced helper in `bin/lib/` only if it is shared by more than one command (`docker.sh`, `shell.sh`, `update.sh`).
- put a support script in `scripts/` if it supports something else
