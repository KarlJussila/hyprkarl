---
name: hyprkarl
description: >
  Use for any change to this Hyprkarl desktop (CachyOS + Hyprland) on the
  user's behalf: Hyprland settings, keybindings, monitors, autostart, the bar,
  menus, notifications, lock and idle, themes, wallpapers, terminals, default
  applications, environment variables, packages, or files under ~/.config/hypr,
  ~/.config/quickshell, ~/.config/hyprkarl, or ~/.config/uwsm. Read it before
  editing any config on this system. Not for developing Hyprkarl itself; for
  that, follow AGENTS.md in the checkout.
---

# Customizing a Hyprkarl system

Hyprkarl is a complete desktop installed as a Git checkout at
`$HYPRKARL_PATH` (`~/.local/share/hyprkarl`). It keeps its defaults updating
by splitting every configuration into Hyprkarl's files, which updates replace,
and the user's files, which nothing touches. Your job is to make each change in
the user's file that exists for it. A change made anywhere else is lost on the
next update, blocks the update, or silently stops Hyprkarl's defaults from
reaching the user.

Many habits that are normal on other Linux systems are wrong here. Read the
list below before changing anything.

## First, check who owns the file

Many files in `~/.config` are symlinks into the checkout. Before editing any
file, check:

```bash
readlink -f ~/.config/path/to/file
```

If it resolves into `~/.local/share/hyprkarl/`, it is Hyprkarl's: do not edit,
replace, or delete it. Find the personal file that overrides it instead (below).
Never edit anything under `$HYPRKARL_PATH`, never commit or pull there, and
never edit files under `~/.local/state/hyprkarl/`, which are generated.

## Where each change goes

| Change | Where |
|---|---|
| Hyprland: settings, keybindings, window rules, monitors, input, autostart | `~/.config/hypr/hyprland.local.lua`, which loads last and wins; monitors also through the display panel |
| Idle timeouts, screen-off, suspend | `~/.config/hypr/hypridle.local.conf`, by redefining the variables at the top of `~/.config/hypr/hypridle.conf` |
| Night light schedule, wallpaper daemon | `~/.config/hypr/hyprsunset.local.conf`, `hyprpaper.local.conf` |
| Terminal settings | `~/.config/<terminal>/local.toml`, `local.ini`, or `local.conf` |
| Bar layout, widgets, notifications, OSD, launcher | `~/.config/quickshell/settings/shell.json`, only the keys that change |
| Menu entries | `~/.config/quickshell/settings/menu.json`, only the entries that change |
| New bar widgets or interfaces, replacing a built-in | QML under `~/.config/quickshell/custom/` |
| Colors, fonts, icons, cursor, GTK and Qt look, wallpapers | A personal theme or overlay in `~/.config/hyprkarl/themes/<name>/`, then `hk-theme set <name>` |
| Session environment variables | `~/.config/uwsm/env.local` |
| Something to run on login, update, theme or wallpaper change | An executable in `~/.config/hyprkarl/hooks/<event>.d/` |
| Personal scripts | `~/.local/bin/`, which is on `PATH` before Hyprkarl's commands |
| btop, fastfetch, Neovim, Yazi | Their own `~/.config/<app>/`; these are the user's copies |

`$HYPRKARL_PATH/docs/configuration-map.md` lists every location, and
`$HYPRKARL_PATH/docs/extending-hyprkarl.md` explains each one.

## Habits that are wrong here

- **Do not edit `~/.config/hypr/hyprland.lua`** or create
  `~/.config/hypr/hyprland.conf`. Hyprland is configured in Lua, and Hyprland
  ignores a `.conf` file. Everything personal goes in `hyprland.local.lua`. To
  change a shipped keybinding, `hl.unbind()` it first; list the live bindings
  with `hk-keybindings-list`. Autostart goes in an
  `hl.on("hyprland.start", ...)` block there, launching apps with
  `uwsm app -- <command>`, not in `~/.config/autostart/` or a new systemd unit.
- **Do not copy a shipped file to change part of it.** Personal files hold only
  what differs; Hyprkarl's defaults keep flowing to everything you leave out.
  In `shell.json`, objects merge but arrays replace, so copy one bar section
  from `$HYPRKARL_PATH/defaults/shell.json` only when changing that section.
- **Do not set environment variables** in `~/.bashrc`, `~/.profile`,
  `~/.zshrc`, `~/.config/environment.d/`, or `/etc/environment`. Session
  variables go in `~/.config/uwsm/env.local` and take effect at the next login.
  Shell startup files are only for variables a shell alone needs.
- **Do not theme applications directly.** No edits to GTK CSS, `qt6ct.conf`,
  `gsettings` themes, `~/.icons/default`, or Kvantum or nwg-look, and no new
  theme engines. Hyprkarl's theme writes all of these; change them through a
  personal theme and `hk-theme set`. A personal overlay needs only the values
  that change; see `$HYPRKARL_PATH/docs/themes.md`.
- **Replace a built-in through Hyprkarl, not around it.** The user may want
  a different bar, launcher, notifier, locker, or idle daemon. Switch
  Hyprkarl's off and take over the `hk-*` commands that reach it, as described
  under "Replace a built-in" in `$HYPRKARL_PATH/docs/extending-hyprkarl.md`, so
  keybindings, menus, and the bar keep working. Running a second one beside
  Hyprkarl's leaves both fighting over the same job.
- **Do not add packages to Hyprkarl's lists.** Install with
  `hk-pkg install [--aur|--flatpak] <package>`; Hyprkarl does not track
  personal packages. Do not remove packages Hyprkarl requires
  (`$HYPRKARL_PATH/packages/pacman.txt` and `aur.txt`).
- **Do not update Hyprkarl with Git.** Updates are `hk-update all`, which the
  user runs in a terminal because it asks questions. System packages are
  `hk-pkg-upgrade`.
- **Do not change `/etc` or anything that needs root** to customize the
  desktop. Almost everything has a user-level place above. If something really
  needs root, explain it and let the user run the command.
- **To change what an `hk-*` command does,** put a script with the same name
  in `~/.local/bin/`, which shadows Hyprkarl's. Do not edit the original.

## Finding things

- Commands: `$HYPRKARL_PATH/docs/commands.md`. Grouped commands such as
  `hk-theme` and `hk-shell` print their usage with `--help`; every command is
  readable source: `cat "$(command -v hk-theme-set)"`. Read a command before
  running it; some act immediately with no arguments.
- Shipped defaults to read before overriding:
  `$HYPRKARL_PATH/defaults/hypr/` (Hyprland), `defaults/shell.json`,
  `defaults/menu.json`, `theme-generator/defaults/theme.yaml` (every theme
  value).
- What each setting does: `docs/shell-configuration.md`,
  `docs/menu-configuration.md`, `docs/themes.md`.
- Installed version: `hk-version`. Problems: `docs/troubleshooting.md`.
