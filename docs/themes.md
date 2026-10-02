# Themes

Hyprkarl keeps theme source and generated runtime output separate:

```text
themes/<name>/                                  shipped authoring source
${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/
└── themes/<name>/                              personal source or overlay
${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/
├── current/theme -> ../themes/<name>.<timestamp>   the active build
└── themes/<name>.<timestamp>/                     the generated build
```

Generated builds do not live in Git or the personal configuration directory.
The GTK theme is also copied to `~/.local/share/themes/hyprkarl/`, because
GTK does not reliably follow symlinked theme directories.

## Switch themes

Use `Hyprkarl Menu -> Config -> Theme` or run:

```bash
hk-theme set <theme-name>
```

List available source themes with:

```bash
hk-theme list
```

Hyprkarl ships `hyprkarl`, `everforest`, `gruvbox`, `loam`, and
`tokyo-night`. The Tokyo Night source uses the original dark Night variant.
Loam uses warm brown surfaces and a narrow olive, ochre, and bark palette. It
began as an adaptation of Melange and retains the upstream attribution in its
source directory.

Every selection rebuilds the theme. `hk-theme set`:

1. loads the built-in source, personal source, or both;
2. merges and resolves the typed value graph;
3. renders and validates every consumer into a new build directory;
4. points `current/theme` at that build and deletes older builds;
5. copies the GTK theme and sets the GTK desktop settings;
6. reloads affected consumers.

A failed build leaves the active theme unchanged. Quickshell notices the switch
and reloads without restarting.

## Source layout

A source may contain:

```text
<name>/
├── theme.yaml
├── overrides/
├── wallpapers/
├── icons/
└── previews/
```

- `theme.yaml` contains typed values and Jinja expressions.
- `overrides/<relative-template-path>` completely replaces one compiler
  template at the same relative path.
- `wallpapers/` contains wallpaper assets. By convention, `01-*` is primary.
- `icons/` adds or replaces generated theme-local icons.
- `previews/` contains repository screenshots such as `busy.png`,
  `launcher.png`, `menu.png`, and `wallpapers.png`.

Set `desktop.icon_theme` to the installed icon family that best fits the
palette. For example, Loam uses `Yaru-olive-dark` and Tokyo Night uses
`Yaru-blue-dark`.

Themes may also opt into the shared Hyprkarl wallpaper:

```yaml
wallpaper:
  generate_default: true
```

The compiler writes `01-hyprkarl-wallpaper.png` using `base.background`,
`accent.primary.base`, and `accent.primary.soft`. A theme may override the
corresponding `wallpaper.background`, `wallpaper.accent`, and
`wallpaper.accent_dim` values. Generation is independent of authored assets,
so the theme may include other files under `wallpapers/` at the same time. An
authored file named `01-hyprkarl-wallpaper.png` wins over the generated one.
The default is `generate_default: false`.

A personal-only theme requires `theme.yaml`. A personal directory with the
same name as a built-in is a sparse overlay and may omit it. That makes small
changes practical. For example:

```text
~/.config/hyprkarl/themes/hyprkarl/
└── theme.yaml
```

```yaml
metrics:
  border:
    standard: 3

shell:
  bar:
    margin:
      screen: 4
```

Run `hk-theme set hyprkarl` after editing it.

## Merge and rendering order

The value graph resolves in this order:

```text
theme-generator/defaults/theme.yaml
  -> themes/<name>/theme.yaml
  -> ~/.config/hyprkarl/themes/<name>/theme.yaml
  -> recursive native Jinja resolution
```

Objects merge recursively. Arrays and scalar values replace earlier values.
Whole-value expressions retain native strings, integers, decimals, and
booleans. Theme authors may define their own structures and reference them from
consumer values. The shipped `metrics`, `motion`, and `typography` names are
defaults, not an allowlist.

Templates and assets use the same ownership order:

```text
compiler template or asset -> built-in replacement -> personal replacement
```

An override replaces a whole template. It does not introduce a second merge
language. Personal wallpaper files add to or replace built-in files.
`.wallpapers-disabled` records inherited wallpaper paths that should be absent
from the generated bundle.

