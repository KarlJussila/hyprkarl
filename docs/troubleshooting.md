# Troubleshooting

This page covers common Hyprkarl setup and runtime problems.

## Configuration apply reports unmanaged paths

Symptoms:

- `install.sh` or `hk-update apply` stops before restowing
- the error lists paths under `~/.config/` or
  `~/.local/share/applications/`

Cause:

- a real file or unrelated link occupies a path reserved for a shipped
  Hyprkarl entry point

What to do:

- inspect every listed path and decide whether to keep or move it
- put ordinary preferences in the documented user-owned application paths or
  under `~/.config/hyprkarl/`
- after resolving the overlap, run `hk-update apply` again

Hyprkarl does not adopt or overwrite these paths. The owner decides how to
resolve the overlap.

## A Change Did Not Take Effect

Symptoms:

- you changed a Hyprkarl setting, but the old behavior is still active

Cause:

- some settings are only read when a session, service, or app starts

What to do:

- if you changed `~/.config/uwsm/default`, restart the graphical session
- if you changed the default shell, log out and log back in
- if you changed Docker group membership, log in again or reboot
- otherwise, restart or reload the affected app or service
- when in doubt, reboot

## Theme Looks Broken After Switching

Symptoms:

- one or more apps look wrong after switching themes

Cause:

- the selected source or an override fails to render or validate
- generated CSS or application configuration is valid but looks wrong
- the affected app has not reloaded yet

What to do:

- run `hk-theme set <theme-name>` and read the compiler error
- compare personal values and overrides with a working source such as
  `themes/hyprkarl/`
- inspect the active build through `~/.local/state/hyprkarl/current/theme/`
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

- `${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/current/wallpaper`
- `${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/current/theme/wallpapers/`

## Bar Does Not Start or Looks Wrong

Symptoms:

- the bar does not appear
- a widget is missing or showing unexpected content
- styling looks wrong after a theme switch

Cause:

- invalid JSON in `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/settings/shell.json`
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
instance and run `qs -p ~/.config/quickshell` in a terminal.
If a user override caused the problem, correct it or remove
`${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/settings/shell.json`. A file that does not parse leaves the
shipped defaults running and logs the error.

## Privilege Prompt Does Not Appear

Hyprkarl's running Quickshell process owns the session polkit agent. Check
`hk-shell status` and the shell log for `Polkit agent registered: true`. If an
older installation still has the replaced agent active, disable it and restart
the shell:

```bash
systemctl --user disable --now hyprpolkitagent.service
hk-shell restart
```

The normal `hk-update` package-removal step removes the old package. Do not run
both agents together; only one can register for the session.

## Docker Is Not Ready

Symptoms:

- `hk-docker install ...` or `hk-docker uninstall ...` refuses to
  run

Cause:

- the current session is not yet in the `docker` group
- `docker.service` is not reachable

What to do:

- log out and back in, or reboot, after the Docker migration changes
  group membership
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
hk-update apply
```

If that fails because the target path already exists, decide whether you want to
keep that live file or replace it with a symlink to Hyprkarl. Hyprkarl will not
adopt or overwrite it. Move or rename the file yourself, then run
`hk-update apply` again.

## Related Docs

- [Getting Started](getting-started.md)
- [Configuration Map](configuration-map.md)
- [Command Reference](commands.md)
