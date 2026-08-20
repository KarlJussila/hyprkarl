# Shell Configuration and State Contract

This document defines the lasting public configuration boundary for the
Quickshell shell. The production bar implements default/user resolution, common
version 1 structure validation, inline built-in and command widget instances,
explicit per-bar and application-wide user-QML modules, explicit layout edits,
and live last-valid reloads.
Widget-specific setting validation lands with each stable module contract.
`hk-shell config` commands and gesture persistence remain later work.

## Files and Ownership

Use one complete shipped file and one optional sparse override:

```text
defaults/shell.json    Hyprkarl's shipped configuration
user/shell.json        the owner's sparse override, when present
```

The shipped file is upstream-owned. The user file is never rewritten during
an update. The shell recursively merges ordinary objects from the user file
over the shipped file, replaces scalars and arrays, then applies explicit
layout operations. This lets new upstream defaults flow through without
inventing implicit ordering or deletion rules for widget arrays.

For example, this is a complete user file that only moves the bar:

```json
{
  "version": 1,
  "bar": {
    "edge": "bottom"
  }
}
```

The planned `hk-shell config init`, `diff`, and `reset` commands will wrap this
contract once the public shell command is introduced. Until then, create and
edit `user/shell.json` directly.

## Merge and Layout Rules

Ordinary JSON objects merge recursively. A user scalar replaces the inherited
scalar. A user array replaces the inherited array in full; arrays are never
concatenated or merged by position. Consequently, setting `bar.layout.start`
directly means supplying that entire ordered section.

For smaller layout customizations, use ordered `bar.layoutEdits` instead:

```json
{
  "version": 1,
  "bar": {
    "edge": "bottom",
    "layoutEdits": [
      { "op": "remove", "id": "gpu" },
      {
        "op": "move",
        "id": "tray",
        "section": "end",
        "before": "audio"
      },
      {
        "op": "override",
        "id": "audio",
        "set": { "showPercentage": true }
      },
      {
        "op": "insert",
        "section": "center.after",
        "after": "caffeine",
        "widget": {
          "id": "night-light",
          "kind": "toggle",
          "onCommand": "hyprsunset -t 4000",
          "offCommand": "pkill hyprsunset",
          "syncCommand": "pgrep -x hyprsunset",
          "onIcon": "󰖔",
          "offIcon": "󰖨"
        }
      }
    ]
  }
}
```

Operations run from top to bottom against the merged layout:

- `remove` deletes the named instance.
- `move` removes the named instance from its current section and places it in
  the target `section`.
- `override` recursively merges `set` into the named instance. It cannot
  change the stable `id` or implementation `kind`.
- `insert` places a complete new `widget` definition in the target section.

The sections are `start`, `center.before`, `center.anchor`, `center.after`, and
`end`. Array sections accept either `before` or `after`; with neither, the
widget is appended. `center.anchor` is a single slot and accepts neither. To
replace its occupant, remove or move the old widget before inserting or moving
the new one. Referencing a missing ID, duplicating an ID, targeting a neighbor
in another section, or occupying a nonempty anchor rejects the configuration.

Stable IDs make every layout change unambiguous. Omission means inheritance,
not removal, and an upstream widget can be added without rewriting the user's
file. Operation order also permits deliberate sequences such as removing a
widget and inserting a different implementation under the same ID.

## Version 1 Shape

Widget instances live inline where they are placed. This avoids a separate ID
map when an instance is referenced only once.

