# AGENTS.md

Guidance for coding agents working in this repository.

## What This Repo Is

Hyprkarl is a desktop configuration repository for CachyOS + Hyprland. Shipped
entry points under `~/.config/` are symlinks into this checkout. Personal
configuration lives outside it, in `~/.config/hyprkarl/`, `~/.config/quickshell/`,
and the applications' own config directories, so updates never touch it.

## Engineering Rules

- Prefer the simplest coherent design, judged over the project's life. A shape
  that is simple today but forces migrations or rewrites on every future change
  is not the simple one.
- Keep upstream defaults flowing to users. Personal files hold only what the
  user changed and merge over shipped defaults; avoid designs that freeze users
  at install-time copies.
- Trust the user. Documented paths describe the supported, update-friendly
  route, not a permission boundary. Do not sandbox, allowlist, or validate
  user-authored QML, scripts, or configuration to police it.
- Do not over-guard. Validate only untrusted input and data Hyprkarl must
  interpret to keep its own invariants. Trust internal callers, the runtime,
  and the session setup. Let readable errors surface instead of wrapping them.
- No plugin system: no discovery, registries, manifests, or approval. User code
  is referenced explicitly by path.

## Keeping Docs Current

When you change behavior, structure, or conventions, update the docs in the
same change, for both audiences:

- **Human docs:** `README.md` and `docs/`. Personal customization belongs in
  `docs/extending-hyprkarl.md`.
- **Agent docs:** this file for repository-wide guidance; `bin/AGENTS.md` for
  commands; `config/quickshell/AGENTS.md` for the shell;
  `theme-generator/AGENTS.md` for the theme compiler; `themes/AGENTS.md` for
  theme authoring. Each adjacent `CLAUDE.md` only imports its `AGENTS.md`.

Agent docs orient a reader and record decisions that are not obvious from the
code. Do not restate the implementation as rules; out-of-date docs are worse
than none.

## Setup Commands

```bash
./install.sh            # Install: bootstrap the updater, then run hk-update apply
./uninstall.sh          # Remove all config symlinks
```

There is no build step. `tests/` holds focused scripts and isolated harnesses;
see `tests/README.md`.

## Releases

Releases are annotated tags `vX.Y.Z` on `main` with a hand-written
`CHANGELOG.md` entry; `develop` is the integration branch. See
`docs/repo-conventions.md`. From v1.0.0, the surfaces listed in
`docs/updating.md` ("What updates keep stable") are promises: renaming or
removing one is a breaking change that needs a changelog note and, where the
user's files can be converted, a migration. Prefer additions.

## Architecture

### Symlinks and starting configs

`hk-update apply` uses GNU Stow to link `config/` into `~/.config/`. `bin/` is
put on `$PATH` by `config/uwsm/env`, after `~/.local/bin` so a personal command
can replace an `hk-*` one. Editing a stowed file edits the live config.
Renaming or deleting one leaves a stale symlink, which `hk-update apply` (or
`hk-update remove-stale`) prunes.

Hyprkarl's defaults must keep updating, so choose how to configure an
application in this order: a shipped file that loads a personal file (the
terminals' `local.*`, the Hypr tools' `*.local.conf`); a default under
`defaults/config/` or `defaults/share/`, which `config/uwsm/env` puts on
`XDG_CONFIG_DIRS` or `XDG_DATA_DIRS` so a user's own file replaces it; output
of the theme, for anything that is appearance. Copying a starting config is
the last resort, for applications with no include mechanism: the paths in
`config/.stow-local-ignore`, which `hk-config-seed` copies when the user has
none of their files. See `docs/configuration-map.md` for each application.

### Updates

`hk-update sync` fetches and shows incoming commits and records the reviewed
revision. `hk-update apply` fast-forwards to it, installs and reviews
packages, runs pending scripts from `migrations/`, seeds starting configs,
restows, rebuilds the theme, reloads consumers, and restarts the shell. The
installer runs the same `apply`, so a fresh install and an update take one
path. Machine update state lives under `~/.local/state/hyprkarl/update/`. See
`docs/updating.md`; `docs/repo-conventions.md` covers writing a migration.

