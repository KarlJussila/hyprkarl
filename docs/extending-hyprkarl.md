# Extending Hyprkarl

Hyprkarl is meant to be extended by editing the repo directly. This page covers
the main extension paths: new commands, new menu actions, new keybindings, and
new theme-aware configuration.

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
  personal overrides under `user/`
- `user/`
  Personal shell and Hyprland configuration that upstream does not replace
- `themes/`
  Theme assets and per-theme overrides
- `templates/`
  Files copied or rendered by setup and install commands
- `applications/`
  Desktop files exposed under `~/.local/share/applications/`

If a command is something a user would reasonably type, put it in `bin/`. If a
helper would only ever be called from one command, keep it in that command
inline. If it would genuinely be shared by two or more commands, extract it as
a function into the appropriate `bin/lib/*.sh` file (or create a new one). If
the thing exists to support something other than a `hk-*` command, put it
under `scripts/`.

## Add a New Shell Command

Typical workflow:

1. Add a new executable in `bin/`.
2. Follow the repo shell conventions in [Shell Style](shell-style.md).
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

## Add a Menu Action

Most menu files live in `bin/hk-menu*`. To add a new action:

1. Find the right menu.
2. Add a label constant and a new case branch.

If you want to add a new menu, the easiest approach is usually to copy an
existing `hk-menu-*` script and edit the labels, commands, and prompt
text.

Minimal example:

Leaf menu (no submenus):

```bash
#!/bin/bash

ROFI_THEME="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/custom-menu.rasi"

FIRST="First action"
SECOND="Second action"

CHOICE=$(printf '%s\n' "$FIRST" "$SECOND" \
    | rofi -dmenu \
           -p "" \
           -no-custom \
           -mesg "Example" \
           -theme "$ROFI_THEME")

case "$CHOICE" in
    "$FIRST")  first-command ;;
    "$SECOND") second-command ;;
    "")        exit 1 ;;
esac

exit 0
```

Dismissing exits 1 so a parent can detect it. Because these scripts run without
`set -e`, a failed action branch still falls through to `exit 0` — only the
explicit `exit 1` on dismiss signals the parent.

Parent menu (has submenus) adds `relaunch_menu` and uses `|| relaunch_menu`
on submenu calls:

```bash
relaunch_menu() { exec "$0"; }

CHOICE=$(printf '%s\n' "$SUBMENU" "$ACTION" \
    | rofi -dmenu \
           -p "" \
           -no-custom \
           -mesg "Example" \
           -theme "$ROFI_THEME")

case "$CHOICE" in
    "$SUBMENU") hk-menu-sub || relaunch_menu ;;  # dismissed → re-show this menu
    "$ACTION")  do-thing ;;
    "")         exit 1 ;;
esac

exit 0
```

When a submenu exits 1 (dismissed), `|| relaunch_menu` execs the current script
in-place, re-showing this menu. When an action completes, execution falls
through to `exit 0`. Dismissing this menu exits 1 so its own parent can detect
it. See `bin/hk-menu` for the canonical pattern.

## Customize Hyprland

`config/hypr/hyprland.lua` is a stable bootstrap. Hyprkarl's implementation
lives in `defaults/hypr/`, while personal modules live in `user/hypr/` and load
after both the shipped configuration and active theme. Supported module names,
in load order, are:

```text
envs, autostart, monitors, permissions, looknfeel,
animations, gum, windows, input, bindings
```

Create only the modules you need. For example, `user/hypr/input.lua` can
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

## Add a New Keybinding

Hyprland is configured in Lua (see
[configuration-map.md](configuration-map.md#hyprland)). The shipped bindings,
useful as examples, live in:

- `defaults/hypr/bindings/apps.lua` — app launchers
- `defaults/hypr/bindings/media.lua` — hardware media/brightness/volume keys
- `defaults/hypr/bindings/windows.lua` — focus, move, resize, float, fullscreen, close
- `defaults/hypr/bindings/workspaces.lua` — workspace switching, monitor moves, scratchpad
- `defaults/hypr/bindings/system.lua` — menus, notifications, panels, screenshots, power

Put personal bindings in `user/hypr/bindings.lua`. The form is
`hl.bind(keys, dispatcher, flags?)`:

```lua
-- Launch a command. Keep a description so it shows in hk-menu-keybindings.
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

For personal placement or behavior changes, add a sparse `user/shell.json`
override. Objects merge recursively, arrays
replace, and `bar.layoutEdits` can target a widget by stable ID without copying
the shipped layout. See [Shell Configuration](shell-configuration.md).

To add a built-in widget kind:

1. Create `config/quickshell/widgets/<kind>.qml` and keep the compact bar
   interaction in that widget.
2. Register the kind in `config/quickshell/config/ShellConfig.qml` so invalid
   configuration is rejected at the public boundary.
3. If it opens a panel, put service-specific state and panel composition under
   `config/quickshell/features/<kind>/` and use the existing per-monitor
   `FeaturePanelHost` rather than creating another popup window.
4. Add every required appearance token to each
   `themes/<theme>/quickshell.json`.

Add a shared component only when multiple widgets genuinely use the same
interaction or visual structure. The command-widget and user-QML extension
lanes described in the shell configuration contract are planned but not yet
implemented.

See `config/quickshell/README.md` for current interactions, structure, and
validation commands.

## Add a Theme-Aware Feature

Hyprkarl switches themes by pointing `config/hyprkarl/current/theme` at a theme
directory and `config/hyprkarl/current/wallpaper` at the selected wallpaper.

If a feature should vary by theme, read through those paths instead of
hardcoding a specific theme.

When an app can import another file, keep its main config in `config/` and
import from the active theme. When it cannot, symlink the full config file from
the active theme into place. Use relative symlinks.

Examples:

- Quickshell watches `theme.name` and reads the selected
  `themes/<name>/quickshell.json` directly
- terminal configs import from `current/theme/...`
- Hyprland `loadfile`s `current/theme/hyprland.lua` at the end of its config
- `hyprlock` points at `current/wallpaper`

## Exposing New Config Files

If you only edit an existing tracked file, the symlink already exists and there
is nothing else to do.

If you add a new file or directory under `config/` or `applications/`, run:

```bash
hk-update dotfiles
```

This re-stows the entire config package, picks up any new files, and removes
symlinks for files that were deleted.
