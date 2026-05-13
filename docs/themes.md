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
- reloads Hyprland, mako, terminals, and `btop`, and restarts Waybar if it is
  running

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

- `hyprland.conf`
  Theme-specific Hyprland styling
- `hyprlock.conf`
  Lock screen styling
- `hyprtoolkit.conf`
  Hyprtoolkit styling
- `waybar.css`
  Waybar colors
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
- `kvantum.kvconfig`, `qt5ct/qt5ct.conf`, `qt5ct/style-colors.conf`,
  `qt6ct/qt6ct.conf`, `qt6ct/style-colors.conf`
  Qt styling
- `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`
  GTK styling
- `nvim/colorscheme.lua`, `nvim/custom-colors.lua`
  Neovim colors
- `wallpapers/`
  Wallpapers available to `hk-wallpaper`

Optional theme files:

- `light.mode`
  Switches GNOME to `prefer-light`. Without it, Hyprkarl uses `prefer-dark`.
- `icons.theme`
  Sets the GNOME icon theme name.
- `icons/`
  Theme-local icons used by Hyprkarl helpers and notifications.

## Create a New Theme

Start from an existing theme:

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
- [Command Reference](reference/commands.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
