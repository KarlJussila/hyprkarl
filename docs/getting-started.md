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

The files under `~/.config/` and `~/.local/share/applications/` are usually
symlinks back into that tree, so the tracked files in Hyprkarl are the source
of truth.

Two setup scripts matter here:

- `setup-dotfiles.sh`
  First-install script. It can replace existing live files with symlinks to
  Hyprkarl.
- `scripts/add-dotfiles.sh`
  Safer re-stow script. It creates symlinks for tracked files that are not
  already exposed in `~/.config/` or `~/.local/share/applications/`.

If you already have a working Hyprkarl setup and only need to expose newly
added files, use `scripts/add-dotfiles.sh`, not `setup-dotfiles.sh`.

## Editing Hyprkarl

If you plan to customize Hyprkarl, make a branch first and edit the files in
`~/.local/share/hyprkarl/`.

For editing guidance, see:

- [Configuration Map](configuration-map.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
- [Repo Conventions](reference/repo-conventions.md)
- [Shell Style](shell-style.md)

## Updating

If you have customized Hyprkarl, update it like a normal git branch and then
decide which setup steps you actually need to re-run.

Before bringing in upstream changes:

- keep your own changes on a branch
- commit or stash your work first, especially changes under `config/` and
  `applications/`
- fetch upstream changes and review them before merging

Example:

```bash
cd ~/.local/share/hyprkarl
git fetch origin
git diff --stat HEAD..origin/main
git merge origin/main
```

After merging upstream changes:

- run `setup-packages.sh` if upstream changed package requirements
- run `setup-system.sh` if upstream changed system-level setup behavior and you
  want those defaults applied
- run `scripts/add-dotfiles.sh` if upstream added new tracked files under
  `config/` or `applications/` and there are no overlapping live files
- run `setup-dotfiles.sh` if you need to replace overlapping live files with
  symlinks to Hyprkarl

`setup-all.sh` runs all three setup steps and is the most complete update
command, but also the most dangerous:

- `setup-packages.sh` can install new packages and remove `wofi` and `dolphin`
- `setup-system.sh` reapplies Hyprkarl's system defaults
- `setup-dotfiles.sh` can replace overlapping live files and then resets the
  tracked `config/` and `applications/` trees to the current git checkout

That last point is the main risk: if you have uncommitted changes under
`config/` or `applications/` in `~/.local/share/hyprkarl`, `setup-dotfiles.sh`
can overwrite them. Commit those changes first if you want to keep them.

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
