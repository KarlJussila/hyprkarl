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
  User-owned Hyprkarl configuration, QML, themes, and hooks
- `packages/`
  Package lists read by `setup-packages.sh` and `hk-update packages`
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

`config/hyprkarl/update/` holds the last-applied commit per update category:

- `config/hyprkarl/update/dotfiles.commit`
- `config/hyprkarl/update/packages.commit`
- `config/hyprkarl/update/system.commit`

These files are machine-local and gitignored. They are written by `hk-update`
and the setup scripts. Delete one to force `hk-update` to re-run that category
regardless of whether anything changed.

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

`hk-display` is the only writer. These are machine state, not personal editing
surfaces; use `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/monitors.lua` for explicit authored rules.

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
| Hypridle, Hyprlock, Hyprpaper, Hyprsunset | `~/.config/hypr/hypr*.conf` | Complete starting files; Hyprlock continues to source active theme values until the user changes it | Restart the affected service | Never |
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

## Quickshell Bar

The production bar lives under `config/quickshell/`. Its main editing surfaces
are:

- `defaults/shell.json`
  Shipped bar edge, widget order, and inline widget instances
- `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json`
  Optional sparse user-owned override for the shipped shell configuration
- `defaults/menu.json`
  Shipped command-menu hierarchy, dynamic providers, search roles, and actions
- `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/menu.json`
  Optional sparse user-owned menu additions and overrides
- `${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/themes/<generation>/quickshell.json`
  Generated semantic colors, typography, minimum bar thickness, natural
  widget padding, logical island corners and borders, radii,
  screen/outer/content spacing, and menu, OSD, notification, and polkit
  appearance. The shell reaches it through the active selector.

The shell watches both shell JSON paths. Ordinary user objects merge over
the default, arrays replace completely, and explicit widget-ID layout edits are
applied afterward. Deleting the user file returns to the default, while an
invalid live edit keeps the last valid configuration running. Version 1
supports top and bottom bars plus built-in, command, and explicitly referenced
user-QML widget kinds. The top-level `modules` object independently selects
the bar, panels, notifications, OSD, polkit, menu, applications, calculator,
and wallpaper runtimes. Module changes latch until `hk-shell restart`; ordinary
shell JSON values still reload live. Personal per-bar modules live below
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/modules/`, receive one narrow context per bar/output, and are
not discovered as plugins. An optional `userRoot.source` names one
application-wide QML composition root below `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/`; it may create
independent surfaces, receive direct overlay controls, and provide reactive
notification positioning for a custom bar. Static
command widgets, including the main-menu button, have no provider runtime.
Configured providers are application-wide rather than duplicated per monitor.
Poll mode starts one process per tick, while stream mode holds one
newline-producing process for frequent updates. See
[Shell Configuration](shell-configuration.md) for the schema and extension
roadmap.

The shell watches the XDG-state `current/theme.json` selector, then reads the
named immutable artifact's `quickshell.json`. Theme switches apply without
restarting the shell.

Hyprland starts it with `hk-shell start`; use `hk-shell status`, `hk-shell
logs`, and `hk-shell stop` to inspect and manage it. A direct `qs -p
config/quickshell` launch remains useful for foreground development.
See `config/quickshell/README.md` for its structure, checks, and interactions.
The display, audio, network, Bluetooth, battery/power, and clock/calendar
panels share a per-monitor host under `config/quickshell/panels/`; their
feature-specific views and state live under `config/quickshell/features/`.
The display view delegates discovery, live changes, and persistence to
`hk-display` rather than owning a second QML state store.
Network scanning and Bluetooth discovery use feature-owned singletons because
those operations are global to an adapter while panels are per monitor.
Network scanning follows panel activity; Bluetooth discovery begins only from
the panel's explicit scan action. Clock uses one application-wide current-time
singleton while viewed-month navigation remains local to each panel. There is
no separate feature-flyout boundary.

`config/quickshell/features/polkit/PolkitState.qml` owns the one session
polkit agent. `PolkitWindow.qml` supplies the per-output modal presentation,
with only the output chosen at request start becoming visible and focused.
This surface is independent of the feature-panel host and has no public IPC
command; polkit's D-Bus request is its entry point.

`config/quickshell/features/command/` owns the corresponding application-wide
command-widget registry and provider lifetime. The public poll/stream contract
is documented in `docs/shell-configuration.md`.

The shell creates the command menu and its dedicated launcher/open-with,
calculator, and wallpaper surfaces once per output. One application-wide
`features/overlay/OverlayState.qml` makes them mutually exclusive and routes
the active surface to the focused output. The shared frame and scroll
interaction also live under `features/overlay/`; each feature directory owns
its domain-specific state and presentation. `features/menu/MenuState.qml`
owns the watched, validated deep merge, navigation history, checked-state
probes, and short-lived dynamic menu sources. See [Menu
Configuration](menu-configuration.md).

The shell-native OSD uses one application-wide state owner and one
click-through window per output under `features/osd/`. `hk-shell osd` sends
typed volume, audio-output, microphone, display/keyboard brightness, or media
state; the state owner selects the focused monitor and resets one dismissal
timer. `defaults/shell.json` owns its edge, margin, and timeouts, while each
theme's `quickshell.json` owns its size, spacing, radius, indicator size,
progress height, and transition duration.

The shell-native notification service uses one application-wide server and
one non-focusable toast stack per output under `features/notifications/`.
New notifications route to the focused output. `NotificationState.qml` owns
tracking, timeout resolution, synchronous replacement, filtering, silence
mode, the one-item visual restore snapshot, and the public IPC target;
`NotificationWindow.qml` and `NotificationToast.qml` own presentation and
interaction. `defaults/shell.json` owns placement, timing, limits, application
filters, compact applications, and icon descriptors. `component` descriptors
load shipped drawings or files under `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/icons/` through one
shared interface. `ScreenSurfaces.qml` supplies the built-in bar's reactive
position by default; a user root may replace that
per-output position without replacing notification presentation. Theme JSON
owns surface color and geometry. Mako
has no runtime or theme path.

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
