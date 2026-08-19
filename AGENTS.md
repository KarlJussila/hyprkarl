# AGENTS.md

Guidance for coding agents working in this repository.

## What This Repo Is

Hyprkarl is a desktop configuration repository for CachyOS + Hyprland. It is installed once, then edited directly — the live `~/.config/` files are symlinks back into this repo, so changes here take effect immediately without a deploy step.

## Keeping Docs Current

When you change behavior, structure, or conventions, **update the documentation
in the same change** — both audiences:

- **Human-facing docs** — `README.md` and `docs/` (getting-started, themes,
  commands, configuration-map, extending, repo-conventions, shell-style,
  updating, …).
- **Agent-facing docs** — the canonical `AGENTS.md` files: this one,
  `bin/AGENTS.md` (command authoring), and `config/quickshell/AGENTS.md` (the
  active bar).
  Each adjacent `CLAUDE.md` only imports its `AGENTS.md` counterpart for Claude
  Code compatibility; keep shared guidance in `AGENTS.md`.

Out-of-date docs are worse than no docs. If a change adds an `hk-*` command,
renames a config surface, alters the theme layout, or shifts a convention, find
and update every doc that describes it. Keep the two audiences consistent with
each other.

## Setup Commands

```bash
./setup-all.sh          # Full setup: packages, dotfiles, system config
./setup-packages.sh     # Install/update packages via pacman + paru
./setup-dotfiles.sh     # Re-run GNU stow to update symlinks (refuses on a dirty config/ tree)
./setup-system.sh       # System-level config (SDDM autologin, etc.)
./uninstall.sh          # Remove all config symlinks (reverses setup-dotfiles.sh)
```

There are no build steps or package.json at the repo root — this is a direct
configuration and command-script repo. There is no automated test suite;
`tests/` holds manual, interactive sandbox harnesses (e.g.
`tests/hk-update-tui.sh`) for exercising a command end to end without touching
the live system. See `tests/README.md`.

## Releases

Releases are annotated git tags `vX.Y.Z` on `main` with a hand-written entry in
`CHANGELOG.md`; `develop` is the integration branch. See "Branches and
Releases" in `docs/repo-conventions.md` for the cut procedure. Until v1.0.0,
minor versions may include breaking changes — call them out in the changelog.

## Architecture

### Symlink Model

`setup-dotfiles.sh` uses GNU stow to symlink:
- `config/` → `~/.config/`
- `applications/` → `~/.local/share/applications/`

`bin/` is not stowed; it is added to `$PATH` directly via `config/uwsm/env`.

Editing files in this repo edits the live running config directly. Renaming or
deleting a config file leaves a **stale symlink** (a live link pointing at a
now-missing repo file); `hk-update dotfiles` prunes them as part of its run,
and `hk-update remove-stale` does just that step.

### Hyprland Configuration

Hyprland is configured in **Lua** (`hyprland.lua`), as required since Hyprland
0.55 — hyprlang `.conf` is deprecated. The API is `hl.config{}`, `hl.bind()`,
`hl.dsp.*` (dispatchers), `hl.window_rule{}` / `hl.layer_rule{}`, `hl.monitor{}`,
`hl.env()`, `hl.gesture{}`, `hl.animation{}` / `hl.curve()`. See
https://wiki.hypr.land/Configuring/Start/.

`config/hypr/hyprland.lua` is the stable entry point. It adds
`defaults/hypr/` and `user/hypr/` to the Lua module path, then loads the
upstream modules from `defaults/hypr/` in this order:

```
envs.lua, autostart.lua, monitors.lua, permissions.lua, looknfeel.lua,
animations.lua, gum.lua, windows.lua, input.lua, bindings.lua
```

It then loads the active theme and matching optional user modules in the same
order. User values therefore win over shipped behavior and the theme. Missing
user files are normal; other load failures must remain visible.

Keybindings are split under `defaults/hypr/bindings/`: `apps.lua`, `media.lua`, `windows.lua` (window management), `workspaces.lua` (workspaces/monitors/scratchpad), `system.lua` (menus, notifications, panels, power). App-specific window rules are split under `defaults/hypr/windows/`: `browsers.lua`, `floating.lua`, `media.lua`, `terminals.lua`, `screenshots.lua` — each required by `windows.lua`, which owns the base rules and the final `default-opacity` application. Personal modules belong in `user/hypr/`; upstream must not add or modify a user's files there.

