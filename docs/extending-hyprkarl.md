# Extending Hyprkarl

Hyprkarl is extended through user-owned configuration and commands. This page
covers the main extension paths: new commands, new menu actions, new
keybindings, and new theme-aware configuration. Change the checkout only when
you are deliberately changing shipped behavior.

## Choose the Right Place

Use this rule of thumb:

- `bin/`
  Commands meant to be run directly. Dispatcher subcommands also live here as
  top-level `hk-<noun>-<action>` commands.
- `bin/lib/`
  Shared sourced helpers used by more than one `bin/` command. Currently
  `docker.sh` and `update.sh`. Single-use logic stays in the command itself.
- `scripts/`
  Support scripts and backend logic
- `config/`
  Application config and session behavior
- `defaults/`
  Hyprkarl-owned defaults; inspect these to understand behavior, but keep
  personal overrides under `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`
- `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`
  Personal shell and Hyprland configuration that upstream does not replace
- `themes/`
  Shipped theme sources, overrides, and assets
- `theme-generator/`
  Integrated compiler defaults, templates, rendering code, and tests
- `templates/`
  Files copied or rendered by setup and install commands
- `applications/`
  Desktop files exposed under `~/.local/share/applications/`

If a command is something a user would reasonably type, put it in `bin/`. If a
helper would only ever be called from one command, keep it in that command
inline. If it would genuinely be shared by two or more commands, extract it
into the appropriate `bin/lib/*.sh` or `bin/lib/*.py` file. If the thing exists
to support something other than a `hk-*` command, put it under `scripts/`.

## Add a New Command

Typical workflow:

1. Add a new executable in `bin/`.
2. Choose Bash or Python using [Command Script Style](shell-style.md).
3. If the command shares enough logic with other `bin/` commands, extract or
   reuse a helper in `bin/lib/`.

### Adding a Subcommand to an Existing Dispatcher

Dispatchers like `hk-theme`, `hk-pkg`, `hk-fingerprint`, `hk-wallpaper`, and
`hk-update` route to top-level commands named `hk-<noun>-<action>`. To add a
new subcommand:

1. Create the action as a new executable: `bin/hk-<noun>-<new-action>`.
2. Add the action name to the `case` in the dispatcher so it routes to your
   new command.

The action script is callable directly (`hk-theme-set foo`) as well as through
the dispatcher (`hk-theme set foo`).

## Add a Lifecycle Hook

Put personal hook executables under `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hooks/<event>.d/`. The supported
events are `post-boot`, `post-update`, `theme-set`, and `wallpaper-set`.
For example:

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hooks/theme-set.d"
$EDITOR "${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hooks/theme-set.d/10-reload-my-app"
chmod +x "${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hooks/theme-set.d/10-reload-my-app"
```

Hooks are non-hidden executable regular files and run in lexical filename
order, so numeric prefixes make dependencies visible. They inherit the public
action's environment but receive no positional arguments. Read current state
through the normal public commands instead of depending on runner internals.

All hooks for an event are attempted. If any fails, `hk-hook-run` returns
nonzero after reporting the file and status. Theme, wallpaper, and update
commands make clear that their main action already completed before returning
that hook failure; session startup reports a `post-boot` failure by desktop
notification. Missing event directories and non-executable files are ignored.

## Add a Menu Action

The static menu hierarchy is data, not a tree of shell branches. Built-in
entries live in `defaults/menu.json`; personal additions and overrides belong
in `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/menu.json`. Add a stable entry ID, its parent menu, order, label, and
a submenu, command, or direct Quickshell surface action:

```json
{
  "version": 1,
  "entries": {
    "utilities.files": {
      "parent": "utilities",
      "order": 25,
      "icon": "",
      "label": "Files",
      "action": { "type": "command", "command": "thunar" }
    }
  }
}
```

Keep nontrivial interaction in a dedicated `hk-*` command and name that
command in the entry. Use a `surface` action when the destination is another
Quickshell overlay; it changes surfaces in-process and may pass an open-ended
parameter object. A menu may declare a `sourceCommand` for dynamic entries and
opt into in-process search. Dynamic providers should normally use Python data
structures and the standard `json` module; Bash is better reserved for
providers that only print prebuilt JSON. The launcher, calculator, open-with
chooser, and wallpaper thumbnail picker use dedicated Quickshell features
rather than the command-menu JSON shape. See
[Menu Configuration](menu-configuration.md) for the full contract, submenu
example, live-reload behavior, and keyboard controls.

## Customize Hyprland

`config/hypr/hyprland.lua` is a stable bootstrap. Hyprkarl's implementation
lives in `defaults/hypr/`, while personal modules live in `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/` and load
after the shipped configuration, active theme, and generated display layout.
Supported module names, in load order, are:

```text
envs, autostart, monitors, permissions, looknfeel,
animations, gum, windows, input, bindings
```

Create only the modules you need. For example, `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/input.lua` can
override selected input values without copying the shipped input configuration:

```lua
hl.config({
    input = {
        kb_layout = "us,fi",
        sensitivity = 0,
    },
})
```

Calls that define collections remain additive. Personal bindings and window
rules can therefore be added directly, while replacing an existing binding
requires an `hl.unbind()` call first. Always run `Hyprland --verify-config`
before reloading.

Display-panel changes persist through `hk-display` under XDG state. They do
not modify `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/monitors.lua`; any monitor rules you place there load
later and remain authoritative on reload.

## Add a New Keybinding

Hyprland is configured in Lua (see
[configuration-map.md](configuration-map.md#hyprland)). The shipped bindings,
useful as examples, live in:

- `defaults/hypr/bindings/apps.lua` — app launchers
- `defaults/hypr/bindings/media.lua` — hardware media/brightness/volume keys
- `defaults/hypr/bindings/windows.lua` — focus, move, resize, float, fullscreen, close
- `defaults/hypr/bindings/workspaces.lua` — workspace switching, monitor moves, scratchpad
- `defaults/hypr/bindings/system.lua` — menus, notifications, panels, screenshots, power

Put personal bindings in `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/bindings.lua`. The form is
`hl.bind(keys, dispatcher, flags?)`:

```lua
-- Launch a command. Keep a description so it appears in the keybindings menu.
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("my-command"), { description = "Do the thing" })

