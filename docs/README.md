# Hyprkarl Manual

Hyprkarl keeps shipped configuration live from its checkout while personal
settings live in the standard XDG configuration directories. This manual
covers setup, daily use, and personal customization. Contributor guides are
listed separately below.

The expected setup is a single-user CachyOS + Hyprland + UWSM system, with the
repo checked out at `~/.local/share/hyprkarl/`.

## Start Here

- Read [Getting Started](getting-started.md) for installation and the symlink
  model.
- Read [Updating](updating.md) for source review, configuration application,
  package review, and system migrations.
- Read [Using Hyprkarl](using-hyprkarl.md) for the standard workflow: menus,
  keybindings, themes, wallpapers, defaults, and utilities.
- Read [Configuration Map](configuration-map.md) if you need to know where a
  change belongs before you touch anything.
- Read [Shell Configuration](shell-configuration.md) for the public JSON and
  runtime-state ownership contracts.
- Read [Menu Configuration](menu-configuration.md) to add, reorder, rename, or
  hide entries in the shell-native command menu.
- Read [Authentication Surfaces](authentication-surfaces.md) for polkit
  ownership, the separate Quickshell locker, and personal PAM configuration.

## Common Tasks

- Switch themes or build a new one:
  [Themes](themes.md)
- Change wallpapers:
  [Using Hyprkarl (Wallpapers)](using-hyprkarl.md#wallpapers) and [Themes](themes.md)
- Reorder widgets or restyle the bar:
  [Customizing the Bar](customizing-bar.md)
- Change default terminal, editor, or shell:
  [Using Hyprkarl](using-hyprkarl.md#defaults-terminal-editor-shell)
- Add personal scripts, hooks, menu actions, keybindings, or QML:
  [Extending Hyprkarl](extending-hyprkarl.md)
- Customize the command menu:
  [Menu Configuration](menu-configuration.md)
- Look up the main `hk-*` commands:
  [Command Reference](commands.md)
- Troubleshooting issues:
  [Troubleshooting](troubleshooting.md)

## User reference

- [Getting Started](getting-started.md)
- [Updating](updating.md)
- [Using Hyprkarl](using-hyprkarl.md)
- [Configuration Map](configuration-map.md)
- [Themes](themes.md)
- [Customizing the Bar](customizing-bar.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
- [Troubleshooting](troubleshooting.md)
- [Command Reference](commands.md)
- [Shell Configuration](shell-configuration.md)
- [Menu Configuration](menu-configuration.md)
- [Authentication Surfaces](authentication-surfaces.md)

## Contributor guides

For changes to the shipped code and defaults in the checkout:

- [Repo conventions](repo-conventions.md): ownership, Stow, branches, and releases
- [Command script style](shell-style.md): authoring shipped `hk-*` commands
- [Quickshell project guide](../config/quickshell/README.md): code structure,
  built-in widgets, and checks
- [Theme compiler guide](../theme-generator/README.md): templates, rendering,
  and compiler development
- [Tests](../tests/README.md): focused checks and acceptance harnesses