## Create a personal theme

Start from a shipped source, not a generated bundle:

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/my-theme"
cp ~/.local/share/hyprkarl/themes/hyprkarl/theme.yaml \
  "${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/my-theme/theme.yaml"
$EDITOR "${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/my-theme/theme.yaml"
hk-theme set my-theme
```

The shared compiler defaults provide fonts, spacing, radii, border widths,
motion, and the complete Quickshell appearance shape. Most new sources only
need palette values and intentional changes.

For direct compiler work, run the module from `theme-generator/`:

```bash
cd ~/.local/share/hyprkarl/theme-generator
python -m theme_generator preview hyprkarl
python -m theme_generator preview hyprkarl -o /tmp/hyprkarl-palette.png
python -m theme_generator capture hyprkarl
python -m theme_generator build hyprkarl -o /tmp/hyprkarl-theme
python -m theme_generator build hyprkarl \
  --overlay ~/.config/hyprkarl/themes/hyprkarl \
  -o /tmp/hyprkarl-theme
python -m theme_generator validate
python -m pytest -q
```

These are authoring and test commands. `hk-theme set` remains the public
build-and-activate action. There is no sibling generator checkout, compiler
sync command, or `hk-theme build` action.

`preview` prints a terminal palette and renders a graphical palette board.
`capture` activates the theme and creates the standard palette, busy desktop,
launcher, menu, and wallpaper-picker images under the source's `previews/`
directory. It uses empty numbered workspace 4 by default and refuses to touch
one that already contains windows. Use `--workspace 9`, for example, when 4 is
occupied. The command recreates the established tiled busy layout, stages the
volume OSD and one notification, controls hover selection, then restores the
previous workspace and pointer position. Preview files are published only
after the complete capture succeeds.

## Generated bundle

The compiler renders the resolved graph into consumer files for:

- Quickshell (including the lock screen), Hyprland, and Hyprtoolkit;
- Alacritty, foot, Ghostty, Kitty, `btop`, `wifitui`, Yazi, and Neovim;
- Qt 5 and Qt 6 palettes;
- GTK 3 and GTK 4, including a palette-derived Colloid theme;
- theme metadata, icons, wallpapers, and previews.

The generated `quickshell.json` owns semantic colors, typography, geometry,
borders, spacing, and component-specific appearance for the bar, panels,
menus, OSD, notifications, polkit, application picker, calculator, and
wallpaper picker. Its `switch` object supplies the shared toggle indicator's
default geometry, border, glyph typography and offsets, and transition timing.
A shell widget may sparsely override those defaults when one application needs
different control geometry without changing the rest of the theme. See
[Customizing the bar](customizing-bar.md#change-the-appearance) for the bar
and switch appearance contract.

The generated `theme.yaml` contains the fully merged and resolved graph for
inspection. It is output, not the next authoring source.

## GTK output

The active build contains a `gtk-theme/` directory. `hk-theme set` copies it
to:

```text
~/.local/share/themes/hyprkarl/
```

This is a real copy because GTK discovery and asset loading have been
unreliable through symlinked theme directories, so do not replace it with a
symlink. Edit theme source and select the theme again instead of editing
the installed copy. Dark sources compile Colloid's dark variant; `mode: light`
compiles its light variant. The user-owned `~/.config/gtk-3.0/settings.ini` and
`gtk-4.0/settings.ini` select the stable `hyprkarl` theme name; `hk-theme set`
applies the light/dark preference through desktop settings.

## Wallpapers

Built-in wallpapers live in `themes/<name>/wallpapers/`. Personal additions
and inherited removals live under the matching personal theme source. The
wallpaper commands update both personal source state and the active build:

```bash
hk-wallpaper set <filename>
hk-wallpaper cycle
hk-wallpaper add /path/to/image.png
hk-wallpaper remove <filename>
hk-wallpaper cache [--regenerate|--single <filename>]
```

The current selection lives in XDG state. To recover an invalid selection,
run:

```bash
hk-wallpaper init || hk-wallpaper cycle
```

## Related docs

- [Using Hyprkarl](using-hyprkarl.md)
- [Command reference](commands.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
