# AGENTS.md

Guidance for coding agents working on the Quickshell bar.

## Goals

Optimize for configurability, extensibility, simplicity, and readability. The
bar has a small configuration layer for casual edits and cohesive QML modules
for implementation. Do not recreate framework services or introduce generic
controllers when a Quickshell singleton already owns the state.

## Editing surfaces

- `../../defaults/shell.json`: shipped bar behavior, widget order, and widget
  instances.
- `../../user/shell.json`: optional sparse user override.
- `../../defaults/menu.json`: shipped static command-menu hierarchy.
- `../../user/menu.json`: optional sparse menu additions and overrides.
- `../../themes/<theme>/quickshell.json`: colors, typography, metrics, and
  island geometry.
- `widgets/*.qml`: one implementation per widget kind.

Shell JSON is data-only. Widget definitions live inline in the layout; `id`
identifies the instance and `kind` selects the implementation loaded by
`WidgetHost.qml`. Ordinary user objects merge recursively over the shipped
default, while arrays replace as complete ordered values. Surgical layout
changes use ordered `bar.layoutEdits` operations keyed by stable widget ID;
do not infer deletion or array ordering from an ordinary deep merge, and do
not restore a separate widget-definition map.

## Architecture

`shell.qml` creates shared configuration, theme, and system state objects, then
uses `Variants` to create one `Bar` per screen after configuration and theme
data are ready.
It also creates one `MenuWindow` per screen after menu data are ready. The
menu singleton selects exactly one requested monitor, owns navigation history,
and exposes the public `menu` IPC target. Each inactive window stays hidden and
does not request keyboard focus.
`config/ShellConfig.qml` alone selects, validates, and watches shell JSON while
retaining the last valid live configuration after a rejected edit. `Bar.qml`
alone owns each bar window and its per-monitor `FeaturePanelHost`. Layout files
own island geometry. Feature directories own feature-specific panel state and
content; bar widgets remain concise status and entry points.

`layout/IslandSurface.qml` is the single renderer for start, center, and end
islands. Its corner and border names are logical rather than top/bottom
coordinates: `screen` faces the output edge, `content` faces the workspace,
`outer` faces a monitor side, and `inner` faces another island. Preserve that
vocabulary for top and bottom bars. `curve` is the concave join supported at a
`screenInner` corner; on other corners it intentionally resolves to square.
The bar window and exclusive zone include screen- and content-side margins,
while panel and tooltip anchors also account for the content margin.

Bar height is intrinsic. `WidgetHost.qml` adds the theme's universal
`horizontalWidgetPadding.cross` to each widget's natural height;
`barMinThickness` is only a floor. `BarLayout.qml` owns the maximum across all
three islands and applies that resolved height to each island. Do not restore
fixed `barThickness` bindings in widgets or let islands resolve their final
heights independently.

Version 1 deliberately accepts only top and bottom bars. Layout and widget
code is horizontal until a vertical design exists; keep edge-dependent popup
placement at the panel-window boundary so later vertical support does not need
a new surface ownership model.

`horizontalWidgetPadding` names the horizontal-bar design, not coordinate
axes. Its `main` value pads along a top/bottom bar and its `cross` value pads
across the bar's thickness. `WidgetHost.qml` owns both values so built-in and
future widgets get the same outer padding and clickable extent by default.
Widget natural sizes must describe content, not include a second copy of host
padding. A widget may expose `hostMainPaddingOffset` for a concrete compactness
requirement; the host resolves `max(0, main + offset)`. The tray binds that
contract to the theme's `trayMainPaddingOffset`. Do not offset cross-axis
padding or add an override without a real design requirement. Add a separate
vertical-bar padding object only when vertical bars are supported. Panel
internals use `controlPadding`; they are not bar-widget padding.

Themes own the entire visual surface, including colors, typography, bar
minimum thickness, spacing, radii, borders, dividers, and the panel gap. Shell
JSON owns placement and behavior, not visual metrics. `config/Theme.qml` watches
the canonical `../hyprkarl/current/theme.name` selector, then reads the chosen
`themes/<name>/quickshell.json` directly. Do not watch through the replaceable
`current/theme` symlink: its target changes on a theme switch and can leave a
file watcher attached to the old theme.

Keep `barMargin`, `islandCorners`, `islandBorders`, `islandRadius`,
`cornerCurveSize`, and `cornerCurveRadius` in every theme. Do not move these
appearance decisions into shell JSON or individual island components.

`panels/FeaturePanelHost.qml` is the lasting window boundary for feature
panels. There is one host per bar/monitor. It owns the `PopupWindow`, trigger
anchoring, cross-axis clamping, preferred width, available-height clamping,
focus grab, Escape and outside-click dismissal, one-active-panel state,
transitions, scrolling, and contact-aware corner radii. Panels grow to their
content height or the remaining monitor height, whichever is smaller; do not
restore an arbitrary theme height cap. It whitelists the bar and popup in one
`HyprlandFocusGrab` so another panel trigger switches on the first click.
It also owns edge-dependent popup gravity: top-bar panels expand downward and
bottom-bar panels expand upward while anchoring within the bar surface.
Panel contents must not create their own popup window or reproduce geometry.

