# Configuration Map

Where Hyprkarl keeps things, and who owns each file.

## Your files

Updates never change these. Hyprkarl creates some of them once, with comments
explaining what goes there.

| What | Where |
|---|---|
| Hyprland settings and keybindings | `~/.config/hypr/hyprland.local.lua` |
| Hypridle, Hyprpaper, Hyprsunset | `~/.config/hypr/hypridle.local.conf`, `hyprpaper.local.conf`, `hyprsunset.local.conf` |
| Terminals | `~/.config/<terminal>/local.toml`, `local.ini`, or `local.conf` |
| Shell and menu settings | `~/.config/quickshell/settings/shell.json` and `menu.json` |
| Personal QML | `~/.config/quickshell/custom/` |
| Personal themes and wallpapers | `~/.config/hyprkarl/themes/<name>/` |
| Lifecycle hooks | `~/.config/hyprkarl/hooks/<event>.d/` |
| Session variables | `~/.config/uwsm/env.local` |
| Personal commands | `~/.local/bin/` |
| Application credentials | `~/.local/share/keyrings/` |
| fastfetch | The theme: its `fastfetch` keys in a theme overlay, or your own `~/.config/fastfetch/config.jsonc` |
| btop, Neovim, Yazi | Their own `~/.config/<app>/`, copied from Hyprkarl once |

See [Extending Hyprkarl](extending-hyprkarl.md) for how to use each.

## Hyprkarl's files

The checkout at `~/.local/share/hyprkarl/` belongs to Hyprkarl; updates replace
it. Its main parts:

- `bin/`: the `hk-*` commands, put on `PATH` after `~/.local/bin`.
- `config/`: configs linked into `~/.config` by GNU Stow, and the starting
  configs for btop, Neovim, and Yazi.
- `defaults/`: the shell's `shell.json` and `menu.json`, Hyprland's modules
  under `hypr/`, XDG defaults under `config/` and `share/`, and the agent
  skill under `skills/`.
- `themes/` and `theme-generator/`: theme sources and their compiler.
- `packages/` and `migrations/`: what `hk-update apply` installs and the
  one-time changes it runs.
- `templates/`: files Hyprkarl writes from, such as the personal files it
  creates, system configs for migrations, and Docker service definitions.
- `data/`: generated data, such as the icon picker's list.

## Machine state

Generated files that describe this machine live under `~/.local/state/hyprkarl/`
and are not for editing:

- `current/theme` links to the active theme build in `themes/`, and
  `current/wallpaper` to the selected wallpaper in it. Everything that reads
  the theme points at `current/theme`.
- `update/` records the reviewed and applied revisions, the package lists as
  last applied, and the migrations that have run. See [Updating](updating.md).
- `display/` holds the layout the display panel saved: `monitors.lua`, which
  Hyprland loads, and `layout.json`. Rules in `hyprland.local.lua` still win.
- `calculator-history.json` keeps the calculator's last five results.
- `application-launches.json` counts launches from the app launcher, which
  its search ranking uses.

