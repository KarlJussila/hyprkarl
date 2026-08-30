# Shell Configuration and State Contract

This document defines the lasting public configuration boundary for the
Quickshell shell. The production bar implements default/user resolution, common
version 1 structure validation, inline built-in and command widget instances,
explicit per-bar and application-wide user-QML modules, explicit layout edits,
and live last-valid reloads for ordinary configuration values. Built-in module
selection is intentionally latched until a shell restart.
Widget-specific setting validation belongs to each stable module contract.

## Files and Ownership

Use one complete shipped file and one optional sparse override:

```text
defaults/shell.json    Hyprkarl's shipped configuration
${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json
                      the owner's sparse override, when present
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

Create and edit `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json`
directly. It is the public, user-owned configuration surface.

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

### Toggle indicators

Every toggle indicator starts from the active theme's complete `switch`
appearance. A `kind: "toggle"` widget may supply a sparse `switch` object when
that instance needs different geometry or glyph placement:

```json
{
  "version": 1,
  "bar": {
    "layoutEdits": [
      {
        "op": "override",
        "id": "caffeine",
        "set": {
          "switch": {
            "trackLength": 30,
            "trackHeight": 10,
            "trackRadius": 3,
            "thumbSize": 16,
            "thumbRadius": 4,
            "thumbPadding": 6,
            "borderWidth": 1,
            "fontFamily": "JetBrains Mono Nerd Font Propo",
            "fontSize": 9,
            "onGlyphOffset": [1, 0],
            "offGlyphOffset": [0, 0],
            "transitionDuration": 140
          }
        }
      }
    ]
  }
}
```

Every field is optional and falls back independently to the theme. The length,
height, size, padding, radius, border, font, offset, and duration values are
logical pixels or milliseconds as their names imply.

Set `"variant": "mark"` in the same object for a stationary checkbox- or
radio-like indicator. A mark draws no track. It occupies only the thumb and
its border, changes the border between the inactive and active colors, and
swaps the configured off/on glyph without moving. Its background remains the
surface color so the glyph keeps normal text contrast. `thumbRadius` controls
whether it is circular, rounded, or square:

```json
{
  "switch": {
    "variant": "mark",
    "thumbRadius": 4,
    "onGlyphOffset": [0, 0]
  }
}
```

Set `"markFilled": true` to opt that instance into filling the active mark with
the accent color.

`ToggleIndicator` exposes this same sparse object as its `appearance` property
for built-in QML compositions. `PanelRow.switchAppearance` passes it through
for panel-row instances. The shipped caffeine widget uses the `mark` variant;
the shared component, bar toggle widget, and panel rows use the same override
contract.

## Built-in modules

The top-level `modules` object selects the built-in runtime groups. Every
shipped value is `true`; a sparse personal override need only name the groups
to disable:

```json
{
  "version": 1,
  "modules": {
    "bar": false,
    "notifications": false
  }
}
```

| Key | Owns when enabled |
|---|---|
| `bar` | Per-output bar windows, the shared system monitor, and command-widget providers. |
| `panels` | The per-output feature-panel popup host. Status widgets remain in the bar. |
| `notifications` | The freedesktop notification server, its IPC target, and toast windows. |
| `osd` | The OSD state, dismissal timer, IPC target, and windows. |
| `polkit` | The session authentication agent and its focused prompt. |
| `menu` | Command-menu state, JSON watchers, dynamic commands, IPC target, and windows. |
| `applications` | The launcher and open-with state, desktop-entry access, IPC targets, and windows. |
| `calculator` | Calculator history state, IPC target, and window. |
| `wallpaper` | Wallpaper-picker state, IPC target, and window. |

Module values are read once when the shell starts. The JSON watcher still
accepts an edited file and uses its ordinary settings, but it keeps the
existing module set and logs a restart warning if it changed. Run
`hk-shell restart` after changing `modules`. This avoids leaving a global
notification server, authentication agent, timer, watcher, or IPC handler from
the previous selection alive in the running process.

`modules.panels: false` removes the feature-panel popup host. It does not
remove audio, battery, Bluetooth, clock, display, or network status widgets
from a running bar. Remove those separately with `bar.layoutEdits` if the bar
should not show them.

Disabling an implementation also leaves its existing entry points alone. For
example, a shipped binding, menu row, or command widget may still refer to a
disabled menu, launcher, calculator, or wallpaper picker. Remove that entry
from personal layout, menu, or Hyprland configuration, or point it at the
replacement you run instead. A menu entry can be hidden with `enabled: false`.

## Version 1 Shape

Widget instances live inline where they are placed. This avoids a separate ID
map when an instance is referenced only once.

```json
{
  "version": 1,
  "modules": {
    "bar": true,
    "panels": true,
    "notifications": true,
    "osd": true,
    "polkit": true,
    "menu": true,
    "applications": true,
    "calculator": true,
    "wallpaper": true
  },
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
    "fallbackIcon": { "kind": "none" },
    "criticalIcon": { "kind": "none" },
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
notifications appear on the focused monitor and reveal at the free end of its
stack. Each toast keeps its own timeout as the stack changes and collapses
toward the bar before removal.
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
The logical `user/<file>.qml` namespace resolves under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/icons/`. The shipped audio
and battery indicators use this same component path rather than special-case
renderer branches. Absolute file paths are supported, and `none` removes the
icon from the notification layout. Sender content images take priority but use
the same theme `notification.iconSize` as application icons, glyphs, and QML
drawings. A component root is an `Item` with writable `progress` and `theme`
properties. For example,
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/icons/RingIcon.qml` can be:

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
critical fallback are tried in that order. Both shipped fallbacks are `none`,
so a notification without an image, override, or application icon gives that
space to its text. Appearance and sizing belong to the theme's `notification`
object in `quickshell.json`.

`center.anchor` is fixed to the monitor midpoint. `before` and `after` grow
away from it. This preserves the deliberate centered-island composition of
the current bar without encoding the implementation's QML object shape as a
public API.

`modules.bar` controls whether the built-in bar is instantiated. With it off,
the per-output bar windows, shared system monitor, and command-widget
providers do not start. The other module switches are independent. With the
default `notifications.edge: "bar"`, a notification stack without a built-in
or personal bar position falls back to the configured bar edge with zero
extent and sits directly against the monitor edge. See [Built-in
modules](#built-in-modules) for the complete switch contract and restart
boundary.

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
3. A QML widget explicitly names a file under `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/modules/`.

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
output name in `HYPRKARL_OUTPUT`. `hk-shell menu` forwards it because the
command process otherwise loses which bar was clicked. This keeps the menu on
that output when Hyprland does not focus monitors on mouse movement. `mode`,
`interval`, and `output` apply only when a provider `command` exists.

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
`.qml` path below `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/modules/` in the supported contract.
`settings` is optional data owned entirely by that module.

For example, this config entry inserts `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/modules/Greeting.qml`:

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

Ordinary changes to `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json` remain live. Run `hk-shell
restart` after changing `modules` or a dynamically referenced QML source; the
latter is outside Quickshell's statically scanned reload graph.

Feature panels remain separate surfaces. A built-in feature widget can declare
its corresponding built-in panel; a user QML widget may use the shared panel
entry point. Panel contents do not live inline in JSON. Display, audio,
network, Bluetooth, power, and calendar all exercise the per-monitor host; no
feature owns a second popup-window implementation. `secondaryCommand` supplies
the advanced launcher used by audio, network, and Bluetooth. The battery widget's
`powerCommand` supplies the power-actions launcher. These strings are
behavior, while all panel colors and geometry remain theme data. Activating an
audio, network, or Bluetooth header cog closes that panel before starting its
configured command.

### Application-wide user QML

Use one explicitly referenced user root for independent surfaces, global
state, or a complete personal bar. It is instantiated once for the shell
process and may compose as many files and per-screen `Variants` as needed.
Configure it in `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json`:

```json
{
  "version": 1,
  "modules": { "bar": false },
  "userRoot": {
    "source": "Extensions.qml",
    "settings": {}
  }
}
```

The documented source location is `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/Extensions.qml`. Its root
may be any QML object and declares `required property var context`. The context
has these direct members:

| Member | Meaning |
|---|---|
| `configuration` | The complete resolved shell JSON. |
| `settings` | `userRoot.settings` from that JSON. |
| `theme` | The live typed theme object. |
| `outputs` | The current `Quickshell.screens` list. |
| `overlayName`, `overlayOutput`, `overlayValues`, `overlayRevision` | The requested exclusive overlay and its change counter. |
| `openOverlay(name, output, values)` | Opens only when no overlay is active. |
| `replaceOverlay(name, output, values)` | Replaces the current overlay request. |
| `pushOverlay(name, output, values)` | Opens a request that may return to the current overlay. |
| `toggleOverlay(name, output, values)` | Closes the matching request or replaces it. |
| `closeOverlay()` | Closes the current overlay. |
| `backOverlay()` | Restores the last request saved by `pushOverlay`, when one exists. |

The ordinary typed theme properties remain available, while
`context.theme.document` exposes the complete generated `quickshell.json` for
custom values such as
`context.theme.document.extensions.dashboard.background`. Theme authors may
derive those values from any source vocabulary by placing the final values
under `shell` in `theme.yaml`.

The same context lets a personal root handle a menu-defined overlay without
registering anything. A menu action such as this:

```json
{
  "type": "surface",
  "surface": "dashboard",
  "parameters": { "section": "weather" }
}
```

sets `context.overlayName` to `dashboard`, passes the object as
`context.overlayValues`, and selects `context.overlayOutput`. The built-in
menu, picker, and display-arrangement surfaces use this same controller.

For a shell-styled modal, import the public module and declare the modal in the
personal root. Its body and optional footer are instantiated only while the
modal is opening or visible. `Hyprkarl.Modal` owns output routing, the focused
layer-shell window, scrim, frame, reveal, outside-click dismissal, and keyboard
traversal; the personal file owns its content and request name:

```qml
import QtQuick
import Quickshell
import Hyprkarl

Scope {
  id: root
  required property var context

  Modal {
    context: root.context
    name: "user.dashboard"
    title: "Dashboard"
    subtitle: root.context.overlayValues.section ?? ""
    preferredWidth: 720
    preferredHeight: 480

    body: Component {
      Item {
        Text {
          anchors.centerIn: parent
          text: "Personal modal content"
          color: root.context.theme.menuForeground
        }
      }
    }
  }
}
```

Use a distinctive name such as `user.dashboard` to avoid accidental overlap
with shipped surfaces; this is a naming convention, not an allowlist. A menu
entry can request it by setting `surface` to the same name. The component also
provides `open(output, values)`, `replace(output, values)`, `toggle(output,
values)`, and `close()` convenience methods. Personal QML remains trusted and
may create its own windows when the shared modal presentation is not suitable.
Set `dismissAction` when outside click, Escape, or Q should do more than close,
such as reverting a pending operation.

Visible, enabled modal descendants with `activeFocusOnTab: true` join the
modal's keyboard navigation automatically. Arrow keys or H/J/K/L move
spatially within a section, Tab and Shift+Tab move between sections, and
Enter/Space remain the control's activation keys. Escape or Q invokes
`dismissAction`. The modal opens in pointer mode without a visible current
control; real pointer movement or the first navigation key establishes one.
Controls use the default `main` section unless they declare a string property
such as `property string navigationSection: "filters"`; built-in modal footer
buttons share the `footer` section. Tab always leaves the current section. Add
`property bool navigationSelected: true` to its selected control when section
entry should restore a current choice.

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
are not schema-policed. Ordinary changes to
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json` apply live. Restart the shell after
editing dynamically loaded QML source or changing `modules`.

## Validation and Resolution

The loader validates the external file boundary and otherwise lets internal
components rely on the parsed contract.

- Missing `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json` selects the shipped default without warning.
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
either changes, without recreating unrelated services. A failed JSON reload
keeps the last valid running configuration and reports the new error. Restart
the shell after changing module switches or dynamically loaded QML source.

## State Ownership

| State | Owner | Persistence |
| --- | --- | --- |
| Widget order and instance settings | Shipped defaults plus sparse personal shell JSON edits | User-owned file |
| Built-in bar enablement, edge, and exclusion behavior | Shipped defaults plus personal shell JSON | User-owned file |
| OSD edge, margin, and dismissal timeouts | Shipped defaults plus personal shell JSON | User-owned file |
| Notification placement, timing, filters, compact apps, and icon selection | Shipped defaults plus personal shell JSON, with an optional reactive user-root position | User-owned file; reactive position is memory only |
| Visible notification stack, silence mode, and one restore snapshot | Application-wide `NotificationState` | Memory only |
| Command-widget results and provider processes | Application-wide `CommandState`, keyed by widget ID | Memory only |
| Colors, typography, spacing, island geometry, borders, and interaction states | Active semantic theme | Theme-derived |
| Open panel, hover, focus, disclosure, and in-progress UI | Quickshell feature objects | Memory only |
| Wi-Fi, Bluetooth, audio, battery, and power state | The corresponding system service | Service-owned |
| Display discovery and live output state | `hk-display` over Hyprland and the internal backlight service | Service-owned |
| Output enablement, mode, position, scale, and transform captured by display actions | `hk-display` | Generated under XDG state |
| Generated theme output and caches | XDG state/cache paths | Regenerable |
| Secrets and machine-local environment | `~/.config/uwsm/env.local` or system service | Never shell JSON |

The shell must not persist transient panel state or copy service-owned choices
into its configuration. Choosing an audio device or power profile changes the
underlying service; it does not rewrite shell JSON.

The display panel follows the same separation. Its per-output QML view queries
and invokes `hk-display`; it does not own a second monitor model or write shell
JSON. Confirmed output enablement, resolution, refresh rate, and scale persist in
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/display/`, whose generated Lua
loads after shipped monitor defaults and before explicit
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/hypr/monitors.lua`. Brightness is backlight service state and is not
copied into that layout. The overview exposes it when available and opens a
staged settings page for each connected output. Resolution and refresh rate
have separate pickers, with refresh options filtered to modes reported for the
drafted resolution. Apply starts a ten-second
backend-owned trial; confirm persists it, while dismissal, timeout, or a lost
shell restores the previous layout. Confirmation targets the output that owns
the feature panel and falls back only if that output was disabled. The global
arranger applies one complete active-output position-and-transform map directly
after rejecting overlaps, while preserving each output's current mode, refresh
rate, and scale. The detail page omits settings that cannot act on the current
draft instead of displaying disabled rows. External DDC brightness and global
text sizing remain outside this panel slice.

## Update Contract

Updates may change `defaults/shell.json` and bump its schema version. They do
not edit `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json`. New inherited values and widgets automatically
appear unless the user replaced the relevant value or explicitly edited that
widget by ID. When a future user schema version is no longer supported, the
update must provide an explicit migration command or documented manual
conversion before support is removed.

The current supported runtime target is the installed Arch package,
Quickshell 0.3.0-2.1 with Qt 6.11.1. Production work must record the exact
package releases used for validation and rerun the lifecycle, popup, and
multi-monitor checks before moving to a newer line.
