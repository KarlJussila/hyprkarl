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
- `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`
  User-owned Hyprland configuration, themes, and hooks
- `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/settings/`
  Personal `shell.json` and `menu.json`
- `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/custom/`
  Personal QML composition roots, widgets, and icon drawings
- `packages/`
  Package lists read by `setup-packages.sh` and `hk-update packages`
- `system/migrations/`
  Ordered one-time system changes run by setup and `hk-update system`
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
- `applications/`
  Desktop files exposed under `~/.local/share/applications/`

## Stateful Runtime Files

Authoritative theme and wallpaper state lives under
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/`. `current/theme` selects an
immutable generated bundle under the state directory's `themes/`;
`current/theme.name`,
`current/theme.json`, and `current/wallpaper` carry the small selectors.

`config/hyprkarl/current/` contains fixed compatibility links to that state:

- `config/hyprkarl/current/theme`
  Link to the XDG-state active-theme link
- `config/hyprkarl/current/theme.name`
  Link to the XDG-state theme name
- `config/hyprkarl/current/wallpaper`
  Link to the XDG-state wallpaper

If theme or wallpaper behavior looks wrong, check this directory first.

Update records live under
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/update/`:

- `pending-source.revision`
  Exact fetched commit confirmed by `hk-update sync` but not yet applied
- `configuration.revision`
  Checkout revision whose configuration last completed the apply workflow
- `packages.json`
  Atomic snapshots of applied requirements and removal changes already reviewed
- `restart-shell-after-apply`
  Temporary restart intent retained when a source transition leaves Quickshell
  stopped until configuration application succeeds
- `system-migrations/<migration-id>`
  Completion markers written one at a time after successful system migrations

These files describe this installation. They are not configuration or generated
source. Legacy commit markers under `config/hyprkarl/update/` are imported into
this state during the first run of the corresponding new command.

Personal executable lifecycle hooks live under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hooks/<event>.d/`. Hyprkarl supports `post-boot`, `post-update`,
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
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/monitors.lua` for explicit authored rules.

The shell calculator keeps its five most recent expression/result pairs in
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/calculator-history.json`.
This is disposable interaction history, not an editing surface.

## Hyprland

Hyprland is configured in **Lua** (`hyprland.lua`), required since Hyprland 0.55
(hyprlang `.conf` is deprecated). `config/hypr/hyprland.lua` is the stable live
bootstrap. Shipped behavior lives under `defaults/hypr/`; the bootstrap adds
that directory and `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/` to Lua's module path, then loads the shipped
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
`config/hyprkarl/current/theme/hyprland.lua`, the generated
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/display/monitors.lua`, then
matching optional files from `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/` in the same order. The generated
layout wins over shipped monitor defaults, while user calls win over shipped,
theme, and generated values. Missing generated and user files are skipped;
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

