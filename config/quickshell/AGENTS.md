# AGENTS.md

Guidance for coding agents working on the Quickshell shell. The repository
rules in `../../AGENTS.md` apply; this file adds what is specific to the shell.

## Layout

- `shell.qml` starts the desktop; `lock.qml` starts the lock screen as its own
  process so restarting the shell never touches an active lock.
- `desktop/`: `Desktop.qml` creates the shared config, theme, user root, and
  application-wide state, then one `Output.qml` per screen holding that
  screen's bar, menu, pickers, OSD, notification, and polkit windows.
- `bar/`: bar windows, island layout, widgets (`bar/widgets/<Kind>Widget.qml`,
  loaded by `WidgetHost.qml` from the widget's `kind`), the shared
  `SystemMonitor` process, command-widget providers, and `PanelHost.qml`.
- `modules/`: one directory per feature, with its state and presentation.
- `ui/`: shared building blocks grouped by purpose (`controls`, `panels`,
  `modal`, `navigation`, `indicators`, `animation`). Put domain-independent UI
  here from the start, even with one caller.
- `config/`: `JsonSettings.qml` (defaults plus personal file, merged),
  `ShellConfig.qml`, `Theme.qml`, `UserRoot.qml`, `Paths.qml`.

QML type files are uppercase; directories and module namespaces are lowercase.
Widget files are loaded by name at runtime, so directories keep checked-in
`qmldir` files.

## Configuration and theme

`ShellConfig` merges `defaults/shell.json` with
`~/.config/quickshell/settings/shell.json`; `MenuState` does the same for
`menu.json`. Objects merge key by key and arrays replace. The shipped defaults
hold every setting, so consumers read values directly
(`shellConfig.osd.timeout`). Do not add QML fallbacks or a schema validator. A
personal file that does not parse leaves the defaults running and logs why.

The `modules` switches are read once at startup; changing them needs
`hk-shell restart`. A disabled module must create none of its windows, state,
timers, processes, or IPC targets. Disabling one does not rewrite the
keybindings or menu entries that point at it.

## Replaceability

The shell runs from `~/.config/quickshell/`, where Stow links these files next
to the user's `settings/` and `custom/`, so personal QML can import any of it.
The pitch is that a user can switch off, replace, or extend any built-in
without touching Hyprkarl's files. Two decisions keep that true:

- Keybindings, menus, and commands reach a module only through its IPC target.
  The target names and method signatures are public: a user replacement
  declares the same target. Changing one is a breaking change; document it in
  the changelog and `docs/extending-hyprkarl.md`.
- Methods that open something take the output name first, empty meaning the
  focused output, so there is one method per action.

`Theme.qml` reads `current/theme/quickshell.json` from XDG state. The compiler's
`theme-generator/defaults/theme.yaml` supplies every value, so consumers read
groups directly (`theme.panel.padding`, `theme.palette.accent`) and new values
go in the compiler defaults, not in QML. A theme switch swaps the
`current/theme` symlink and deletes the old build; that deletion is what wakes
the file watcher. Appearance belongs to the theme and placement and behavior
to shell JSON. The one exception is a toggle's per-instance `switch` geometry.

## Extension points

All are explicit references, with no discovery or registration:

- `kind: "qml"` widgets load `custom/modules/<source>` with a `context` object
  (`bar/widgets/QmlWidget.qml` builds it).
- One application-wide `userRoot.source` (`config/UserRoot.qml`) for
  independent surfaces or a replacement bar. Its context exposes config,
  theme, and the surface request and methods, plus an optional
  `notificationPosition(outputName)` hook.
- `ui.modal.Modal` is the public frame for personal modals.
- Notification `component` icons from `custom/icons/`.

Do not validate user sources or settings. Dynamically loaded QML is outside
Quickshell's reload graph, so source edits need `hk-shell restart`.

## Design direction

The shell keeps the old AGS bar's compact, information-dense character.
Feature panels should feel like composed desktop controls, each with its own
hierarchy rather than one generic quick-settings grid; Omarchy and macOS are
references for control quality, not layouts to copy. Put current state and
common actions first, show failures where the action happened, and keep
advanced controls reachable without crowding the default view. Every visible
state comes from the theme. Bars are horizontal (top or bottom) only; vertical
bars are a later design task, so do not carry untested vertical branches.

## Decisions worth knowing

- **Launching.** Run user actions through `uwsm-app --` so applications
  survive a shell stop. Pass `HYPRKARL_OUTPUT` as an explicit `env` argument;
  `uwsm-app` hands arguments to its daemon, not the caller's environment.
- **Tray menus** need `//@ pragma UseQApplication` in `shell.qml`.
- **Tooltips** use `ShellTooltip`, a non-focusable `PopupWindow`. Qt Controls'
  `ToolTip` does not cooperate with the shell's layers and input.
- **Panels** are hosted by one `PanelHost` per bar, which owns the popup
  window, anchoring, focus grab, dismissal, and keyboard navigation. Panel
  content must not create its own window. The screenshot IPC target releases
  the focus grab without closing the panel.
- **Bar geometry.** Height comes from the tallest widget, floored at the
  theme minimum, and is shared by all islands. `WidgetHost` owns widget
  padding, so widget sizes describe content only. Bars are horizontal (top or
  bottom); keep edge-dependent placement at the window boundary.
- **Command widgets.** One provider per widget ID regardless of monitor count,
  and none at all when no widget has a `command`. Poll intervals are the
  user's choice; the docs warn about the cost.
- **Keyboard navigation.** `KeyboardNavigator` and `NavigationState` give
  panels and modals one current control across pointer and keyboard. Controls
  join with `activeFocusOnTab` and group with `navigationSection`. Do not add
  a second focus chain.
- **Overlays.** `OverlayState` keeps menu, launcher, calculator, wallpaper
  picker, display arranger, and personal modals mutually exclusive and routes
  them to a monitor. Menu surface actions push, so Back returns to the menu.
- **Notifications.** `NotificationState` is the single server. Its model is
  keyed by entry serial so delegates and their timers survive stack changes.
- **Display.** `DisplayPanel` is a view over `hk-display`. The ten-second
  keep-or-revert trial is guaranteed by the backend watchdog, not QML, so a
  broken mode reverts even if the shell dies. The arranger rejects overlapping
  frames and applies directly, without the trial.
- **Network and Bluetooth.** Scanning is global while panels are per monitor,
  so `NetworkState` and `BluetoothState` count requesters. Bluetooth discovery
  starts only on an explicit scan. The installed Bluetooth and PowerProfiles
  APIs report no pairing prompts or write failures; do not invent them.
- **Polkit.** `PolkitState` owns the single agent; `PolkitWindow` binds to its
  current `AuthFlow`. The `qmllint` warning about `AuthFlow` is an upstream
  type-metadata gap (the upstream example has it too); verify live instead of
  wrapping it.
- **Lock.** The lock engages before reading the theme, so a broken theme
  cannot leave the session unlocked. Hypridle owns suspend ordering
  (`before_sleep_cmd` plus `inhibit_sleep = 3`). Password authenticates through
  `/etc/pam.d/login`. Fingerprint uses the one-line service in
  `modules/lock/pam/`; PAM resolves `include` inside a custom directory, so it
  cannot include system stacks. Keep `modules/lock/licenses/` with the
  fingerprint SVG.

## Checks

From the repository root:

```bash
/usr/lib/qt6/bin/qmllint $(rg --files config/quickshell -g '*.qml' | sort)
tests/hk-shell-modules.sh
hk-shell restart && hk-shell logs --tail 100 --no-color
```

The installed type metadata leaves about 20 known `qmllint` warnings
(`PopupAnchor`, `PanelWindow`, and similar); compare the count rather than
expecting zero. The live log is authoritative. Lock changes need a live check:
password, fingerprint, and suspend/resume.
