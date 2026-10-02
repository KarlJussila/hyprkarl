# AGENTS.md

Guidance for working in `bin/`, the `hk-*` command library. Every file here is
a user-facing command, on `$PATH` directly via `config/uwsm/env`; there is no
deploy step. Full command reference: `docs/commands.md`.

## Command Structure

- **Simple command**: one script, one action. The default.
- **Dispatcher**: a command with three or more distinct actions (`hk-theme`,
  `hk-wallpaper`, `hk-update`, `hk-pkg`, `hk-fingerprint`, `hk-docker`,
  `hk-shell`, `hk-display`). Each subcommand is its own top-level command,
  `hk-<noun>-<action>`; the dispatcher is a thin router that `exec`s it.
- **`bin/lib/`**: helpers shared by two or more commands. Not for single-use
  logic; keep that in the command itself.

## Naming

Noun-first: the thing acted on comes before the action (`hk-theme-set`,
`hk-screen-record`, `hk-icon-find`). Four deliberate exceptions where no
noun-first form reads naturally: `hk-show-done`, `hk-open-with`,
`hk-suggest-reboot`, `hk-notify-window-class`. Don't add new exceptions
without good reason.

## Boundaries

- **Talking to the shell.** Commands reach Quickshell only through `hk-shell`
  (`menu`, `launcher`, `calculator`, `wallpaper`, `open-with`, `osd`,
  `notifications`). Hardware and media commands send semantic state to
  `hk-shell osd`; the shell picks icons and timing. Menus are data in
  `defaults/menu.json`. Dynamic menu rows come from `*-menu-entries`
  providers that print a JSON array and never open the menu themselves.
- **Clicked monitor.** Bar clicks set `HYPRKARL_OUTPUT`, and `hk-shell menu`
  forwards it so the menu opens on the clicked bar even when Hyprland does not
  focus monitors on mouse movement.
- **Screenshots** go through `hk-screenshot`, which releases a feature panel's
  focus grab for the selection and restores it afterwards.
- **Displays.** `hk-display` is the only display-control path; its library
  writes the layout under `~/.local/state/hyprkarl/display/`, which loads
  before the user's `monitors.lua`. Its `stderr` messages are shown in the
  display panel, so its commands print one clean line on failure. The
  keep-or-revert trial's watchdog is a separate process so a lost shell cannot
  strand an unconfirmed layout.
- **`hk-open-with`** is the one Gio boundary for MIME lookup, default apps, and
  file-aware launching; QML must not duplicate it.
- **Updates.** `hk-update` treats `config/`, `applications/`, `defaults/`, and
  `themes/` as upstream-owned and never generates or replaces personal files.
  See `docs/updating.md`. `hk-config-seed` copies an application's starting
  config only when the user has none of its files.
- **Themes.** `lib/theme.sh` builds a theme, swaps `current/theme` to it,
  copies the GTK theme, and sets GTK settings. Wallpaper additions and
  removals persist under the personal theme source; never modify checked-in
  theme sources from a command.
- **Hooks.** `hk-hook-run` runs the user's executables for `login`,
  `post-update`, `theme-set`, and `wallpaper-set`. Add an event only for a
  real public action.
- **Lock.** `hk-lock` starts `lock.qml`; `hk-suspend` only suspends, and
  Hypridle locks first.

## Style

Follow `docs/shell-style.md`. Use Bash for orchestration and simple pipelines,
Python for structured data, JSON, and real parsing; do not bury a Python
program in `python3 -c`. Bash: `#!/bin/bash`, no `set -euo pipefail`
(intentional), guard clauses as `if` blocks, 2-space indent, `gum log` for
user-facing output in interactive commands. Python: `#!/usr/bin/env python3`
and a `main() -> int` entry point. Let errors surface; catch only where the
command can still do something useful, such as skipping one broken Docker
manifest.

`$HYPRKARL_PATH` is guaranteed by the session environment, so no fallbacks
outside `lib/update.sh` and the setup scripts, which must run from a TTY.

Several scripts and `defaults/menu.json` embed Nerd Font glyphs in labels.
These private-use-area characters are easy to drop silently when rewriting a
whole file; prefer targeted edits.
