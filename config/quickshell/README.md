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

The dedicated application, calculator, and wallpaper surfaces use that
instance too:

```bash
hk-shell launcher toggle
hk-shell calculator toggle
hk-shell wallpaper set
hk-open-with <file>
```

Only one focused shell overlay is visible at a time. Opening one of these
surfaces replaces an open command menu or another dedicated overlay on the
focused output.

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
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json`:

```json
{
  "version": 1,
  "bar": {
    "enabled": true,
    "edge": "bottom"
  }
}
```

Objects merge recursively over the shipped configuration; arrays replace as
complete ordered values. Use `bar.layoutEdits` for explicit `insert`, `move`,
`override`, and `remove` operations keyed by stable widget ID. Widget
definitions live inline where they are placed; `id` identifies an instance and
`kind` selects its built-in, command-backed, or explicitly referenced user-QML
implementation. The center layout
has `before`, one optional midpoint `anchor`, and `after` entries so the clock
can remain at the exact monitor midpoint. See `docs/shell-configuration.md` for
examples and the full merge contract.

Version 1 supports top and bottom bars. The shell watches both paths: default
updates and valid user edits are resolved live, deleting the user file returns
to the shipped default, and a rejected live edit leaves the last valid layout
running with an actionable log message. The current bar implements built-in,
command, and user-QML widget kinds. A user-QML instance names a relative file
below `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/modules/` and receives the documented per-bar context;
modules are never discovered or registered implicitly. A command widget can
poll through `bash -c` or consume a persistent newline
stream. Polling starts a process on every tick, so short intervals carry a CPU
and battery cost; stream mode is intended for frequent updates. Static command
buttons omit the provider command and create no timer or process; the shipped
main-menu button uses that form.

`bar.enabled: false` destroys the built-in per-output bar windows and makes
their application-wide hardware monitor and command providers inert; the
menu, notifications, OSD, and polkit remain active. One optional
`userRoot.source` loads an application-wide QML composition root from
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/`. It can own independent or per-screen surfaces and may
publish a reactive notification position for each output. This is one
explicitly referenced user module, not a discovered plugin collection. See
`docs/shell-configuration.md` for its context and positioning contract.

