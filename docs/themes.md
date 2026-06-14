# Themes

Hyprkarl themes are directories under `themes/`. The active theme is selected
by updating symlinks under `config/hyprkarl/current/`.

## How Theme Selection Works

The active theme state lives in `config/hyprkarl/current/`:

- `theme`
  relative symlink to `../../../themes/<name>`
- `theme.name`
  active theme name
- `wallpaper`
  symlink to the current wallpaper inside the active theme

When you run:

```bash
hk-theme set <theme-name>
```

Hyprkarl:

- updates `config/hyprkarl/current/theme`
- writes `config/hyprkarl/current/theme.name`
- updates the wallpaper state
- updates GNOME and QT themes
- reloads Hyprland, mako, terminals, and `btop`
- restarts AGS (picks up the new `bar.scss`)

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

- `hyprland.lua`
  Theme-specific Hyprland styling (Lua — Hyprland's config is Lua since 0.55).
  The main Hyprland config loads it last via `loadfile`, so it overrides earlier
  settings. Typically just the active border color, e.g.
  `hl.config({ general = { col = { active_border = "rgb(63005A)" } } })`.
- `hyprlock.conf`
  Lock screen styling
- `hyprtoolkit.conf`
  Hyprtoolkit styling
- `bar.scss`
  AGS bar colors, spacing, radii, and typography
- `rofi.rasi`
  Rofi styling
- `mako.ini`
  Notification styling
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
  The GTK theme bundle stowed to `~/.local/share/themes/hyprkarl/`.
  Contains `index.theme` (theme metadata) and the GTK3/4 stylesheets under
  `gtk-3.0/` and `gtk-4.0/` (`gtk.css`, `gtk-dark.css`, and assets).
  GTK apps read their colors from here.
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
  Theme-local icons used by Hyprkarl helpers and notifications.

## Create a New Theme

There are two ways to make a theme.

### Generate one from a color palette (recommended)

The themes shipped with Hyprkarl are produced by a companion tool,
[hyprkarl-theme-generator](https://github.com/KarlJussila/hyprkarl-theme-generator).
It renders an entire theme — every file listed under
[Theme Contents](#theme-contents) — from a single YAML color palette, so the
colors stay consistent across Hyprland, the bar, terminals, GTK, Qt, and the
rest. It's the easiest path if you're building a new look, and it pairs well
with an LLM: hand it a terminal colorscheme (or describe the mood you want) and
have it write the palette.

```bash
git clone https://github.com/KarlJussila/hyprkarl-theme-generator.git
cd hyprkarl-theme-generator
# create palettes/my-theme/palette.yaml (see that repo's AGENTS.md), then:
python generate.py my-theme
export HYPRKARL_PATH=~/.local/share/hyprkarl
./sync_theme.sh my-theme          # installs it into themes/my-theme/
hk-theme set my-theme
```

### Copy an existing theme

For quick tweaks to an existing look, copy a theme directory and edit it in place:

```bash
cd ~/.local/share/hyprkarl
cp -a themes/hyprkarl themes/my-theme
```

Then edit the copied files and activate it:

```bash
hk-theme set my-theme
```

Starting from an existing theme is easier than building one from scratch,
because the repo already expects a specific file layout.

## Wallpapers in Themes

Wallpapers are stored in each theme's `wallpapers/` directory.

To add a wallpaper to the current theme, you can run:

```bash
hk-wallpaper add /path/to/image.png
```

That copies the file into the current theme's `wallpapers/` directory, rebuilds
its thumbnail, and sets it as the current wallpaper.

You can also add wallpapers manually by copying image files into:

```text
themes/<theme>/wallpapers/
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

- Missing theme files do not always fail loudly.
- To restore wallpaper state, use:

```bash
hk-wallpaper init || hk-wallpaper cycle
```

## Related Docs

- [Using Hyprkarl](using-hyprkarl.md)
- [Command Reference](commands.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