Validate any change non-destructively with `Hyprland --verify-config` before
relaunching — a broken `hyprland.lua` has no automatic fallback.

### Theme System

Themes live in `themes/{name}/` and control Hyprland, the bars, rofi,
terminals, mako, hyprlock, GTK, and Qt. Themes are meant to control **look** —
colors, fonts, spacing — not behavior. The active theme is tracked by the
symlink `config/hyprkarl/current/theme` (plus `theme.name`).

Switch themes with:
```bash
hk-theme set <theme-name>    # hyprkarl, everforest, gruvbox
```

When adding a new component that needs theming, add a corresponding file to
each theme directory. Themes can also be generated from a single color palette
with the companion
[theme generator](https://github.com/KarlJussila/hyprkarl-theme-generator)
(locally at `../theme-generator/`).

### Quickshell Bar Configuration

The active bar under `config/quickshell/` reads
the upstream-owned `defaults/shell.json` and applies the optional sparse
`user/shell.json` override. Objects merge recursively, arrays replace as
complete ordered values, and `bar.layoutEdits` provides explicit widget-ID
operations for surgical layout changes. Widget instances are defined inline
in the default layout, and version 1 accepts top and bottom bars only. Keep
appearance in each theme's `quickshell.json`; shell JSON owns placement and
behavior. Island corner shapes, selective borders, and
screen/outer/content margins are theme data rendered once by
`layout/IslandSurface.qml`. Widgets report natural heights, the bar resolves
the tallest one against the theme minimum, and all islands receive that shared
height. `WidgetHost.qml` applies universal `horizontalWidgetPadding.main` and
`.cross` values along and across top/bottom bar widgets; widget natural sizes
must not duplicate those insets. A concrete widget may request a main-axis
offset, resolved with a zero floor; the tray binds this to
`trayMainPaddingOffset`. Panel internals use the separate `controlPadding`
token. `Theme.qml` watches the canonical
`current/theme.name` selector and
then reads the selected theme file directly so replacing the active-theme
symlink cannot strand its file watcher on the previous target. Each bar owns
one `FeaturePanelHost`; audio, network, Bluetooth,
battery/power, and clock/calendar panels compose shared panel controls inside
that host, while feature directories own service-specific state. Bluetooth
and network use feature singletons for adapter-global discovery/scan
ownership; clock uses one application-wide current-time owner. See
`config/quickshell/AGENTS.md` before changing the shell. Use `hk-shell` to
start, stop, restart, inspect, or read logs from the production bar.
The same shell renders the command hierarchy from `defaults/menu.json` plus
the optional deep-merged `user/menu.json`. Menu entries use stable IDs; a
menu's optional `sourceCommand` may provide validated command entries that
must be rediscovered when it opens, as the Docker service menus do;
`hk-shell menu` is the only public transport for opening or toggling static
navigation. Domain-owned providers supply themes, Docker services, live
keybindings, Nerd Font icons, and setup-aware fingerprint actions; searchable
menus filter those entries in-process. Providers run without a login shell,
and dynamic destinations appear only after their complete model validates;
preformat large static catalogs instead of transforming them on every open.
Remaining `hk-menu-*` commands own real
interfaces rather than forwarding to Quickshell. The menu preserves the
original Rofi surface's compact width, centered rows, title band, nested frame,
and bordered selection, while inheriting the active shell theme's semantic
palette, typography, rounded geometry, border treatment, and interaction
states. The nested `menu` object owns menu-specific modifiers and metrics.

### `hk-*` Commands

All user-facing utilities are in `bin/` and follow the `hk-*` naming
convention. See `bin/AGENTS.md` for command structure, naming rules, and
authoring conventions before adding or editing one.

### Session Environment

`config/uwsm/env` sets session-wide environment variables (including
`HYPRKARL_PATH` and `$PATH`). Changes require a new Hyprland session.
`config/uwsm/default` controls `$TERMINAL`, `$EDITOR`, and `$SHELL`.
`~/.config/uwsm/env.local` holds machine-local variables and is not tracked.

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
- `docs/shell-style.md` — Bash/Python command scripting conventions
- `docs/commands.md` — full `hk-*` command reference
- `docs/repo-conventions.md` — editing conventions, stowed-config model, branches and releases
- `docs/updating.md` — the `hk-update` model and workflows
