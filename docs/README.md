# Hyprkarl Manual

Hyprkarl keeps shipped configuration live from its checkout while personal
settings live in the standard XDG configuration directories. This manual
covers setup, daily use, repo layout, and customization.

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
  ownership and the current-runtime lock-screen deferral.

## Common Tasks

- Switch themes or build a new one:
  [Themes](themes.md)
- Change wallpapers:
  [Using Hyprkarl (Wallpapers)](using-hyprkarl.md#wallpapers) and [Themes](themes.md)
- Reorder widgets or restyle the bar:
  [Customizing the Bar](customizing-bar.md)
- Change default terminal, editor, or shell:
  [Using Hyprkarl](using-hyprkarl.md#defaults-terminal-editor-shell)
- Add a command, menu action, keybinding, or theme-aware config:
  [Extending Hyprkarl](extending-hyprkarl.md)
- Customize the command menu:
  [Menu Configuration](menu-configuration.md)
- Look up the main `hk-*` commands:
  [Command Reference](commands.md)
- Troubleshooting issues:
  [Troubleshooting](troubleshooting.md)

## Reference

- [Getting Started](getting-started.md)
- [Updating](updating.md)
- [Using Hyprkarl](using-hyprkarl.md)
- [Configuration Map](configuration-map.md)
- [Themes](themes.md)
- [Customizing the Bar](customizing-bar.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
- [Troubleshooting](troubleshooting.md)
- [Command Reference](commands.md)
- [Repo Conventions](repo-conventions.md)
- [Command Script Style](shell-style.md)
- [Shell Configuration](shell-configuration.md)
- [Menu Configuration](menu-configuration.md)
- [Authentication Surfaces](authentication-surfaces.md)
