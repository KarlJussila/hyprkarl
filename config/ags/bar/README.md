# AGS Bar

This bar is organized around two customization levels:

Casual users: 
- Rearrange widgets in `config/layout.config.ts`
- Change widget behavior in `config/widgets.config.ts`
- Adjust styling in the active theme's `bar.scss`
Advanced users:
- Change rendering and runtime logic under `widgets/`, `layout/`, `flyout/`, and `primitives/`
- Adjust styling in `layout/styles/`

## Start Here

- `config/layout.config.ts`: move the bar, reorder widget IDs, toggle decorative corner curves, and configure autohide
- `config/widgets.config.ts`: change labels, commands, visibility rules, flyout settings, and other high-level behavior
- `themes/<theme>/bar.scss`: change spacing, radii, typography, borders, and most visual styling through grouped public tokens

## Quick Examples

Move the bar, reorder widgets, and square off the gap-facing corners:

```ts
edge: "left",
corners: { screenInner: "square", contentInner: "square" },
start: ["menu", "workspaces"],
center: {
  start: [],
  center: ["clock"],
  end: ["caffeine"],
},
end: ["tray", "battery"],
```

Enable autohide (bar hides after pointer leaves, reveals on hover):

```ts
autohide: true,
```

Keep the bar visible but stop reserving screen space:

```ts
exclusive: false,
```

Use the classic edge look — concave curves where islands meet the screen edge across the gaps, rounded content-side corners:

```ts
// layout.config.ts
corners: {
  screenOuter: "square",
  screenInner: "curve",
  contentOuter: "square",
  contentInner: "round",
},
borders: { screen: false, content: true, outer: true, inner: true },
margin: 0,
```

Leave the center island empty:

```ts
center: {
  start: [],
  center: [],
  end: [],
},
```

Center a group of widgets without a single pivot:

```ts
center: {
  start: [],
  center: ["clock", "caffeine"],
  end: [],
},
```

Layout references can reuse the same widget ID more than once when you want the exact same widget instance in multiple slots.

Widget IDs are instance names, not kind names. When you want two differently configured copies of the same widget, define two IDs with the same `kind` and reference those IDs in the layout.

Use the same widget instance more than once:

```ts
start: ["clock"],
center: {
  start: [],
  center: ["clock"],
  end: [],
},
```

Create two different widget instances of the same kind:

```ts
clockCompact: {
  kind: "clock",
  format: "%H:%M",
  flyout: {
    align: "start",
  },
},

clockFull: {
  kind: "clock",
  format: "%a %-I:%M %p",
},
```

```ts
start: ["clockCompact"],
center: {
  start: [],
  center: ["clockFull"],
  end: [],
},
```

In practice:

- Reuse the same ID when you want the same config in multiple places.
- Create a second ID with the same `kind` when you want a variant with different behavior.

Change widget behavior:

```ts
clock: {
  kind: "clock",
  format: "%a %-I:%M %p",
  flyout: {
    align: "end",
  },
},
```

Add a network launcher widget:

```ts
network: {
  kind: "network",
  commands: {
    primary: "hk-launch-wifi",
  },
},
```

Add a Bluetooth launcher widget:

```ts
bluetooth: {
  kind: "bluetooth",
  commands: {
    primary: "hk-launch-bluetooth",
  },
},
```

Add an audio widget with a flyout slider, optional percentage label, and configurable tooltip text:

```ts
audio: {
  kind: "audio",
  showPercentage: true,
  commands: {
    secondary: "hk-launch-audio",  // right-click launches audio app; left-click opens flyout
  },
  tooltip: {
    enabled: true,
    active: "{device} {percentage}",
    muted: "Muted {device}",
    unavailable: "Audio unavailable",
  },
},
```

Disable the audio tooltip entirely:

```ts
audio: {
  kind: "audio",
  tooltip: { enabled: false },
},
```

Customize battery tooltip text without touching widget code:

```ts
battery: {
  kind: "battery",
  tooltip: {
    enabled: true,
    charging: "{percentage} charging at {power}",
    discharging: "{power} remaining draw {percentage}",
    plugged: "On AC {percentage}",
    fallback: "Battery {percentage}",
  },
},
```

Set `tooltip: { enabled: false }` to suppress the battery tooltip entirely.