Audio, network, Bluetooth, battery/power, and clock/calendar now exercise this
host with five different compositions. Their repeated header, section, row,
and action controls are the stable baseline vocabulary; feature-specific
summaries, sliders, calendar cells, and navigation remain with their features.
`PanelHeader` owns the compact optional header action; audio, network, and
Bluetooth place their advanced-settings cog there instead of adding a wide
footer action.
Feature-panel actions that launch an external command request it through their
bar entry point, which closes the owning panel before spawning the command.
There is no second feature-window or legacy flyout boundary. In the power and
network panels, facts already owned by the primary content do not become
decorative header subtitles: battery facts belong to `BatterySummary`, and the
connected Wi-Fi network is the selected first entry in the sorted network list.
`BatterySummary` aligns percentage/status above indicator/rate and marks the
rate with an up arrow while charging or a down arrow while discharging. Its
percentage column is three monospaced glyphs wide, uses `MAX` at full charge,
and scales the indicator to the same width; the bar battery readout uses `MAX`
too. Every panel content exposes a reactive `preferredWidth`; the host owns
clamping and anchoring. Keep the default binding to `panelWidth` and the
power variation bound to the theme-owned `powerPanelWidth`.
`BatteryIndicator` keeps its original 18×10 primary-widget surface at the
default `nativeScale` of 1. The panel sets `nativeScale` to allocate a larger
canvas; do not use the item's transform scale, which blurs its texture.
Small canvas strokes must resolve against `Screen.devicePixelRatio`; the audio
indicator uses a two-physical-pixel stroke and is vertically centered in its
bar row.

Hover text uses `ShellTooltip`, a non-focusable `PopupWindow` with an empty
input mask. Do not replace it with Qt Controls' attached `ToolTip`; that window
does not participate correctly in the shell's layer or input behavior.

CPU, GPU, RAM, and recording state share the single long-running process in
`state/SystemState.qml`; event-driven widgets use Quickshell services directly.
`features/network/NetworkState.qml` is a feature-owned singleton because scan
requests are application-global while panels are per monitor; it reference
counts panel requesters so closing one monitor's panel cannot stop another's
scan. `features/bluetooth/BluetoothState.qml` owns the equivalent
adapter-global discovery lifetime and stops discovery only when this shell
started it. Opening a Bluetooth panel does not request discovery; only its
explicit scan action registers that panel as an owner, and closing the panel
releases it. Bluetooth device and power-profile actions otherwise write the
Quickshell service objects directly; do not add generic controllers around
them. The installed Bluetooth API does not expose pairing-agent prompts or
action failure reasons, so keep `hk-bluetooth-launch` as the advanced route
instead of inventing success or failure state. PowerProfiles likewise exposes
the selected profile but no per-write result; render service-confirmed state
and do not synthesize a profile-change failure.
`features/clock/ClockState.qml` is the one application-wide current-time owner.
Bar labels and every calendar panel bind to it so monitor count cannot create
divergent dates. Viewed-month offset is panel-local transient state and resets
when that panel opens; do not persist it or use Qt's implicit `model.today` as
a second date owner.
The three performance widgets share `ExpandableReadout`; the tray owns the
same clipped horizontal expansion for its dynamic item list. Its divider lives
inside that clipped panel so it reveals between the fixed trigger and items on
top and bottom bars. Universal host padding supplies the outer inset for the
workspace row. The tray applies `trayMainPaddingOffset` to its outer host inset
and reuses the unmodified universal main-axis value between its internal
divider and item row. Do not turn either into item-to-item spacing.

Component and feature directories have checked-in `qmldir` files where runtime
loading or singleton registration requires them. Widget files are loaded from
configuration, so Quickshell's static scanner cannot discover all relative
imports on its own.

`features/menu/MenuState.qml` alone reads, watches, recursively merges, and
validates menu JSON. Entries merge by stable ID; `enabled: false` hides one.
Keep commands as leaf actions and static hierarchy in data. `MenuWindow.qml`
owns the full-monitor overlay, exclusive keyboard focus, history navigation,
and outside-click dismissal. Existing static `hk-menu-*` entry points are thin
IPC wrappers; specialized searchable selectors may remain separate Rofi
commands until their own shell-native surfaces are designed.
The command menu deliberately blends two visual sources. Preserve the retired
Rofi menu's compact width, centered icon-and-label rows, title band, nested
frame, row gaps, and bordered selection. Derive its palette, font, radii,
border color, and translucent accent states from the current shell theme. The
nested `menu` object may override those inherited tokens and owns its distinct
geometry and opacity modifiers. Outside-click and Escape go to the parent from
a submenu and close only at the root, matching the old nested menu dismissal
behavior.

## Checks

From the repository root:

```bash
/usr/lib/qt6/bin/qmllint $(rg --files config/quickshell -g '*.qml' | sort)
hk-shell start
hk-shell logs --tail 100 --no-color
hk-shell stop
```

The live launch is authoritative because Quickshell's installed qmltypes omit
some internal types used by its public QML API. Use `qs -p config/quickshell`
only when a foreground development process is useful.

`hk-shell` is the public lifecycle boundary for the production bar. Hyprland
session startup calls `hk-shell start`; use the same command family for normal
start, stop, restart, status, and log access. A successful stop must mean `qs
list` no longer reports a live instance; restart relies on that observable
boundary instead of racing a process that is still shutting down.
