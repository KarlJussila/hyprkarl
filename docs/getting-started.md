# Getting Started

This page covers the Hyprkarl setup model, the safe mental model for editing
the repo, and the difference between first-install scripts and later
maintenance.

## Environment Assumptions

Hyprkarl is written for:

- CachyOS with Hyprland already installed
- a single local user
- UWSM-managed graphical sessions
- a repo checkout at `~/.local/share/hyprkarl`

## Setup Flow

The normal install path is:

```bash
git clone --depth=1 https://github.com/KarlJussila/hyprkarl.git ~/.local/share/hyprkarl
cd ~/.local/share/hyprkarl
./setup-all.sh
```

`setup-all.sh` runs three scripts in order:

- `setup-packages.sh`
  Installs the packages Hyprkarl expects.
- `setup-system.sh`
  Applies system-level settings such as GTK defaults, SDDM autologin, logind
  lid handling, sudo and faillock settings, and LocalSend firewall rules.
- `setup-dotfiles.sh`
  Uses GNU Stow to replace the live files under `~/.config/` and
  `~/.local/share/applications/` with symlinks to the matching files in
  `~/.local/share/hyprkarl`. If a path does not already exist, it just creates
  the symlink. If a path already exists, it replaces that existing file with a
  symlink to Hyprkarl's tracked file. So after the script finishes, both new
  paths and overlapping paths point at Hyprkarl; the difference is that
  overlapping existing configs are overwritten unless you back them up first.

## Understand the Symlink Model

Hyprkarl is edited from `~/.local/share/hyprkarl/`.

The files under `~/.config/` and `~/.local/share/applications/` are symlinks
back into that tree, so the tracked files in Hyprkarl are the source of truth.
Editing `~/.config/hypr/hyprland.conf` and editing
`~/.local/share/hyprkarl/config/hypr/hyprland.conf` are the same operation.

## Editing Hyprkarl

If you plan to customize Hyprkarl, make a branch first and edit the files in
`~/.local/share/hyprkarl/`.

For editing guidance, see:

- [Configuration Map](configuration-map.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
- [Repo Conventions](repo-conventions.md)
- [Shell Style](shell-style.md)

## Updating

After initial setup, use `hk-update` to apply changes from upstream. It tracks
which commit each category was last applied at, so it only acts when something
has actually changed.

```bash
cd ~/.local/share/hyprkarl
git fetch origin
git merge origin/main   # or rebase onto your personal branch
hk-update all
```

`hk-update all` runs dotfiles, packages, and system in sequence. You can also
run each individually:

```bash
hk-update dotfiles    # re-stow config files, remove stale symlinks
hk-update remove-stale  # remove stale symlinks and empty dirs (no restow)
hk-update packages    # install new required packages, prompt to remove dropped ones
hk-update system      # re-run system-level setup
hk-update check       # preview what would change without doing anything
```

See [Updating](updating.md) for the full update workflow, conflict resolution,
and what to do when things go wrong.

## Changes That Need a New Session

Some changes do not take effect immediately:

- `config/uwsm/default` changes affect new sessions
- `hk-default-shell` changes affect the next login
- `hk-docker setup` changes to group membership require a new login or
  reboot
- most other changes can be reloaded live

## Where to Go Next

- [Using Hyprkarl](using-hyprkarl.md) for daily workflows
- [Configuration Map](configuration-map.md) for repo layout
- [Extending Hyprkarl](extending-hyprkarl.md) for adding your own behavior