```json
{
  "version": 1,
  "osd": {
    "edge": "bottom",
    "margin": 40,
    "timeout": 2000,
    "mediaTimeout": 3000
  },
  "notifications": {
    "edge": "bar",
    "side": "right",
    "gap": 0,
    "sideMargin": 0,
    "defaultTimeout": 5000,
    "statusTimeout": 2000,
    "maxVisible": 5,
    "fallbackIcon": { "kind": "glyph", "value": "󰂚" },
    "criticalIcon": { "kind": "glyph", "value": "󰀦" },
    "ignoredApplications": ["spotify"],
    "compactApplications": ["battery"],
    "iconOverrides": {
      "battery": {
        "kind": "component",
        "source": "builtin/BatteryIcon.qml"
      }
    }
  },
  "bar": {
    "enabled": true,
    "edge": "top",
    "exclusive": true,
    "layout": {
      "start": [
        {
          "id": "menu",
          "kind": "command",
          "icon": "",
          "tooltip": "Main menu",
          "primaryCommand": "hk-shell menu toggle main"
        },
        { "id": "workspaces", "kind": "workspaces" },
        {
          "id": "cpu",
          "kind": "cpu",
          "primary": "{temp}°",
          "alternate": "{temp}° | {usage}%"
        }
      ],
      "center": {
        "before": [
          { "id": "recording", "kind": "recording" }
        ],
        "anchor": {
          "id": "clock",
          "kind": "clock",
          "primary": "ddd h:mm AP",
          "alternate": "ddd h:mm:ss AP"
        },
        "after": [
          { "id": "caffeine", "kind": "toggle" }
        ]
      },
      "end": [
        { "id": "audio", "kind": "audio" },
        { "id": "bluetooth", "kind": "bluetooth" },
        { "id": "network", "kind": "network" },
        {
          "id": "battery",
          "kind": "battery",
          "showPercentage": true,
          "lowThreshold": 0.15,
          "powerCommand": "hk-shell menu toggle power"
        }
      ]
    }
  }
}
```

`osd.edge` accepts `top` or `bottom`; `margin` is its distance from that output
edge. `timeout` controls volume, output, microphone, and brightness feedback,
while `mediaTimeout` controls track feedback. These placement and lifecycle
values deep-merge like other ordinary objects, so a user override may set only
one of them. OSD appearance is theme data under `osd` in `quickshell.json`, not
shell configuration.

`notifications.edge` accepts `bar`, `top`, or `bottom`; `bar` follows the
built-in bar or an application-wide user root's reactive positioning
provider. Explicit `top` and `bottom` values always use that monitor edge and
bypass bar-relative positioning. `side` accepts `left` or `right`. `gap`
separates the stack from the supplied surface extent (or explicit screen
edge), while `sideMargin` separates it
from the monitor side. With the shipped zero values, the stack overlaps the
bar border, sits flush against the right screen edge, sharpens the one corner
touching both, and reveals from the bar into the workspace. The shipped
theme's zero `notification.stackSpacing` joins adjacent toasts along one border
and sharpens only corners the neighboring toast actually reaches; overhanging
corners stay rounded. A positive value restores separate rounded toasts. New
notifications appear on the focused monitor.
`defaultTimeout` applies when a sender does not request a timeout,
`statusTimeout` applies to shell-owned status messages, and `maxVisible` caps
each stack. A sender timeout of zero and every critical notification remain
until dismissed. Hover pauses a running toast timer.

`ignoredApplications` and `compactApplications` contain lowercase exact
application names. Arrays replace in a user override, so supply the complete
desired list. `iconOverrides` is an ordinary object and therefore deep-merges;
its lowercase keys may match either the sender's application name or its icon
name. Each value is an icon descriptor:

```json
{
  "version": 1,
  "notifications": {
    "iconOverrides": {
      "discord": { "kind": "icon", "value": "discord" },
      "my mixer": {
        "kind": "component",
        "source": "builtin/AudioIcon.qml"
      },
      "my monitor": {
        "kind": "component",
        "source": "user/RingIcon.qml"
      },
      "backup job": { "kind": "glyph", "value": "󰁯" },
      "noisy utility": { "kind": "none" }
    }
  }
}
```

`icon` accepts an icon-theme name or file path, `glyph` uses the theme font,
and `component` loads a small QML drawing. `builtin/<file>.qml` resolves under
the shipped `features/notifications/icons/` directory;
`user/<file>.qml` resolves under `user/quickshell/icons/`. The shipped audio
and battery indicators use this same component path rather than special-case
renderer branches. A component root is an `Item` with writable `progress` and
`theme` properties. For example, `user/quickshell/icons/RingIcon.qml` can be:

