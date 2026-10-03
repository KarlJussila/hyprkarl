# Extending Hyprkarl

This guide covers personal customization: scripts, hooks, menu entries,
keybindings, and Quickshell interfaces. These live outside the checkout and
survive Hyprkarl updates. No Git branch is needed.

For changes to Hyprkarl's shipped implementation, start with
[Repo conventions](repo-conventions.md).

## Choose the right place

| What you want to change | Personal location |
|---|---|
| Application preferences | The application's own configuration directory; see the [ownership table](configuration-map.md#application-configuration) |
| Hyprland settings and keybindings | `~/.config/hypr/hyprland.local.lua` |
| Quickshell behavior, modules, and bar layout | `~/.config/quickshell/settings/shell.json` |
| Menu entries | `~/.config/quickshell/settings/menu.json` |
| Quickshell widgets and independent interfaces | `~/.config/quickshell/custom/` |
| Theme values, templates, and assets | `~/.config/hyprkarl/themes/<name>/` |
| Lifecycle hooks | `~/.config/hyprkarl/hooks/<event>.d/` |
| Personal commands | `~/.local/bin/` |

The examples use the usual `~/.config/` location. If you set `XDG_CONFIG_HOME`,
use that directory instead.

## Add a personal command

Put an executable script in `~/.local/bin/`. Hyprkarl's session already adds
that directory to `PATH`, so menus and keybindings can call it by name.

```bash
mkdir -p ~/.local/bin
$EDITOR ~/.local/bin/my-command
chmod +x ~/.local/bin/my-command
```

Give it the appropriate shebang, such as `#!/bin/bash` or
`#!/usr/bin/env python3`. Use Bash for command orchestration and Python for
structured data or substantial parsing.

A personal command with the same name as an `hk-*` command replaces it, because
`~/.local/bin` comes first on `PATH`. Keybindings, menus, Hypridle, and other
commands then run yours.

You can also add personal desktop entries under
`~/.local/share/applications/` to expose applications or scripts in the
launcher.

## Add a lifecycle hook

Hooks run after you log in, a complete update, a theme switch, or a
wallpaper change. Put executable files in the corresponding
`~/.config/hyprkarl/hooks/<event>.d/` directory. The event names are
`login`, `post-update`, `theme-set`, and `wallpaper-set`.

For example, to reload an application after switching themes:

```bash
mkdir -p ~/.config/hyprkarl/hooks/theme-set.d
$EDITOR ~/.config/hyprkarl/hooks/theme-set.d/10-reload-my-app
chmod +x ~/.config/hyprkarl/hooks/theme-set.d/10-reload-my-app
```

