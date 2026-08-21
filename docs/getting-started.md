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
  Bootstraps the update command's package dependencies, then runs the same
  one-time removal review and required-package installation used by
  `hk-update packages`.
- `setup-dotfiles.sh`
  Configures the default source remote and branch, then runs the same apply
  path used after an update. That path migrates personal configuration, uses
  GNU Stow to expose shipped entry points and desktop files, builds the selected
  theme and GTK payload, and reloads affected applications. Application configs
  intended for personal editing are copied once as real files. Existing real
  files and user-authored directory symlinks are left alone unless they occupy
  a required Stow entry point, in which case setup stops and lists them.
- `setup-system.sh`
  Runs pending one-time system migrations. These configure SDDM autologin,
  logind lid handling, sudo and faillock settings, LocalSend firewall rules,
  and Docker without rerunning completed migrations on later updates.

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
`~/.local/share/hyprkarl/`. Automatic source sync is for the clean released
branch; maintain a custom branch with Git and use `hk-update apply` afterward.

For editing guidance, see:

- [Configuration Map](configuration-map.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
- [Repo Conventions](repo-conventions.md)
- [Command Script Style](shell-style.md)

## Updating

After initial setup, use `hk-update` to review and apply changes from upstream.
The review step pins one exact fetched revision without changing the live
checkout.

```bash
hk-update all
```

`hk-update all` runs the complete sequence. You can also stop between steps or
run one category yourself:

```bash
hk-update sync          # fetch, review, and pin an exact source revision
hk-update apply         # advance to that revision and apply configuration
hk-update packages      # review removals once and install requirements
hk-update system        # run pending one-time system migrations
hk-update check         # report pending work without changing it
hk-update remove-stale  # remove broken links into the checkout only
```

See [Updating](updating.md) for source configuration, custom-branch handling,
package review, and recovery details.

## Changes That Need a New Session

Some changes do not take effect immediately:

- `~/.config/uwsm/default` changes affect new sessions
- `hk-default-shell` changes affect the next login
- Docker group changes made by its system migration require a new login or reboot
- most other changes can be reloaded live

## Where to Go Next

- [Using Hyprkarl](using-hyprkarl.md) for daily workflows
- [Configuration Map](configuration-map.md) for repo layout
- [Extending Hyprkarl](extending-hyprkarl.md) for adding your own behavior
