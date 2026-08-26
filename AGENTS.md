# AGENTS.md

Guidance for coding agents working in this repository.

## What This Repo Is

Hyprkarl is a desktop configuration repository for CachyOS + Hyprland. Stable
shipped entry points under `~/.config/` are symlinks into this checkout, while
ordinary personal configuration lives outside it under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/` and the applications' own
configuration directories.

## Core Engineering Rules

- Prefer the simplest coherent architecture. Remove unnecessary guards,
  layers, indirection, duplication, and special cases instead of elaborating
  them.
- Optimize extension surfaces for directness and readability. A documented
  file, data shape, or small context is preferable to a framework the project
  does not need.
- Trust the user. The person running Hyprkarl owns the system, and documented
  paths and contracts describe the supported, update-friendly route rather
  than a permission boundary. Do not sandbox, allowlist, or reject user-authored
  QML, scripts, or configuration merely because it steps outside that route.
- Do not over-guard. Validate data Hyprkarl must interpret to preserve its own
  invariants and inputs that cross a genuinely untrusted boundary. If an
  off-contract user change works, allow it. If it fails, add concise
  Hyprkarl-specific context when that is easy and leave debugging of the user's
  code to the user.
- Hyprkarl will not have a plugin marketplace. It ships a default configuration
  and suggests convenient paths for personalization; it does not govern,
  install, approve, or sandbox third-party extensions.

## Keeping Docs Current

When you change behavior, structure, or conventions, **update the documentation
in the same change** — both audiences:

- **Human-facing docs** — `README.md` and `docs/` (getting-started, themes,
  commands, configuration-map, extending, repo-conventions, shell-style,
  updating, …).
- **Agent-facing docs** — this file owns repository-wide rules;
  `bin/AGENTS.md` owns command authoring, `config/quickshell/AGENTS.md` owns the
  active shell, `theme-generator/AGENTS.md` owns compiler work, and
  `themes/AGENTS.md` owns theme authoring.
  Each adjacent `CLAUDE.md` only imports its `AGENTS.md` counterpart for Claude
  Code compatibility; keep shared guidance in `AGENTS.md`.

Out-of-date docs are worse than no docs. If a change adds an `hk-*` command,
renames a config surface, alters the theme layout, or shifts a convention, find
and update every doc that describes it. Keep the two audiences consistent with
each other.

## Setup Commands

```bash
./setup-all.sh          # Full setup: packages, dotfiles, system config
./setup-packages.sh     # Bootstrap and run the package update workflow
./setup-dotfiles.sh     # Configure source and apply shipped configuration
./setup-system.sh       # Run pending one-time system migrations
./uninstall.sh          # Remove all config symlinks (reverses setup-dotfiles.sh)
```

There are no build steps or package.json at the repo root — this is a direct
configuration and command-script repo. `tests/` holds focused scripts and
isolated acceptance harnesses, including `tests/hk-update.sh`, which exercises
the updater against a disposable clone and home. See `tests/README.md`.

## Releases

Releases are annotated git tags `vX.Y.Z` on `main` with a hand-written entry in
`CHANGELOG.md`; `develop` is the integration branch. See "Branches and
Releases" in `docs/repo-conventions.md` for the cut procedure. Until v1.0.0,
minor versions may include breaking changes — call them out in the changelog.

## Architecture

### Symlink Model

`setup-dotfiles.sh` uses GNU Stow to symlink the non-ignored shipped entry
points from:

- `config/` → `~/.config/`
- `applications/` → `~/.local/share/applications/`

`bin/` is not stowed; it is added to `$PATH` directly via `config/uwsm/env`.

`config/.stow-local-ignore` also marks application starting configs that
`hk-user-migrate` copies once as real user-owned files. Editing those seed
files does not change an existing installation, and updates must never
overwrite or recreate the personal copy. An XDG-state migration marker records
that the seed operation completed. Keep native include bootstraps tracked only
when they remain a useful stable entry point; see `docs/configuration-map.md`
for the application-by-application ownership table.

Editing a non-ignored tracked entry point edits the live running config
directly. Renaming or deleting one leaves a **stale symlink** (a live link
pointing at a now-missing repo file); `hk-update apply` prunes them as part
of its run, and `hk-update remove-stale` does just that step.

### Update workflow

The normal checkout stays clean on the configured released branch.
`hk-update sync` fetches the explicit `hyprkarl.updateRemote` and
`hyprkarl.updateBranch`, shows the incoming commits and file summary, and
records one confirmed commit under XDG state without changing the checkout.
`hk-update apply` stops Quickshell, fast-forwards to that exact revision,
migrates personal config, restows shipped entry points, rebuilds and activates
the selected theme and GTK payload, reloads affected consumers, restarts the
shell, then records configuration success. A failed operation must not clear
the reviewed revision or claim configuration success before configuration and
reload work completes.

Direct `hk-update apply` always reapplies the current committed checkout, even
when that revision was recorded already, so setup and repair can restore
missing shipped links and generated output.

`hk-update packages` owns one atomic `packages.json` state file. It presents
new removal changes in one multi-select review and records the whole change as
reviewed whether the owner removes or keeps each package. `hk-update system`
runs pending executable files from `system/migrations/` in lexical order and
records each only after success. All machine update records belong under
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/update/`, never in tracked or
personal configuration.