Battery tooltip tokens:

- `{power}`: current battery draw or charge rate in watts, for example `17.0W`
- `{time}`: remaining charge or discharge time when the service reports it, for example `2:00`
- `{percentage}`: battery percentage, for example `42%`

Audio tooltip tokens:

- `{device}`: current output description when available, for example `Speakers`
- `{percentage}`: current volume percentage, for example `42%`

Battery indicator overrides live directly on the widget config. The shape parallels the toggle's switch: pixel dimensions at the top level, font typography shared across glyphs, and a `glyphs` record where each entry has `glyph` + `glyphOffset`:

```ts
battery: {
  kind: "battery",
  indicator: {
    width: 20,
    terminalWidth: 5,
    terminalHeight: 2,
    fontSize: 10,
    fontFamily: "JetBrains Mono Nerd Font Propo",
    glyphs: {
      charging: { glyph: "󱐋", glyphOffset: [0, 0] },
    },
  },
},
```

Audio has two configurable surfaces: the bar icon (`indicator`) and the slider in the flyout (`slider`). Tune the bar icon's overall size and stroke weight with two knobs:

```ts
audio: {
  kind: "audio",
  indicator: {
    height: 18,     // base canvas height in px (default 14)
    lineWidth: 2,   // stroke width (default 1.4)
  },
},
```

Audio slider tuning follows the same flat pattern:

```ts
audio: {
  kind: "audio",
  slider: {
    trackLength: 240,
    trackThickness: 8,
    trackRadius: 4,
    fillRadius: 4,
    borderWidth: 1,
    thumbWidth: 12,
    thumbHeight: 12,
    thumbRadius: 6,
    thumbVisible: false,
  },
},
```

## CPU Widget

