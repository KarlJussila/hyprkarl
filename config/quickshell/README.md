# Quickshell

Hyprkarl's desktop and lock screen share this project, its theme, and its UI
components. `hk-shell` manages the desktop. `hk-lock` launches the lock in its
own process so restarting the desktop preserves an active lock.

## Project structure

```text
shell.qml                    desktop launch file
lock.qml                     lock launch file and secure-lock lifecycle
config/                      settings, theme, paths, personal-root loading
desktop/
  Desktop.qml                shared state, module selection, output creation
  Output.qml                 one monitor's bar and independent windows
bar/
  BarWindow.qml              one layer-shell bar
  PanelHost.qml              the bar's shared panel popup
  BarState.qml               bar-only provider lifetimes
  SystemMonitor.qml          CPU/GPU/RAM/recording state
  read-system-state.sh       the monitor's data source
  layout/                    island geometry and widget placement
  widgets/                   compact bar widgets, including personal QML
  commands/                  command-widget providers
modules/
  audio/ bluetooth/ clock/ display/ network/ power/
                             service state and bar-panel content
  applications/ calculator/ menu/ wallpaper/
                             focused pickers and their state
  notifications/ osd/ polkit/ independent desktop services and presentation
  lock/                      authentication, sleep/resume, lock presentation
ui/
  animation/                 shared motion
  controls/                  buttons, tooltips, switches, readouts
  indicators/                shared audio/battery drawings
  navigation/                pointer and keyboard navigation
  panels/                    shared panel rows, headers, actions, sliders
  modal/                     shared focused windows and overlay routing
```

Directory names identify ownership. A module keeps its state and presentation
together. `bar/` owns bar-specific code. `ui/` groups reusable building blocks
by purpose, including animations, basic controls, and input handling. These can
belong in `ui/` from the start, even with one caller. Module-specific behavior
stays with its module.

QML types require uppercase filenames, such as `BarWindow.qml` and
`ShakeAnimation.qml`. Lowercase `shell.qml` and `lock.qml` are launch files,
not reusable types. Directories and module namespaces are lowercase. Personal
QML can use `import ui.modal` to create a shared `Modal`.

## Personal configuration

Edit `~/.config/quickshell/settings/shell.json` for module switches, bar layout,
behavior, and the personal root. Edit `settings/menu.json` for
menus. Ordinary JSON settings reload live; module switches require
`hk-shell restart`.

Personal QML lives under `~/.config/quickshell/custom/`. Reference widgets
explicitly in the layout or name an application-wide `userRoot.source` to add
independent interfaces or replace the bar. Removing a widget or disabling a
module stops its runtime. Existing command/keybinding entry points can be
changed in their own personal configuration.

Launcher entries and user command actions run through `uwsm-app --`, so
applications survive stopping or restarting the desktop shell. Polling and
service-monitor processes remain owned by the shell.

Appearance comes from personal theme sources, applied with `hk-theme set <name>`.

The manual owns the detailed contracts:

- [Shell settings and QML extensions](../../docs/shell-configuration.md)
- [Menu configuration](../../docs/menu-configuration.md)
- [Authentication](../../docs/authentication-surfaces.md)
- [Themes](../../docs/themes.md)

## Adding a built-in widget

1. Create `bar/widgets/<Kind>Widget.qml`. `WidgetHost` resolves the filename
   from the layout's `kind`, so `kind: "example"` loads `ExampleWidget.qml`.
   Existing widgets show the properties supplied by the host.
2. Add its default instance and stable ID to `defaults/shell.json` at the
   repository root. Keep widget-specific settings with the widget.
3. Put service state and panel content in the corresponding `modules/`
   directory. Use the bar's `PanelHost` for panels and tie runtime creation
   to the widget or module that needs it.
4. Add required appearance values to the final `shell` object in
   `theme-generator/defaults/theme.yaml`. See the
   [compiler guide](../../theme-generator/README.md) for theme integration.

## Editing and checks

Stop the production desktop before multi-file QML edits. Quickshell watches
source files and can load an incomplete intermediate generation. A staged tree
outside the live source is also suitable. Personal QML loaded dynamically needs
`hk-shell restart` after source edits. A new file in this directory reaches the
running shell only once `hk-update apply` links it.

From the repository root:

```bash
/usr/lib/qt6/bin/qmllint $(rg --files config/quickshell -g '*.qml' | sort)
tests/hk-shell-modules.sh
python3 tests/hk-shell-launch.py
```

The module check briefly creates an isolated desktop instance. Check the lock
live: password, fingerprint, and suspend/resume. See
[tests](../../tests/README.md).

Quickshell's type metadata has known warnings for some native types. Verify a
clean runtime and exercise the affected public action as well as linting:

```bash
hk-shell start
hk-shell status
hk-shell logs --tail 100 --no-color
```
