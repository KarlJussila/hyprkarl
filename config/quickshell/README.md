# Quickshell Bar

This directory contains Hyprkarl's production Quickshell bar. Hyprland starts
it through `hk-shell`, which is also the public lifecycle and diagnostics
boundary.

Start and inspect the bar from the repository root:

```bash
hk-shell start
hk-shell status
hk-shell logs
hk-shell stop
```

Use `qs -p config/quickshell` instead when a foreground process is useful for
development. `hk-shell start` is idempotent, starts the shell in a UWSM scope,
and reports a failed QML load even though daemonized `qs` itself exits
successfully in that case. `hk-shell stop` waits until Quickshell unregisters
the instance, so `hk-shell restart` cannot race a process that is still
shutting down. `hk-shell logs` reads the newest instance and accepts native
`qs log` options such as `--follow` and `--tail 100`.

The command menu uses the same running instance:

```bash
hk-shell menu toggle main
hk-shell menu open utilities
hk-shell menu close
```

Hardware and media commands use the shell-native OSD. It can also be exercised
directly:

```bash
hk-shell osd volume 42 false
hk-shell osd audio-output 67 false "Built-in Audio Analog Stereo"
hk-shell osd microphone true
hk-shell osd display-brightness 55
hk-shell osd keyboard-brightness 67
hk-shell osd media playing 38 "Track title" "Artist"
```

Notification controls use the same public command family:

```bash
hk-shell notifications dismiss
hk-shell notifications dismiss-all
hk-shell notifications toggle-silenced
hk-shell notifications restore
```

Validate all QML files without launching the bar:

```bash
/usr/lib/qt6/bin/qmllint $(rg --files config/quickshell -g '*.qml' | sort)
```

Quickshell's generated type metadata produces a few tooling-only warnings for
types it creates internally. A live `hk-shell start` is therefore the final
check.

## Configuration

`defaults/shell.json` is Hyprkarl's shipped configuration. To customize the
bar without editing that upstream default, create a sparse override at
`user/shell.json`:

```json
{
  "version": 1,
  "bar": {
    "edge": "bottom"
  }
}
```

Objects merge recursively over the shipped configuration; arrays replace as
complete ordered values. Use `bar.layoutEdits` for explicit `insert`, `move`,
`override`, and `remove` operations keyed by stable widget ID. Widget
definitions live inline where they are placed; `id` identifies an instance and
`kind` selects its built-in implementation. The center layout has `before`, one
optional midpoint `anchor`, and `after` entries so the clock can remain at the
exact monitor midpoint. See `docs/shell-configuration.md` for examples and the
full merge contract.

Version 1 supports top and bottom bars. The shell watches both paths: default
updates and valid user edits are resolved live, deleting the user file returns
to the shipped default, and a rejected live edit leaves the last valid layout
running with an actionable log message. The current bar implements built-in
widget kinds; the planned command and user-QML extension lanes have not landed
yet.

The shipped menu hierarchy lives in `defaults/menu.json`; an optional sparse
`user/menu.json` adds or overrides menus and entries by stable ID. Ordinary
objects recursively merge, `enabled: false` hides an entry, valid changes
apply live, and invalid changes retain the last valid menu. A menu may use a
short-lived `sourceCommand` for validated entries that must be rediscovered on
open. Themes, Docker services, live keybindings, Nerd Font icons, and
fingerprint state use this boundary. Menus may opt into in-process fuzzy
search, theme-owned search/reference widths, and left, center, or right row
alignment. Providers run without a login shell and dynamic destinations appear
atomically after validation; static catalogs such as the icon list are
preformatted when their data is generated. Providers that construct entries
use Python dictionaries and the standard `json` module; simple pass-through
providers may remain Bash.
Menu appearance
uses the active shell theme plus its nested `menu` object. The compact width,
centered rows, title band, nested frame, and bordered selection retain the old
Rofi menu's identity; palette, typography, rounded geometry, borders, and
accent states now belong to the shell's visual system. See
`docs/menu-configuration.md` for the schema and examples.

Themes own appearance through the active runtime bundle's `quickshell.json`.
`Theme.qml` watches the XDG-state `current/theme.json` selector, then reads the
immutable artifact named there, so a theme switch applies to a running bar.
This includes every color plus typography, minimum bar thickness,
spacing, radii, borders, dividers, panel sizing, and transition timing.

