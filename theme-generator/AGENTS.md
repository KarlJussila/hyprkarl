# Theme compiler

Use these instructions for compiler, renderer, CLI, GTK, validation, template,
and test work under `theme-generator/`. Follow the repository-level
`../AGENTS.md` as well. Changes to a built-in theme source under `../themes/`
also load `../themes/AGENTS.md`, which owns the authoring workflow and color
contract.

## Ownership

- `theme_generator/theme.py` owns recursive merge, native expression
  resolution, required-color validation, and template helpers.
- `theme_generator/render.py` owns source-layer resolution, template rendering,
  asset precedence, and complete bundle assembly.
- `theme_generator/gtk.py` owns Colloid compilation and GTK asset recoloring.
- `theme_generator/preview.py` owns terminal and graphical palette previews.
- `theme_generator/capture.py` owns the repeatable live desktop screenshot
  setup and complete-set preview publication.
- `theme_generator/wallpaper.py` owns the optional palette-derived default
  wallpaper.
- `theme_generator/validation.py` owns whole-repository build validation.
- `theme_generator/cli.py` is the single command-line boundary.
- `defaults/theme.yaml` owns shared typed tokens and final consumer defaults.
- `templates/` owns shared consumer templates; a theme override replaces one
  complete template at the same relative path.
- `vendor/colloid/` is pinned third-party source. Preserve its license and keep
  Hyprkarl-specific work outside it when possible.

## Source and renderer contracts

The compiler recursively merges shared defaults, a built-in source, and an
optional same-name personal source before resolving expressions. Objects merge;
arrays and scalar values replace. YAML strings, integers, decimals, and
booleans retain their types, and whole-value Jinja expressions resolve to
native values.

The source vocabulary is open-ended. Do not schema-check or allowlist custom
token names, require authors to use the shipped `metrics`, `motion`, or
`typography` structures, or add a second expression language. The resolved
`shell` object is the stable `quickshell.json` consumer value; its inputs may
use any author-defined structure.

Validate required semantic colors, unresolved expressions, source-layer
requirements, and external tool failures at the public build boundary. Within
that boundary, renderer components rely on those contracts. Do not add guards
for impossible internal misuse or restrict owner-authored templates and source
graphs.

Build into a clean staging directory and publish only a complete validated
bundle. Generated bundles are runtime artifacts, not authoring sources. Keep
the prior output intact when a replacement fails.

`wallpaper.generate_default` explicitly opts a theme into the shared Hyprkarl
wallpaper. Its default colors are `base.background`, `accent.primary.base`, and
`accent.primary.soft`. Authored assets are linked into the same bundle after
it is written, so an authored file with the generated filename replaces it.
Assets are links rather than copies so that large wallpaper collections cost
nothing per build.

## Implementation rules

Use Python for structured data, YAML and JSON work, template handling, parsing,
and substantial string manipulation. Do not add shell parsing, forwarding
wrappers, consumer-specific CLI branches, or another template/merge layer.
Keep each responsibility with the owner above rather than teaching the CLI or
renderer about individual themes.

When adding a consumer, add one shared template and generate every built-in
theme. Use a theme override only when that theme needs structurally different
output; values that fit the shared graph belong in `theme.yaml` or
`defaults/theme.yaml`.

## Checks

Run from `theme-generator/`:

```bash
python -m theme_generator validate
python -m pytest -q
```

For a focused authoring preview or disposable build:

```bash
python -m theme_generator preview <name>
python -m theme_generator capture <name>
python -m theme_generator build <name> -o /tmp/<name>-theme
```

Live capture uses an empty numbered workspace, opens its windows in tiling
order, and intentionally controls focus, OSD and notification state, selected
items, and pointer hover. Keep that setup aligned with the shipped busy,
launcher, menu, and wallpaper screenshots. Never move or float capture windows
to imitate the layout.