```qml
import QtQuick
import QtQuick.Window

Item {
  id: root

  property real progress: -1
  property var theme: null

  onThemeChanged: drawing.requestPaint()

  Canvas {
    id: drawing

    anchors.fill: parent
    onPaint: {
      const context = getContext("2d")
      context.clearRect(0, 0, width, height)
      context.strokeStyle = root.theme.foreground
      context.lineWidth = 2 / Screen.devicePixelRatio
      context.beginPath()
      context.arc(width / 2, height / 2, Math.min(width, height) / 3, 0, Math.PI * 2)
      context.stroke()
    }
  }
}
```

For data-driven drawings, a standard `int:value` notification hint supplies
`progress` from 0 through 100; notifications without it receive `-1`.
A notification's content image takes priority over these application-icon
rules; otherwise an override, the sender's application icon, and the normal or
critical fallback are tried in that order. Appearance and sizing belong to the
theme's `notification` object in `quickshell.json`.

`center.anchor` is fixed to the monitor midpoint. `before` and `after` grow
away from it. This preserves the deliberate centered-island composition of
the current bar without encoding the implementation's QML object shape as a
public API.

`bar.enabled` controls whether the built-in bar is instantiated. When it is
false, its per-output windows, panels, widgets, application-wide command
providers, and hardware polling process are absent or inactive. Menu, OSD,
notifications, and polkit remain available. With the default
`notifications.edge: "bar"`, notifications fall back to the configured bar
edge with zero extent and therefore sit directly against the monitor edge.

Version 1 accepts `top` and `bottom`. Left and right are added only when
vertical layouts and panel behavior are implemented and tested. The current
layout and widgets are intentionally horizontal; edge-dependent popup
placement remains explicit at the panel-window boundary.

The same layout appears on every monitor initially. Do not add output-specific
overrides until a concrete different-per-monitor use case defines their
selection and fallback rules.

## Extension Lanes

Version 1 has three supported ways to place a widget:

1. A built-in widget uses `kind` to select a Hyprkarl-owned implementation.
2. A command widget either polls an explicit command or reads a persistent
   command stream and renders its documented text or small JSON result.
3. A QML widget explicitly names a file under `user/quickshell/modules/`.

All three lanes are implemented. A separate, optional application-wide user
root composes interfaces that do not belong to one bar instance. User QML is
always explicitly referenced; there is no module discovery or plugin
installation layer.

### Command widgets

A command widget can be a static action button without a data provider. The
shipped main-menu button is one:

```json
{
  "id": "menu",
  "kind": "command",
  "icon": "",
  "tooltip": "Main menu",
  "primaryCommand": "hk-shell menu toggle main"
}
```

With no provider `command`, `text` or `icon` supplies the static presentation
and no timer or process is created. Click commands receive the clicked bar's
output name in `HYPRKARL_OUTPUT`; `hk-shell menu` uses it so a bar action opens
on that bar's monitor rather than whichever monitor was previously focused.
`mode`, `interval`, and `output` apply only when a provider `command` exists.

A minimal polling widget treats trimmed standard output as its text:

```json
{
  "version": 1,
  "bar": {
    "layoutEdits": [
      {
        "op": "insert",
        "section": "end",
        "before": "audio",
        "widget": {
          "id": "load-average",
          "kind": "command",
          "command": "cut -d' ' -f1 /proc/loadavg",
          "interval": 5000,
          "icon": "󰓅",
          "tooltip": "One-minute load average"
        }
      }
    ]
  }
}
```

A provider `command` is a non-empty command string run by the non-login shell
`bash -c`. When it is present, `mode` defaults to `poll`. In poll mode,
`interval` is a required positive integer in milliseconds and the command runs
immediately, then once per interval. There is intentionally no enforced
minimum.

