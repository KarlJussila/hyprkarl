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

hyprkarl_parse_back_args "$@"

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
    "")        hyprkarl_run_back "${HYPRKARL_BACK_ARGS[@]}" ;;
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

## Add a Waybar Feature

Waybar config is split between shared config, support scripts, and shared
styling:

1. Put module config in `config/waybar/config.jsonc`.
2. Put support scripts under `scripts/waybar/`.
3. Put shared styling in `config/waybar/style.css`.

See [Customizing Waybar](customizing-waybar.md) for the Waybar configuration
guidelines.

## Add a Theme-Aware Feature

Hyprkarl switches themes by pointing `config/hyprkarl/current/theme` at a theme
directory and `config/hyprkarl/current/wallpaper` at the selected wallpaper.

If a feature should vary by theme, read through those paths instead of
hardcoding a specific theme.

When an app can import another file, keep its main config in `config/` and
import from the active theme. When it cannot, symlink the full config file from
the active theme into place. Use relative symlinks.

Examples:

- Waybar imports `current/theme/waybar.css`
- terminal configs import from `current/theme/...`
- `hyprlock` points at `current/wallpaper`

## When to Run `add-dotfiles.sh`

If you only edit an existing tracked file, the symlink already exists and there
is nothing else to do.

If you add a new file or directory under `config/` or `applications/`, run:

```bash
./scripts/add-dotfiles.sh
```

`add-dotfiles.sh` is the restrained Stow helper. It will not overwrite files in
the source tree or the destination tree.

Do not re-run `setup-dotfiles.sh` as a normal update step. It is part of the
initial setup flow and can overwrite existing files.

It can still be useful for refreshing Hyprkarl itself if you have not made your
own config changes on top of it.
