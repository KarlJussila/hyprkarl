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
- use `scripts/add-dotfiles.sh` when you only need to expose new tracked files
- keep your own changes on a git branch in `~/.local/share/hyprkarl`

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

- `config/hyprkarl/current/wallpaper` points at a missing file
- the wallpaper cache is stale
- the active theme has no wallpapers

What to do:

```bash
hk-wallpaper init || hk-wallpaper cycle
hk-wallpaper cache --regenerate
```

Then inspect:

- `config/hyprkarl/current/wallpaper`
- `config/hyprkarl/current/theme/wallpapers/`

## Bar Does Not Start or Looks Wrong

Symptoms:

- the bar does not appear
- a widget is missing or showing unexpected content
- styling looks wrong after a theme switch

Cause:

- a TypeScript error in `config/ags/bar/config/widgets.config.ts` or
  `config/ags/bar/config/layout.config.ts`
- a CSS error in the active theme's `bar.scss`
- AGS is not running

What to do:

- check the AGS log for errors: `journalctl --user -u app-ags@bar.service -e`
- restart the bar:

```bash
hk-ags-restart
```

- if a widget config change caused the problem, restore the previous value and
  restart again

## Docker Is Not Ready

Symptoms:

- `hk-docker install ...` or `hk-docker uninstall ...` refuses to
  run

Cause:

- the current session is not yet in the `docker` group
- `docker.service` is not reachable

What to do:

- log out and back in, or reboot, after `hk-docker setup`
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
./scripts/add-dotfiles.sh
```

If that fails because the target path already exists, decide whether you want to
keep that live file or replace it with a symlink to Hyprkarl.

`setup-dotfiles.sh` is the stronger tool, but it has a different risk: it can
replace overlapping live files, and it resets `config/` and `applications/` in
`~/.local/share/hyprkarl` to the current git checkout. Commit any changes you
want to keep under those trees before running it.

## Related Docs

- [Getting Started](getting-started.md)
- [Configuration Map](configuration-map.md)
- [Command Reference](reference/commands.md)