Hooks run in lexical filename order, inherit the action's environment, and
receive no arguments. Use `hk-theme current` or the
[active theme files](#use-the-active-theme-in-personal-code) when a hook needs
the current selection. A failed hook is reported after the remaining hooks
run; the theme or wallpaper change has already completed.

## Add a menu action

Create `~/.config/quickshell/settings/menu.json` with the entries you want to
add or change. For example, this adds a personal command to Utilities:

```json
{
  "entries": {
    "utilities.my-command": {
      "parent": "utilities",
      "order": 25,
      "label": "My command",
      "action": { "type": "command", "command": "my-command" }
    }
  }
}
```

Valid edits apply live. Keep longer commands in personal scripts and reference
them here. Menu command actions already launch through `uwsm-app --`.

Entries can also open submenus or Quickshell interfaces. Existing entries can
be renamed, reordered, or hidden by ID. See
[Menu configuration](menu-configuration.md) for these options and dynamic
entry providers.

## Customize Hyprland

Put personal Hyprland settings in `~/.config/hypr/hyprland.local.lua`. Hyprkarl creates it once and
loads it after the shipped settings, active theme, and generated display
layout, so it can change selected values without copying the shipped
configuration:

```lua
hl.config({
    input = {
        kb_layout = "us,fi",
        sensitivity = 0,
    },
})
```

Keybindings go in the same file:

```lua
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("uwsm-app -- my-command"), {
    description = "My command",
})
```

Descriptions appear in the keybindings menu. Binding and window-rule calls
add to the existing configuration; use `hl.unbind()` before replacing a
shipped binding. The files under `defaults/hypr/` are useful examples. To split
your settings across files, `require` them from `~/.config/hypr/` under names
that differ from Hyprkarl's modules.

Validate with `Hyprland --verify-config` before reloading. See the
[Hyprland configuration map](configuration-map.md#hyprland) for each module's
purpose and display configuration.

## Extend Quickshell

Most shell changes are settings in `~/.config/quickshell/settings/shell.json`;
see [Shell configuration](shell-configuration.md). That includes [command
widgets](shell-configuration.md#command-widgets), which put a script's output
or a button in the bar without any QML. For more, write QML:

- a **QML widget** renders and behaves however you like inside the bar;
- an **application-wide root** adds windows of its own, a different bar, or
  replacements for built-in parts.

The shell runs from `~/.config/quickshell/`, where Hyprkarl's files are links
next to your `settings/` and `custom/`. Your QML can import any of it, such as
`import ui.modal` or `import "../modules/lock"` from `custom/`. It runs inside
the shell with no sandbox; an error in it is logged and leaves the rest of the
shell running. Run `hk-shell restart` after editing a QML file.

### QML widgets

Put the file under `~/.config/quickshell/custom/modules/` and place it in a
bar section with `kind: "qml"`. `settings` is yours to define:

```json
{
  "id": "greeting",
  "kind": "qml",
  "source": "Greeting.qml",
  "settings": { "text": "Hello", "command": "notify-send Hello" }
}
```

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
        color: root.context.theme.palette.foreground
        font.family: root.context.theme.typography.uiFamily
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.context.runCommand(root.context.settings.command)
    }
}
```

Each monitor's bar gets its own instance. `context` provides:

| Member | Meaning |
|---|---|
| `widgetId`, `settings` | The widget's `id` and `settings` from `shell.json` |
| `theme` | The live theme; see [Theme values](#theme-values) |
| `edge` | `top` or `bottom` |
| `output`, `barWindow` | The monitor's name and the bar window |
| `runCommand(command)` | Runs a command with `HYPRKARL_OUTPUT` set |
| `togglePanel(trigger, component)`, `closePanel()` | Opens content in the bar's popup panel, attached to `trigger` |
| `launchPanelCommand(command)` | Closes the panel, then runs a command |

The widget may also set `tooltip` (text shown on hover), `tooltipSuppressed`,
and `widgetVisible` (false hides it entirely; plain `visible` only hides its
content).

### Application-wide QML

Point `userRoot.source` at a file under `~/.config/quickshell/custom/`. The
shell loads it once, so it can hold your own windows (one per monitor with
`Variants`), global state, or a whole bar. To replace the built-in bar, also
turn it off:

```json
{
  "modules": { "bar": false },
  "userRoot": { "source": "Extensions.qml", "settings": {} }
}
```

Its root declares `required property var context`, which provides:

| Member | Meaning |
|---|---|
| `configuration`, `settings` | The merged `shell.json`, and its `userRoot.settings` |
| `theme` | The live theme; see [Theme values](#theme-values) |
| `surfaceName`, `surfaceOutput`, `surfaceParameters` | The open surface, if any |
| `openSurface(name, output, parameters)` | Opens a surface unless one is open |
| `replaceSurface(...)`, `toggleSurface(...)` | Opens it in place of the current one, or closes it if it is the current one |
| `pushSurface(...)`, `backSurface()` | Opens one that can return to the current one, and returns |
| `closeSurface()` | Closes the current surface |

A **surface** is one focused interface open on one monitor at a time: a menu,
the launcher, or one of yours. A menu entry opens one by name:

```json
{ "type": "surface", "surface": "user.dashboard", "parameters": { "section": "weather" } }
```

Your root sees `surfaceName` change to `user.dashboard` and shows its window.
`Modal` from `ui.modal` does the window part, matching the shell's own menus,
including keyboard navigation:

```qml
import QtQuick
import Quickshell
import ui.modal

Scope {
    id: root
    required property var context

    Modal {
        context: root.context
        name: "user.dashboard"
        title: "Dashboard"
        subtitle: root.context.surfaceParameters.section ?? ""

        body: Component {
            Text {
                text: "Personal content"
                color: root.context.theme.menu.foreground
            }
        }
    }
}
```

`Modal` opens on the surface's monitor whenever the surface has its `name`,
and offers `open(output, parameters)`, `replace`, `toggle`, and `close`. Use a
`user.` prefix to avoid Hyprkarl's names. Set `dismissAction` to run something
other than closing on Escape or an outside click. Controls with
`activeFocusOnTab: true` join its keyboard navigation; give one
`property string navigationSection` to group it, and
`property bool navigationSelected: true` to make it the one keyboard entry
lands on.

A replacement bar can tell notifications where it is, so they keep sitting
against it, with a root function:

```qml
function notificationPosition(outputName: string): var {
    return { "edge": "top", "extent": 30, "connected": true, "reachesSide": true }
}
```

`extent` is the bar's current height from that edge, `connected` joins the
notification border to the bar's, and `reachesSide` sharpens the shared
corner. Return `null` for the default position. It is a normal QML binding, so
an animated bar can return its live height.

### Notification icons

A notification icon with `"kind": "component"` (see [Shell
configuration](shell-configuration.md#notifications)) is a small QML drawing
under `~/.config/quickshell/custom/icons/`. Its root is an `Item` with writable
`progress` and `theme` properties. `progress` carries a notification's
`int:value` hint from 0 to 100, or -1 without one.

### Theme values

`context.theme` reads the active theme's `shell` values by group, such as
`theme.palette.accent` or `theme.panel.padding`; see
[Themes](themes.md#shell-appearance). `theme.values` is the whole document,
so a personal theme can carry values for your own QML, for example
`theme.values.extensions.dashboard.background` from an `extensions` group you
add under `shell` in `theme.yaml`.

## Replace a built-in

Every built-in part of the shell can be switched off and replaced without
editing Hyprkarl's files. Keybindings, the bar, and menu entries reach each
part through a named IPC target, so a replacement that answers the same target
works with all of them unchanged.

To replace one, set its switch under `modules` in `shell.json` to `false`, then
declare the target in your [application-wide QML
root](#application-wide-qml):

```qml
import Quickshell.Io

IpcHandler {
    target: "launcher"

    function open(output: string): bool { /* show your launcher */ return true }
    function toggle(output: string): bool { /* ... */ return true }
    function close(): void { /* ... */ }
}
```

`output` names the monitor to open on; an empty string means the focused one.

| Built-in | Switch | Target and methods your replacement provides |
|---|---|---|
| Bar | `bar` | None. Build your own bar in the root; optionally provide `notificationPosition()` |
| Application launcher | `applications` | `launcher`: `open(output)`, `toggle(output)`, `close()` |
| Open-with chooser | `applications` | `openWith`: `open(output, path)`, `close()` |
| Menu | `menu` | `menu`: `open(output, menu)`, `toggle(output, menu)`, `close()` |
| Calculator | `calculator` | `calculator`: `open(output)`, `toggle(output)`, `close()` |
| Wallpaper picker | `wallpaper` | `wallpaper`: `open(output, action)`, `close()`; `action` is `set` or `remove` |
| Notifications | `notifications` | Any notification server. For the keybindings: `notifications`: `dismiss()`, `dismissAll()`, `toggleSilenced()`, `restore()` |
| OSD | `osd` | `osd`: `volume(percent, muted)`, `output(percent, muted, description)`, `microphone(muted)`, `display(percent)`, `keyboard(percent)`, `media(action, percent, title, artist)` |
| Polkit prompt | `polkit` | Any polkit agent |
| Lock screen | None | Your own `hk-lock` in `~/.local/bin/` |

Menu entries that open the launcher, calculator, or wallpaper picker do so by
surface name (`launcher`, `calculator`, `wallpaper`). With the built-in
switched off, your root sees that request as described under
[Application-wide QML](#application-wide-qml)
and can open its replacement.

## Use the active theme in personal code

Author personal themes or sparse overlays under
`~/.config/hyprkarl/themes/<name>/`, then apply them with `hk-theme set <name>`.
See [Themes](themes.md) for values, template replacements, and assets.

Personal QML receives the active theme through its context, including custom
values in `context.theme.values`. Scripts and other applications can read
generated files through
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/current/theme/`; the generated
`theme.yaml` contains the resolved values. The sibling `current/wallpaper`
selects the active wallpaper. Edit theme sources and rebuild rather than
editing generated files. Use a `theme-set` hook when your application needs
an explicit reload.
