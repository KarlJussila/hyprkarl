# AGENTS.md

Guidance for working in `bin/` — the hk-* command library. Every file here is a
user-facing command, on `$PATH` directly via `config/uwsm/env`; there is no
deploy step. Full command reference: `docs/commands.md`.

## Command Structure

- **Simple command** — one script, one action. The default.
- **Dispatcher** — a command with three or more distinct actions (`hk-theme`,
  `hk-wallpaper`, `hk-update`, `hk-pkg`, `hk-fingerprint`, `hk-docker`). Each
  subcommand lives as its own top-level command in the form
  `hk-<noun>-<action>`; the dispatcher is a thin router that `exec`s it.
- **`bin/lib/`** — sourced helpers shared by two or more commands (`docker.sh`,
  `shell.sh`, `update.sh`). Not for single-use logic; keep that in the command
  itself.

## Naming

Noun-first: the thing acted on comes before the action (`hk-theme-set`,
`hk-screen-record`, `hk-icon-find`). Four deliberate exceptions where no
noun-first form reads naturally: `hk-show-done`, `hk-open-with`,
`hk-suggest-reboot`, `hk-notify-window-class`. Don't add new exceptions
without good reason.

Static menu navigation is defined in `defaults/menu.json` and rendered by
Quickshell. The corresponding `hk-menu-*` commands are thin public wrappers
around `hk-shell menu`; `hk-menu-fingerprint` only selects the applicable
shell-native menu from real setup state, and `hk-menu-wallpaper` retains narrow
action subcommands for the dedicated image and file pickers. Do not rebuild
navigation hierarchy in those scripts. Docker menu wrappers expose
`--entries` for the shell's dynamic source boundary; they do not render their
own UI. Search-heavy selectors such as applications, themes, keybindings, and
icons may continue using Rofi.

## Style

Follow `docs/shell-style.md`. Highlights: `#!/bin/bash` shebang, no
`set -euo pipefail` (intentional), guard clauses as `if` blocks, 2-space
indent, `gum log` for user-facing output in interactive commands.
`$HYPRKARL_PATH` is guaranteed by the session environment — no fallbacks
outside `lib/update.sh` and the setup scripts, which must run from a TTY.

Several scripts and `defaults/menu.json` embed Nerd Font glyphs in labels.
These private-use-area characters are easy to drop silently when rewriting a
whole file; prefer targeted edits.

`hk-update` treats `config/`, `applications/`, `defaults/`, and `themes/` as
upstream-owned configuration. Files under `user/` are review-only: update
commands may display them but must never generate, replace, reset, or adopt
them.