-- A built-in dispatcher instead of a command.
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Full screen" })
```

Common flags: `{ description = "…" }` (shown in the keybind menu, which reads live
`hyprctl binds`), `locked = true` (works on the lockscreen), `repeating = true`,
`mouse = true`. Dispatchers live under `hl.dsp.*` —
see https://wiki.hypr.land/Configuring/Basics/Dispatchers/.

If the binding needs more than a short command, add a script in `bin/` and bind
to that. After editing, validate with `Hyprland --verify-config`.

## Add a Quickshell Bar Feature

For personal placement or behavior changes, add a sparse `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json`
override. Objects merge recursively, arrays
replace, and `bar.layoutEdits` can target a widget by stable ID without copying
the shipped layout. See [Shell Configuration](shell-configuration.md).

For a personal readout, prefer a `kind: "command"` instance before adding a
built-in QML implementation. Give it a stable ID, an explicit command, and
either a polling interval or persistent stream mode, plus optional static icon,
tooltip, semantic state, and click commands. It may return trimmed text or a
small validated JSON object. Polling launches a process on every tick, so use a
conservative interval to avoid needless CPU wakeups and battery drain; prefer a
stream for frequent updates. The application-wide command registry runs one
provider per ID even when several monitors render the widget. See
[Command widgets](shell-configuration.md#command-widgets) for examples and the
output schema.

The same kind owns static command buttons: omit the provider command and
interval, provide text or an icon plus a click command, and the widget creates
no background timer or process. The shipped main-menu button uses this form.

For a personal widget whose rendering or interaction cannot fit that data
contract, add an explicitly referenced `kind: "qml"` module under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/modules/`. It receives only the documented per-bar context and
can use the existing tooltip and feature-panel surfaces without editing
Hyprkarl-owned QML. See
[User QML widgets](shell-configuration.md#user-qml-widgets).

For an interface that is not owned by one bar widget, explicitly reference one
application-wide QML root through `userRoot.source` in `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json`. It
can create independent or per-output surfaces, consume arbitrary custom values
from `context.theme.document`, and optionally supply reactive notification
positioning for a personal bar. Its direct context also exposes the current
overlay request and methods to open, replace, toggle, or close it. Set
`modules.bar` to `false` when that root replaces the built-in bar, then run
`hk-shell restart`. See
[Application-wide user QML](shell-configuration.md#application-wide-user-qml).

To add a built-in widget kind:

1. Create `config/quickshell/widgets/<kind>.qml` and keep the compact bar
   interaction in that widget.
2. Register the kind in `config/quickshell/config/ShellConfig.qml` so invalid
   configuration is rejected at the public boundary.
3. If it opens a panel, put service-specific state and panel composition under
   `config/quickshell/features/<kind>/` and use the existing per-monitor
   `FeaturePanelHost` rather than creating another popup window.
4. Add required appearance values to
   `theme-generator/defaults/theme.yaml` under the final `shell` object and
   expose only the semantic QML property the component needs. Theme-specific
   sources may derive that final value from any custom token structure.

Add a shared component only when multiple widgets genuinely use the same
interaction or visual structure.

See `config/quickshell/README.md` for current interactions, structure, and
validation commands.

## Add a Theme-Aware Feature

`hk-theme set` compiles a built-in source plus an optional
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/<name>/` overlay into an immutable XDG-state artifact. It
atomically points `current/theme` at that artifact and `current/wallpaper` at
the selection.
The paths under `config/hyprkarl/current/` are fixed compatibility links into
that state tree.

If a feature should vary by theme, read through those paths instead of
hardcoding a specific theme.

When an app has a useful native include mechanism, keep a small tracked
bootstrap in `config/`, load the generated theme and shipped defaults, then
load a real personal sidecar last. When an app cannot merge cleanly, provide a
starting config that `hk-user-migrate` copies once and never replaces. A
stable relative link inside that personal tree may still point at generated
theme data.

Examples:

- Quickshell watches the XDG-state `theme.json` selector and reads the selected
  artifact's `quickshell.json`
- terminal bootstraps import from `current/theme/...` and load their personal
  `local.*` sidecars last
- Hyprland `loadfile`s `current/theme/hyprland.lua` at the end of its config
- `hyprlock` points at `current/wallpaper`

Themes use a typed `theme.yaml` source. The integrated compiler merges its
shared defaults, built-in values, and personal values before resolving Jinja
expressions without coercing numbers or booleans to strings. The shipped
`metrics`, `motion`, and `typography` groups are conventions, not a schema.
Authors can define their own vocabulary as long as consumer-facing values such
as the final `shell` object reference it. See [Themes](themes.md).

## Exposing New Config Files

If you edit an existing non-ignored tracked entry point, its live symlink is
already present. If you edit one of the ignored application seed files, that
changes future installs only; edit the corresponding real file under
`~/.config/` to change this machine.

If you add a new file or directory under `config/` or `applications/`, run:

```bash
hk-update dotfiles
```

This re-stows the tracked entry points, picks up new non-ignored files, and
removes stale Hyprkarl links. Add a new seed migration deliberately when a new
application should receive a real starting file; do not rely on Stow for it.
