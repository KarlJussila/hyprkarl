# Repo Conventions

This guide is for contributors changing Hyprkarl's shipped code, defaults, or
installation behavior in the checkout. For personal configuration and
extensions, use [Extending Hyprkarl](extending-hyprkarl.md).

## Readability First

Hyprkarl favors direct, readable configuration over clever abstraction.

That means:

- keep the files people are likely to edit easy to find
- prefer small scripts with one clear path through them
- prefer a plain config file when that is enough
- document what changed for the user or editor when you add or change behavior

## Trust User-Owned Code

The documented user paths and extension contracts are the supported,
update-friendly route, not a sandbox. Hyprkarl does not block user-authored
QML, scripts, or configuration merely because it goes beyond that contract.
Off-contract changes may work, and users are free to accept the maintenance
and debugging cost when they do. When they fail, Hyprkarl should add concise
context for failures it can identify cheaply, then let the underlying runtime
report the user's error.

Hyprkarl will not have a plugin marketplace. It provides a curated default and
suggested locations for personal code; it does not install, approve, constrain,
or promise compatibility for third-party extensions.

## Put Changes in the Right Layer

- `config/`
  Stowed application config and stable live entry points
- `defaults/`
  Upstream-owned behavior and data defaults
- `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`
  User-owned overrides. Upstream does not add or replace personal files there.
- `themes/`
  Shipped theme authoring sources and assets
- `theme-generator/`
  Integrated compiler code, defaults, templates, tests, and vendored Colloid
- `bin/`
  Commands meant to be run directly. Subcommands of a dispatcher (`hk-theme set`, `hk-pkg install`, …) live as their own top-level commands using the noun-first form `hk-<noun>-<action>`. The dispatcher is a thin router that `exec`s them.
- `bin/lib/`
  Shared Bash or Python helpers used by more than one `bin/` command
  (`docker.sh`, `update.sh`, `keybindings.py`). Single-use logic stays in the
  command itself.
- `templates/`
  Files copied or rendered by setup and install commands
- `applications/`
  Desktop files exposed under `~/.local/share/applications/`
- `system/migrations/`
  Focused system changes run once in lexical order and recorded in XDG state
- `docs/`
  Documentation for using and editing Hyprkarl

## Stateful Paths

Authoritative current theme and wallpaper state lives outside Git under
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/`. These tracked repository
paths are fixed compatibility links into that state tree:

- `config/hyprkarl/current/theme`
- `config/hyprkarl/current/wallpaper`

Theme sources under `themes/` are upstream-owned; personal themes, same-name
overlays, wallpaper additions, and removal markers belong under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/`.
Switching themes builds into a new directory before moving the `current/theme`
symlink, so a failed build never changes the active theme.

`~/.local/share/themes/hyprkarl/` is derived runtime output, not an editing
surface. It is a copy of the active build's `gtk-theme/` because GTK does not
reliably follow symlinked theme directories.

## Branches and Releases

- `main` is the released branch: what a fresh install clones and what the
  default `hk-update sync` source points to.
- `develop` is the integration branch. Work lands there first and is merged to
  `main` when it's ready to ship.
- A release is an annotated tag `vX.Y.Z` on `main`, cut together with a
  hand-written entry in `CHANGELOG.md`:

  ```bash
  git checkout main && git merge develop
  # move the Unreleased notes under a new version heading in CHANGELOG.md, commit
  git tag -a vX.Y.Z -m "Hyprkarl vX.Y.Z"
  git push origin main vX.Y.Z
  ```

- Until v1.0.0, minor versions may include breaking changes; the changelog
  calls them out explicitly.

The normal checkout stays on `main`. `hk-update sync` fetches and pins an exact
confirmed `origin/main` commit without moving the checkout; `hk-update apply`
performs the fast-forward. A custom branch is maintained with ordinary Git,
then applied with `hk-update apply`.

## Stow Behavior

Non-ignored files under `config/` and files under `applications/` are exposed
through GNU Stow. `config/.stow-local-ignore` separates stable tracked entry
points from application starting configs. `hk-config-seed` copies those to
their normal `~/.config/<application>/` paths when an application has none of
them yet, and never overwrites a file that exists.

Files under `defaults/` are read directly from the checkout by stable entry
points. Personal configuration is read from the application's own directory
or `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`, as documented in
[Configuration Map](configuration-map.md). It is never stowed or owned by a
Git branch.

- editing an existing non-ignored tracked entry point needs no extra step
- editing an ignored seed changes only future migrations and installs
- editing a real application config under `~/.config/` is immediate and
  update-safe
- adding or removing a tracked entry point requires re-stowing with
  `hk-update apply`

`setup-dotfiles.sh` is the initial-setup wrapper around the same configuration
apply command. Use `hk-update apply` directly during normal maintenance.

For a new application integration, use its native configuration mechanism.
When includes work, a small tracked bootstrap can load generated theme data,
shipped defaults, and personal settings last. Otherwise, provide a starting
config: add it under `config/`, ignore it in `config/.stow-local-ignore`, and
list it in `bin/hk-config-seed`.

## Contributor guides

- [Command script style](shell-style.md) for shipped commands and dispatchers
- [Quickshell project guide](../config/quickshell/README.md) for shell code
- [Theme compiler guide](../theme-generator/README.md) for generated consumers
- [Tests](../tests/README.md) for validation
