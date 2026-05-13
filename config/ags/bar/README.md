# AGS Bar

This bar is organized around two customization levels:

Casual users: 
- Rearrange widgets in `config/layout.config.ts`
- Change widget behavior in `config/widgets.config.ts`
- Adjust styling in `theme.scss`
Advanced users:
- Change rendering and runtime logic under `widgets/`, `layout/`, `overlays/`, and `primitives/`
- Adjust styling in `layout/styles/`

## Start Here

- `config/layout.config.ts`: move the bar, reorder widget IDs, and toggle decorative corner curves
- `config/widgets.config.ts`: change labels, commands, visibility rules, dropdown settings, and other high-level behavior
- `theme.scss`: change spacing, radii, typography, borders, and most visual styling through grouped public tokens

## Quick Examples

Move widgets:

```ts
showCornerCurves: false,
start: ["menu", "workspaces"],
center: {
  start: [],
  anchor: "clock",
  end: ["caffeine"],
},
end: ["tray", "battery"],
```

Leave the center island empty:

```ts
center: {
  start: [],
  end: [],
},
```

Center a whole island without a dedicated anchor widget:

```ts
center: {
  start: ["clock", "caffeine"],
  end: [],
},
```

Layout references can reuse the same widget ID more than once when you want the same widget in multiple slots.

Change widget behavior:

```ts
clock: {
  kind: "clock",
  display: {
    horizontal: "%a %-I:%M %p",
  },
  dropdown: {
    enabled: false,
  },
},
```

Advanced widget drawing overrides stay nested so the main config surface stays readable:

```ts
battery: {
  kind: "battery",
  advanced: {
    indicator: {
      width: 20,
      chargingGlyphFontSize: 10,
    },
  },
},
```

## Styling Guide

`theme.scss` is the public styling surface. It is grouped by editing task:

- `Core colors`: text, surface, accent, border, error, and low-battery colors
- `Typography`: main UI font, mono font, and font size
- `Bar shell`: island radius and border width
- `Shared controls`: default button padding
- `Widget tuning`: workspace, tray, and battery spacing
- `Dropdowns`: dropdown padding and row sizing

Common styling changes:

- tighter buttons: lower `$button-pad-x`
- rounder islands: raise `$radius`
- hide only the decorative curve cutouts: set `showCornerCurves: false` in `layout.config.ts`
- softer separators: change `$border`
- bigger dropdown rows: raise `$dropdown-row-pad-y`
- more obvious active workspace: change `$accent`

Theme tokens stay short because `theme.scss` is already a namespace. Rendered CSS classes stay prefixed (`bar-*`, `widget-*`, `is-*`) because they live in the global selector space and act as the public styling hooks for the actual widget tree.

## Architecture

`app.ts` starts the bar and `Bar.tsx` resolves config before rendering per monitor. The configuration pipeline is:

1. `config/layout.config.ts` and `config/widgets.config.ts` export data-only config.
2. `widgets/registry.shared.ts` validates layout references and normalizes widget definitions.
3. `widgets/shared/widgetDefinitions.ts` dispatches normalization by widget kind.
4. Each widget folder owns a `definition.ts` file for defaults and config normalization.
5. `widgets/registry.tsx` renders normalized widgets through `manifest.tsx` files.

Each widget folder now has a split responsibility:

- `definition.ts`: public config shape, defaults, and normalization
- `manifest.tsx`: render registration for the widget
- `WidgetName.tsx`: top-level view component, kept intentionally small
- helper files: extracted behavior, service integration, and sub-components

Shared internal helpers live in `widgets/shared/`. For example, `DropdownButton.tsx` centralizes dropdown trigger wiring so widgets like clock and battery do not duplicate it.

## Styling Architecture

The styling system now separates public and internal hooks:

- Public theme tokens live in `theme.scss`
- Public widget classes start with `widget-`
- Public shell/layout classes start with `bar-`
- State classes use `is-*`, for example `is-active`, `is-open`, and `is-vertical`

Examples of safe styling hooks:

- `bar-shell`
- `bar-segment`
- `widget-menu-button`
- `widget-workspace-button`
- `widget-battery-display`
- `widget-tray-panel`
- `dropdown-row`

Internal helper classes may still exist to support layout math, but styling changes should usually start from the public hooks above.

## Contributor Notes

Keep `layout.config.ts`, `widgets.config.ts`, and `theme.scss` friendly to edit. If a new styling knob is likely to matter to many users, expose it as a grouped token in `theme.scss`. If it is too low-level, keep it internal or hide it behind a nested `advanced` section. Prefer explicit `widget-*`, `bar-*`, and `is-*` classes over selectors that depend on GTK child structure.

## Troubleshooting

- Run `npm run check` from the project root (`config/ags` in this repo layout) to run config tests and confirm the bar still bundles.
- If the bar shows a config error fallback, read the terminal output first. Errors point directly to the bad path in `layout.config.ts` or `widgets.config.ts`.
- GTK still supplies base colors. `theme.scss` is the main appearance entrypoint for the rest of the bar.