Island geometry uses logical edges so the same theme works on top and bottom
bars. `bar.margin.screen`, `.content`, and `.outer` control the
screen-side gap, workspace-side gap, and gaps at the monitor's horizontal
ends. `bar.island.corners` selects `square` or `round` independently at the
screen/content and outer/inner intersections; `screenInner` additionally
accepts `curve` for the concave joins between islands. `bar.island.borders`
toggles the corresponding four edges. `bar.island.radius`, `.curveSize`, and
`.curveRadius` size those shapes. See `docs/customizing-bar.md` for a
complete example.

`bar.widgetPadding.main` and `.cross` are universal outer padding for
every widget on a top or bottom bar. `main` follows the bar and `cross` follows
its thickness; “horizontal” names the bar orientation, not a coordinate axis.
The host applies both values to every widget. Widget natural sizes contain only
their content, so padding is never stacked on a second built-in inset.
`bar.trayPaddingOffset` adjusts the tray's main-axis host padding and is added
with a zero floor; the shipped `-2` turns the universal `6` into `4` pixels per
outer side. The revealed tray keeps the unmodified universal padding beside
its divider, without adding space between adjacent items. It also mirrors the
effective outer inset between the chevron and divider, keeping the trigger the
same visible width when collapsed or expanded. Panel internals use the separate
`metrics.controlPadding` value.

Tray icons use the StatusNotifierItem interaction contract: left click
activates the item, middle click invokes its secondary action, and right click
opens its native menu. Items that expose only a menu open it on left click as
well. The root `UseQApplication` pragma is required for those Qt platform menus.
Opening an empty tray only flips the chevron. Its open state is retained, so
the tray expands automatically if an item appears later.

The cross-axis padding contributes to each widget's natural height, while
`bar.minimumThickness` only supplies a floor. The bar resolves the tallest widget
and gives every island that same content height. A vertical-bar padding object
will accompany vertical-bar support rather than being exposed speculatively.

The sibling top-level `osd` object owns transient-surface behavior:
`edge` (`top` or `bottom`), edge `margin`, ordinary `timeout`, and
`mediaTimeout`, all in milliseconds. Each theme's nested `osd` object owns
widths, padding, spacing, radius, indicator size, progress height, and motion.

The sibling `notifications` object owns bar-relative docking, timeouts, stack
limit, exact application filters, compact applications, fallback icons, and
data-defined application/icon-name overrides. An override descriptor may use
an icon-theme name or path, a Nerd Font glyph, a built-in or user QML drawing,
or no icon. Notification content images remain message content and take
priority. Each theme's `notification` object owns surface color, widths,
padding, spacing, radius, icon/image sizes, custom-indicator scale, progress
height, and reveal timing. See `docs/shell-configuration.md` for the complete
schema and override examples.

## Structure

- `shell.qml` creates one bar per Quickshell screen after configuration and
  theme data load. `ScreenSurfaces.qml` groups that screen's bar, menu, OSD,
  and notification windows so bar-relative surfaces use the real bar geometry.
- `config/ShellConfig.qml` selects, validates, and watches shell JSON.
- `Bar.qml` owns the layer-shell window and exclusive zone.
- `panels/FeaturePanelHost.qml` owns the one feature-panel window and active
  panel lifecycle for each monitor.
- `layout/` owns island placement and the shared island surface; it positions
  the center island at its natural width around a center widget fixed to the
  monitor midpoint.
- `widgets/WidgetHost.qml` loads widget kinds from the instance definitions.
- `widgets/*.qml` provide compact status and panel entry points.
- `features/` owns feature-specific panel state and composition. Audio,
  network, Bluetooth, power, and clock/calendar all use this boundary.
- `features/menu/` owns menu configuration, navigation state, IPC, and the
  per-screen overlay.
- `features/osd/` owns one typed state/IPC object and the per-screen,
  click-through transient surface.
- `features/notifications/` owns the freedesktop server, notification
  lifecycle and IPC, icon presentation, and one non-focusable stack per screen.
- `components/` contains shared buttons, tooltips, and panel controls.
- `state/SystemState.qml` owns the one polling process used by CPU, GPU, RAM,
  and recording widgets.

