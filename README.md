# Hyprkarl
Hyprkarl is a desktop configuration repo for CachyOS + Hyprland, inspired by
Omarchy. It supplies a complete default system while keeping ordinary personal
configuration outside the checkout.

> **Warning:** The fresh-install path (`setup-*.sh` on a new machine) is
> largely untested — the running system it produces is daily-driven, but the
> first-run setup itself is not. Review the scripts before running them, and
> use at your own risk.

## Screenshots

<table>
  <tr>
    <td><img src="themes/hyprkarl/previews/busy.png" alt="Busy desktop"/><br/><sub>Busy desktop</sub></td>
    <td><img src="themes/hyprkarl/previews/launcher.png" alt="App launcher"/><br/><sub>App launcher</sub></td>
  </tr>
  <tr>
    <td><img src="themes/hyprkarl/previews/menu.png" alt="Hyprkarl menu"/><br/><sub>Hyprkarl menu</sub></td>
    <td><img src="themes/hyprkarl/previews/wallpapers.png" alt="Wallpaper picker"/><br/><sub>Wallpaper picker</sub></td>
  </tr>
</table>

## Requirements

- Base CachyOS (Hyprland) install
- Single-user. Hyprkarl does not try to support multi-user setups.
- Btrfs filesystem (with LUKS encryption) and Limine boot loader are strongly recommended. Hyprkarl may implement changes involving either one in the future.
- Hyprland must be running under UWSM (this is the default on CachyOS). SDDM autologin is configured to launch `hyprland-uwsm.desktop`.

## Warnings

- The SDDM system migration enables autologin. The intention is to rely on LUKS encryption for boot authentication instead of requiring two passwords. If you prefer not to use autologin, disable it manually afterward.
- Multi-user setups are not supported. You're on your own if you need one.

## Installation

Clone into `~/.local/share/` and run the setup script:

```bash
git clone --depth=1 https://github.com/KarlJussila/hyprkarl.git ~/.local/share/hyprkarl
cd ~/.local/share/hyprkarl
./setup-all.sh
```

> **Note:** CachyOS's Hyprland edition now ships the Noctalia shell
> (`cachyos-hypr-noctalia`) by default, which conflicts with hyprkarl.
> `setup-all.sh` runs `setup-purge-noctalia.sh` first to remove it — it will
> ask for confirmation and is a no-op if Noctalia isn't installed.

> **Warning:** If you already have configs you care about in `~/.config/` or
> `~/.local/share/applications/`, back them up first. The initial setup keeps
> existing user-owned application configs where possible, but shipped entry
> points and desktop files may still overlap paths you use.

## Uninstalling

```bash
~/.local/share/hyprkarl/uninstall.sh
```

Removes all of Hyprkarl's config symlinks (reversing `setup-dotfiles.sh`).
User-owned application configs, installed packages, and completed system
migration changes are left in place; the script lists what you may want to
remove or undo manually.

## After Installation

