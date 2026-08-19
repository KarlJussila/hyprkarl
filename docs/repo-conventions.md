# Repo Conventions

This page covers Hyprkarl’s general editing conventions beyond the command
script guidelines in [Command Script Style](shell-style.md).

## Readability First

Hyprkarl favors direct, readable configuration over clever abstraction.

That means:

- keep the files people are likely to edit easy to find
- prefer small scripts with one clear path through them
- prefer a plain config file when that is enough
- document what changed for the user or editor when you add or change behavior

## Put Changes in the Right Layer

- `config/`
  Stowed application config and stable live entry points
- `defaults/`
  Upstream-owned behavior and data defaults
- `user/`
  User-owned overrides. Upstream may document this namespace but does not add
  or replace personal configuration files.
- `themes/`
  Theme assets and per-theme overrides
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
- `docs/`
  Documentation for using and editing Hyprkarl

## Stateful Paths

Authoritative current theme and wallpaper state lives outside Git under
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/`. These tracked repository
paths are immutable compatibility links into that state tree:

- `config/hyprkarl/current/theme`
- `config/hyprkarl/current/theme.name`
- `config/hyprkarl/current/wallpaper`

Theme sources under `themes/` are upstream-owned; personal themes, same-name
overlays, wallpaper additions, and removal markers belong under `user/themes/`.
Switching themes must stage and validate a complete bundle before atomically
moving the XDG-state selector.

`~/.local/share/themes/hyprkarl/` is derived runtime output, not an editing
surface. It is a marked real-file copy of the active bundle's `gtk-theme/`
payload because GTK does not reliably follow moving theme-directory symlinks.

## Branches and Releases

- `main` is the released branch: what a fresh install clones and what
  `hk-update` merges from.
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

`hk-update tui` shows the current version (`git describe`) in its intro, so an
update reads as a move between releases rather than between commit hashes.

## Stow Behavior

Files under `config/` and `applications/` are exposed through GNU Stow.

Files under `defaults/` and `user/` are read directly from the checkout by
stable entry points. They are not stowed: updates own `defaults/`, while a
user's branch owns their files under `user/`.

- editing an existing tracked file needs no extra step
- adding a new tracked file (or removing one) requires re-stowing with
  `hk-update dotfiles`

Do not treat `setup-dotfiles.sh` as a normal maintenance command. It belongs to
the initial setup flow and is too aggressive for routine refreshes.

## Related Docs

- [Command Script Style](shell-style.md)
- [Configuration Map](configuration-map.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
