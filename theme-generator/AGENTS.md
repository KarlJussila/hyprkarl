# AGENTS.md: authoring a new theme

You are helping a user create or change a Hyprkarl theme. This file covers the
compiler and theme authoring rules. Follow the repository-level `../AGENTS.md`
as well.

For how the build pipeline works, read `README.md`. This directory contains
Hyprkarl's theme compiler. A **theme** is generated
from one typed `theme.yaml` graph. Shared defaults provide the normal fonts,
geometry, motion, and consumer values; each theme provides its colors and any
overrides. Everything downstream (terminals, Quickshell, Hyprland, GTK,
Qt, …) is rendered from the resolved graph.

Your task, almost always, is to **translate a reference color scheme the user
provides into the required color groups** — typically a terminal colorscheme
(Alacritty/Kitty/iTerm/base16/etc.), but any source with a background, a
foreground, and a set of accent colors works. If the user hasn't given you a
reference, ask for one (or for the mood/colors they want) before writing the
theme. The same source may also customize typed non-color tokens or introduce
its own vocabulary. The rest of this document tells you how.

The generator itself is organized by responsibility under `theme_generator/`:
`theme.py` owns deep merge, native expression resolution, and color validation;
`render.py` owns complete
bundle assembly, `gtk.py` owns Colloid compilation, and `cli.py` is the only
command-line boundary. Keep structured data and template work in Python. Do
not add shell parsing, forwarding scripts, a second template language, or
consumer-specific branches to the CLI. Validate theme sources and external
tool failures at their boundaries; trusted renderer components may rely on
those contracts.

---

## 1. The workflow

```bash
# Run these commands from theme-generator/.

# 1. Write ../themes/<name>/theme.yaml  (see §2–§5)

# 2. Preview the colors in the terminal (show the user)
python -m theme_generator preview <name>

# 3. Generate a disposable complete theme bundle
python -m theme_generator build <name>       # writes output/<name>/

# 4. Confirm every built-in theme generates cleanly
python -m pytest -q

# 5. Activate through Hyprkarl's public command
hk-theme set <name>
```

Most built-in themes need **only** `../themes/<name>/theme.yaml`. Personal
themes and same-name overlays belong in
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/<name>/`. Explicit template
overrides, wallpapers, and previews are optional (see §7).

---

## 2. Typed source model

`defaults/theme.yaml` is recursively merged with the theme source before any
expressions resolve. Objects merge; arrays and scalar values replace. YAML
strings, integers, decimals, and booleans retain their types, and whole-value
Jinja expressions resolve to native values rather than being coerced to text.

The source vocabulary is open-ended. Never reject an unknown object or require
theme authors to use the shipped `metrics`, `motion`, or `typography` names.
Authors may add their own structures and reference them from consumer values:

```yaml
widths:
  standard_border: 2
  popup_radius: 10

shell:
  metrics:
    borderWidth: "{{widths.standard_border}}"
  panel:
    radius: "{{widths.popup_radius}}"
```

The resolved `shell` object is the stable `quickshell.json` consumer contract.
Its inputs may use any vocabulary. Do not add a schema or allowlist for custom
tokens, deletion markers for harmless unused defaults, or a second expression
language. Validate required colors and real rendering failures at their public
boundaries; otherwise trust the author.

## 3. Color palette structure

A palette starts with `mode: dark` or `mode: light`, followed by six color
groups. Any color may be a literal hex string (`"#rrggbb"`) or
a Jinja2 expression that references another palette value and/or calls a color
function (see §6). Values are resolved over multiple passes, so derived values
can reference other derived values.

### `base` — surfaces and text

| Key | Meaning | Typical source |
|---|---|---|
| `background` | Deepest color; the terminal/desktop background | scheme background |
| `layer0`–`layer4` | Layered surfaces, progressively lighter (`layer0` == background) | `lighten(background, 3/7/10/14)`, or hand-picked surface colors |
| `surface_soft` / `surface` / `surface_alt` | Semantic aliases, usually `layer1` / `layer2` / `layer4` | derived |
| `foreground` | Primary text | scheme foreground |
| `foreground_muted` | Secondary/dimmer text | `darken(foreground, ~13)` or a "comment" gray |
| `foreground_dim` | Faint text (e.g. inactive) | `darken(foreground, ~30)` |

### `ansi` — the 8 normal terminal colors

`black red green yellow blue magenta cyan white`. Map these **directly** from the
reference scheme's normal colors (color0–color7).

### `bright` — the 8 bright terminal colors

Same keys as `ansi`. Map from the scheme's bright colors (color8–color15). **Any
missing key is auto-derived as `lighten(ansi.<key>, 20)`** — so you can omit the
whole group, or only specify the ones you want to pin (e.g. `bright.black`).

### `accent` — identity colors (`primary`, `secondary`, `tertiary`)

Each accent has three shades:

```yaml
accent:
  primary:
    base:   "{{ansi.magenta}}"                       # the theme's signature hue
    soft:   "{{darken(accent.primary.base, 25)}}"    # muted variant
    bright: "{{bright.magenta}}"                      # vivid variant
