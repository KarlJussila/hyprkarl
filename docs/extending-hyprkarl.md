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
| Hyprland settings and keybindings | `~/.config/hyprkarl/hypr/*.lua` |
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

Create only the files you need under `~/.config/hyprkarl/hypr/`. Hyprkarl loads
those after the shipped settings, active theme, and generated display layout.
The supported filenames, in load order, are:

```text
envs.lua, autostart.lua, monitors.lua, permissions.lua, looknfeel.lua,
animations.lua, gum.lua, windows.lua, input.lua, bindings.lua
```

For example, `input.lua` can change selected values without copying the
shipped configuration:

```lua
hl.config({
    input = {
        kb_layout = "us,fi",
        sensitivity = 0,
    },
})
```

For keybindings, use `bindings.lua`:

```lua
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("uwsm-app -- my-command"), {
    description = "My command",
})
```

Descriptions appear in the keybindings menu. Binding and window-rule calls
add to the existing configuration; use `hl.unbind()` before replacing a
shipped binding. The files under `defaults/hypr/` are useful examples.

Validate with `Hyprland --verify-config` before reloading. See the
[Hyprland configuration map](configuration-map.md#hyprland) for each module's
purpose and display configuration.

## Extend Quickshell

Use `~/.config/quickshell/settings/shell.json` for module switches, widget
settings, and bar layout. Objects merge with the shipped defaults, while
arrays replace them, so to change a bar layout section you copy it from the
defaults and own it. See [Bar customization](customizing-bar.md) for examples.

There are three ways to add your own interfaces:

- A [command widget](shell-configuration.md#command-widgets) displays output
  from a script or provides a static button. It can poll or read a persistent
  stream, and supports click commands.
- A [QML widget](shell-configuration.md#user-qml-widgets) provides custom
  rendering or interaction within a bar. Put its source under
  `~/.config/quickshell/custom/modules/` and reference it explicitly with
  `kind: "qml"`.
- An [application-wide QML root](shell-configuration.md#application-wide-user-qml)
  creates independent windows or a replacement bar. Put its source under
  `~/.config/quickshell/custom/` and reference it with `userRoot.source`.
  Set `modules.bar` to `false` if it replaces the built-in bar.

Personal QML can reuse the project's UI types. For example, `import ui.modal`
provides `Modal` for a shell-styled focused interface. The linked QML guides
document the available context, theme values, and methods.

Ordinary JSON settings reload live. Run `hk-shell restart` after changing
module switches or personal QML source.

The shell runs from `~/.config/quickshell/`, where Hyprkarl's files are links
next to your `settings/` and `custom/`. Personal QML can import any shipped
module or component by its path in that tree, such as `import ui.modal` or
`import "../modules/lock"` from `custom/`.

## Replace a built-in

Every built-in part of the shell can be switched off and replaced without
editing Hyprkarl's files. Keybindings, the bar, and menu entries reach each
part through a named IPC target, so a replacement that answers the same target
works with all of them unchanged.

To replace one, set its switch under `modules` in `shell.json` to `false`, then
declare the target in your [application-wide QML
root](shell-configuration.md#application-wide-user-qml):

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
[Application-wide user QML](shell-configuration.md#application-wide-user-qml)
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
