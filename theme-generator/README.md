# Hyprkarl theme compiler

This directory contains Hyprkarl's build-time theme compiler. One typed YAML
theme graph renders through shared templates into a complete desktop theme
bundle.

![Desktop](../themes/hyprkarl/previews/busy.png)

<p align="center">
  <img src="../themes/hyprkarl/previews/launcher.png" width="49%" alt="Launcher" />
  <img src="../themes/hyprkarl/previews/menu.png" width="49%" alt="Menu" />
</p>

## Ownership Model

```text
theme-generator/defaults/theme.yaml
                                shared typed tokens and consumer defaults
              │
              ├── deep merge ── themes/<name>/theme.yaml
              ├── deep merge ── ~/.config/hyprkarl/themes/<name>/theme.yaml
              │                 optional personal values
              ▼
recursive native Jinja resolution
              │
              ▼
theme-generator/templates/       shared consumer templates
theme-generator/theme_generator/ resolution, rendering, and validation
themes/<name>/                   built-in overrides and assets
~/.config/hyprkarl/themes/<name>/ personal overrides and assets
              │
              ▼
new build under XDG state, made active by hk-theme set
```

`defaults/theme.yaml` owns the shipped vocabulary and shared values for fonts,
spacing, radii, borders, motion, and final Quickshell appearance. A theme
source recursively merges over those defaults, then every Jinja expression is
resolved until the graph is concrete. Arrays and scalar values replace their
default; ordinary objects merge recursively.

The source vocabulary is deliberately open-ended. A theme may add arbitrary
objects and refer to them from the final consumer values. The generator does
not require custom tokens to use the shipped `metrics`, `motion`, or
`typography` terminology. The `shell` object is the stable generated
`quickshell.json` contract; how its values are derived remains theme-owned.

A personal source with the same name as a built-in merges over it before
expressions resolve. It may omit `theme.yaml` when it contains only overrides
or assets. A user-only theme must provide `theme.yaml`. Compiler templates,
built-in overrides, and personal overrides apply in that order. Assets use the
same precedence.

Hyprkarl consumes generated bundles and can stage one into runtime state. The
generator is not required in every desktop session.

## What It Generates

- Quickshell semantic colors, surfaces, typography, geometry, borders, and
  motion for the bar, panels, menu, OSD, notifications, polkit, and lock screen
- Hyprland
- Alacritty, Kitty, Ghostty, and foot
- btop, wifitui, and yazi
- Neovim
- Qt 5/6 palettes
- a palette-derived Colloid GTK 3/4 theme and recolored assets
- theme metadata, icons, wallpapers, and previews

Unlike theme systems that merely select Adwaita or Adwaita Dark, GTK output is
compiled from the same color tokens as the rest of the desktop.

## Requirements

- Python 3.10+
- `jinja2`, `colour`, `pillow`, and `pyyaml` from `requirements.txt`
- `sassc` for Colloid GTK compilation
- `grim` and `ydotool` for automated desktop screenshots

The normal Hyprkarl package setup installs these dependencies from the system
repositories. For development on another distribution, install the Python
dependencies directly:

```bash
pip install -r requirements.txt
```

## Commands

Run the module from `theme-generator/`:

```bash
python -m theme_generator build hyprkarl
python -m theme_generator build ../themes/my-theme -o /tmp/my-theme
python -m theme_generator build ../themes/my-theme -o /tmp/renamed --name renamed
python -m theme_generator build hyprkarl --overlay ~/.config/hyprkarl/themes/hyprkarl
python -m theme_generator preview hyprkarl
python -m theme_generator capture hyprkarl
python -m theme_generator validate
python -m pytest -q
```

`build` accepts a built-in name, a source directory, or a direct `theme.yaml`
path. It builds into a clean staging directory and replaces the destination,
so removed templates cannot survive as stale output.

`--name` sets the embedded theme name when it differs from the source directory
name. `--overlay` adds one personal source layer. `hk-theme set` owns normal
build and activation. The compiler CLI remains the direct authoring and test
tool.

`preview` prints the palette in the terminal and renders a 1600×1000 palette
board under `output/`. Pass `-o` to choose another image path.

`capture` activates the theme and writes `palette.png`, `busy.png`,
`launcher.png`, `menu.png`, and `wallpapers.png` to the source's `previews/`
directory. It uses empty numbered workspace 4 by default; pass `--workspace`
to select another empty workspace. The busy desktop is created through normal
tiling order, with fastfetch focused above a selected Nautilus folder on the
left and btop on the right. The command also stages a notification and volume
OSD, controls pointer hover deliberately, and restores the prior workspace and
pointer position. Existing previews are replaced only after the full set is
captured.

