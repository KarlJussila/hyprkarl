# Themes

Hyprkarl keeps theme source and generated runtime output separate:

```text
themes/<name>/                                  shipped authoring source
${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/
└── themes/<name>/                              personal source or overlay
${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/
├── current/                                    active selectors
└── themes/<name>.<generation>/                 generated immutable bundles
```

Generated bundles do not live in Git or the personal configuration directory.
The installed GTK payload is the one deliberate copy outside XDG state.

## Switch themes

Use `Hyprkarl Menu -> Config -> Theme` or run:

```bash
hk-theme set <theme-name>
```

List available source themes with:

```bash
hk-theme list
```

Every selection rebuilds the theme. `hk-theme set`:

1. loads the built-in source, personal source, or both;
2. merges and resolves the typed value graph;
3. renders every consumer into a temporary directory;
4. validates the complete bundle;
5. installs an immutable artifact under XDG state;
6. atomically changes the active selector;
7. materializes the GTK payload and reloads affected consumers.

A failed build leaves the active theme and installed GTK copy unchanged.
Quickshell watches `current/theme.json`, so a successful switch applies without
restarting the shell. Hyprkarl retains the current and immediately previous
artifacts.

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

## Generated bundle

The compiler renders the resolved graph into consumer files for:

- Quickshell, Hyprland, Hyprlock, and Hyprtoolkit;
- Alacritty, foot, Ghostty, Kitty, `btop`, `wifitui`, Yazi, and Neovim;
- Qt 5 and Qt 6 palettes;
- GTK 3 and GTK 4, including a palette-derived Colloid theme;
- theme metadata, icons, wallpapers, and previews.

The generated `quickshell.json` owns semantic colors, typography, geometry,
borders, spacing, and component-specific appearance for the bar, panels,
menus, OSD, notifications, polkit, application picker, calculator, and
wallpaper picker. See [Customizing the bar](customizing-bar.md#change-the-appearance)
for its bar geometry.

The generated `theme.yaml` contains the fully merged and resolved graph for
inspection. It is output, not the next authoring source.

## GTK output

The active artifact contains a `gtk-theme/` payload. `hk-theme set` copies that
payload to:

```text
~/.local/share/themes/hyprkarl/
```

This is a marked real-file copy. GTK discovery and asset loading have been
unreliable through moving theme-directory symlinks, so do not replace it with a
symlink tree. Edit theme source and select the theme again instead of editing
the installed copy. Dark sources compile Colloid's dark variant; `mode: light`
compiles its light variant. The user-owned `~/.config/gtk-3.0/settings.ini` and
`gtk-4.0/settings.ini` select the stable `hyprkarl` theme name; `hk-theme set`
applies the light/dark preference through desktop settings.

## Legacy complete bundles

The integrated compiler no longer accepts a hand-written complete generated
bundle as theme source. During migration, `hk-user-migrate` moves one to a
dated backup under:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/theme-backups/
```

It does not delete or reinterpret that bundle. To convert it, create a source
directory under `~/.config/hyprkarl/themes/<name>/`, move the original palette
or intentional token values into `theme.yaml`, put structural consumer changes
under `overrides/`, and copy wallpapers, icons, and previews as assets. Build
it with `hk-theme set <name>`, compare the result with the backup, then keep or
remove the backup on your own schedule.

## Wallpapers

Built-in wallpapers live in `themes/<name>/wallpapers/`. Personal additions
and inherited removals live under the matching personal theme source. The
wallpaper commands update both personal source state and the active artifact:

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
