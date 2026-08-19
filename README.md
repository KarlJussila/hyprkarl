# Hyprkarl
Hyprkarl is a desktop configuration repo for CachyOS + Hyprland, inspired by
Omarchy. It is meant to be installed and then edited directly.

> **Warning:** The fresh-install path (`setup-*.sh` on a new machine) is
> largely untested — the running system it produces is daily-driven, but the
> first-run setup itself is not. Review the scripts before running them, and
> use at your own risk.

## Screenshots

<table>
  <tr>
    <td><img src="themes/hyprkarl/screenshots/busy.png" alt="Busy desktop"/><br/><sub>Busy desktop</sub></td>
    <td><img src="themes/hyprkarl/screenshots/launcher.png" alt="App launcher"/><br/><sub>App launcher</sub></td>
  </tr>
  <tr>
    <td><img src="themes/hyprkarl/screenshots/menu.png" alt="Hyprkarl menu"/><br/><sub>Hyprkarl menu</sub></td>
    <td><img src="themes/hyprkarl/screenshots/wallpapers.png" alt="Wallpaper picker"/><br/><sub>Wallpaper picker</sub></td>
  </tr>
</table>

## Requirements

- Base CachyOS (Hyprland) install
- Single-user. Hyprkarl does not try to support multi-user setups.
- Btrfs filesystem (with LUKS encryption) and Limine boot loader are strongly recommended. Hyprkarl may implement changes involving either one in the future.
- Hyprland must be running under UWSM (this is the default on CachyOS). SDDM autologin is configured to launch `hyprland-uwsm.desktop`.

## Warnings

- The setup script enables SDDM autologin. The intention is to rely on LUKS encryption for boot authentication instead of requiring two passwords. If you prefer to disable autologin, edit `setup-system.sh` before running it, or disable it manually afterward.
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
> `~/.local/share/applications/`, back them up first. `setup-dotfiles.sh`
> replaces overlapping live files with symlinks to Hyprkarl.

## Uninstalling

```bash
~/.local/share/hyprkarl/uninstall.sh
```

Removes all of Hyprkarl's config symlinks (reversing `setup-dotfiles.sh`).
Installed packages and `setup-system.sh` changes are left in place; the script
lists them so you can undo what you want manually.

## After Installation

Hyprkarl's configs and scripts live in `~/.local/share/hyprkarl/`. The live
files under `~/.config/` and `~/.local/share/applications/` are usually
symlinks back into that tree, so edit the files in Hyprkarl itself.

A few things worth knowing:

- create a git branch before customizing
- updates are normal git merges, not a special Hyprkarl workflow
- user environment variables live in `~/.config/uwsm/`
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
  Adding commands, menus, keybindings, and theme-aware config
- [docs/troubleshooting.md](docs/troubleshooting.md)
  Common setup and runtime failures
- [docs/commands.md](docs/commands.md)
  Command reference
- [docs/repo-conventions.md](docs/repo-conventions.md)
  Editing conventions, stowed-config model, stateful paths
- [docs/shell-style.md](docs/shell-style.md)
  Hyprkarl's Bash/Python command scripting style
- [docs/architecture-roadmap.md](docs/architecture-roadmap.md)
  Completed shell-foundation work and the remaining architecture roadmap
- [docs/shell-product-brief.md](docs/shell-product-brief.md)
  Bar aesthetic, independent feature panels, and product direction
- [docs/shell-configuration.md](docs/shell-configuration.md)
  Shell JSON, extension lanes, and runtime-state ownership
- [docs/menu-configuration.md](docs/menu-configuration.md)
  Shell-native menu entries, user overrides, Python dynamic providers, and
  direct menu commands
- [docs/authentication-surfaces.md](docs/authentication-surfaces.md)
  Polkit surface design and the pinned-version lock-screen decision

## Themes

