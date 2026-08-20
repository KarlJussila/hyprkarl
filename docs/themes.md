# Themes

Hyprkarl's shipped theme bundles live under `themes/`; personal bundles and
overlays live under `user/themes/`. Selecting a theme copies those sources into
an immutable runtime bundle under XDG state, then atomically swaps one symlink.
Git never owns the selected theme or wallpaper.

## How Theme Selection Works

The authoritative state lives under:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/
├── current/
│   ├── theme -> ../themes/<name>.<generation>
│   ├── theme.name
│   ├── theme.json
│   └── wallpaper -> theme/wallpapers/<file>
└── themes/
    └── <name>.<generation>/
```

`config/hyprkarl/current/{theme,theme.name,wallpaper}` are tracked, fixed
compatibility links into this state directory. Their targets do not change
when a theme changes, so updates can safely refresh the repository without
overwriting personal runtime state.

When you run:

```bash
hk-theme set <theme-name>
```

Hyprkarl takes an exclusive theme lock, assembles the built-in bundle plus an
optional same-name `user/themes/<name>/` overlay, validates the complete
result, and atomically activates it. Only after activation does it:

- updates the wallpaper state
- updates GNOME and Qt settings
- reloads Hyprland, terminals, and `btop`

If assembly or validation fails, the previous runtime bundle stays active.
Quickshell watches `current/theme.json`, then follows its immutable artifact
name to `quickshell.json`; a switch applies without rebuilding unrelated shell
state. Hyprkarl retains the current and immediately previous artifacts.

## Switch the Active Theme

The usual way to switch themes is `Hyprkarl Menu -> Config -> Theme`, but you
can also run:

```bash
hk-theme set <theme-name>
```

To list installed themes, run:

```bash
hk-theme list
```

## Theme Contents

The simplest way to create a theme is to copy an existing one and keep the same
layout.

A full theme in this repo includes:

- `palette.yaml`
  Canonical palette and mode used to render the bundle. This makes every
  generated output traceable to its generator input. Runtime activation does
  not require this source file for a complete hand-authored legacy bundle.

- `hyprland.lua`
  Theme-specific Hyprland styling (Lua — Hyprland's config is Lua since 0.55).
  The bootstrap loads it after shipped defaults and before optional
  `user/hypr/*.lua` modules. Theme values override defaults; explicit personal
  values can still override the theme. Typically it sets the active border, e.g.
  `hl.config({ general = { col = { active_border = "rgb(63005A)" } } })`.
- `hyprlock.conf`
  Lock screen styling
- `hyprtoolkit.conf`
  Hyprtoolkit styling
- `quickshell.json`
  Quickshell's semantic `palette`, `surfaces`, `typography`, and `metrics`
  roles, plus component-specific `bar`, `panel`, `tooltip`, `menu`, `osd`,
  `notification`, and `polkit`
  values.
  It controls minimum bar thickness, spacing, island corner
  and border geometry, radii, dividers, tooltip radius, panel gap,
  preferred/max panel size, and transition timing. `bar.margin` controls the
  screen, outer, and content gaps; `bar.island.corners` and `.borders` control
  the four logical island edges. `bar.widgetPadding.main` and `.cross`
  provide universal padding along and across top/bottom bar widgets;
  `bar.trayPaddingOffset` adjusts the tray's main-axis inset with a zero floor,
  while `metrics.controlPadding` belongs to panel internals.
  `bar.minimumThickness` is only a
  floor; the tallest naturally padded widget sets a shared island height.
  The shell-native command menu inherits this file's semantic palette,
  typography, radii, and borders. Its nested `menu` object owns menu-specific
  width, nested-frame geometry, row spacing, selection treatment, backdrop,
  and optional semantic overrides. The shipped composition carries forward
  the original Rofi menu's compact identity without reproducing it literally.
  The nested `osd` object controls normal/media widths, padding, spacing,
  radius, indicator size, progress height, and transition duration; OSD
  placement and timeouts remain behavior in `shell.json`.
  The nested `notification` object controls normal/compact widths, padding,
  stack spacing (zero joins the stack into one bordered surface), radius,
  application-icon and content-image sizes, custom
  indicator scale, progress height, and reveal timing. Notification routing,
  docking, timing, filtering, and icon selection remain behavior in
  `shell.json`.
  The nested `polkit` object controls the modal prompt width, padding,
  spacing, radius, icon size, title-band accent, and transition
  timing. Authentication behavior remains owned by Quickshell's polkit flow.
  All Quickshell surface colors and interaction states come from semantic
  theme data rather than consumer-specific color aliases. See
  [Customizing the Bar](customizing-bar.md#change-the-appearance) for the
  geometry schema.
- `rofi.rasi`
  Rofi styling
- `alacritty.toml`, `foot.ini`, `ghostty.conf`, `kitty.conf`
  Terminal colors
- `btop.theme`
  `btop` colors
- `wifitui.toml`
  `wifitui` colors
- `yazi.toml`
  Yazi theme settings
- `qt5ct/qt5ct.conf`, `qt5ct/style-colors.conf`
  Qt5 color palette and widget style settings
- `qt6ct/qt6ct.conf`, `qt6ct/style-colors.conf`
  Qt6 color palette and widget style settings
- `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`
  GTK settings files (stowed to `~/.config/gtk-{3,4}.0/`); point GTK apps to
  the theme name and set the dark/light preference
- `gtk-theme/`
  The GTK theme payload copied to `~/.local/share/themes/hyprkarl/` on setup,
  update, and every theme switch.
  Contains `index.theme` (theme metadata) and the GTK3/4 stylesheets under
  `gtk-3.0/` and `gtk-4.0/` (`gtk.css`, `gtk-dark.css`, and assets).
  GTK apps read their colors from this real directory. Hyprkarl deliberately
  does not make the installed theme directory or its payload files symlinks;
  GTK theme discovery and asset loading are less reliable through moving
  symlink trees. `.hyprkarl-managed` marks the installed copy as safe to
  replace. An unrelated existing directory at that name is rejected unless
  setup is explicitly run with its force/adopt path.
- `nvim/colorscheme.lua`, `nvim/custom-colors.lua`
  Neovim colors
- `wallpapers/`
  Wallpapers available to `hk-wallpaper`

Optional theme files:

- `light.mode`
  Switches GNOME to `prefer-light`. Without it, Hyprkarl uses `prefer-dark`.
- `icons.theme`
  Single-line file naming the icon theme. Applied via `gsettings` on theme
  switch and embedded in `gtk-theme/index.theme`.
- `icons/`
  Theme-local icons used by Hyprkarl helpers and shell surfaces.

## Create a New Theme

There are two ways to make a theme.

### Generate one from a color palette (recommended)

The themes shipped with Hyprkarl are produced by the companion tool,
[hyprkarl-theme-generator](https://github.com/KarlJussila/hyprkarl-theme-generator).
It renders an entire theme — every file listed under
[Theme Contents](#theme-contents) — from a single YAML color palette, so the
colors stay consistent across Hyprland, the bar, terminals, GTK, Qt, and the
rest. It's the easiest path if you're building a new look, and it pairs well
with an LLM: hand it a terminal colorscheme (or describe the mood you want) and
have it write the palette.

Keep its checkout beside Hyprkarl (the default), or set
`HYPRKARL_THEME_GENERATOR_PATH` in `~/.config/uwsm/env.local`. Create a source
directory with `palette.yaml`, optional `overrides/`, `wallpapers/`, and
`previews/`, then run:

```bash
hk-theme build /path/to/my-theme
hk-theme set my-theme
```

`hk-theme build <source> [name]` writes the complete generated bundle to
`user/themes/<name>/`, never to upstream-owned `themes/`. Generator developers
use its direct `python -m theme_generator sync ...` command when intentionally
refreshing the checked-in built-ins. Keep the palette source outside that
generated destination; a clean rebuild replaces the destination as one unit.

### Copy an existing theme

For a complete hand-edited personal theme, copy a bundle into `user/`:

```bash
cp -a ~/.local/share/hyprkarl/themes/hyprkarl \
  ~/.local/share/hyprkarl/user/themes/my-theme
```

Then edit the copied files and activate it:

```bash
hk-theme set my-theme
```

Starting from an existing theme is easier than building one from scratch,
because the repo already expects a specific file layout.

### Move an existing custom theme

An output-only theme created before palette-first generation can keep working.
Move its complete directory from `themes/<name>/` to `user/themes/<name>/`, then
run `hk-theme set <name>`. Runtime validation checks the files consumers need;
it does not require a historical theme to invent a palette.

To make that theme generator-owned later, create a new source directory with
`palette.yaml`, put only genuine exceptions under `overrides/`, copy its assets,
and use `hk-theme build`. Compare the result before replacing the old personal
bundle.

## Wallpapers in Themes

Built-in wallpapers live in `themes/<name>/wallpapers/`. Personal additions
and built-in removals are recorded under `user/themes/<name>/`, then included
the next time the bundle is assembled. Wallpaper commands also update the
active runtime bundle immediately.

To add a wallpaper to the current theme, you can run:

```bash
hk-wallpaper add /path/to/image.png
```

That copies the file into `user/themes/<name>/wallpapers/`, copies it into the
active runtime bundle, rebuilds its thumbnail, and selects it.

You can also add wallpapers manually by copying image files into:

```text
user/themes/<theme>/wallpapers/
```

Then rebuild that theme's thumbnail cache:

```bash
hk-wallpaper cache
```

Wallpaper commands always operate on the active theme:

```bash
hk-wallpaper set <filename>
hk-wallpaper cycle
hk-wallpaper remove <filename>
hk-wallpaper cache [--regenerate|--single <filename>]
```

## Sharp Edges

- Theme activation rejects an incomplete bundle or invalid `quickshell.json`
  without changing the active theme.
- To restore wallpaper state, use:

```bash
hk-wallpaper init || hk-wallpaper cycle
```

## Related Docs

- [Using Hyprkarl](using-hyprkarl.md)
- [Command Reference](commands.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
