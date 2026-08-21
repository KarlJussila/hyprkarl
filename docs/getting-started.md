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

`setup-all.sh` runs three scripts in order, stopping at the first failure:

- `setup-packages.sh`
  Installs the packages Hyprkarl expects.
- `setup-dotfiles.sh`
  Runs the personal-config migrations, then uses GNU Stow to expose stable
  shipped entry points under `~/.config/` and desktop files under
  `~/.local/share/applications/`. Application configs that Hyprkarl expects
  users to edit are copied once as real files instead of being stowed. Existing
  real files and user-authored directory symlinks are left alone.
  On re-runs it refuses to proceed while the repo has uncommitted `config/` or
  `applications/` changes, since the stow step resets those paths to HEAD —
  commit (or discard) first.
  Before it restows, `hk-user-migrate` moves retired checkout-local personal
  configuration to `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`, materializes
  old Hyprkarl-owned application links, and seeds missing application configs
  and terminal override files. That seed migration runs once; a later update
  does not recreate a file you removed.
- `setup-system.sh`
  Applies system-level settings such as GTK defaults, SDDM autologin, logind
  lid handling, sudo and faillock settings, and LocalSend firewall rules.

To leave Hyprkarl, `uninstall.sh` removes every config symlink (reversing
`setup-dotfiles.sh`) and prints the user-owned configs, packages, and system
settings it leaves in place for you to remove or undo manually.

## Understand the Symlink Model

Hyprkarl is edited from `~/.local/share/hyprkarl/`.

Stable shipped entry points under `~/.config/` and files under
`~/.local/share/applications/` are symlinks back into that tree, so tracked
Hyprkarl implementation files remain live. For example,
`~/.config/hypr/hyprland.lua` points at the stable bootstrap in this checkout.
Ordinary Hyprland personalization belongs in
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/`, not in that bootstrap or
the shipped modules under `defaults/hypr/`.

Most application preferences are real files in the application's normal
configuration directory. Terminal bootstraps remain linked to Hyprkarl but
load `local.*` sidecars last. The application ownership table in
[Configuration Map](configuration-map.md#application-configuration) names the
editable path for every managed application.

## Editing Hyprkarl

Personalize Hyprkarl through `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`.
Create a fork branch only when changing shipped code or defaults in
`~/.local/share/hyprkarl/`.

For editing guidance, see:

- [Configuration Map](configuration-map.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
- [Repo Conventions](repo-conventions.md)
- [Command Script Style](shell-style.md)

## Updating

After initial setup, use `hk-update` to apply changes from upstream. It tracks
which commit each category was last applied at, so it only acts when something
has actually changed.

```bash
cd ~/.local/share/hyprkarl
git fetch origin
git merge origin/main
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

- `~/.config/uwsm/default` changes affect new sessions
- `hk-default-shell` changes affect the next login
- Docker group changes made by `setup-system.sh` require a new login or reboot
- most other changes can be reloaded live

## Where to Go Next

- [Using Hyprkarl](using-hyprkarl.md) for daily workflows
- [Configuration Map](configuration-map.md) for repo layout
- [Extending Hyprkarl](extending-hyprkarl.md) for adding your own behavior
