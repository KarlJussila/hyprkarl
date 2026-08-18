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
- `../../themes/<theme>/quickshell.json`: colors, typography, and metrics.
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
`config/ShellConfig.qml` alone selects, validates, and watches shell JSON while
retaining the last valid live configuration after a rejected edit. `Bar.qml`
alone owns each bar window and its per-monitor `FeaturePanelHost`. Layout files
own island geometry. Feature directories own feature-specific panel state and
content; bar widgets remain concise status and entry points.

Version 1 deliberately accepts only top and bottom bars. Layout and widget
code is horizontal until a vertical design exists; keep edge-dependent popup
placement at the panel-window boundary so later vertical support does not need
a new surface ownership model.

Themes own the entire visual surface, including colors, typography, bar
thickness, spacing, radii, borders, dividers, and the panel gap. Shell JSON
owns placement and behavior, not visual metrics. `config/Theme.qml` watches
the canonical `../hyprkarl/current/theme.name` selector, then reads the chosen
`themes/<name>/quickshell.json` directly. Do not watch through the replaceable
`current/theme` symlink: its target changes on a theme switch and can leave a
file watcher attached to the old theme.

`panels/FeaturePanelHost.qml` is the lasting window boundary for feature
panels. There is one host per bar/monitor. It owns the `PopupWindow`, trigger
anchoring, cross-axis clamping, preferred and maximum size, focus grab, Escape
and outside-click dismissal, one-active-panel state, transitions, scrolling,
and contact-aware corner radii. It whitelists the bar and popup in one
`HyprlandFocusGrab` so another panel trigger switches on the first click.
It also owns edge-dependent popup gravity: top-bar panels expand downward and
bottom-bar panels expand upward while anchoring within the bar surface.
Panel contents must not create their own popup window or reproduce geometry.

Audio, network, Bluetooth, battery/power, and clock/calendar now exercise this
host with five different compositions. Their repeated header, section, row,
and action controls are the stable baseline vocabulary; feature-specific
summaries, sliders, calendar cells, and navigation remain with their features.
There is no second feature-window or legacy flyout boundary.

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
started it. Bluetooth device and power-profile actions otherwise write the
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
top and bottom bars.

Component and feature directories have checked-in `qmldir` files where runtime
loading or singleton registration requires them. Widget files are loaded from
configuration, so Quickshell's static scanner cannot discover all relative
imports on its own.

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

`hk-shell` is the public lifecycle boundary for this prototype. Use it for
normal start, stop, restart, status, and log access. Do not add more shell
commands, change session startup or package ownership, or replace the existing
AGS controls until a task explicitly includes that cutover. A successful stop
must mean `qs list` no longer reports a live instance; restart relies on that
observable boundary instead of racing a process that is still shutting down.
