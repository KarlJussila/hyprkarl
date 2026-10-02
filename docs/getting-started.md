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
./install.sh
```

`install.sh` checks that it runs as your normal user on a pacman system from
`~/.local/share/hyprkarl`, removes CachyOS's Noctalia shell if present,
installs the few tools the updater needs, and then runs the same
`hk-update apply` that every update uses. That installs the required packages,
runs the one-time migrations (SDDM autologin, lid handling, sudo and faillock
settings, LocalSend firewall rules, Docker), copies starting configs, links the
shipped entry points, builds the theme, and reloads what is running. If a real
file sits where Hyprkarl needs a link, it stops and lists it. Rerunning the
installer is safe.

To leave Hyprkarl, `uninstall.sh` removes every config symlink and prints the
user-owned configs, packages, and system settings it leaves in place for you
to remove or undo manually.

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

## Personalizing Hyprkarl

Use the personal paths in [Configuration Map](configuration-map.md) for
application preferences, Quickshell settings, and Hyprland configuration.
[Extending Hyprkarl](extending-hyprkarl.md) covers adding personal scripts,
hooks, menus, keybindings, and QML. These changes need no Git branch.

To change shipped code or defaults in `~/.local/share/hyprkarl/`, see
[Repo conventions](repo-conventions.md). Automatic source sync is for the
clean released branch; maintain a custom branch with Git and use
`hk-update apply` afterward.

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
hk-update sync          # fetch and review incoming changes
hk-update apply         # apply them: packages, migrations, configuration, theme
hk-update packages      # review removals once and install requirements
hk-update check         # report pending work without changing it
hk-update remove-stale  # remove broken links into the checkout only
```

See [Updating](updating.md) for source configuration, custom-branch handling,
package review, and recovery details.

## Changes That Need a New Session

Some changes do not take effect immediately:

- `~/.config/uwsm/env.local` changes and `hk-default-editor` affect new sessions
- `hk-default-shell` changes affect the next login
- Docker group changes made by its migration require a new login or reboot
- most other changes can be reloaded live

## Where to Go Next

- [Using Hyprkarl](using-hyprkarl.md) for daily workflows
- [Configuration Map](configuration-map.md) for repo layout
- [Extending Hyprkarl](extending-hyprkarl.md) for adding your own behavior
