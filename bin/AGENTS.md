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
  `shell.sh`, `theme.sh`, `update.sh`). Not for single-use logic; keep that in the command
  itself.

## Naming

Noun-first: the thing acted on comes before the action (`hk-theme-set`,
`hk-screen-record`, `hk-icon-find`). Four deliberate exceptions where no
noun-first form reads naturally: `hk-show-done`, `hk-open-with`,
`hk-suggest-reboot`, `hk-notify-window-class`. Don't add new exceptions
without good reason.

Static menu navigation is defined in `defaults/menu.json` and rendered by
Quickshell. Open or toggle it directly through `hk-shell menu`; do not add
forwarding `hk-menu-*` aliases. Launcher, calculator, open-with, and wallpaper
selection are also Quickshell interfaces opened through their typed `hk-shell`
commands. Dynamic shell entries come from noun-owned provider commands such as
`hk-theme-menu-entries`, `hk-docker-menu-entries`, and
`hk-fingerprint-menu-entries`. Providers own discovery and actions but never
open the shell menu themselves. Keep the open path proportional to the state
actually needed for its rows. Generate large static catalogs directly in menu
JSON shape rather than rebuilding them in a provider on every open.
The Docker provider trusts Hyprkarl's authored manifest shape. It isolates each
manifest load so one broken service is logged to stderr and skipped without
hiding the remaining services; do not add a second manifest schema validator
to the menu path.
The bar's generic command-widget launcher sets `HYPRKARL_OUTPUT` to its output
name. `hk-shell-menu` uses that context when present so the static command
button opens on the bar that was clicked; ordinary callers continue to target
the focused monitor.

`hk-open-with <file>` is the file-manager entry point for the shared
application picker. Its internal `entries` and `launch` actions form the one
Gio boundary for MIME discovery, changing the default application, and
file-aware launch semantics. QML must not duplicate those operations.
`hk-wallpaper-entries` is the equivalent short-lived JSON source for the
thumbnail picker; wallpaper mutation remains in `hk-wallpaper` commands.

`hk-shell osd` is the only public transport for transient shell status.
Hardware and media commands own their system action and pass only semantic
state—levels, mute state, output description, track text, and media action—to
the typed OSD calls. They do not resolve icons or send replacement Mako
notifications. The shell owns indicator selection, timing, monitor routing,
and presentation.

`hk-shell notifications` is the only public transport for notification
dismissal, silence mode, and one-item restore.
Bindings and helpers must use that typed surface rather than call a daemon
control tool or internal QML object. Notification producers continue to use
the standard freedesktop service through `notify-send` or their toolkit.

`hk-display` is the single display-control boundary. Its Python library owns
Hyprland output discovery, live scale and enable/disable changes, internal
backlight control, and the generated layout under
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/display/`. The Quickshell panel
must call this command rather than write Hyprland rules or persistence itself.
Generated `monitors.lua` loads before `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/monitors.lua`, so personal Lua
remains the final authority. Do not add a second shell-JSON display-state store
or make the backend rewrite user-authored monitor configuration.

`hk-hook-run` is the only lifecycle-hook runner. It accepts exactly
`post-boot`, `post-update`, `theme-set`, or `wallpaper-set`, then runs
non-hidden executable regular files from `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hooks/<event>.d/` in lexical
order. Missing directories and non-executable files are normal. It attempts
every hook, reports each failure, and returns nonzero if any failed. Wire new
events only to a real successful public action; do not add hook metadata,
arguments, retries, or background execution without a concrete requirement.

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
Do not translate exceptions merely to catch them again one call later. When an
external workflow needs a friendly failure, prefer one catch-all at the public
command boundary. Catch per item only when the command can still return useful
results from the remaining items, as the Docker menu provider does.
`$HYPRKARL_PATH` is guaranteed by the session environment — no fallbacks
outside `lib/update.sh` and the setup scripts, which must run from a TTY.
Update entry points source `lib/update.sh` before invoking hooks so that
guarantee also holds for a pre-session `hk-update all`.

Several scripts and `defaults/menu.json` embed Nerd Font glyphs in labels.
These private-use-area characters are easy to drop silently when rewriting a
whole file; prefer targeted edits.

`hk-update` treats `config/`, `applications/`, `defaults/`, and `themes/` as
upstream-owned configuration. Personal files live outside the checkout under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`; update commands must not
generate, replace, reset, or adopt them.

`hk-user-migrate` also owns the one-time application-config seed migration.
Paths ignored by `config/.stow-local-ignore` are starting material, not live
files. The migration may replace a link that points directly into Hyprkarl,
but it must preserve real files and owner-authored symlink trees. Record a
completed seed migration in XDG state so routine updates never recreate a file
the user deletes. Add a new migration ID for a genuinely new seed operation;
do not make copy-if-missing an every-update policy.

`lib/theme.sh` owns the theme source-to-runtime boundary. `hk-theme set` invokes
the integrated Python compiler with a built-in source and optional same-name
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/` overlay. The compiler
renders and validates a complete temporary bundle before the command installs
an immutable XDG-state artifact and atomically swaps the selector. The
repository's `config/hyprkarl/current/` entries are fixed compatibility links.
Wallpaper additions and removals persist under the personal theme source;
never mutate checked-in theme sources from a public command. Do not restore
`hk-theme build`, a sibling generator path, or a generated-bundle input mode.
The same library owns installation of the GTK payload as a marked real-file
copy. `hk-theme-set` refreshes it while holding the theme lock; setup/update
uses the same helper and may replace an unrelated destination only on the
explicit force/adopt path.