Keep new behavior in the widget that owns it. Add a shared component only when
multiple widgets genuinely use the same interaction or visual structure.

## Current interactions

- The bar menu button, `SUPER + ALT + SPACE`, and
  `hk-shell menu toggle main` toggle the shell-native main menu on the focused
  output. `SUPER + ESCAPE` opens its power section. Searchable menus focus
  their input and retain arrow/Enter navigation; other menus support arrows or
  H/J/K/L, Home/End, Enter/Space, and Escape/Backspace. Clicking outside
  dismisses the menu.
- Left-click opens feature panels or performs a widget's primary action.
- Right-click runs the configured secondary launcher.
- Middle-click is reserved for an explicitly configured tertiary action.
- CPU, GPU, and RAM values start collapsed; left-click reveals the value and
  right-click switches between primary and alternate formats. Their readouts
  and the system tray expand horizontally instead of appearing immediately.
  The open tray separates its expander from its items with a divider. Tray
  items and workspace labels have outer padding at their group boundaries
  without adding space between adjacent items.
- Focused workspaces use accent-colored brackets; audio, battery, and toggle
  widgets use drawn indicators instead of font-dependent approximations.
- Audio, network, Bluetooth, battery/power, and clock/calendar open
  independent, stable-width feature panels through one per-monitor host. The
  host expands each panel to its content height or the remaining monitor
  height, scrolls only content that still cannot fit, switches between those
  triggers on the first click, dismisses on Escape or an outside click, and
  sharpens the bar-side corner when it also touches a monitor side. External
  launcher actions close their panel before opening the configured app.
- Audio exposes output and microphone volume/mute, selectable default devices,
  input activity, and a header settings cog. Network exposes Wi-Fi state,
  scanning and sorted networks, inline passwords, connection progress/errors,
  and its own header settings cog. The connected network appears once as the
  selected first row rather than being repeated above the list.
- Bluetooth exposes adapter power, connected/paired/available device sections,
  explicitly requested discovery, direct connect/pair actions, reported device
  battery, and a header settings cog. Opening the panel alone does not start a
  scan. Pairing that requires a PIN/passkey agent remains in the advanced tool
  because the installed Quickshell API does not expose that interaction or
  device-action failure reasons.
- Battery/power composes charge state, a reliable time estimate when UPower
  provides one, energy rate, power profiles, profile holds/degradation, and
  the configured power-action menu without introducing a separate controller.
  Percentage and charge status appear once in the battery summary rather than
  being duplicated in the panel header. The percentage and status form its
  first row; the indicator and energy rate form its second, with an up/down
  arrow showing whether power is entering or leaving the battery. The summary
  gives its percentage and indicator matching three-character widths. Both
  battery readouts use `MAX` instead of `100%`; the compact panel width
  remains independently themeable through `panel.powerWidth`. The drawn
  indicator keeps its original 18×10 canvas in the bar and allocates a larger
  canvas for the panel rather than magnifying a small texture.
  The audio indicator centers in its bar row and resolves its stroke to two
  physical pixels so fractional output scaling does not soften it.
  The installed PowerProfiles API exposes confirmed profile state but no
  per-write failure result, so the bar does not invent one.
- Clock/calendar binds the bar, date header, viewed month, and current-day
  highlight to one shared clock. Previous/next controls navigate real months,
  a return action appears away from the current month, and reopening resets to
  today without persisting transient navigation state.
- Volume, output switching, microphone mute, display/keyboard brightness, and
  media keys coalesce into one focused-monitor OSD. It reuses the bar's drawn
  audio indicator for audio and theme-font Nerd Font glyphs for the other
  semantic states; it never takes focus or pointer input.
- Desktop notifications route to the focused output and support application
  icons or content images, body text, progress, hover-paused expiry, critical
  persistence, synchronous updates, silence mode, and one-item visual restore.
  The default stack grows from the bar into the workspace at the right screen
  edge, overlaps the bar border, and joins adjacent toasts along one shared
  border. Corners square only where the neighboring toast reaches them, so
  width overhangs remain rounded. The outer corner touching both the bar and
  screen is sharp as well. Clicking a toast or using the notification binding
  dismisses it; no permanent close button or action-button row is rendered.
  Mako is not started or configured.
