# Customizing the Bar

Hyprkarl's bar is built with Quickshell. Its shipped placement and behavior
live in `defaults/shell.json`; personal changes belong in the optional
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json`. Appearance is entirely
theme-derived from the active bundle's `quickshell.json`.

## Design Direction

The shell keeps the retired AGS bar's compact, information-dense character,
but its flyouts are not the design target. Feature panels should feel like
deliberately composed desktop controls: direct, easy to scan, and cohesive
without forcing audio, network, Bluetooth, power, display, and calendar into
one generic quick-settings grid. Omarchy and macOS are references for control
quality and hierarchy, not layouts to copy.

Every visible state is theme-derived, including text, surfaces, borders,
accents, warnings, hover, selection, and disabled treatment. Shared shells own
window geometry, focus, dismissal, animation, and contact-aware corners;
features own their information hierarchy and interactions. Put current state
and common actions first, show real failures where an action occurs, and keep
advanced controls reachable without making the default surface noisy.

Top and bottom bars are first-class. Vertical bars remain a later design task;
the current implementation keeps orientation at the layout and popup
boundaries without carrying untested vertical branches through every widget.

## Override the Shipped Configuration

Create `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json` with only the values you want to
change. Objects merge recursively over the shipped defaults. Arrays replace as
complete ordered values, so use `bar.layoutEdits` when you only need to move,
insert, override, or remove one widget by its stable ID.

For example, this moves the bar to the bottom without copying any upstream
layout:

```json
{
  "version": 1,
  "bar": {
    "edge": "bottom"
  }
}
```

Deleting the user file returns to the shipped configuration. Valid edits apply
live; an invalid edit is rejected and the last valid layout remains running.
Version 1 supports top and bottom bars.

Set `modules.bar` to `false` to remove the built-in bar without stopping the
other built-in modules:

```json
{
  "version": 1,
  "modules": { "bar": false }
}
```

This destroys the per-output bar windows and makes their system monitor and
command-widget providers inert. Module choices latch at shell start, so run
`hk-shell restart` after editing this value. See
[Application-wide user QML](shell-configuration.md#application-wide-user-qml)
for composing a replacement bar and publishing its reactive notification
extent.

`modules.panels: false` is narrower: it removes the feature-panel popup host
but leaves the bar's status widgets. Remove individual status widgets with
`bar.layoutEdits`. [Shell configuration](shell-configuration.md#built-in-modules)
lists every built-in module switch.

See [Shell Configuration](shell-configuration.md) for the full merge contract,
widget schema, and layout-edit examples.

## Reorder, Add, or Remove Widgets

Each layout entry defines a widget instance inline. `id` is the stable instance
identity and `kind` selects its built-in implementation. The bar has `start`,
`center`, and `end` islands; the center island uses `before`, an optional
midpoint `anchor`, and `after` so its anchor can remain exactly centered.

Prefer `bar.layoutEdits` for focused personal changes. Replace a whole layout
array only when you intend to own its complete ordering.

The shipped `display` widget opens controls for the bar's own output. Remove it
with a layout edit if monitor controls do not belong in your bar:

```json
{
  "version": 1,
  "bar": {
    "layoutEdits": [
      { "op": "remove", "id": "display" }
    ]
  }
}
```

Its overview controls internal-backlight brightness and opens a staged settings
page for each connected output. That page controls enablement, resolution,
refresh rate, and cleaned scale. Resolution and refresh rate open separate
pickers; the available refresh rates come only from modes matching the drafted
resolution. Apply starts a ten-second trial: keep it in
the confirmation modal or the backend restores the previous layout, even if
the shell disappears. Confirmation opens on the display that owns the panel,
falling back to another active display only if that output was disabled. With
two or more active outputs,
`Arrange displays` opens a global modal where the output frames can be dragged
into position or right-clicked to rotate clockwise. A line inside each frame
marks its physical bottom edge, and overlapping frames must be separated before
Apply. Arrangement preserves mode, refresh rate, and scale and does not show
the trial confirmation. Those actions go through `hk-display`; they do not
rewrite personal shell JSON or Hyprland Lua. Brightness remains immediate
because it is backlight service state rather than monitor-layout state.

## Add a Command Widget

Use `kind: "command"` for a personal readout that can be produced by a small
command. This example inserts the one-minute load average before the audio
widget without copying the shipped layout:

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

The command runs once per interval for that ID even when several monitors
render the bar. Polling starts a new process on every tick, so overly short
intervals can waste CPU and battery. Use the persistent stream mode for
high-frequency or event-driven values. The provider may return plain text or a
small validated JSON presentation object. See
[Shell Configuration](shell-configuration.md#command-widgets) for JSON output,
stream mode, semantic states, click commands, failure behavior, and the
complete contract.

For a static action button, omit the provider `command` and `interval`, supply
an `icon` or `text`, and set a click command. This form creates no timer or
process until it is clicked. Click commands receive the owning bar's output
name as `HYPRKARL_OUTPUT`.

## Add a QML Widget

Use `kind: "qml"` only when the command-widget surface is not expressive
enough. Put the implementation below `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/modules/`, reference it
explicitly with a relative `source`, and keep per-instance data in `settings`:

```json
{
  "op": "insert",
  "section": "end",
  "before": "audio",
  "widget": {
    "id": "greeting",
    "kind": "qml",
    "source": "Greeting.qml",
    "settings": { "text": "Hello" }
  }
}
```

The module root declares `required property var context`. That context supplies
the live semantic theme, instance settings, bar edge and orientation, owning
output/window, command helpers, and shared feature-panel entry points. Modules
are instantiated once per rendered bar; they are not discovered or registered
as plugins. See [User QML widgets](shell-configuration.md#user-qml-widgets) for
the complete QML example and context contract. Restart the shell after editing
a module source; JSON layout changes still apply live.

## Change the Appearance

Every bar color, plus typography, thickness, spacing, borders, radii, panel
sizing, and transition timing, comes from the active generated bundle's
`quickshell.json`. Shared appearance begins in the integrated compiler's typed
`theme-generator/defaults/theme.yaml` graph; its final `shell` object is
serialized as that JSON contract. Add a corresponding consumer value there
when introducing a required theme property. Individual built-in or personal
sources may override it directly or derive it from their own token vocabulary.
`hk-theme set` rebuilds the selected source, and the running shell watches the
new runtime artifact without requiring a restart.

The theme's `shell.switch` object owns the default track and thumb geometry,
border, glyph typography and offsets, and transition duration for every shared
toggle indicator. A particular toggle may sparsely override those defaults
through its widget-level `switch` object. It may also select the trackless,
stationary `"mark"` variant for checkbox- or radio-like presentation. See
[Toggle indicators](shell-configuration.md#toggle-indicators) for the complete
field list and per-instance examples.

The island silhouette is theme-owned too. For example, the shipped themes use:

```json
{
  "bar": {
    "minimumThickness": 22,
    "widgetPadding": { "main": 6, "cross": 3 },
    "trayPaddingOffset": -2,
    "margin": { "screen": 0, "outer": 0, "content": 0 },
    "island": {
      "radius": 8,
      "curveSize": 12,
      "curveRadius": 4,
      "corners": {
        "screenOuter": "square",
        "screenInner": "curve",
        "contentOuter": "square",
        "contentInner": "round"
      },
      "borders": {
        "screen": false,
        "content": true,
        "outer": false,
        "inner": true
      }
    }
  }
}
```

These names are relative to the bar rather than fixed screen coordinates:
`screen` faces the monitor edge, `content` faces the workspace, `outer` faces
a horizontal monitor side, and `inner` faces another island. This makes one
theme behave equivalently on top and bottom bars. A corner may be `square` or
`round`; `screenInner` may also be `curve` to form a concave join. Setting all
four border values to `false` makes islands borderless. The three margins move
the bar away from the screen edge, monitor sides, or workspace respectively;
screen and content margins are included in the reserved bar area.

`bar.widgetPadding` applies to every widget on a top or bottom bar.
`main` pads along the bar and `cross` pads across its thickness; “horizontal”
describes the bar orientation rather than the x-axis. The shared widget host
owns this padding, including its clickable area. Widget natural sizes should
therefore describe content without including another outer inset.
`bar.trayPaddingOffset` is added to `main` for the tray's outer host padding,
with a floor of zero. The shipped `-2` turns `6` into `4` pixels per side. The
revealed item row still uses the unmodified `main` value beside its divider,
and neither value adds item-to-item spacing. Panel rows and actions use the
separate `metrics.controlPadding` value.

`panel.width` sets the normal feature-panel width, while
`panel.powerWidth` independently sizes the more compact power panel. Both are
theme metrics; changing the latter does not squeeze the network, Bluetooth, or
audio surfaces. Panel height is content-driven and grows as far as the
remaining monitor height; scrolling begins only after content exceeds that
physical limit, so there is no theme height cap to configure.

Feature panels use the same visual vocabulary as the shell menus while keeping
their own independently overridable theme values. `panel.outerRadius`,
`innerRadius`, `outerBorderWidth`, `outerPadding`, and `innerBorderWidth` shape
the nested frame. `headerPadding` and `headerAccentOpacity` shape the left-aligned
title band. `entryRadius`, `entryPadding`, `selectionBorderWidth`, and
`selectionAccentOpacity` control rows and actions. `sectionBackground` is the
alternate solid background behind the current navigation section. The panel
color and type defaults are `background`, `foreground`, `accent`, `border`,
`font`, `fontSize`, and `fontWeight`. These fields derive from the same shared
palette, typography, radii, borders, and opacity tokens as `menu` by default;
either surface can still be changed without changing the other.

Feature panels open without a current control or section highlight. Moving the
pointer makes the item below it current. The first Up/Down/Left/Right, H/J/K/L,
Tab, or Shift+Tab input enters keyboard navigation and focuses the current
choice in the first section when available, or that section's first control.
Further arrow or H/J/K/L input moves within the current section; Tab and
Shift+Tab jump between sections even when the current section has several
controls. Entering a selectable section focuses its current selection instead
of its first row. Enter or Space activates the focused row or action. On a
slider, Left/Right or H/L changes its value while Up/Down or J/K continues
through the section. Escape or Q closes the panel. The current section switches
from the normal panel background to `sectionBackground`; its heading keeps the
same color and weight. Only the current control gets the accent wash. A selected
value keeps accent text and a border, so selection remains distinct from
navigation. The panel never shows separate mouse-hover and keyboard focus
cursors. Audio treats output, input, and their device choices as one section
because its level headings are controls themselves.

The shell-native command menu uses the nested `menu` object in the same theme
file. Its width, nested-frame metrics, row spacing, and selection treatment
preserve the earlier Rofi menu's compact visual identity. Colors, typography,
radii, borders, and accent states inherit the shell's semantic theme tokens by
default; the nested object can override them when needed. See
[Menu Configuration](menu-configuration.md#appearance) for the full field
list.

The dedicated application picker, calculator, and wallpaper picker inherit
that same frame. Their additional appearance values live in
`applicationPicker`, `calculator`, and `wallpaperPicker` beside `menu` in
`quickshell.json`. The wallpaper object controls the carousel width and preview
height as screen fractions, the preview aspect ratio, the carousel ellipse's
horizontal radius, side-item scale and opacity, and the gap between previews.
See [Themes](themes.md) for the ownership split.

`bar.minimumThickness` is the bar's minimum content height, not a forced height.
Each widget's content plus the cross-axis padding establishes its natural
height; the tallest widget sets one shared height for all three islands. A
separate vertical-bar padding object will be introduced alongside vertical-bar
support.

## Manage and Inspect the Bar

Hyprland starts the bar through the same public lifecycle commands used for
development and troubleshooting:

```bash
hk-shell start
hk-shell stop
hk-shell restart
hk-shell status
hk-shell logs --tail 100 --no-color
```

Use `QML_IMPORT_PATH=config/quickshell qs -p config/quickshell` only when a
foreground development process is useful. See `config/quickshell/README.md` for the implemented interactions,
internal structure, and validation commands.

## Related Docs

- [Using Hyprkarl](using-hyprkarl.md)
- [Configuration Map](configuration-map.md)
- [Themes](themes.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