The shipped menu hierarchy lives in `defaults/menu.json`; an optional sparse
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/menu.json` adds or overrides menus and entries by stable ID. Ordinary
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
providers may remain Bash. A `surface` action moves directly from the command
menu to a dedicated or user-composed Quickshell overlay without spawning a
command; its optional parameter object is passed through unchanged.
Menu appearance
uses the active shell theme plus its nested `menu` object. The compact width,
centered rows, title band, nested frame, and bordered selection retain the old
Rofi menu's identity; palette, typography, rounded geometry, borders, and
accent states now belong to the shell's visual system. See
`docs/menu-configuration.md` for the schema and examples.

The launcher/open-with chooser, calculator, and wallpaper picker are dedicated
surfaces rather than command-menu entry shapes. They share the command menu's
frame, focus lifecycle, and touchpad momentum through `features/overlay/`, but
each feature owns its domain behavior. Built-in menu entries reach these
surfaces through in-process surface actions. The launcher consumes Quickshell's
resident desktop-entry model and launches through `gtk-launch`; open-with asks
`hk-open-with` for Gio's application model and may set the chosen application
as the MIME default before launching. The calculator evaluates with `qalc` and
keeps five recent expression/result pairs in XDG state. The wallpaper picker
loads cached thumbnails from `hk-wallpaper-entries` and delegates changes to
`hk-wallpaper`. Their widths, row counts, icon size, grid geometry, and history
limit are theme values under `applicationPicker`, `calculator`, and
`wallpaperPicker`.

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

The sibling `notifications` object owns surface-relative docking, timeouts, stack
limit, exact application filters, compact applications, fallback icons, and
data-defined application/icon-name overrides. An override descriptor may use
an icon-theme name or path, a Nerd Font glyph, a built-in or user QML drawing,
or no icon. Notification content images remain message content and take
priority. Each theme's `notification` object owns surface color, widths,
padding, spacing, radius, icon size, custom-indicator scale, progress
height, and reveal timing. See `docs/shell-configuration.md` for the complete
schema and override examples.

## Structure

- `shell.qml` retains application-wide feature singletons and creates one
  surface group per Quickshell screen after configuration and theme data load.
  `ScreenSurfaces.qml` groups that screen's bar, focused overlays, OSD,
  notification, and polkit windows so each surface receives the correct output.
- `config/ShellConfig.qml` selects, validates, and watches shell JSON.
- `config/UserRoot.qml` loads the optional application-wide user composition
  root and forwards its reactive notification-position method.
- `Bar.qml` owns the layer-shell window and exclusive zone.
- `panels/FeaturePanelHost.qml` owns the one feature-panel window and active
  panel lifecycle for each monitor.
- `layout/` owns island placement and the shared island surface; it positions
  the center island at its natural width around a center widget fixed to the
  monitor midpoint.
- `widgets/WidgetHost.qml` loads widget kinds from the instance definitions.
- `widgets/*.qml` provide compact status and panel entry points;
  `widgets/qml.qml` is the host for explicitly referenced
  modules under `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/modules/`.
- `features/` owns feature-specific panel state and composition. Display,
  audio, network, Bluetooth, power, and clock/calendar all use this boundary.
  Display is a per-output view over the separate `hk-display` backend rather
  than a second QML monitor-state owner.
- `features/menu/` owns menu configuration, navigation state, IPC, and the
  per-screen overlay.
- `features/overlay/` owns focused-surface exclusivity, the shared visual frame,
  and touchpad momentum used by menus and dedicated pickers.
- `features/applications/` owns the resident launcher and Gio-backed open-with
  chooser; `features/calculator/` and `features/wallpaper/` own their
  corresponding state, IPC, and per-screen presentations.
- `features/osd/` owns one typed state/IPC object and the per-screen,
  click-through transient surface.
- `features/notifications/` owns the freedesktop server, notification
  lifecycle and IPC, icon presentation, and one non-focusable stack per screen.
- `features/polkit/` owns the one session agent and the focused modal prompt;
  it binds directly to Quickshell's active authentication flow and has no IPC.
- `features/command/` owns one application-wide polling or persistent-stream
  provider per provider-backed command-widget ID. Static action buttons do not
  enter that registry.
- `components/` contains shared buttons, tooltips, and panel controls.
- `state/SystemState.qml` owns the one polling process used by CPU, GPU, RAM,
  and recording widgets.

Keep new behavior in the widget that owns it. Add a shared component only when
multiple widgets genuinely use the same interaction or visual structure.

## Current interactions

- The bar's static command widget toggles the shell-native main menu on its own
  output. `SUPER + ALT + SPACE` and `hk-shell menu toggle main` target the
  focused output; `SUPER + ESCAPE` opens its power section. Searchable menus focus
  their input and retain arrow/Enter navigation; other menus support arrows or
  H/J/K/L, Home/End, Enter/Space, and Escape/Backspace. Clicking outside
  dismisses the menu.
- `SUPER + SPACE` opens the resident application launcher. The calculator and
  wallpaper picker use their corresponding `hk-shell` commands, while
  `hk-open-with <file>` opens the same application chooser in file mode. Search,
  selection, dismissal, and touchpad momentum are consistent across these
  focused overlays. The open-with footer uses the shell switch primitive to
  optionally make the selected application the MIME default.
- Left-click opens feature panels or performs a widget's primary action.
- Right-click runs the configured secondary launcher.
- Middle-click is reserved for an explicitly configured tertiary action.
- Command widgets render shared text or validated JSON results from one
  application-wide provider per ID. Poll providers skip overlapping runs;
  persistent providers consume one result per newline.
- CPU, GPU, and RAM values start collapsed; left-click reveals the value and
  right-click switches between primary and alternate formats. Their readouts
  and the system tray expand horizontally instead of appearing immediately.
  The open tray separates its expander from its items with a divider. Tray
  items and workspace labels have outer padding at their group boundaries
  without adding space between adjacent items.
- Focused workspaces use accent-colored brackets; audio, battery, and toggle
  widgets use drawn indicators instead of font-dependent approximations.
- Display, audio, network, Bluetooth, battery/power, and clock/calendar open
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
- Display targets the output containing the clicked bar. It exposes an
  available internal backlight, whole-logical-pixel scale presets, and
  connected-output enablement without allowing the last active output to be
  disabled. `hk-display` owns discovery, live Hyprland changes, and the
  generated XDG-state layout; the panel does not rewrite shell JSON or
  personal monitor rules. External DDC brightness, mode/position editing, and
  global text size are intentionally outside this first slice.
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
- Polkit requests open a compact modal prompt on the output that was focused
  when the request began. The prompt follows PAM's response visibility,
  supports multiple identities when supplied, submits with Enter, cancels
  with Escape, and leaves retries to the service-owned authentication flow.
  `hyprpolkitagent` is not started alongside it.
