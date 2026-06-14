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

## Add a New Keybinding

Hyprland is configured in Lua (see
[configuration-map.md](configuration-map.md#hyprland)). Bindings live in:

- `config/hypr/bindings/apps.lua` — app launchers
- `config/hypr/bindings/media.lua` — hardware media/brightness/volume keys
- `config/hypr/bindings/windows.lua` — focus, move, resize, float, fullscreen, close
- `config/hypr/bindings/workspaces.lua` — workspace switching, monitor moves, scratchpad
- `config/hypr/bindings/system.lua` — menus, notifications, panels, screenshots, power

Put the binding in the file that matches its purpose. The form is
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

## Add an AGS Bar Feature

The AGS bar has two casual editing surfaces and one advanced one:

- `config/ags/bar/config/layout.config.ts`: add widget IDs to `start`, `center`,
  or `end`.
- `config/ags/bar/config/widgets.config.ts`: add a widget definition keyed by ID;
  `kind` picks the implementation.
- `themes/<theme>/bar.scss`: add styling tokens. New styling knobs that affect
  all themes belong in every `themes/*/bar.scss`.

To add a new widget kind, create a folder under `config/ags/bar/widgets/<name>/`
with:

- `spec.tsx`: `createWidgetSpec` call with `kind`, `defaults`, `schema`, and
  `render`.
- `<Name>Widget.tsx`: top-level view component.
- `normalize.ts`: field normalizers used as `schema` values (if needed).

Register the new kind in `config/ags/bar/widgets/catalog.ts`.

To control the bar at runtime without editing config:

```bash
hk-ags autohide on|off|toggle
hk-ags exclusive on|off|toggle
hk-ags show|hide|toggle
hk-ags status
```

See `config/ags/bar/README.md` for the full widget reference and styling guide.

## Add a Theme-Aware Feature

Hyprkarl switches themes by pointing `config/hyprkarl/current/theme` at a theme
directory and `config/hyprkarl/current/wallpaper` at the selected wallpaper.

If a feature should vary by theme, read through those paths instead of
hardcoding a specific theme.

When an app can import another file, keep its main config in `config/` and
import from the active theme. When it cannot, symlink the full config file from
the active theme into place. Use relative symlinks.

Examples:

- the AGS bar symlinks `theme.scss` to `current/theme/bar.scss`
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
