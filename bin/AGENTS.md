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
Quickshell. Open or toggle it directly through `hk-shell menu`; do not add
forwarding `hk-menu-*` aliases. A command named `hk-menu-*` must own an actual
interactive surface, as the launcher, calculator, and wallpaper picker still
do. Dynamic shell entries come from noun-owned provider commands such as
`hk-theme-menu-entries`, `hk-docker-menu-entries`, and
`hk-fingerprint-menu-entries`. Providers own discovery and actions but never
open the shell menu themselves. Keep the open path proportional to the state
actually needed for its rows. Generate large static catalogs directly in menu
JSON shape rather than rebuilding them in a provider on every open.

## Style

Follow `docs/shell-style.md`. Choose Python for structured data, JSON,
substantial parsing, and heavy string transformation; choose Bash for clear
command orchestration and simple pipelines. Dynamic menu providers should
normally construct dictionaries and lists in Python and serialize them with
the standard `json` module. A provider that only prints prebuilt JSON may stay
in Bash. Do not bury a sizeable Python program in `python3 -c` inside a Bash
wrapper.

For Bash: use the `#!/bin/bash` shebang, no `set -euo pipefail` (intentional),
guard clauses as `if` blocks, 2-space indentation, and `gum log` for
user-facing output in interactive commands. For Python: use
`#!/usr/bin/env python3`, a `main() -> int` entry point, and concise boundary
errors on stderr. `bin/lib/*.sh` and `bin/lib/*.py` are both reserved for logic
shared by multiple commands.
`$HYPRKARL_PATH` is guaranteed by the session environment — no fallbacks
outside `lib/update.sh` and the setup scripts, which must run from a TTY.

Several scripts and `defaults/menu.json` embed Nerd Font glyphs in labels.
These private-use-area characters are easy to drop silently when rewriting a
whole file; prefer targeted edits.

`hk-update` treats `config/`, `applications/`, `defaults/`, and `themes/` as
upstream-owned configuration. Files under `user/` are review-only: update
commands may display them but must never generate, replace, reset, or adopt
them.
