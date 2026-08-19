# Troubleshooting

This page covers common Hyprkarl setup and runtime problems.

## `setup-dotfiles.sh` Replaced Existing Config Files

Symptoms:

- a first install replaced config you expected to keep
- files under `~/.config/` or `~/.local/share/applications/` now point at
  Hyprkarl

Cause:

- `setup-dotfiles.sh` is the aggressive dotfile setup script. It uses GNU Stow
  to replace live files with symlinks to Hyprkarl's tracked `config/` and
  `applications/` files.

What to do:

- treat `setup-dotfiles.sh` as a first-install tool
- use `hk-update dotfiles` when you only need to expose new tracked files
- keep your own changes on a git branch in `~/.local/share/hyprkarl`

Note that your *committed* changes are safe: re-running `setup-dotfiles.sh`
refuses to proceed while `config/` or `applications/` have uncommitted
changes, because its stow step resets those paths to HEAD.

## A Change Did Not Take Effect

Symptoms:

- you changed a Hyprkarl setting, but the old behavior is still active

Cause:

- some settings are only read when a session, service, or app starts

What to do:

- if you changed `config/uwsm/default`, restart the graphical session
- if you changed the default shell, log out and log back in
- if you changed Docker group membership, log in again or reboot
- otherwise, restart or reload the affected app or service
- when in doubt, reboot

## Theme Looks Broken After Switching

Symptoms:

- one or more apps look wrong after switching themes

Cause:

- the selected theme is missing a file Hyprkarl expects
- a theme file contains invalid config, CSS, or theme data
- the affected app has not reloaded yet

What to do:

- compare the theme against a working theme such as `themes/hyprkarl/`
- check that the expected theme files exist
- inspect the specific theme file used by the app that looks wrong
- run `hk-theme set <theme-name>` again
- if needed, restart the affected app

## Wallpaper State Looks Wrong

Symptoms:

- no wallpapers appear
- thumbnails are stale
- the wrong wallpaper is active

Cause:

- the XDG-state `current/wallpaper` points at a missing runtime wallpaper
- the wallpaper cache is stale
- the active theme has no wallpapers

What to do:

```bash
hk-wallpaper init || hk-wallpaper cycle
hk-wallpaper cache --regenerate
```

Then inspect:

- `${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/current/`
- `config/hyprkarl/current/wallpaper`
- `config/hyprkarl/current/theme/wallpapers/`

## Bar Does Not Start or Looks Wrong

Symptoms:

- the bar does not appear
- a widget is missing or showing unexpected content
- styling looks wrong after a theme switch

Cause:

- invalid JSON in `user/shell.json`
- invalid theme data in the active theme's `quickshell.json`
- a QML load error or stopped Quickshell instance

What to do:

- inspect the managed instance and its logs:

```bash
hk-shell status
hk-shell logs --tail 100 --no-color
hk-shell restart
```

`hk-shell start` prints a QML load error when Quickshell fails before
registering the instance. For foreground development, stop the managed
instance and run `qs -p "$HYPRKARL_PATH/config/quickshell"` in a terminal.
If a user override caused the problem, correct it or remove
`user/shell.json`; the shell otherwise retains its last valid
configuration during a live edit.

## Docker Is Not Ready

Symptoms:

- `hk-docker install ...` or `hk-docker uninstall ...` refuses to
  run

Cause:

- the current session is not yet in the `docker` group
- `docker.service` is not reachable

What to do:

- log out and back in, or reboot, after `setup-system.sh` changes Docker group
  membership
- confirm that `id -nG "$USER"` includes `docker`
- confirm that `docker ps` prints a container table, even if it is empty

## Battery or Brightness Helpers Fail

Symptoms:

- battery notifications do nothing
- the battery display in the bar does not work
- brightness commands fail or show no change

Cause:

- the expected battery or backlight device does not exist under `/sys`

What to do:

- check `/sys/class/power_supply/` for a battery device such as `BAT0`
- check `/sys/class/backlight/` for a display backlight device
- check `/sys/class/leds/` for a keyboard backlight device

## Notifications Do Not Appear

Check that the production shell is running and owns the desktop notification
service:

```bash
hk-shell status
hk-shell logs --tail 100 --no-color
busctl --user status org.freedesktop.Notifications
```

Only one process can own `org.freedesktop.Notifications`. Stop an independently
started notification daemon if the log reports that the name is already
registered, then restart the shell. Hyprkarl no longer starts or configures
Mako. If only one application's notifications are absent, inspect
`notifications.ignoredApplications` in the effective shell configuration.

## A New Tracked Config File Is Not Exposed

Symptoms:

- you added a new tracked file under `config/` or `applications/`, but Hyprkarl
  is still behaving as if that file does not exist
- the file also does not appear under `~/.config/` or
  `~/.local/share/applications/`

Cause:

- the symlink has not been created yet
- or a real file already exists at the target path

What to do:

```bash
hk-update dotfiles
```

If that fails because the target path already exists, decide whether you want to
keep that live file or replace it with a symlink to Hyprkarl. Use
`hk-update dotfiles --adopt` to pull the conflicting file into the repo for
review, or `hk-update dotfiles --force` to overwrite it with the repo version.

## Related Docs

- [Getting Started](getting-started.md)
- [Configuration Map](configuration-map.md)
- [Command Reference](commands.md)