The `cpu` widget shows CPU temperature, usage, and a per-core tooltip. By default, primary click toggles the label and secondary click switches between primary and alt formats. Both can be remapped via `commands` (see [Click Commands](#click-commands)).

```ts
cpu: {
  kind: "cpu",
  format: "{temp}°",
  formatAlt: "{temp}° | {usage}%",
  formatVertical: "{temp}°",
  formatVerticalAlt: "{usage}%",
  tooltip: {
    text: "CPU: {usage}%\n{cores}",
  },
  interval: 2000,
},
```

CPU format tokens:

- `{usage}`: overall CPU usage as a whole percent, for example `42`
- `{temp}`: CPU package temperature in degrees Celsius, for example `55`

CPU tooltip tokens include all format tokens plus:

- `{cores}`: multi-line per-core breakdown, for example `Core 0: 12%\nCore 1: 8%`

Set `tooltip: { text: "" }` to suppress the tooltip entirely.

Leave `format` empty to show the icon only. Leave `formatAlt` empty to disable the secondary click.

## GPU Widget

The `gpu` widget shows GPU usage, VRAM, and temperature for the active GPU. By default, primary click toggles the label and secondary click switches between primary and alt formats. Both can be remapped via `commands` (see [Click Commands](#click-commands)).

```ts
gpu: {
  kind: "gpu",
  format: {
    primary: "{usage}%",
    alt: "{usage}% | {vram_used}/{vram_total}",
    vertical: "{usage}%",
    verticalAlt: "{vram}%",
  },
  tooltip: "{name}\nUsage: {usage}%\nVRAM: {vram_used}/{vram_total}\nTemp: {temp}°",
  interval: 5000,
},
```

GPU format tokens:

- `{usage}`: GPU usage as a whole percent, for example `42`
- `{vram}`: VRAM usage as a percentage of total, for example `35`
- `{vram_used}`: used VRAM in GiB, for example `2.7G`
- `{vram_total}`: total VRAM in GiB, for example `8.0G`
- `{temp}`: GPU temperature in degrees Celsius, for example `55`
- `{name}`: the GPU's display name (tooltip use), for example `Radeon RX 7600`

Data is read vendor-agnostically: AMD and Intel metrics come from sysfs in-process (no subprocess), and NVIDIA falls back to `nvidia-smi`. The widget auto-selects the most capable active GPU. On hybrid laptops, a runtime-suspended discrete GPU is skipped — its live data is unavailable while asleep, so the active iGPU is shown instead; when the dGPU is genuinely in use it becomes active and is followed automatically.

The widget will not keep a discrete GPU awake. Reading an *active* discrete GPU's sensors (usage, VRAM, temperature) re-arms its runtime autosuspend timer, so for such a card the live sensors are read no faster than its autosuspend delay (the last reading is replayed in between); the card can then fall back to sleep when idle, and the widget reverts to the always-on GPU. The always-on GPU itself updates every `interval`. Pinning a discrete GPU with `card` (for example `"card1"`) bypasses auto-selection but is still subject to this throttle. A token with no available value (for example `{temp}` on hardware that exposes none) renders empty.

## RAM Widget

The `ram` widget shows RAM and swap usage. By default, primary click toggles the label and secondary click switches between primary and alt formats. Both can be remapped via `commands` (see [Click Commands](#click-commands)).

```ts
ram: {
  kind: "ram",
  icon: "",
  format: "{ram}%",
  formatAlt: "{ram_used}/{ram_total} | {swap_used}/{swap_total}",
  formatVertical: "{ram}%",
  formatVerticalAlt: "{ram_used}\n{swap_used}",
  decimals: 0,
  tooltip: {
    text: "RAM: {ram_used}/{ram_total}\nSwap: {swap_used}/{swap_total}",
  },
  interval: 2000,
},
```

RAM format tokens:

- `{ram}`: RAM usage as a percentage, for example `42`
- `{ram_used}`: used RAM as a human-readable size, for example `6.1G`
- `{ram_total}`: total RAM as a human-readable size, for example `16G`
- `{ram_free}`: free RAM as a human-readable size
- `{swap}`: swap usage as a percentage
- `{swap_used}`: used swap as a human-readable size
- `{swap_total}`: total swap as a human-readable size
- `{swap_free}`: free swap as a human-readable size

Set `tooltip: { text: "" }` to suppress the tooltip entirely.

Decimal precision is controlled per format slot. Setting `decimals` changes the base precision and the remaining fields fall back to it:

```ts
ram: {
  kind: "ram",
  decimals: 1,         // base: all slots default to 1
  decimalsAlt: 2,      // override for the alt format
  decimalsVertical: 0, // override for vertical
  // decimalsVerticalAlt defaults to decimalsVertical
},
```

## Clock Tooltip

The clock tooltip accepts a `strftime` format string via `tooltip.text`. When `text` is empty (the default), no tooltip is shown.

```ts
clock: {
  kind: "clock",
  tooltip: {
    text: "%A, %B %-d",
  },
},
```

This shows the full weekday and date, for example `Monday, May 25`. Any `strftime` format is valid — `%c` for the locale default, `%Y-%m-%d %H:%M:%S` for an ISO-style datetime, and so on. Set `text: ""` to suppress the tooltip entirely.

## Recording Widget

The `recording` widget is an indicator that appears only while a screen recording is active. It is hidden at all other times and takes no space in the bar. Clicking it stops the recording by running the configured command.

```ts
recording: {
  kind: "recording",
  icon: "󰻂",
  commands: {
    primary: "hk-record-screen --stop-recording",
  },
  tooltip: {
    text: "Recording — click to stop",
  },
},
```

The widget receives state updates via `ags request recording-sync`, which `hk-record-screen` calls automatically on start and stop. No polling is involved.

Set `tooltip: { text: "" }` to suppress the tooltip.

## Click Commands

Most widgets support a `commands` config object that lets you remap or add click actions without touching widget code:

```ts
commands: {
  primary?: string    // left click
  secondary?: string  // right click
  tertiary?: string   // middle click
}
```

Each field accepts:

- **omitted** — use the widget's built-in default for that click
- `""` — disable that click (no action)
- `"some-shell-command"` — run the command via `execAsync`
- `"{token}"` — call a widget-internal function

Supported tokens per widget type:

| Widget | Token | Effect |
|--------|-------|--------|
| clock | `{flyout}` | open/close the calendar flyout |
| clock | `{toggle-alt}` | switch between primary and alt time formats |
| audio | `{flyout}` | open/close the volume slider flyout |
| battery | `{flyout}` | open/close the power profiles flyout |
| cpu | `{toggle-label}` | reveal/hide the usage label |
| cpu | `{toggle-alt}` | switch between primary and alt formats |
| ram | `{toggle-label}` | reveal/hide the usage label |
| ram | `{toggle-alt}` | switch between primary and alt formats |

Examples:

```ts
// Disable right-click on clock (keep default left-click flyout)
clock: {
  kind: "clock",
  commands: { secondary: "" },
},

// Open the calendar flyout on right-click instead of left-click
clock: {
  kind: "clock",
  commands: { primary: "", secondary: "{flyout}" },
},

// Launch htop on middle-click from the CPU widget
cpu: {
  kind: "cpu",
  commands: { tertiary: "kitty --class floating htop" },
},

// Network widget: left-click opens settings, right-click opens a second tool
network: {
  kind: "network",
  commands: {
    primary: "hk-launch-wifi",
    secondary: "nm-connection-editor",
  },
},
```

## Autohide

Autohide is configured in `layout.config.ts`:

```ts
autohide: true,   // hide bar when pointer is not over it
exclusive: true,  // whether the bar reserves screen space when visible
```

When `autohide` is `true`, the bar hides 300ms after the pointer leaves and reveals when the pointer enters or a flyout opens. The reveal transition takes 100ms and is implemented as a margin offset.

The `exclusive` field is independent of `autohide`. Setting `exclusive: false` keeps the bar visible but stops reserving space at the screen edge.

### Bar CLI

The bar can also be controlled at runtime via `hk-ags` (or directly via `ags request bar <subcommand>`):

```bash
hk-ags autohide on|off|toggle   # change autohide mode
hk-ags exclusive on|off|toggle  # change exclusive mode
hk-ags show                     # force bar visible
hk-ags hide                     # force bar hidden
hk-ags toggle                   # toggle between forced show/hide
hk-ags status                   # print JSON: {autohide, exclusive, hidden}
```

These commands affect all monitors. `bar toggle` forces visibility off if the bar is currently shown and not in autohide mode, otherwise forces it visible.

## Layout And Instance Model

`layout.config.ts` controls bar-level structure:

- `edge`: which side of the screen the bar attaches to

Island appearance is composed from three independent knobs. Corners and sides are named in **screen/content** × **outer/inner** terms so the same name behaves correctly on any bar edge: **screen** is the long edge facing the docked screen edge, **content** the long edge facing away; **outer** is the short cap of the start/end islands that faces a screen edge, **inner** is any cap facing the gaps between islands (including both ends of the center island).

- `corners`: per-corner style, each `"round" | "square" | "curve"` (defaults to `"round"`). Keys: `screenOuter`, `screenInner`, `contentOuter`, `contentInner`.
  - `"curve"` draws the decorative concave cutout that joins islands to the screen edge across the gaps. It only has an anchor on the **screen-inner** corners (the gap-facing screen corner of every island — the start/end islands' inner corner and both caps of the center island, all set via `screenInner`). On any other corner `"curve"` falls back to `"square"`.
- `borders`: which island sides draw a border, each a boolean (default `true`). Keys: `screen`, `content`, `outer`, `inner`.
- `dividers`: whether separators are drawn between adjacent widgets within an island (default `true`).
- `margin`: reserved gap in pixels around the bar. A single number applies uniformly, or an object with `screen`, `outer`, `content` (all optional, default `0`): `screen` is the gap on the docked edge, `outer` the gap at the bar's two ends, `content` the gap reserved between the bar and the windows it pushes away. Example: `margin: 8` reserves 8 px all around; `margin: { screen: 4, outer: 8 }`. A non-zero `screen`/`outer` margin pairs well with fully-rounded ("capsule") islands. Autohide accounts for the configured screen-edge margin automatically.

Two common looks, expressed in these knobs:
- **Floating capsules** (the default): all `corners` `"round"`, all `borders` on, a small `margin`.
- **Classic edge bar**: `screenInner: "curve"` with `screenOuter`/`contentOuter` `"square"` and `contentInner: "round"`; `borders` `{ screen: false, content: true, outer: true, inner: true }`; `margin: 0`.
- `autohide`: whether the bar hides when the pointer is not over it
- `exclusive`: whether the bar reserves space at the screen edge (default true)
- `start`, `center`, and `end`: which widget IDs appear in each island; `center` has its own `start`, `center`, and `end` sub-lists

`widgets.config.ts` controls widget instances:

- each top-level key is a widget ID
- `kind` chooses the widget implementation
- the rest of the object configures that specific instance

That means this is valid:

```ts
clockCompact: { kind: "clock", flyout: { align: "start" } },
clockFull: { kind: "clock", flyout: { align: "end" } },
```

Both are `clock` widgets, but they are different instances because their IDs are different.

The built-in widget kinds currently include `menu`, `workspaces`, `tray`, `clock`, `caffeine`, `cpu`, `ram`, `audio`, `bluetooth`, `network`, and `battery`.

## Styling Guide

`themes/<theme>/bar.scss` is the public styling surface. It is grouped by editing task:

- `Core colors`: text, surface, background, accent, border, error, and low-battery colors
- `Typography`: main UI font, mono font, and font size
- `Bar shell`: island radius and border width
- `Widget tuning`: workspace, tray, icon, and widget padding spacing
- `Flyouts`: flyout padding and row sizing

Common styling changes:

- tighter buttons: lower `$widget-padding-horizontal`
- rounder islands: raise `$border-radius`
- change which corners are rounded/squared/curved: edit `corners` in `layout.config.ts`
- softer separators: change `$border`
- bigger flyout rows: raise `$flyout-row-pad`
- more obvious active workspace: change `$accent`

`corners` (in `layout.config.ts`) and `$border-radius` (in `theme.scss`) are independent:

- `corners` chooses each corner's treatment — `"round"`, `"square"`, or `"curve"` (the concave cutout drawn between islands and the screen edge).
- `$border-radius` controls how large the rounded/curved corners are.

## Architecture

`app.ts` starts the bar and `Bar.tsx` resolves config before rendering per monitor. The configuration pipeline is:

1. `config/layout.config.ts` and `config/widgets.config.ts` export data-only config.
2. `widgets/resolveBarConfiguration.ts` validates layout references and resolves widget definitions.
3. `widgets/catalog.ts` is the single widget catalog and dispatches by widget kind.
4. Each widget folder owns its widget-specific resolve logic and render wiring, while readable widget layout stays local to that widget folder.
5. `widgets/renderWidgetByKind.tsx` renders resolved widgets through that catalog.

### Autohide Architecture

When `autohide` is enabled, `Bar.tsx` creates a `BarVisibilityController` per monitor. The controller tracks pointer position, flyout state, and forced show/hide commands. `barCliHandler.ts` registers a single `ags msg` listener and fans commands out to all per-monitor controllers.

A hotzone window sits at the bar edge when the bar is hidden. Pointer entry into the hotzone triggers the reveal.

### Theme-Managed Stylesheet

`bar/theme.scss` is a symlink to the active theme's `bar.scss`. Running `hk-theme set` updates the symlink and restarts AGS if it is running. Per-theme bar styling lives in `themes/<name>/bar.scss`.

Each widget folder should keep the readable layout module separate from denser wiring:

- `WidgetName.tsx`: top-level view module, kept intentionally small
- `spec.tsx`: widget-owned resolve logic and render entry using `createWidgetSpec`
- helper files like `normalize.ts`, service integrations, and sub-components

Each widget uses `createWidgetSpec` which generates `resolve()` automatically from a `schema` map of field-name to `FieldNormalizer`. Widget-specific types are inferred from the schema rather than declared in a separate `types.ts`.

`bar/types.ts` holds the bar-wide config type definitions. Widget-specific types and normalizers live with the widget. Shared internal helpers live in `widgets/shared/`. Widgets with flyouts own their open/close state and call `createFlyout` from `flyout/createFlyout.tsx` to mount the flyout window and get a trigger-setup hook for the button.

## Styling Architecture

The styling system separates public and internal hooks:

- Public theme tokens live in `themes/<theme>/bar.scss`
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
- `flyout-row`
- `widget-cpu-button`
- `widget-ram-button`

Internal helper classes may still exist to support layout math, but styling changes should usually start from the public hooks above.

## Contributor Notes

Keep `layout.config.ts`, `widgets.config.ts`, and `themes/<theme>/bar.scss` friendly to edit. If a new styling knob is likely to matter to many users, expose it as a grouped token in `bar.scss`. If it is too low-level, keep it internal instead of complicating the public config shape. Prefer explicit `widget-*`, `bar-*`, and `is-*` classes over selectors that depend on GTK child structure.