### Hyprland

Hyprland is configured in Lua (required since 0.55): `hl.config{}`,
`hl.bind()`, `hl.dsp.*`, `hl.window_rule{}`, `hl.monitor{}`, and so on. See
https://wiki.hypr.land/Configuring/Start/.

`config/hypr/hyprland.lua` loads the shipped modules from `defaults/hypr/`
(envs, autostart, monitors, permissions, looknfeel, animations, gum, windows,
input, bindings), then the active theme, then the display layout written by
`hk-display`, then the user's `~/.config/hypr/hyprland.local.lua`.
Bindings are split under `defaults/hypr/bindings/` and window rules under
`defaults/hypr/windows/`.

Check changes with `Hyprland --verify-config` before reloading; a broken
`hyprland.lua` has no fallback.

### Themes

Themes control look, not behavior. Sources live in `themes/<name>/`
(`theme.yaml`, optional `overrides/`, assets); personal themes and same-name
overlays live in `~/.config/hyprkarl/themes/<name>/`. The compiler in
`theme-generator/` merges its defaults, the theme, and any personal overlay,
and renders every consumer's files.

`hk-theme set <name>` builds into `~/.local/state/hyprkarl/themes/<name>.<timestamp>`,
points the `current/theme` symlink at it, deletes older builds, copies the GTK
theme to `~/.local/share/themes/hyprkarl/` (GTK does not follow symlinked theme
directories reliably), and sets the GTK desktop settings. Consumers read
through `current/theme`. Read `themes/AGENTS.md` before editing a theme and
`theme-generator/AGENTS.md` before changing the compiler.

### Quickshell

The shell in `config/quickshell/` draws the bar, panels, menus, launcher,
notifications, OSD, polkit prompt, and lock screen. `shell.qml` starts the
desktop; `lock.qml` runs the lock screen as a separate process. Behavior comes
from `defaults/shell.json` and `defaults/menu.json` with the user's files in
`~/.config/quickshell/settings/` merged over them; appearance comes from the
theme. It runs from `~/.config/quickshell/`, where Stow links it, so personal
QML can import and replace any part. Read `config/quickshell/AGENTS.md` before
changing it, and use `hk-shell` to start, restart, or read its logs.

### Commands

User-facing commands live in `bin/` as `hk-*`. Read `bin/AGENTS.md` before
adding or editing one.

### Lifecycle hooks

`hk-hook-run` runs the user's executables in
`~/.config/hyprkarl/hooks/<event>.d/` in lexical order. Events: `login`,
`post-update`, `theme-set`, `wallpaper-set`. Add an event only for a concrete
workflow.

### Session environment

`config/uwsm/env` sets session-wide variables, including `HYPRKARL_PATH`,
`$PATH`, and the XDG defaults directories; changes need a new session.
`~/.config/uwsm/default` holds the editor `hk-default-editor` chose, and
`~/.config/uwsm/env.local` holds machine-local variables. Both are user-owned.

## Command Script Style

Read `docs/shell-style.md` before writing a command. Use Bash for
orchestration and simple pipelines, Python for structured data and JSON. Bash
scripts use `#!/bin/bash` and intentionally omit `set -euo pipefail`.

## Key Docs

- `docs/configuration-map.md`: repo layout and who owns each file
- `docs/themes.md`: theme structure and wallpapers
- `docs/extending-hyprkarl.md`: personal scripts, hooks, menus, keybindings, QML
- `docs/shell-configuration.md`: shell settings and QML extension points
- `docs/authentication-surfaces.md`: lock screen and polkit
- `docs/shell-style.md`: Bash and Python conventions
- `docs/commands.md`: `hk-*` command reference
- `docs/repo-conventions.md`: editing conventions, branches, releases
- `docs/updating.md`: the update workflow
