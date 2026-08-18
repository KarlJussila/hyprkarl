# AGENTS.md

Guidance for coding agents working on the AGS bar.

## What This Is

AGS (Aylur's GTK Shell) bar for Hyprland. TypeScript + TSX compiled and run by the `ags` CLI. `app.ts` is the entrypoint; everything under `bar/` is the bar implementation.

## Goals

Optimize every change for readability first. The bar has two working layers,
and each should stay approachable for its audience:

- **Configuration layer** — someone with minimal technical context should be
  able to add, remove, or reposition widgets by editing
  `bar/config/layout.config.ts` (also home to bar-level toggles: `edge`,
  `autohide`, `exclusive`, and island appearance via `corners`, `borders`,
  `dividers`), adjust widget behavior in `bar/config/widgets.config.ts`, and
  adjust styling through `bar/theme.scss`.
- **Implementation layer** — new widget kinds, primitives, and layout code
  under `bar/`.

Keep the configuration entry points stable. If an option is too low-level for
most users, hide it behind an internal default instead of expanding the main
config surface.

## Commands

```bash
npm run typecheck      # tsc --noEmit over the bar sources (catches type errors)
npm run bundle:check   # Confirm AGS can bundle app.ts (writes to /tmp)
npm run check          # typecheck + bundle:check — run this before calling a change done
```

There is no dev server. The live bar reloads when AGS is restarted (`hk-ags restart`).

`ags bundle` transpiles with esbuild, which strips types without checking them —
so bundling alone never catches type errors; they show only as editor squiggles.
`npm run typecheck` runs a real `tsc` and is the source of truth. It filters out
errors originating in AGS's own bundled library sources (`/usr/share/ags`,
`gnim`), which our imports pull in and `skipLibCheck` can't suppress; the filter
lives in `typecheck.sh`.

There is no test suite — `widgets.config.ts` is type-checked at edit time via
the `WidgetDefinitions` union, and `assertWidgetsExist` performs the only
runtime validation at bar mount. If you add genuinely tricky stateful behavior,
add a targeted test alongside it; don't reintroduce a generic test layer.

### Dev environment (`node_modules` + `@girs`)

Both are gitignored and never committed; they're generated in **this repo dir**,
which is the single source of truth — `~/.config/ags/{node_modules,@girs}` are
just stow symlinks back here. `setup-dotfiles.sh` builds them before stowing:
`npm install` creates `node_modules` (the `ags`/`gnim` entries are recorded as
links in `package-lock.json`, so no registry fetch — and they resolve to
**relative** symlinks, which matters: stow aborts on absolute ones), and `ags
types` generates `@girs`. On a fresh clone, run `npm install` + `ags types -d .`
— or just rerun `setup-dotfiles.sh` — before `npm run check` will work.

## Architecture

### Configuration pipeline

1. `bar/config/layout.config.ts` — data-only: bar edge, widget ID order, island appearance (`corners`, `borders`, `dividers`). This file is a symlink to the active theme's `bar-layout.ts`.
2. `bar/config/widgets.config.ts` — data-only: widget instances keyed by ID; `kind` picks the implementation.
3. `bar/widgets/index.ts` — flat registry that maps every `kind` to a Component plus its `defaults` object. Also exports `assertWidgetsExist`, the only runtime validation in the pipeline (catches typos in layout widget IDs and unknown kinds; everything else is TypeScript).
4. `bar/Bar.tsx` — looks up `widgets[def.kind].Component` and renders it directly. No resolve/normalize step.

Widget IDs in `layout.config.ts` are instance names, not kind names. Two IDs
with the same `kind` produce independently configured widget instances (e.g.
`battery` and `batteryCompact`) — defining multiple IDs with the same `kind` is
the supported way to expose differently configured variants of one widget.

### Widget files

Reference: `bar/widgets/_template/` — copy this folder to start a new widget.

Every widget lives in its own folder at `bar/widgets/<kind>/`, with the component entry at `<kind>/index.tsx`. That file:

1. Exports a `<Kind>Config` type with every field optional.
2. Exports a `defaults` const matching the resolved (all-fields-present) shape.
3. Default-exports the component. Inside, `mergeConfig(defaults, config)` fills in any unspecified fields with defaults (one-level-deep merge — passing a partial nested object keeps the unspecified keys from defaults).

Simple widgets (`clock`, `cpu`, `gpu`, `menu`, `ram`, `recording`) are folders containing one or two files. Complex widgets (`audio`, `battery`, `bluetooth`, `network`, `toggle`, `tray`, `workspaces`) have sibling files for state stores, sub-components, and helpers — the folder *is* the namespace, so siblings drop the widget-name prefix (e.g. `audio/Indicator.tsx`, `audio/state.ts`, not `AudioIndicator.tsx` / `audioState.ts`). Components are `PascalCase.tsx`, utilities are `camelCase.ts`.