Hyprkarl's shipped defaults, entry points, and scripts live in
`~/.local/share/hyprkarl/`. Stable entry points are symlinks back into that
tree; application preference files are real files in their normal
`~/.config/<application>/` locations and are never overwritten after their
initial migration. Personal Hyprkarl configuration lives under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`; normal personal commands belong
in `~/.local/bin/`.

A few things worth knowing:

- no Git branch is needed for ordinary personalization
- use a fork branch only when changing Hyprkarl's shipped implementation
- user environment variables and session defaults live in `~/.config/uwsm/`
  and require a new session to take effect

## Documentation

The full manual lives under `docs/`.

- [docs/README.md](docs/README.md)
  Manual index
- [docs/getting-started.md](docs/getting-started.md)
  Installation, symlink model, updating, and restart boundaries
- [docs/using-hyprkarl.md](docs/using-hyprkarl.md)
  Daily workflow: menus, keybindings, themes, wallpapers, defaults, and
  utilities
- [docs/configuration-map.md](docs/configuration-map.md)
  Repo layout and main editing surfaces
- [docs/themes.md](docs/themes.md)
  Theme structure, wallpaper layout, and theme switching
- [docs/customizing-bar.md](docs/customizing-bar.md)
  Bar widget layout, styling, and runtime control
- [docs/extending-hyprkarl.md](docs/extending-hyprkarl.md)
  Personal scripts, hooks, menus, keybindings, and Quickshell interfaces
- [docs/troubleshooting.md](docs/troubleshooting.md)
  Common setup and runtime failures
- [docs/commands.md](docs/commands.md)
  Command reference
- [docs/repo-conventions.md](docs/repo-conventions.md)
  Contributor conventions, stowed-config model, branches, and releases
- [docs/shell-style.md](docs/shell-style.md)
  Hyprkarl's Bash/Python command scripting style
- [docs/shell-configuration.md](docs/shell-configuration.md)
  Shell JSON, extension lanes, and runtime-state ownership
- [docs/menu-configuration.md](docs/menu-configuration.md)
  Shell-native menu entries, user overrides, Python dynamic providers, and
  direct menu commands
- [docs/authentication-surfaces.md](docs/authentication-surfaces.md)
  Polkit ownership and the separate Quickshell lock screen

## Themes

Shipped themes live under `themes/`; personal themes and overlays live under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/`. Selecting a theme builds
it under `${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl`, so switching never
edits tracked files, and Quickshell picks up the switch without restarting. Built-ins are authored as typed `theme.yaml`
graphs whose strings, numbers, booleans, shared defaults, and arbitrary custom
structures can feed stable consumer values. The semantic `quickshell.json`
controls island corner shapes,
selective borders, and screen/outer/content margins as well as colors and
typography. It also provides the minimum height and widget padding; the tallest
widget determines one shared height for all islands. Inspect or manage the bar
with `hk-shell status`, `hk-shell logs`, and the other `hk-shell` lifecycle
commands. Volume, audio-output, microphone, display/keyboard brightness, and
media-key feedback use the same shell through a focused-monitor, click-through
OSD. The shell also owns desktop notifications, including focused-monitor
routing, progress, silence mode, one-item restore, bar-connected geometry, and
data-defined application icon overrides with user QML drawings; Mako is no
longer part of the session. Polkit privilege requests also use a focused,
theme-aware Quickshell prompt; the separate `hyprpolkitagent` process is no
longer part of the session. Session locking uses the Quickshell lock feature,
launched by `hk-lock`, with password authentication and automatically detected
fingerprint authentication.
The locker shares the active theme and survives desktop-shell restarts. The
display panel opens a staged submenu for each
output with enablement, resolution, refresh rate, and scale controls. Resolution
and refresh rate use separate pickers, and the latter lists only rates supported
at the selected resolution. Those changes
use a ten-second keep-or-revert confirmation on the panel's display when
possible. Internal backlight brightness remains immediate. A global
drag-to-arrange modal changes positions and rotates a frame clockwise on
right-click, rejecting overlaps before applying directly through the persistent
`hk-display` backend; explicit personal Hyprland monitor rules still have the
final say. Personal command widgets can add bar readouts
without editing QML using one application-wide polling or persistent-stream
provider per widget ID. Static command buttons such as the main-menu trigger
use the same kind without starting a timer or process. More specialized
personal bar widgets can be explicitly loaded from
`${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/custom/modules/` through a small per-bar context, without turning the
shell into a plugin platform. The built-in bar can also be disabled while the
other built-in modules remain independently selectable through the nine
top-level `modules` switches in shell JSON. Restart the shell after changing a
switch. One explicitly referenced application-wide user QML root under
`${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/custom/` can compose replacement surfaces, consume open-ended theme data,
observe and control overlay requests, and publish reactive notification
positioning for a custom bar. The public `ui.modal.Modal` QML component lets
that root add shell-styled, lazy-content modals without registering a plugin.
The app launcher, open-with chooser, calculator, and wallpaper picker are also
Quickshell-native. They share the shell's focused-overlay frame and interaction
model while keeping application, calculation, and wallpaper behavior in small
feature-owned implementations. Open-with can optionally set the selected
application as the MIME default before launching the file.

Switch themes from `Hyprkarl Menu -> Config -> Theme` or with:

```bash
hk-theme set <theme-name>
```