`hk-update apply` links Hyprkarl's agent skill into the skill folders of
coding agents (`~/.agents`, `~/.claude`, `~/.codex`), creating them, so an
agent you install later finds it; see
[Extending Hyprkarl](extending-hyprkarl.md#ask-an-ai-agent). A theme switch
also writes outside that folder: the GTK theme to
`~/.local/share/themes/hyprkarl/`, `~/.config/qt5ct/qt5ct.conf` and
`qt6ct.conf`, and the default cursor in `~/.local/share/icons/default/`.

## Hyprland

Hyprland is configured in Lua. `~/.config/hypr/hyprland.lua` links to
Hyprkarl's bootstrap, which loads, in order:

1. Hyprkarl's modules from `defaults/hypr/`: `envs`, `autostart`, `monitors`,
   `permissions`, `looknfeel`, `animations`, `gum`, `windows` (which includes
   `windows/*.lua`), `input`, and `bindings` (which includes `bindings/*.lua`);
2. the theme's `hyprland.lua`;
3. the display panel's `monitors.lua`;
4. your `~/.config/hypr/hyprland.local.lua`, so it wins over everything.

At login, the `autostart` module runs `hk-autostart`, which starts the shell,
the idle daemon, and the wallpaper, sets the cursor, and runs your `login`
hooks.

Unfocused windows are 80% opaque through a `default-opacity` tag that every
window gets; a window rule with `tag = "-default-opacity"` keeps one opaque,
as Hyprkarl does for media players.

Check changes with `Hyprland --verify-config`; a broken `hyprland.lua` has no
fallback. For syntax, see Hyprland's
[Configuring](https://wiki.hypr.land/Configuring/) and
[Variables](https://wiki.hypr.land/Configuring/Variables/) pages.

## Session environment

`config/uwsm/env`, loaded when the session starts:

- exports `HYPRKARL_PATH`;
- puts `~/.local/bin`, then Hyprkarl's `bin/`, first on `PATH`, so a personal
  command can replace an `hk-*` command of the same name;
- puts `defaults/config/` first in `XDG_CONFIG_DIRS` and `defaults/share/`
  first in `XDG_DATA_DIRS`, followed by Flatpak's entries;
- sets `EDITOR=nvim`, `QT_QPA_PLATFORMTHEME`, and `WIFITUI_THEME`;
- loads `~/.config/uwsm/default`, where `hk-default-editor` records your
  editor, then `~/.config/uwsm/env.local`.

Changes to any of these need a new session.

## Application configuration

Hyprkarl configures each application in whichever of four ways keeps its
defaults updating.

**Shipped file plus a personal file.** Hyprkarl links its config into
`~/.config`; that file loads the theme and Hyprkarl's settings, then your
file.

| Application | Your file | Apply changes |
|---|---|---|
| Alacritty | `~/.config/alacritty/local.toml` | Automatic, or a new window |
| foot | `~/.config/foot/local.ini` | New window |
| Ghostty | `~/.config/ghostty/local.conf` | Reload Ghostty's config or open a new window |
| Kitty | `~/.config/kitty/local.conf` | `hk-terminal-reload` or a new window |
| Hypridle | `~/.config/hypr/hypridle.local.conf`; its timeouts and actions are variables you can redefine | Restart `hypridle.service` |
| Hyprpaper, Hyprsunset | `~/.config/hypr/hyprpaper.local.conf`, `hyprsunset.local.conf` | Restart the service |
| Hyprland | `~/.config/hypr/hyprland.local.lua` | Automatic reload |

**Hyprkarl defaults that your own file replaces.** These programs search
`XDG_CONFIG_DIRS` or `XDG_DATA_DIRS` after your own folders, so Hyprkarl's file
applies until you create one at the same path.

| Default | Purpose | Your override |
|---|---|---|
| `defaults/config/xdg-desktop-portal/portals.conf` | Portal backends, including the terminal file chooser | `~/.config/xdg-desktop-portal/portals.conf` |
| `defaults/config/xdg-terminals.list` | Terminal for `xdg-terminal-exec`; `hk-default-terminal` writes yours | `~/.config/xdg-terminals.list` |
| `defaults/share/applications/` | Terminal arguments for Alacritty and foot; Nautilus without D-Bus activation, which opened two windows | A file of the same name in `~/.local/share/applications/` |

The launcher hides a few rarely used applications through
`applications.hidden` in `shell.json`.

**Owned by the theme.** Change these through a [personal theme](themes.md),
not in place.

| Application | How |
|---|---|
| GTK 3/4 | Linked `gtk.css` imports the installed theme; linked `settings.ini` selects it |
| Qt5ct / Qt6ct | Each theme switch writes `qt5ct.conf` and `qt6ct.conf`; changes made in qt6ct last until the next switch |
| Hyprtoolkit | Linked `~/.config/hypr/hyprtoolkit.conf` |
| Cursor | Each theme switch writes `~/.local/share/icons/default/index.theme` |
| File chooser | Linked `xdg-desktop-portal-termfilechooser/config`, which opens Yazi in your terminal |
| fastfetch | The theme's whole config, found through `XDG_CONFIG_DIRS`; your own `~/.config/fastfetch/config.jsonc` replaces it |

**Starting configs.** btop, Neovim, and Yazi cannot load Hyprkarl's
defaults next to a file of yours, so `hk-update apply` copies Hyprkarl's
complete config when you have none of their files. The copy is yours; updates
never change it. Delete it to get Hyprkarl's current version on the next
update. Their theme colors stay linked to the active theme.

## Shell and themes

The shell's behavior comes from `defaults/shell.json` and `menu.json` with your
files merged over them, and its appearance from the theme. See [Shell
configuration](shell-configuration.md), [Menu
configuration](menu-configuration.md), [Themes](themes.md), and
[Authentication](authentication-surfaces.md).
