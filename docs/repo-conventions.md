# Repo Conventions

This page covers Hyprkarl’s general editing conventions beyond the shell
guidelines in [Shell Style](shell-style.md).

## Readability First

Hyprkarl favors direct, readable configuration over clever abstraction.

That means:

- keep the files people are likely to edit easy to find
- prefer small scripts with one clear path through them
- prefer a plain config file when that is enough
- document what changed for the user or editor when you add or change behavior

## Put Changes in the Right Layer

- `config/`
  Application config and session behavior
- `themes/`
  Theme assets and per-theme overrides
- `bin/`
  Commands meant to be run directly. Subcommands of a dispatcher (`hk-theme set`, `hk-pkg install`, …) live as their own top-level commands using the noun-first form `hk-<noun>-<action>`. The dispatcher is a thin router that `exec`s them.
- `bin/lib/`
  Shared sourced helpers used by more than one `bin/` command (`docker.sh`, `update.sh`). Single-use logic stays in the command itself.
- `scripts/`
  Support scripts and backend logic
- `templates/`
  Files copied or rendered by setup and install commands
- `applications/`
  Desktop files exposed under `~/.local/share/applications/`
- `docs/`
  Documentation for using and editing Hyprkarl

## Stateful Paths

Most files in the repo are static, but these paths represent current state:

- `config/hyprkarl/current/theme`
- `config/hyprkarl/current/theme.name`
- `config/hyprkarl/current/wallpaper`

If you change theme or wallpaper behavior, preserve that model unless you
intend to replace it.

## Stow Behavior

Files under `config/` and `applications/` are exposed through GNU Stow.

- editing an existing tracked file needs no extra step
- adding a new tracked file (or removing one) requires re-stowing with
  `hk-update dotfiles`

Do not treat `setup-dotfiles.sh` as a normal maintenance command. It belongs to
the initial setup flow and is too aggressive for routine refreshes.

## Related Docs

- [Shell Style](shell-style.md)
- [Configuration Map](configuration-map.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