`hk-update all` runs sync, apply, packages, and system in that order, then emits
`post-update`. A custom branch is outside automatic source sync; its owner
merges or rebases manually and uses the remaining update commands. Do not
restore the retired TUI, baseline-commit diffing, dotfiles subcommand, or
force/adopt paths.

### Hyprland Configuration

Hyprland is configured in **Lua** (`hyprland.lua`), as required since Hyprland
0.55 — hyprlang `.conf` is deprecated. The API is `hl.config{}`, `hl.bind()`,
`hl.dsp.*` (dispatchers), `hl.window_rule{}` / `hl.layer_rule{}`, `hl.monitor{}`,
`hl.env()`, `hl.gesture{}`, `hl.animation{}` / `hl.curve()`. See
https://wiki.hypr.land/Configuring/Start/.

`config/hypr/hyprland.lua` is the stable entry point. It adds
`defaults/hypr/` and `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/` to the Lua module path, then loads the
upstream modules from `defaults/hypr/` in this order:

```
envs.lua, autostart.lua, monitors.lua, permissions.lua, looknfeel.lua,
animations.lua, gum.lua, windows.lua, input.lua, bindings.lua
```

It then loads the active theme, the machine-generated display layout from
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/display/monitors.lua`, and
matching optional user modules in the same order. Generated display state
therefore overrides the shipped catch-all monitor rule without dirtying the
repository, while explicit personal `hypr/monitors.lua` calls retain the final say.
Missing generated and user files are normal; other load failures must remain
visible.

Keybindings are split under `defaults/hypr/bindings/`: `apps.lua`, `media.lua`, `windows.lua` (window management), `workspaces.lua` (workspaces/monitors/scratchpad), `system.lua` (menus, notifications, panels, power). App-specific window rules are split under `defaults/hypr/windows/`: `browsers.lua`, `floating.lua`, `media.lua`, `terminals.lua`, `screenshots.lua` — each required by `windows.lua`, which owns the base rules and the final `default-opacity` application. Personal modules belong in `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/`; upstream must not add or modify them.

Validate any change non-destructively with `Hyprland --verify-config` before
relaunching — a broken `hyprland.lua` has no automatic fallback.

### Theme System

Shipped theme sources live in `themes/{name}/`; personal themes and overlays
live in `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/{name}/`. Themes control **look** — colors, fonts, spacing
— not behavior. `hk-theme set` stages and validates an immutable bundle under
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/themes/`, then atomically swaps
the XDG-state selector. The tracked paths under `config/hyprkarl/current/` are
fixed compatibility links into that state, never the state itself.

Switch themes with:
```bash
hk-theme set <theme-name>    # hyprkarl, everforest, gruvbox, loam, tokyo-night
```

`themes/<name>/` contains authoring source only: `theme.yaml`, optional complete
template replacements under `overrides/`, and assets. The integrated compiler
under `theme-generator/` owns shared defaults, templates, Colloid source,
rendering, validation, and tests. A build merges shared defaults, the built-in
graph, and an optional same-name personal graph before native Jinja resolution.
Compiler templates, built-in overrides, and personal overrides apply in that
order; assets use the same precedence. A personal-only theme requires
`theme.yaml`, while a same-name overlay may omit it. Strings, numbers, booleans,
and arbitrary user-defined structures may feed final consumer values.
Read `themes/AGENTS.md` before changing a built-in theme source and
`theme-generator/AGENTS.md` before changing the compiler or its templates.

`hk-theme set <name>` is the public build-and-activate action. It renders and
validates a temporary complete bundle, installs an immutable artifact below
XDG state, transactionally replaces the GTK payload, then publishes the
selector. A failed GTK install must leave the prior selector and payload in
place. Generated bundles never live
under `themes/` or the personal configuration root. Developers may run
`python -m theme_generator` from `theme-generator/` for direct previews,
builds, validation, and tests; there is no sibling checkout or sync command.

GTK theme payloads are the deliberate exception to runtime symlink consumption.
`theme_install_gtk_payload` materializes the active bundle's `gtk-theme/` as a
marked real-file copy at `~/.local/share/themes/hyprkarl/` on setup, update,
and theme switch. Do not replace it with a theme-directory or leaf-file symlink
scheme; GTK discovery and asset loading have been unreliable through those
paths. Normal updates migrate the old Hyprkarl-owned Stow tree but reject an
unrelated directory at the same destination.