To register a new widget kind: import its component, defaults, and Config in `bar/widgets/index.ts`, add an entry to the `widgets` map and `ConfigByKind` map, and document its config surface in `bar/widgets/SPEC.md`.

### Shared widget utilities

- `bar/widgets/shared/types.ts` — `WidgetProps<TConfig>`, `WidgetClicks`, `WidgetFlyout`, `defaultFlyout`, and `mergeConfig(defaults, overrides)`.
- `bar/widgets/shared/useWidgetCommands.ts` — `useWidgetCommands({ commands, primaryFallback?, secondaryFallback?, tertiaryFallback?, tokens?, flyout? })`. Returns `{ execPrimary, execSecondary, execTertiary, triggerSetup }`. The single entry point for wiring clicks; pass `flyout` to opt the widget into a flyout. Tokens like `{flyout}`, `{toggle-alt}`, `{toggle-label}` are user-facing strings that can appear as `commands` values in `widgets.config.ts`.
- `bar/widgets/shared/template.ts` — `substituteTokens(template, substitutions)` for `{token}` substitution with per-line whitespace normalization.
- `bar/widgets/shared/PollingMonitor.tsx` — shared view used by `cpu/` and `ram/`; owns format selection, alt-toggle state, decimal selection, tooltip, and reveal animation.
- `bar/widgets/shared/formatters.ts`, `drawScale.ts`, `resolveCommand.ts` — small leaf helpers.
- `bar/flyout/createFlyout.tsx` — low-level flyout mount. Most widgets don't call this directly; they go through `useWidgetCommands` with a `flyout` option.

### Config surface conventions

- User-facing tooltips are plain strings (or per-state objects when the widget varies tooltip by state). Empty string = no tooltip for that state.
- Rendering metrics (`indicator.*`, `slider.*`, `switch.*`) live in each widget's `defaults`. They can be overridden in `widgets.config.ts` if needed, but the canonical config doesn't surface them — see `SPEC.md` for the full per-widget knob list.
- A widget without an entry in `widgets.config.ts` cannot be referenced from `layout.config.ts` — `assertWidgetsExist` throws a readable `Error` at bar mount, and the bar falls back to a config-error UI showing the message.

### Styling

- `bar/theme.scss` — the public styling API; edit this for spacing, radii, typography, colors. Group tokens by purpose, keep common edits near the top, prefer short semantic token names.
- `bar/styles/` — internal SCSS partials (`_layout.scss`, `_widgets.scss`, `_flyouts.scss`, `_shared.scss`).
- `style.scss` — root stylesheet that `@use`s the partials; most bar changes belong in `theme.scss`, not here.
- GTK still supplies base colors; each theme's `bar.scss` overrides the palette.

CSS class naming conventions:
- `bar-*` — bar shell and layout structure.
- `widget-*` — widget-level public hooks.
- `is-*` — state classes (`is-active`, `is-open`, `is-vertical`).

When exposing CSS hooks, prefer explicit classes from this list over selectors
that rely on widget tree structure. If a style change requires tracing several
nested selectors, that usually means the hook should be made more explicit.

### Flyouts

Flyout windows (clock calendar, audio slider, battery profiles) are in `bar/flyout/`. Widgets opt into a flyout by passing the `flyout` option to `useWidgetCommands`; it owns the open state and wires up the flyout mount, returning a `triggerSetup` to attach to the button.

### Toggle widget

`bar/widgets/toggle/` is a generic stateful switch widget. Config: `commands: { on, off, sync }` (separate shell commands for each state transition; `sync` must exit 0 when active, non-zero when inactive) and `endpoint` (AGS request identifier — external scripts call `ags request <endpoint>` to trigger a re-sync). Use this as a template for any toggle backed by an external service. The controller is keyed by `endpoint`, so multiple independent toggle instances can coexist.

## Coding Style

- TypeScript strict mode, TSX components, 2-space indent, no semicolons (Prettier defaults in `package.json`).
- `PascalCase` for component files, `camelCase` for utility modules.
- Keep `layout.config.ts` and `widgets.config.ts` data-only — no logic.
- Preserve reactive prop types (`Accessor<T> | T`) through wrapper chains; do not narrow them back to plain values.
- Comment the why where code is dense (the collapse logic in `bar/layout/islandLayout.tsx` and the GPU autosuspend throttling in `bar/widgets/gpu/state.ts` are the house style); don't add obvious comments.
- When building a new widget, copy `bar/widgets/_template/` to `bar/widgets/<kind>/`. Start with just `index.tsx`; add sibling files as needed without prefixing them with the widget name — the folder is the namespace.
