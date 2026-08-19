# Using Hyprkarl

This page covers the standard ways to use Hyprkarl through menus, keybindings,
and commands.

## Main Menus

The main menu is:

```bash
hk-shell menu toggle main
```

You can open it from the terminal, from the Hyprkarl button in the bar, or
with `SUPER + ALT + SPACE`.

Its top-level sections are:

- `Launch`
  App launcher
- `Install`
  Package install menus
- `Uninstall`
  Package uninstall menus
- `Utilities`
  Toggles, screen recording, and other utility actions
- `Config`
  Themes, wallpapers, defaults, and other quick settings
- `Power`
  Lock, suspend, reboot, and shutdown actions

The hierarchy is a Quickshell surface. Escape, Left, or Backspace goes to the
parent menu and closes the root; clicking outside also closes it. Open any
surface directly with `hk-shell menu open <menu-id>`.

The shipped hierarchy lives in `defaults/menu.json`. Add, reorder, rename, or
hide entries without editing that default by creating `user/menu.json`; see
[Menu Configuration](menu-configuration.md).

## Common Keybindings

Some common keybindings are:

- `SUPER + ALT + SPACE`
  Open the main Hyprkarl menu
- `SUPER + SPACE`
  Open the app launcher
- `SUPER + ESCAPE`
  Open the power menu
- `SUPER + K`
  Search keybindings
- `SUPER + CTRL + A`
  Open audio controls
- `SUPER + CTRL + B`
  Open Bluetooth controls
- `SUPER + CTRL + W`
  Open Wi-Fi controls
- `SUPER + CTRL + T`
  Open `btop`

Shipped keybindings are defined in `defaults/hypr/bindings/`; personal bindings
belong in `user/hypr/bindings.lua`. The keybindings menu reads the live bindings
from Hyprland.

## System Tray

Expand the tray from its chevron to reveal StatusNotifier items. Left click
activates an item, middle click invokes its secondary action, and right click
opens its native menu. An item that only provides a menu opens it on left click
too. Opening an empty tray only flips the chevron; it expands automatically if
an item appears while it remains open.

## Themes

The usual way to switch themes is `Hyprkarl Menu -> Config -> Theme`, but you
can also run:

```bash
hk-theme set <theme-name>
```

When the theme changes, Hyprkarl atomically assembles and validates a runtime
bundle under `${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl`, then:

- updates the wallpaper state
- updates GNOME and Qt themes
- reloads Hyprland, terminals, `btop`, and the bar

Some changes may not take effect everywhere immediately, but most of the theme
switch happens right away.

See [Themes](themes.md) for the full architecture.

## Wallpapers

Each theme has its own `wallpapers/` directory. The current wallpaper is tracked
in XDG state; `config/hyprkarl/current/wallpaper` is a stable compatibility link
to it.

The usual way to manage wallpapers is `Hyprkarl Menu -> Config -> Wallpaper`, but you can also run:

```bash
hk-wallpaper set <filename>
hk-wallpaper cycle
hk-wallpaper add /path/to/image.png
hk-wallpaper remove <filename>
```

You can also add wallpapers from yazi with its `Set as wallpaper` action.

## Defaults: Terminal, Editor, Shell

The usual way to change these is `Hyprkarl Menu -> Config -> Defaults`.

The defaults commands are:

- `hk-default-terminal <terminal>`
  Install a terminal if needed and make it the default terminal.
- `hk-default-editor <editor>`
  Install an editor if needed and make it the default editor.
- `hk-default-shell <shell>`
  Install a shell if needed and make it the login shell.

Shell changes take effect on the next login.

## Package and App Installation

Install sources are:

- Pacman:
  `hk-pkg-install-tui`
- AUR:
  `hk-pkg-install-tui --aur`
- Flatpak:
  `hk-pkg-install-tui --flatpak`
- Docker services:
  `hk-shell menu open docker-install`

The package menus use `fzf` to search available packages.

For normal package management, it is usually simpler to use the package managers
directly: `pacman`, `yay` (or `paru`), and `flatpak`.

`hk-pkg` exists as a convenience layer when you want one command shape
across pacman, AUR, and Flatpak, or when you want to script against that
interface:

- `hk-pkg install ...`
- `hk-pkg remove ...`
- `hk-pkg missing ...`
- `hk-pkg present ...`

Add `--flatpak` for Flatpak app ids.

## Docker Services

Hyprkarl's Docker support is limited to four predefined local service stacks:
`traefik`, `kiwix`, `degoog`, and `searxng`. It is not a general Docker
container management interface.

Docker services are managed with:

- `hk-shell menu open docker-install`
- `hk-shell menu open docker-uninstall`
- `hk-docker install <service>`
- `hk-docker uninstall <service>`

Installed services keep their files under `~/.traefik`, `~/.kiwix`,
`~/.degoog`, and `~/.searxng`.

## TUIs and Utility Commands

Some Hyprkarl commands open TUIs and reuse an existing window when one is
already open:

- `hk-audio-launch`
- `hk-bluetooth-launch`
- `hk-wifi-launch`

Common utility commands include:

- `hk-screen-record`
- `hk-nightlight`
- `hk-caffeine`
- `hk-playerctl`
- `hk-shell start|stop|restart|status|logs` for Quickshell lifecycle and logs
- `hk-shell menu` for direct command-menu control
- `hk-shell osd` for typed custom volume, brightness, microphone, output, or
  media feedback
- `hk-audio-restart`
- `hk-wifi-restart`

For the rest of the command surface, see
[Command Reference](commands.md).