```

- **primary** — the theme's signature/identity color (what makes it recognizable).
- **secondary** — the main contrasting accent.
- **tertiary** — a calmer/semantic accent.

Pick the three `base` colors from the `ansi` group (occasionally a literal). A
good default for `soft` is `darken(base, 25)` and for `bright` the matching
`bright.<color>`.

### `status` — semantic state colors

`success warning error urgent`. Conventionally green / yellow / red / bright-red,
sourced from `ansi`/`bright` or the accents:

```yaml
status:
  success: "{{ansi.green}}"
  warning: "{{ansi.yellow}}"
  error:   "{{ansi.red}}"
  urgent:  "{{bright.red}}"
```

### `ui` — semantic UI roles

| Key | Meaning | Common value |
|---|---|---|
| `cursor` | Cursor color | scheme cursor, or `base.foreground` |
| `text` | Default UI text | `{{base.foreground}}` |
| `text_secondary` | Secondary UI text | `{{accent.tertiary.base}}` |
| `selection_bg` / `selection_fg` | Selection highlight | `base.layer4` / `base.foreground` |
| `panel` | Panel/surface background | `{{base.surface}}` |
| `border` | Primary border | `{{accent.primary.base}}` |
| `border_inner` | Secondary/inner border | a muted gray or second accent |
| `border_soft` | Muted border | `{{accent.primary.soft}}` |
| `highlight` | Active/highlight color | `{{accent.primary.bright}}` |

---

## 4. Generating colors from a reference color scheme

This is the recommended path. Given a reference scheme, follow these steps.

**Step 1 — Extract the source colors.** From the reference, pull:
`background`, `foreground`, `cursor` (if present), `selection` bg/fg (if
present), and the 16 terminal colors (`color0`–`color15`). base16 schemes give
you `base00`–`base0F`; standard terminal configs give you the 16 directly.

**Step 2 — Fill the obvious 1:1 mappings.**

| Palette key | Source |
|---|---|
| `base.background` | scheme `background` |
| `base.foreground` | scheme `foreground` |
| `ansi.{black…white}` | `color0`–`color7` |
| `bright.{black…white}` | `color8`–`color15` (omit any you want auto-derived) |
| `ui.cursor` | scheme cursor (else `base.foreground`) |
| `ui.selection_bg` / `ui.selection_fg` | scheme selection (else `base.layer4` / `base.foreground`) |

**Step 3 — Derive the surface layers.** If the scheme ships explicit surface
shades (many base16 schemes do — `base01`/`base02`), use them for `layer1`–
`layer4`. Otherwise derive them: `layer1 = "{{lighten(base.background, 3)}}"`,
then `7`, `10`, `14`. Keep `layer0 = "{{base.background}}"`.

**Step 4 — Derive the muted foregrounds.** Use the scheme's "comment"/gray color
for `foreground_muted` if it has one; otherwise `darken(base.foreground, 13)`
and `darken(base.foreground, 30)` for muted/dim.

**Step 5 — Choose the accents.** This is the one judgment call. Pick:
- **primary.base** — the scheme's most identifying hue (its "brand" color).
- **secondary.base** — a strong contrasting hue.
- **tertiary.base** — a calmer third hue.

Source each from `ansi.*` and fill `soft`/`bright` with `darken(base, 25)` and
`bright.<color>`. When in doubt, look at how `themes/hyprkarl`,
`themes/gruvbox`, and `themes/everforest` assign accents — they are the
reference implementations.

**Step 6 — Wire up `status` and `ui`** using the conventional mappings in §3.
Prefer expressions (`{{ansi.green}}`, `{{accent.primary.base}}`) over duplicated
literals so the palette stays internally consistent.

**Step 7 — Check contrast.** Text colors must be readable on their backgrounds.
Where a chosen color may be too low-contrast, wrap it with `ensure_contrast`,
e.g. `"{{ensure_contrast(accent.tertiary.base, base.surface, 4.5)}}"`.

**Step 8 — Generate, preview, and iterate** (§1). `theme_generator preview` is
the fast feedback loop; `theme_generator build` produces the full bundle.

---

## 5. A minimal starting template

```yaml
mode: dark