### Quickshell Bar Configuration

The active bar under `config/quickshell/` reads
the upstream-owned `defaults/shell.json` and applies the optional sparse
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json` override. Objects merge recursively, arrays replace as
complete ordered values, and `bar.layoutEdits` provides explicit widget-ID
operations for surgical layout changes. Widget instances are defined inline
in the default layout. The top-level `modules` object selects the nine optional
built-in runtimes: bar, panels, notifications, OSD, polkit, menu,
applications/open-with, calculator, and wallpaper. Module choices latch at
shell startup, so `hk-shell restart` is required after changing them;
`modules.bar` controls the built-in per-output bars, while
`modules.panels` controls only their feature-panel popup hosts. Version 1
accepts top and bottom bars only. Keep
appearance defaults in each theme's `quickshell.json`; shell JSON owns
placement and behavior. The shared toggle indicator deliberately also accepts
sparse per-instance control geometry over the theme's `shell.switch` default.
Island corner shapes, selective borders, and
screen/outer/content margins are theme data rendered once by
`layout/IslandSurface.qml`. Widgets report natural heights, the bar resolves
the tallest one against the theme minimum, and all islands receive that shared
height. `WidgetHost.qml` applies universal `bar.widgetPadding.main` and `.cross`
values along and across top/bottom bar widgets; widget natural sizes
must not duplicate those insets. A concrete widget may request a main-axis
offset, resolved with a zero floor; the tray binds this to
`bar.trayPaddingOffset`. Panel internals use the separate
`metrics.controlPadding` token. `Theme.qml` watches the canonical XDG-state
`current/theme.json` selector, then reads the immutable artifact named there.
One optional `userRoot.source` loads a trusted application-wide QML composition
root for independent surfaces or a replacement bar. Its documented context
exposes the resolved configuration, theme, outputs, current overlay request,
and direct overlay methods. Personal roots may import `Hyprkarl.Modal` for the
same shell-styled exclusive modal boundary as built-in surfaces. It may publish
reactive per-output notification positioning; there is no discovery or plugin
layer.
The shell keeps application-wide service state separate from per-output
presentation. Feature panels compose through one host per bar; focused menus,
pickers, and the display arranger compose the shared modal frame; OSD,
notifications, and polkit each retain their own lifecycle boundary. Command
providers exist once per provider-backed widget ID, and static widgets create
no polling runtime. Explicit personal QML receives the documented narrow
context without discovery, registration, or sandboxing.

Read `config/quickshell/AGENTS.md` before changing shell implementation and
`config/quickshell/README.md` for the contributor map and checks. Use
`hk-shell` to start, stop, restart, inspect, or read logs from the production
shell.

### `hk-*` Commands

All user-facing utilities are in `bin/` and follow the `hk-*` naming
convention. See `bin/AGENTS.md` for command structure, naming rules, and
authoring conventions before adding or editing one.

### Lifecycle Hooks

`hk-hook-run` executes user-owned, non-hidden executable files from
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hooks/<event>.d/` in lexical order. The supported events are
`post-boot`, `post-update`, `theme-set`, and `wallpaper-set`, each emitted only
by its existing public action. Missing directories are a no-op. The runner
attempts every hook and returns nonzero after reporting failures; the owning
action must state when its primary change already completed. Do not add event
metadata, retries, background execution, or new event names without a concrete
public workflow.

### Session Environment

`config/uwsm/env` sets session-wide environment variables (including
`HYPRKARL_PATH` and `$PATH`). Changes require a new Hyprland session.
`~/.config/uwsm/default` controls `$TERMINAL`, `$EDITOR`, and `$SHELL`.
`~/.config/uwsm/env.local` holds machine-local variables. Both are real user-owned files, seeded or migrated by `hk-user-migrate` and never tracked.

## Command Script Style

`bin/` scripts follow `docs/shell-style.md` — read it before writing or editing
a command. Use Python for structured data, JSON generation, substantial
parsing, and heavy string manipulation; use Bash when command orchestration or
a simple pipeline remains clearer. Bash commands use `#!/bin/bash` and
intentionally omit strict mode (`set -euo pipefail`); Python commands use
`#!/usr/bin/env python3` and ordinary standard-library data structures.

## Key Docs

- `docs/configuration-map.md` — repo layout and main editing surfaces
- `docs/themes.md` — theme structure and wallpaper layout
- `docs/extending-hyprkarl.md` — adding commands, menus, keybindings, theme-aware config
- `docs/authentication-surfaces.md` — polkit ownership and the lock-screen release boundary
- `docs/shell-style.md` — Bash/Python command scripting conventions
- `docs/commands.md` — full `hk-*` command reference
- `docs/repo-conventions.md` — editing conventions, stowed-config model, branches and releases
- `docs/updating.md` — the `hk-update` model and workflows