Each poll starts a new Bash process and whatever processes the command itself
launches. An unnecessarily short interval can waste CPU, reduce battery life,
and repeatedly wake an otherwise idle system. Choose the slowest interval that
still makes the readout useful. For frequent or event-driven updates, use
`"mode": "stream"` and omit `interval`; the shell starts one persistent
provider and consumes one result per newline instead of spawning a process for
every sample. A stream provider must flush each emitted line and is not
automatically restarted after it exits.

```json
{
  "id": "vpn",
  "kind": "command",
  "mode": "stream",
  "command": "my-vpn-status --follow",
  "output": "json",
  "icon": "󰖂"
}
```

`output` defaults to `text`; set it to `json` when the producer needs to change
presentation dynamically. A polled text command may use its complete standard
output; a stream emits one text value or one complete JSON object on each line.
Static `icon`, `tooltip`, and semantic `state` values provide defaults.
Optional `primaryCommand`, `secondaryCommand`, and `tertiaryCommand` run through
`bash -c` on left, right, and middle click respectively.

A JSON producer prints one object with only these optional fields:

```json
{
  "text": "VPN",
  "icon": "󰖂",
  "tooltip": "Connected to home",
  "state": "accent",
  "visible": true
}
```

`text`, `icon`, and `tooltip` are strings. `visible` is a boolean. `state` is
one of `normal`, `muted`, `accent`, `warning`, or `urgent` and selects the
corresponding semantic theme color; providers do not inject literal colors.
Omitted fields inherit the widget's static values. Construct nontrivial JSON
with a small Python command using dictionaries and the standard `json` module,
not shell string concatenation.

One application-wide registry owns exactly one provider per command-widget ID,
regardless of monitor count. Every bar view reads that shared result. A new
poll is skipped while the previous invocation is still running. A nonzero exit
or invalid JSON logs a concise warning and retains the last successful value;
a widget remains hidden until its first valid result. Changing unrelated shell
configuration does not restart unchanged providers.

When no command widget has a provider `command`, the registry model is empty:
it creates no timers and starts no processes. Static action buttons such as the
shipped menu remain ordinary rendered command widgets without entering that
registry. A configured stream has one long-running provider process. A
configured poll widget has no running OS process between ticks and launches
only when its timer fires.

### User QML widgets

Use `kind: "qml"` when a widget needs custom interaction or rendering that the
command-widget presentation contract cannot express. `source` is a relative
`.qml` path below `user/quickshell/modules/` in the supported contract.
`settings` is optional data owned entirely by that module.

For example, this config entry inserts `user/quickshell/modules/Greeting.qml`:

```json
{
  "op": "insert",
  "section": "end",
  "before": "audio",
  "widget": {
    "id": "greeting",
    "kind": "qml",
    "source": "Greeting.qml",
    "settings": {
      "text": "Hello",
      "command": "notify-send 'Hello from Hyprkarl'"
    }
  }
}
```

The module root must be an `Item` with `required property var context`:

```qml
import QtQuick

Item {
  id: root

  required property var context
  property string tooltip: "Run greeting"

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  Text {
    id: label
    anchors.centerIn: parent
    text: root.context.settings.text
    color: root.context.theme.foreground
    font.family: root.context.theme.uiFontFamily
    font.pixelSize: root.context.theme.bodyFontSize
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.context.runCommand(root.context.settings.command)
  }
}
```

Each bar/output owns its own module instance. The injected context is the
complete supported shell boundary:

| Member | Meaning |
| --- | --- |
| `widgetId` | Stable ID from the widget definition |
| `settings` | The instance's optional JSON settings object |
| `theme` | Live semantic shell theme object |
| `edge` | `top` or `bottom` for the owning bar |
| `orientation` | `horizontal` in version 1 |
| `output` | Owning output name |
| `barWindow` | Owning bar window for deliberate window-relative behavior |
| `runCommand(command)` | Run non-login `bash -c` with `HYPRKARL_OUTPUT` set |
| `togglePanel(trigger, component)` | Open or toggle content in the shared per-output panel host |
| `closePanel()` | Close the shared panel |
| `launchPanelCommand(command)` | Close the panel, then run a command |