For personal changes, create only the relevant `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/*.lua` files. The
files under `defaults/hypr/` are upstream-owned references and should not be
edited for ordinary personalization. See
[Extending Hyprkarl](extending-hyprkarl.md#customize-hyprland).

For Hyprland syntax and option reference, see the official Hyprland docs:
[Configuring](https://wiki.hypr.land/Configuring/) and
[Variables](https://wiki.hypr.land/Configuring/Variables/).

## UWSM and Session Defaults

`config/uwsm/env` sets the session-wide environment:

- exports `HYPRKARL_PATH`
- adds `~/.local/bin` and Hyprkarl's `bin/` to `PATH`
- extends `XDG_DATA_DIRS` for Flatpak desktop entries
- points `WIFITUI_THEME` at the active theme
- sets `QT_QPA_PLATFORMTHEME`
- sources `~/.config/uwsm/default`
- sources `~/.config/uwsm/env.local` if it exists

`~/.config/uwsm/default` is the user-editable place for:

- `TERMINAL`
- `EDITOR`
- optional screenshot directory override
- optional screen recording directory override

The default terminal and editor commands update this file. Changes here require
a new session.

`~/.config/uwsm/env.local` is for machine-local environment variables such as API
keys and personal settings. It is a real user-owned file. `hk-user-migrate`
migrates an old checkout copy or creates it from a shipped example when absent.

## Application Configuration

`hk-user-migrate` converts the old application links and creates missing
starting configs once. Completion is recorded at
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/migrations/seeded-application-config-v1`.
After that marker exists, Hyprkarl does not replace or recreate these files.
Deleting one is a valid way to return that application to its own defaults.
If a terminal already has a real primary config, migration moves it to the
terminal's personal sidecar before Stow installs the small bootstrap. Existing
application trees with personal config are otherwise left intact rather than
being filled with Hyprkarl defaults.

| Application | Personal editing path | How Hyprkarl participates | Apply changes | Replaced on update |
|---|---|---|---|---|
| Alacritty | `~/.config/alacritty/local.toml` | Tracked `alacritty.toml` imports the generated theme, shipped terminal defaults, then this file | Automatic config reload or a new window | Bootstrap and shipped defaults only |
| foot | `~/.config/foot/local.ini` | Tracked `foot.ini` includes the generated theme, shipped defaults, then this file | New window | Bootstrap only |
| Ghostty | `~/.config/ghostty/local.conf` | Tracked `config.ghostty` loads the generated theme and then this optional file | Reload Ghostty's config or open a new window | Bootstrap only |
| Kitty | `~/.config/kitty/local.conf` | Tracked `kitty.conf` includes the generated theme and then this file | `hk-terminal-reload` or a new window | Bootstrap only |
| Btop | `~/.config/btop/` | Complete starting config with a stable active-theme link | Restart Btop; theme switches call `hk-btop-reload` | Never |
| Fastfetch | `~/.config/fastfetch/` | Complete starting config and logo | Next run | Never |
| Fish | `~/.config/fish/` | Complete starting config; Fish also loads its ordinary `conf.d/` files | New shell or source the changed file | Never |
| GTK 3/4 | `~/.config/gtk-3.0/` and `~/.config/gtk-4.0/` | Personal `gtk.css` imports `hyprkarl.css`, which reads the materialized active GTK theme; `settings.ini` remains personal | Restart affected applications | Personal files never; `~/.local/share/themes/hyprkarl/` is regenerated |
| Hypridle, Hyprpaper, Hyprsunset | `~/.config/hypr/hypr*.conf` | Complete starting files | Restart the affected service | Never |
| Hyprtoolkit | Theme source under `~/.config/hyprkarl/themes/` | Stable tracked link to the generated active theme | `hk-theme set <name>` | Link is managed; generated target is replaced |
| Neovim | `~/.config/nvim/` | Complete starting tree with stable theme links | Restart or reload Neovim | Never |
| Qt5ct / Qt6ct | `~/.config/qt5ct/` and `~/.config/qt6ct/` | Personal Qt settings with stable generated palette links | Restart affected applications | Never |
| Desktop portals | `~/.config/xdg-desktop-portal/` and `~/.config/xdg-desktop-portal-termfilechooser/` | Complete starting configs | Restart the portal services or begin a new session | Never |
| Terminal preference | `~/.config/xdg-terminals.list` | Complete starting file used by `xdg-terminal-exec` | Next terminal launch | Never |
| Yazi | `~/.config/yazi/` | Complete starting tree with plugins and a stable theme flavor link | Next Yazi launch | Never |

The corresponding ignored paths under `config/` are shipped seed material,
not the live personal copy. Editing one changes future first-run defaults, not
the current user's configuration. A full replacement is always possible by
changing or removing the personal files; the documented paths are a convenient
layout, not a restriction.

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
windows. Locking runs on demand through `hk-lock`; `hk-suspend` waits for secure
locking before suspending.

`hk-user-migrate` moves old Quickshell personal files from `~/.config/hyprkarl/`
into `quickshell/settings/` and `quickshell/custom/`. Conflicting copies are
preserved and reported. It also seeds native PAM files once without overwriting
existing policies.

Use `hk-shell start`, `stop`, `restart`, `status`, and `logs` to manage the
desktop. The active immutable theme bundle reloads through the XDG-state
`current/theme.json` selector.

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
XDG state selects the active bundle; `config/hyprkarl/current/` provides stable
compatibility links for existing consumers.

## Scripts and Commands

Use this rule of thumb:

- put a command in `bin/` if it should be run directly. Subcommands of a dispatcher (e.g. `hk-theme set`) live as their own top-level commands (`hk-theme-set`); the dispatcher just `exec`s them.
- put a sourced helper in `bin/lib/` only if it is shared by more than one command (`docker.sh`, `shell.sh`, `update.sh`).
- put a support script in `scripts/` if it supports something else
