# Extending Hyprkarl

Hyprkarl is meant to be extended by editing the repo directly. This page covers
the main extension paths: new commands, new menu actions, new keybindings, and
new theme-aware configuration.

## Choose the Right Place

Use this rule of thumb:

- `bin/`
  Commands meant to be run directly
- `bin/lib/`
  Internal shell helpers for `bin/`, kept as `*.sh` files
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

If a command is something a user would reasonably type, put it in `bin/`. If it
exists to support another `bin/` command, put it in `bin/lib/`. If it exists to
support something else, put it under `scripts/`.

## Add a New Shell Command

Typical workflow:

1. Add a new executable in `bin/`.
2. Follow the repo shell conventions in [Shell Style](shell-style.md).
3. If the command shares enough logic with other `bin/` commands, extract or
   reuse a helper in `bin/lib/`.

## Add a Menu Action

Most menu files live in `bin/hk-menu*`. To add a new action:

1. Find the right menu.
2. Add a label constant and a new case branch.

If you want to add a new menu, the easiest approach is usually to copy an
existing `hk-menu-*` script and edit the labels, commands, and prompt
text.

Minimal example:

```bash
#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/shell.sh"
ROFI_THEME="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/custom-menu.rasi"

BACK=()
if [[ "${1:-}" == "--back" ]]; then
  shift; BACK=("$@")
fi
SELF=("$(basename "$0")")
[[ -n "${BACK[*]}" ]] && SELF+=(--back "${BACK[@]}")

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
    "")        (( ${#BACK[@]} )) && "${BACK[@]}" ;;
esac
```

## Add a New Keybinding

Hyprland bindings live in:

- `config/hypr/bindings/apps.conf`
- `config/hypr/bindings/media.conf`
- `config/hypr/bindings/tiling.conf`
- `config/hypr/bindings/utilities.conf`

Put the binding in the file that matches its purpose.

If the binding needs more than a short command, add a script in `bin/` and bind
to that.

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