Shipped themes live under `themes/`; personal themes and overlays live under
`user/themes/`. Selection atomically assembles an immutable runtime bundle
under `${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl`, so switching never
edits tracked files. Quickshell watches the runtime selector and applies theme
switches without restarting. Its semantic `quickshell.json` controls island corner shapes,
selective borders, and screen/outer/content margins as well as colors and
typography. It also provides the minimum height and widget padding; the tallest
widget determines one shared height for all islands. Inspect or manage the bar
with `hk-shell status`, `hk-shell logs`, and the other `hk-shell` lifecycle
commands. Volume, audio-output, microphone, display/keyboard brightness, and
media-key feedback use the same shell through a focused-monitor, click-through
OSD. The shell also owns desktop notifications, including focused-monitor
routing, progress, silence mode, one-item restore, bar-connected geometry, and
data-defined application icon overrides with user QML drawings; Mako is no
longer part of the session. Personal command widgets can add bar readouts
without editing QML using one application-wide polling or persistent-stream
provider per widget ID. Static command buttons such as the main-menu trigger
use the same kind without starting a timer or process. More specialized
personal bar widgets can be explicitly loaded from
`user/quickshell/modules/` through a small per-bar context, without turning the
shell into a plugin platform.

Switch themes from `Hyprkarl Menu -> Config -> Theme` or with:

```bash
hk-theme set <theme-name>
```

To build your own theme, generate one into `user/themes/` with
`hk-theme build <source> [name]` and the adjacent
[hyprkarl-theme-generator](https://github.com/KarlJussila/hyprkarl-theme-generator)
(recommended), or copy an existing bundle there and edit it. See
[docs/themes.md](docs/themes.md) for both approaches and the full theme layout.

Provided themes:
<details>
<summary>hyprkarl</summary>

<table>
  <tr>
    <td><img src="themes/hyprkarl/screenshots/busy.png" alt="Busy desktop"/><br/><sub>Busy desktop</sub></td>
    <td><img src="themes/hyprkarl/screenshots/launcher.png" alt="App launcher"/><br/><sub>App launcher</sub></td>
  </tr>
  <tr>
    <td><img src="themes/hyprkarl/screenshots/menu.png" alt="Hyprkarl menu"/><br/><sub>Hyprkarl menu</sub></td>
    <td><img src="themes/hyprkarl/screenshots/wallpapers.png" alt="Wallpaper picker"/><br/><sub>Wallpaper picker</sub></td>
  </tr>
</table>

</details>

<details>
<summary>everforest</summary>

<table>
  <tr>
    <td><img src="themes/everforest/screenshots/busy.png" alt="Busy desktop"/><br/><sub>Busy desktop</sub></td>
    <td><img src="themes/everforest/screenshots/launcher.png" alt="App launcher"/><br/><sub>App launcher</sub></td>
  </tr>
  <tr>
    <td><img src="themes/everforest/screenshots/menu.png" alt="Hyprkarl menu"/><br/><sub>Hyprkarl menu</sub></td>
    <td><img src="themes/everforest/screenshots/wallpapers.png" alt="Wallpaper picker"/><br/><sub>Wallpaper picker</sub></td>
  </tr>
</table>

</details>

<details>
<summary>gruvbox</summary>

<table>
  <tr>
    <td><img src="themes/gruvbox/screenshots/busy.png" alt="Busy desktop"/><br/><sub>Busy desktop</sub></td>
    <td><img src="themes/gruvbox/screenshots/launcher.png" alt="App launcher"/><br/><sub>App launcher</sub></td>
  </tr>
  <tr>
    <td><img src="themes/gruvbox/screenshots/menu.png" alt="Hyprkarl menu"/><br/><sub>Hyprkarl menu</sub></td>
    <td><img src="themes/gruvbox/screenshots/wallpapers.png" alt="Wallpaper picker"/><br/><sub>Wallpaper picker</sub></td>
  </tr>
</table>

</details>

## Keybindings

These are the basic keybindings to get you started. You can search the rest in
the keybindings menu. Personal additions and overrides belong in
`user/hypr/bindings.lua`; shipped bindings live under `defaults/hypr/bindings/`.

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

If you have customized Hyprkarl, update it like a normal git branch. Review
upstream changes before merging them and commit your own work first. Shell and
Hyprland personalization under `user/` is deliberately separate from
Hyprkarl-owned defaults so routine upstream changes do not edit those files.

For the full update workflow, including when to run `hk-update`,
`setup-packages.sh`, `setup-system.sh`, or `setup-dotfiles.sh`, see
[docs/getting-started.md](docs/getting-started.md) and
[docs/updating.md](docs/updating.md).