An optional root `tooltip` string uses the shared shell tooltip. Set an
optional root `tooltipSuppressed` boolean while another surface is active.
Expose `widgetVisible` to collapse the entire host reactively; the ordinary
QML `visible` property only hides module content because child visibility is
inherited from its parent. A concrete compactness requirement may expose
`hostMainPaddingOffset`, which uses the same zero-floored universal-padding
contract as built-in widgets.

Panel content passed to `togglePanel` follows the same contract as built-in
panel content: its root reports `implicitHeight` and may expose
`preferredWidth`. The shared host owns the popup window, anchoring, focus,
available-height scrolling, dismissal, animation, and contact-aware corners.
Do not create another popup window for a bar-attached feature.

The loader passes no Hyprkarl state singleton or service object. A module can
import normal QML and Quickshell APIs, but it is trusted, unsandboxed code
running inside the shell process. A missing or unloadable source logs the QML
error and collapses that instance without taking down the rest of the bar.
The shell does not validate `source` or `settings` to police user code. It
resolves `source` from the documented module directory and passes `settings`
through; stepping outside the contract is allowed to work or fail according to
normal QML behavior.

Changes to `user/shell.json` remain live; after editing a dynamically
referenced QML source, run `hk-shell restart` because it is outside
Quickshell's statically scanned reload graph.

Feature panels remain separate surfaces. A built-in feature widget can declare
its corresponding built-in panel; a user QML widget may use the shared panel
entry point. Panel contents do not live inline in JSON. Audio, network,
Bluetooth, power, and calendar all exercise the per-monitor host; no feature
owns a second popup-window implementation. `secondaryCommand` supplies the
advanced launcher used by audio, network, and Bluetooth. The battery widget's
`powerCommand` supplies the power-actions launcher. These strings are
behavior, while all panel colors and geometry remain theme data. Activating an
audio, network, or Bluetooth header cog closes that panel before starting its
configured command.

### Application-wide user QML

Use one explicitly referenced user root for independent surfaces, global
state, or a complete personal bar. It is instantiated once for the shell
process and may compose as many files and per-screen `Variants` as needed.
Configure it in `user/shell.json`:

```json
{
  "version": 1,
  "bar": { "enabled": false },
  "userRoot": {
    "source": "Extensions.qml",
    "settings": {}
  }
}
```

The documented source location is `user/quickshell/Extensions.qml`. Its root
may be any QML object and declares `required property var context`. The context
contains `settings`, the complete merged shell `configuration`, and the live
`theme`. The ordinary typed theme properties remain available, while
`context.theme.document` exposes the complete generated `quickshell.json` for
custom values such as
`context.theme.document.extensions.dashboard.background`. Theme authors may
derive those values from any source vocabulary by placing the final values
under `shell` in `theme.yaml`.

An optional root method can override notification positioning per output while
`notifications.edge` is `bar`:

```qml
import QtQml
import Quickshell
import Quickshell.Wayland

Scope {
  id: root
  required property var context

  Variants {
    id: customBars
    model: Quickshell.screens

    PanelWindow {
      required property var modelData

      screen: modelData
      anchors.top: true
      anchors.left: true
      anchors.right: true
      implicitHeight: 30
      color: root.context.theme.barSurface

      // Bind this to the animated onscreen portion for an autohiding bar.
      property real notificationExtent: height
    }
  }

  function notificationPosition(outputName: string): var {
    const bar = customBars.instances.find(candidate =>
      candidate.screen.name === outputName)
    if (!bar) return null

    return {
      "edge": "top",
      "extent": bar.notificationExtent,
      "connected": bar.notificationExtent > 0,
      "reachesSide": true
    }
  }
}
```

The method may return `null` to use the built-in position for that output, or
an object whose supplied fields override it. `edge` is `top` or `bottom`;
`extent` is the reactive distance from that screen edge. `connected` says the
notification shares the surface border when `notifications.gap` is zero, and
`reachesSide` says that surface reaches the configured notification side so
their outer corner should sharpen. A hidden custom bar normally reports zero
extent and `connected: false`, causing the stack to sit against the screen
edge. These are ordinary QML bindings: changing a property read by the method
repositions an existing notification window immediately.

