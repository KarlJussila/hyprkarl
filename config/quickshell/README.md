# Quickshell Shell

This directory contains Hyprkarl's production desktop shell. Hyprland starts
it through `hk-shell`, which is also the public lifecycle and diagnostics
boundary.

```bash
hk-shell start
hk-shell stop
hk-shell restart
hk-shell status
hk-shell logs --tail 100 --no-color
```

Use `QML_IMPORT_PATH=config/quickshell qs -p config/quickshell` only when a
foreground development process is useful. Stop the production shell before
editing QML: Quickshell watches its
source tree, so a multi-file edit can otherwise load a temporary inconsistent
generation. JSON configuration and theme changes have their own last-valid or
atomic live-reload boundaries.

The QML-editing boundary was rechecked on 2026-08-21 with Quickshell 0.3.0-2.1
and Qt 6.11.1. The observed crashes occurred only when the source watcher
loaded incomplete intermediate generations during multi-file edits; clean
starts and normal runtime actions did not reproduce them, and no reachable
Hyprkarl lifetime error was found. Hyprkarl therefore avoids editing a live
production tree instead of carrying a runtime compatibility layer for that
development-only path.

Public configuration belongs in the manual rather than this contributor map:

- [`docs/customizing-bar.md`](../../docs/customizing-bar.md) covers widget
  layout, bar geometry, appearance, and runtime control.
- [`docs/shell-configuration.md`](../../docs/shell-configuration.md) covers
  shell JSON, module switches, command and QML widgets, and the application-wide
  user root.
- [`docs/menu-configuration.md`](../../docs/menu-configuration.md) covers
  command menus, dynamic providers, and custom overlay actions.
- [`docs/themes.md`](../../docs/themes.md) covers theme-source authoring and the
  generated runtime bundle.

## Runtime Shape

`shell.qml` creates the shared configuration and theme, optional application
state, and one `ScreenSurfaces` instance per output. Top-level `modules`
switches gate complete runtimes: disabled modules do not retain their windows,
services, timers, watchers, processes, or IPC targets. `BarRuntime.qml` owns
bar-only system and command providers, so disabling the built-in bar makes
those providers inert too.

Each output's `ScreenSurfaces.qml` composes its optional bar, focused overlays,
OSD, notification stack, and polkit prompt. Application-wide state chooses the
target output; presentation stays per-output. The optional user root can own
independent surfaces or replace the bar and may publish reactive notification
positioning without entering a discovery or plugin system. The app-wide
display arranger, display-change confirmation, and personal `Hyprkarl.Modal`
declarations use the same exclusive modal boundary. The display confirmation's
ten-second rollback is also enforced by a detached backend watchdog.

## Contributor Map

- `config/` selects, merges, validates, and watches shell JSON and the active
  generated theme. `UserRoot.qml` loads the explicitly configured trusted user
  composition root.
- `state/BarRuntime.qml` owns state used only by the built-in bar.
  `SystemState.qml` is the single long-running provider for the CPU, GPU, RAM,
  and recording widgets.
- `Bar.qml` owns one layer-shell bar window and its feature-panel host.
- `layout/` owns start, center, and end placement plus the single island
  renderer. Island edges use logical screen/content/outer/inner names so one
  theme works at the top or bottom.
- `widgets/WidgetHost.qml` loads inline widget definitions and owns universal
  host padding. `widgets/qml.qml` adapts explicitly referenced personal QML
  modules to the documented per-bar context.
- `panels/FeaturePanelHost.qml` owns the per-output popup, anchoring, focus,
  dismissal, spatial keyboard navigation, section traversal, focused-item
  scrolling, animation, and contact-aware corners. Feature content must not
  create another popup boundary.
- `components/NavigationState.qml` owns the single current pointer-or-keyboard
  control and active section. Shared panel controls use it instead of styling
  `containsMouse` and `activeFocus` independently.
- `features/display/`, `audio/`, `network/`, `bluetooth/`, `power/`, and
  `clock/` own their service-specific state and panel compositions. Display
  also owns staged per-output settings, backend-confirmed layout trials, and
  the global position-and-rotation arrangement draft and content.
- `features/command/` owns one provider per provider-backed command-widget ID.
  Static command widgets never enter that registry.
- `features/menu/` owns menu data, hierarchy, rows, selection, search, and
  navigation. It composes the shared overlay frame and momentum behavior.
- `features/overlay/` owns exclusive focused-surface routing, the generic
  `ModalWindow.qml` frame, picker-specific `OverlayWindow.qml`, and
  `MomentumScroll.qml`.
- `Hyprkarl/` is the public QML module. `Modal.qml` gives the explicit personal
  root a styled, keyboard-navigable modal with lazy body/footer content and no
  registration layer.
- `features/applications/`, `calculator/`, and `wallpaper/` own their dedicated
  picker state and presentation without adding another window framework.
- `features/osd/` owns typed transient state and one click-through surface per
  output.
- `features/notifications/` owns the freedesktop server, lifecycle, icon
  resolution, and one non-focusable stack per output.
- `features/polkit/` owns the single session agent and its focused modal
  presentation. It is not a feature panel and has no IPC command.
- `components/` contains controls and visual primitives shared by more than one
  real consumer.

Keep behavior with its owner. Extract a shared component only after multiple
features need the same interaction or presentation. Keep appearance defaults
in the generated theme contract, placement and behavior in shell JSON, and
transient service state with the service or feature that owns it. A shared
control may accept a documented sparse per-instance appearance override when
one application needs different geometry within the same theme.

## Checks

Lint the complete QML tree before starting it:

```bash
/usr/lib/qt6/bin/qmllint $(rg --files config/quickshell -g '*.qml' | sort)
```

Quickshell's generated type metadata produces a small number of known tooling
warnings, so a clean production launch is the authoritative integration check:

```bash
hk-shell start
hk-shell status
hk-shell logs --tail 100 --no-color
```

When a change affects interaction, exercise the public command that reaches
it and inspect the live surface. A successful `hk-shell stop` must leave no
live instance in `qs list`; restart relies on that observable boundary.