## Typed Theme Graph

YAML strings, integers, decimals, and booleans retain their native types.
Whole-value Jinja expressions also resolve natively, so arithmetic and boolean
expressions can feed JSON consumers without string coercion:

```yaml
dimensions:
  unit: 2
  standard_border: "{{dimensions.unit}}"
  popup_radius: "{{dimensions.unit * 5}}"

effects:
  animate: true
  duration: 140

shell:
  metrics:
    borderWidth: "{{dimensions.standard_border}}"

  polkit:
    radius: "{{dimensions.popup_radius}}"
    transitionDuration: "{{effects.duration if effects.animate else 0}}"
```

This custom vocabulary may coexist with or replace references to the shipped
`metrics` structure. Unused default tokens can remain in the resolved graph;
only values reachable from a consumer template affect generated behavior.

`templates/quickshell.json` serializes the resolved `shell` object with
Jinja's JSON encoder. Other consumer templates select whichever tokens they
need and remain ordinary text templates.

## Color Palette

The required color groups remain `base`, `ansi`, `bright`, `accent`, `status`,
and `ui`. Colors may be literals or expressions referencing any other token.
Missing bright ANSI colors derive from their normal counterpart.

```yaml
mode: dark

base:
  background: "#1e1e2e"
  layer0: "{{base.background}}"
  layer1: "{{lighten(base.layer0, 3)}}"
  foreground: "#cdd6f4"

ansi:
  red: "#f38ba8"
  # ...all eight ANSI colors

accent:
  primary:
    base: "{{ansi.red}}"
    soft: "{{darken(accent.primary.base, 25)}}"
    bright: "{{bright.red}}"
```

Available color functions are `lighten`, `darken`, `mix`, `saturate`,
`rotate`, `rgba`, `hyprrgb`, `strip_hash`, `contrast`, `luminance`, and
`ensure_contrast`. The complete color contract and authoring workflow are in
[the theme authoring instructions](../themes/AGENTS.md).

Invalid required colors, missing semantic color roles, unresolved expressions,
and template errors fail the build at its public boundary. Custom token names
and structures are not restricted. The previous output remains intact until a
complete replacement is ready.

Themes may set `wallpaper.generate_default: true` to render the shared
Hyprkarl wallpaper from the resolved background, primary accent, and soft
primary accent. The generated file joins any authored wallpaper assets.

The generated bundle includes the fully merged and resolved graph as
`theme.yaml`, making every consumer value inspectable without evaluating the
source again.

## Theme Exceptions

Most themes need only `theme.yaml`. Use
`overrides/<relative-template-path>` only for structurally different consumer
output. The override replaces the shared template; it does not add another
merge language.

Choose the desktop icon family in theme data:

```yaml
desktop:
  icon_theme: Yaru-olive-dark
```

```text
../themes/my-theme/
├── theme.yaml
├── overrides/
│   └── hyprland.lua
├── wallpapers/
└── previews/
```

### Migrating `palette.yaml` sources

Rename the source to `theme.yaml`. Its existing color groups remain valid; the
shared defaults supply the new non-color token graph. Generated bundles now
contain a resolved `theme.yaml` instead of the old raw `palette.yaml` copy.

Legacy output-only bundles are migration inputs, not authoring sources. Move
their original palette values and intentional overrides into the source layout
before relying on the integrated compiler.

## Code Layout

| Path | Responsibility |
|---|---|
| `defaults/theme.yaml` | Shared typed tokens and final consumer defaults |
| `theme_generator/theme.py` | Deep merge, native expression resolution, color validation, and template helpers |
| `theme_generator/render.py` | Source resolution, template rendering, and clean bundle assembly |
| `theme_generator/gtk.py` | Colloid compilation and GTK asset recoloring |
| `theme_generator/preview.py` | Terminal and graphical palette previews |
| `theme_generator/capture.py` | Repeatable live desktop screenshot staging |
| `theme_generator/wallpaper.py` | Optional palette-derived default wallpaper |
| `theme_generator/validation.py` | Whole-repository build validation |
| `theme_generator/cli.py` | The single command-line boundary |
| `templates/` | Shared consumer templates |
| `../themes/` | Built-in theme sources and explicit exceptions |
| `vendor/colloid/` | Pinned Colloid source |

## License

The vendored Colloid GTK theme is GPL-3.0. Hyprkarl's top-level license covers
the integrated compiler, and `vendor/colloid/LICENSE` records the vendored
license.
