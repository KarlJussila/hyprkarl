# Shell Configuration and State Contract

This document defines the lasting public configuration boundary for the
Quickshell shell. The production bar implements default/user resolution, common
version 1 structure validation, inline built-in widget instances, explicit
layout edits, and live last-valid reloads. Widget-specific setting validation
will land with each stable module contract.
Command widgets, user QML modules, `hk-shell config` commands, and gesture
persistence remain later work.

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
  "bar": {
    "edge": "top",
    "exclusive": true,
    "layout": {
      "start": [
        { "id": "menu", "kind": "menu" },
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
          "powerCommand": "hk-menu-power"
        }
      ]
    }
  }
}
```

`center.anchor` is fixed to the monitor midpoint. `before` and `after` grow
away from it. This preserves the deliberate centered-island composition of
the current bar without encoding the implementation's QML object shape as a
public API.

Version 1 accepts `top` and `bottom`. Left and right are added only when
vertical layouts and panel behavior are implemented and tested. The current
layout and widgets are intentionally horizontal; edge-dependent popup
placement remains explicit at the panel-window boundary.

The same layout appears on every monitor initially. Do not add output-specific
overrides until a concrete different-per-monitor use case defines their
selection and fallback rules.

## Extension Lanes

The complete version 1 contract will support three ways to place a widget:

1. A built-in widget uses `kind` to select a Hyprkarl-owned implementation.
2. A command widget runs an explicit command at a configured interval and
   renders its documented text or small JSON result.
3. A QML widget explicitly names a file under `user/quickshell/modules/`.

Only the built-in lane is implemented in the current shell. Until the
other two land, validation rejects kinds that do not name a built-in widget.

There is no directory scan, manifest, installation hook, dependency resolver,
or implicit enable state. A user module exists in the running shell because a
canonical config entry references it.

A QML widget receives only the context its supported contract needs: semantic
theme values, orientation, its instance settings, the owning bar window, and
shared tooltip and panel entry points. It does not receive internal singleton
objects simply because they are convenient.

Feature panels remain separate surfaces. A built-in feature widget can declare
its corresponding built-in panel; a user QML widget may use the shared panel
entry point. Panel contents do not live inline in JSON. Audio, network,
Bluetooth, power, and calendar all exercise the per-monitor host; no feature
owns a second popup-window implementation. `secondaryCommand` supplies the
advanced launcher used by audio, network, and Bluetooth. The battery widget's
`powerCommand` supplies the power-actions launcher. These strings are
behavior, while all panel colors and geometry remain theme data.

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
- Unknown built-in kinds and missing user QML files are invalid configuration.

The shell watches both files and recomputes the effective configuration when
either changes, without recreating unrelated services. `hk-shell reload` is
the planned explicit equivalent. A failed live reload keeps the last valid
running configuration and reports the new error.

## State Ownership

| State | Owner | Persistence |
| --- | --- | --- |
| Widget order and instance settings | Shipped defaults plus sparse `user/shell.json` edits | User override is versioned |
| Bar edge and exclusion behavior | Shipped defaults plus `user/shell.json` | User override is versioned |
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
