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

Themes own appearance through `themes/<theme>/quickshell.json`. `Theme.qml`
watches `config/hyprkarl/current/theme.name`, then reads the selected theme
file directly, so both a theme switch and an edit to the active JSON apply to a
running bar. This includes every color plus typography, bar thickness, spacing,
radii, borders, dividers, panel sizing, and transition timing.

## Structure

- `shell.qml` creates one bar per Quickshell screen after configuration and
  theme data load.
- `config/ShellConfig.qml` selects, validates, and watches shell JSON.
- `Bar.qml` owns the layer-shell window and exclusive zone.
- `panels/FeaturePanelHost.qml` owns the one feature-panel window and active
  panel lifecycle for each monitor.
- `layout/` owns island placement; it positions the center island at its
  natural width around a center widget fixed to the monitor midpoint.
- `widgets/WidgetHost.qml` loads widget kinds from the instance definitions.
- `widgets/*.qml` provide compact status and panel entry points.
- `features/` owns feature-specific panel state and composition. Audio,
  network, Bluetooth, power, and clock/calendar all use this boundary.
- `components/` contains shared buttons, tooltips, and panel controls.
- `state/SystemState.qml` owns the one polling process used by CPU, GPU, RAM,
  and recording widgets.

Keep new behavior in the widget that owns it. Add a shared component only when
multiple widgets genuinely use the same interaction or visual structure.

## Current interactions

- Left-click opens feature panels or performs a widget's primary action.
- Right-click runs the configured secondary launcher.
- Middle-click is reserved for an explicitly configured tertiary action.
- CPU, GPU, and RAM values start collapsed; left-click reveals the value and
  right-click switches between primary and alternate formats. Their readouts
  and the system tray expand horizontally instead of appearing immediately.
  The open tray separates its expander from its items with a divider.
- Focused workspaces use accent-colored brackets; audio, battery, and toggle
  widgets use drawn indicators instead of font-dependent approximations.
- Audio, network, Bluetooth, battery/power, and clock/calendar open
  independent, stable-width feature panels through one per-monitor host. The
  host clamps to monitor bounds, scrolls dense content, switches between those
  triggers on the first click, dismisses on Escape or an outside click, and
  sharpens the bar-side corner when it also touches a monitor side.
- Audio exposes output and microphone volume/mute, selectable default devices,
  input activity, and an advanced-settings route. Network exposes Wi-Fi state,
  current connection, scanning and sorted networks, inline passwords,
  connection progress/errors, and an advanced-settings route.
- Bluetooth exposes adapter power, connected/paired/available device sections,
  discovery, direct connect/pair actions, reported device battery, and an
  advanced-settings route. Pairing that requires a PIN/passkey agent remains
  in the advanced tool because the installed Quickshell API does not expose
  that interaction or device-action failure reasons.
- Battery/power composes charge state, a reliable time estimate when UPower
  provides one, energy rate, power profiles, profile holds/degradation, and
  the configured power-action menu without introducing a separate controller.
  The installed PowerProfiles API exposes confirmed profile state but no
  per-write failure result, so the bar does not invent one.
- Clock/calendar binds the bar, date header, viewed month, and current-day
  highlight to one shared clock. Previous/next controls navigate real months,
  a return action appears away from the current month, and reopening resets to
  today without persisting transient navigation state.