The module is trusted, unsandboxed user code. Its source and private settings
are not schema-policed. Changes to `user/shell.json` apply live; restart the
shell after editing the dynamically loaded QML source.

## Validation and Resolution

The loader validates the external file boundary and otherwise lets internal
components rely on the parsed contract.

- Missing `user/shell.json` selects the shipped default without warning.
- An unreadable user file, invalid JSON, invalid effective field, unsupported
  version, or invalid layout operation reports the file and failing path, then
  starts with the shipped default.
- An invalid shipped default is a Hyprkarl defect and must fail loudly; it is
  not hidden behind another internal fallback.
- Duplicate widget IDs are invalid because IDs identify instances for runtime
  state and diagnostics.
- Command widget fields are validated where the shared provider runtime needs
  a stable process contract. Other widget kinds flow to `WidgetHost`; a missing
  implementation becomes a normal QML loader error. User-QML `source` and
  `settings` are likewise passed through because they belong to trusted user
  code.

The shell watches both files and recomputes the effective configuration when
either changes, without recreating unrelated services. `hk-shell reload` is
the planned explicit equivalent. A failed live reload keeps the last valid
running configuration and reports the new error.

## State Ownership

| State | Owner | Persistence |
| --- | --- | --- |
| Widget order and instance settings | Shipped defaults plus sparse `user/shell.json` edits | User override is versioned |
| Built-in bar enablement, edge, and exclusion behavior | Shipped defaults plus `user/shell.json` | User override is versioned |
| OSD edge, margin, and dismissal timeouts | Shipped defaults plus `user/shell.json` | User override is versioned |
| Notification placement, timing, filters, compact apps, and icon selection | Shipped defaults plus `user/shell.json`, with an optional reactive user-root position | User override is versioned; reactive position is memory only |
| Visible notification stack, silence mode, and one restore snapshot | Application-wide `NotificationState` | Memory only |
| Command-widget results and provider processes | Application-wide `CommandState`, keyed by widget ID | Memory only |
| Colors, typography, spacing, island geometry, borders, and interaction states | Active semantic theme | Theme-derived |
| Open panel, hover, focus, disclosure, and in-progress UI | Quickshell feature objects | Memory only |
| Wi-Fi, Bluetooth, audio, battery, and power state | The corresponding system service | Service-owned |
| Monitor modes and arrangement | Future display integration | Backend-owned, contract not yet chosen |
| Generated theme output and caches | XDG state/cache paths | Regenerable |
| Secrets and machine-local environment | `config/uwsm/env.local` or system service | Never shell JSON |

One component owns writes to `user/shell.json`. If drag-to-reorder or another
shell gesture later persists configuration, it goes through that same writer
and uses an atomic temporary-file replacement. Do not add a second layout
state store.

The shell must not persist transient panel state or copy service-owned choices
into its configuration. Choosing an audio device or power profile changes the
underlying service; it does not rewrite shell JSON.

## Update Contract

Updates may change `defaults/shell.json` and bump its schema version. They do
not edit `user/shell.json`. New inherited values and widgets automatically
appear unless the user replaced the relevant value or explicitly edited that
widget by ID. When a future user schema version is no longer supported, the
update must provide an explicit migration command or documented manual
conversion before support is removed.

The initial supported runtime target is the installed Arch package,
Quickshell 0.3.0-2.1 with Qt 6.11.1. Production work must record the exact
package releases used for validation and rerun the lifecycle, popup, and
multi-monitor checks before moving to a newer line.

## Remaining Implementation Decisions

- Whether tray visibility preferences belong inline on the tray widget or in a
  separate service-owned file; choose only after the tray UI is designed.
- Whether direct manipulation such as drag-to-reorder is part of the first
  production release. JSON editing remains the required baseline.