base:
  background: "#1e1e2e"
  layer0: "{{base.background}}"
  layer1: "{{lighten(base.layer0, 3)}}"
  layer2: "{{lighten(base.layer0, 7)}}"
  layer3: "{{lighten(base.layer0, 10)}}"
  layer4: "{{lighten(base.layer0, 14)}}"
  surface_soft: "{{base.layer1}}"
  surface: "{{base.layer2}}"
  surface_alt: "{{base.layer4}}"
  foreground: "#cdd6f4"
  foreground_muted: "{{darken(base.foreground, 13)}}"
  foreground_dim: "{{darken(base.foreground, 30)}}"

ansi:        # map color0–color7 here
  black: "#45475a"
  red: "#f38ba8"
  green: "#a6e3a1"
  yellow: "#f9e2af"
  blue: "#89b4fa"
  magenta: "#f5c2e7"
  cyan: "#94e2d5"
  white: "#bac2de"

# bright: omitted — auto-derived as lighten(ansi.*, 20). Pin keys only if needed.

accent:
  primary:
    base: "{{ansi.blue}}"
    soft: "{{darken(accent.primary.base, 25)}}"
    bright: "{{bright.blue}}"
  secondary:
    base: "{{ansi.magenta}}"
    soft: "{{darken(accent.secondary.base, 25)}}"
    bright: "{{bright.magenta}}"
  tertiary:
    base: "{{ansi.green}}"
    soft: "{{darken(accent.tertiary.base, 25)}}"
    bright: "{{bright.green}}"

status:
  success: "{{ansi.green}}"
  warning: "{{ansi.yellow}}"
  error: "{{ansi.red}}"
  urgent: "{{bright.red}}"

ui:
  cursor: "{{base.foreground}}"
  text: "{{base.foreground}}"
  text_secondary: "{{accent.tertiary.base}}"
  selection_bg: "{{base.layer4}}"
  selection_fg: "{{base.foreground}}"
  panel: "{{base.surface}}"
  border: "{{accent.primary.base}}"
  border_inner: "{{ansi.black}}"
  border_soft: "{{accent.primary.soft}}"
  highlight: "{{accent.primary.bright}}"
```

---

## 6. Color functions

Usable as functions (`lighten(x, 10)`) or Jinja2 filters (`x | lighten(10)`):

| Function | Effect |
|---|---|
| `lighten(c, pct)` / `darken(c, pct)` | Shift HSL lightness by ±pct |
| `saturate(c, pct)` | Shift HSL saturation |
| `rotate(c, deg)` | Rotate hue by degrees |
| `mix(c1, c2, pct)` | Blend `pct`% of `c2` into `c1` |
| `ensure_contrast(fg, bg, target=4.5)` | Nudge `fg` until it meets a WCAG contrast ratio against `bg` |
| `contrast(c1, c2)` / `luminance(c)` | Measure contrast ratio / relative luminance |
| `rgba(c, alpha)` | `rgba(r,g,b,alpha)` string |
| `hyprrgb(c)` | `rgb(rrggbb)` (Hyprland format) |
| `strip_hash(c)` | hex without the leading `#` |

Percentages are absolute HSL points (e.g. `lighten(c, 10)` adds 0.10 to
lightness), not relative.

---

## 7. Optional: template overrides and wallpapers

The base templates in `templates/` apply to every theme and derive their
values from the resolved token graph, so most themes need no overrides. Add files under
`../themes/<name>/overrides/` only when:

- the base template's color choices don't look good for your palette, or
- you want structurally different output for a tool.

A theme-specific file at the same relative path **replaces** the base one.
Do not use an override merely to change a value that belongs in `theme.yaml`.

To ship wallpapers and preview screenshots with the theme, add:

- `../themes/<name>/wallpapers/` — wallpaper images copied verbatim into the
  generated theme. By convention `01-*` is the primary wallpaper. **Only
  include images you have the right to redistribute.**
- `../themes/<name>/previews/` — `busy.png`, `launcher.png`, `menu.png`, and
  `wallpapers.png`; these become `screenshots/` in the generated bundle.

---

## 8. Definition of done

- `python -m theme_generator build <name>` succeeds and `output/<name>/` looks right.
- `python -m pytest -q` passes and validates that every theme, including the
  Quickshell semantic manifest and Colloid GTK output, generates cleanly.
- Text is readable on its backgrounds; accents are distinct and on-theme.
- Derived values use expressions rather than duplicated literals where practical.