To create your own theme, add a source directory under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/`. A new theme needs
`theme.yaml`; a same-name overlay may contain only sparse values, template
overrides, or assets. `hk-theme set` builds, validates, and activates it. See
[docs/themes.md](docs/themes.md) for the source layout and merge order.

Provided themes:

`hyprkarl`, `everforest`, `gruvbox`, `loam`, and `tokyo-night`. Tokyo Night
uses the original dark Night variant. Loam pairs warm brown surfaces with
olive-moss highlights and restrained ochre accents.

<details>
<summary>hyprkarl</summary>

<table>
  <tr>
    <td><img src="themes/hyprkarl/previews/busy.png" alt="Busy desktop"/><br/><sub>Busy desktop</sub></td>
    <td><img src="themes/hyprkarl/previews/launcher.png" alt="App launcher"/><br/><sub>App launcher</sub></td>
  </tr>
  <tr>
    <td><img src="themes/hyprkarl/previews/menu.png" alt="Hyprkarl menu"/><br/><sub>Hyprkarl menu</sub></td>
    <td><img src="themes/hyprkarl/previews/wallpapers.png" alt="Wallpaper picker"/><br/><sub>Wallpaper picker</sub></td>
  </tr>
</table>

</details>

<details>
<summary>everforest</summary>

<table>
  <tr>
    <td><img src="themes/everforest/previews/busy.png" alt="Busy desktop"/><br/><sub>Busy desktop</sub></td>
    <td><img src="themes/everforest/previews/launcher.png" alt="App launcher"/><br/><sub>App launcher</sub></td>
  </tr>
  <tr>
    <td><img src="themes/everforest/previews/menu.png" alt="Hyprkarl menu"/><br/><sub>Hyprkarl menu</sub></td>
    <td><img src="themes/everforest/previews/wallpapers.png" alt="Wallpaper picker"/><br/><sub>Wallpaper picker</sub></td>
  </tr>
</table>

</details>

<details>
<summary>gruvbox</summary>

<table>
  <tr>
    <td><img src="themes/gruvbox/previews/busy.png" alt="Busy desktop"/><br/><sub>Busy desktop</sub></td>
    <td><img src="themes/gruvbox/previews/launcher.png" alt="App launcher"/><br/><sub>App launcher</sub></td>
  </tr>
  <tr>
    <td><img src="themes/gruvbox/previews/menu.png" alt="Hyprkarl menu"/><br/><sub>Hyprkarl menu</sub></td>
    <td><img src="themes/gruvbox/previews/wallpapers.png" alt="Wallpaper picker"/><br/><sub>Wallpaper picker</sub></td>
  </tr>
</table>

</details>

<details>
<summary>loam</summary>

<img src="themes/loam/previews/palette.png" alt="Loam palette" />

<table>
  <tr>
    <td><img src="themes/loam/previews/busy.png" alt="Loam busy desktop"/><br/><sub>Busy desktop</sub></td>
    <td><img src="themes/loam/previews/launcher.png" alt="Loam app launcher"/><br/><sub>App launcher</sub></td>
  </tr>
  <tr>
    <td><img src="themes/loam/previews/menu.png" alt="Loam Hyprkarl menu"/><br/><sub>Hyprkarl menu</sub></td>
    <td><img src="themes/loam/previews/wallpapers.png" alt="Loam wallpaper picker"/><br/><sub>Wallpaper picker</sub></td>
  </tr>
</table>

</details>

<details>
<summary>tokyo-night</summary>

<img src="themes/tokyo-night/previews/palette.png" alt="Tokyo Night palette" />

<table>
  <tr>
    <td><img src="themes/tokyo-night/previews/busy.png" alt="Tokyo Night busy desktop"/><br/><sub>Busy desktop</sub></td>
    <td><img src="themes/tokyo-night/previews/launcher.png" alt="Tokyo Night app launcher"/><br/><sub>App launcher</sub></td>
  </tr>
  <tr>
    <td><img src="themes/tokyo-night/previews/menu.png" alt="Tokyo Night Hyprkarl menu"/><br/><sub>Hyprkarl menu</sub></td>
    <td><img src="themes/tokyo-night/previews/wallpapers.png" alt="Tokyo Night wallpaper picker"/><br/><sub>Wallpaper picker</sub></td>
  </tr>
</table>

</details>

## Keybindings

These are the basic keybindings to get you started. You can search the rest in
the keybindings menu. Personal additions and overrides belong in
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/bindings.lua`; shipped bindings live under `defaults/hypr/bindings/`.

```
SUPER + K              ->  Searchable list of keybinds
SUPER + ALT + SPACE    ->  Hyprkarl menu
SUPER + SPACE          ->  App launcher
SUPER + SHIFT + F      ->  File manager (yazi)
SUPER + ENTER          ->  Terminal
SUPER + [0-9]          ->  Navigate to workspace
SUPER + SHIFT + [0-9]  ->  Move window to workspace
SUPER + F              ->  Fullscreen
SUPER + T              ->  Toggle tiling/floating
```

## Updating

Releases are annotated git tags (`vX.Y.Z`) on `main`; see
[CHANGELOG.md](CHANGELOG.md) for what changed in each.

Routine personalization lives outside the checkout under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`, so it does not need a personal
Git branch. Create a fork branch only when changing Hyprkarl's shipped code or
defaults. Routine upstream updates do not edit personal files.

Run `hk-update all` to review an exact upstream revision, apply it, review
package removals once, and run pending system migrations. For the full workflow
and the role of the initial setup wrappers, see
[docs/getting-started.md](docs/getting-started.md) and
[docs/updating.md](docs/updating.md).
