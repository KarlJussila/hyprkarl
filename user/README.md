# User Configuration

This namespace is reserved for configuration owned by the person using this
Hyprkarl checkout. Upstream may document files here, but does not add personal
configuration or change an existing user's files.

The Quickshell shell uses `shell.json` here when it exists; otherwise it
uses `defaults/shell.json`. A minimal override looks like:

```json
{
  "version": 1,
  "bar": {
    "edge": "bottom"
  }
}
```

Objects merge recursively, arrays replace completely, and layout changes use
explicit widget-ID operations. See
[`docs/shell-configuration.md`](../docs/shell-configuration.md) for the schema
and update contract.

A personal readout can be inserted with `kind: "command"`. The shell owns one
polling or persistent-stream provider per widget ID, not one per monitor, and
renders either trimmed text or a validated JSON presentation object. Polling
starts a process on every tick, so short intervals can cost CPU and battery;
use stream mode for frequent updates. A command widget with only static text or
an icon and click actions creates no provider timer or process; the shipped
main-menu button uses that form. See
[`Command widgets`](../docs/shell-configuration.md#command-widgets) for the
minimal example, semantic states, click actions, and failure behavior.

Personal QML bar widgets belong under `user/quickshell/modules/`. Reference one
explicitly from `shell.json` with `kind: "qml"`, a relative `source`, and an
optional `settings` object. The module root receives the documented per-bar
context; there is no directory discovery or plugin manifest. See
[`User QML widgets`](../docs/shell-configuration.md#user-qml-widgets) for a
complete config and module example. Restart the shell after changing a module
source.

Application-wide personal interfaces belong in one explicitly referenced QML
root such as `user/quickshell/Extensions.qml`. Configure it with
`userRoot.source` in `shell.json`; it receives live theme and configuration
data and may create independent windows or per-screen variants. A custom bar
can set `bar.enabled` to false and expose the documented reactive notification
position method so the shell's notification stack follows its visible extent.
See
[`Application-wide user QML`](../docs/shell-configuration.md#application-wide-user-qml).

The Quickshell command menu uses `menu.json` here when it exists. It is also a
sparse versioned override; menu and entry objects merge by stable ID. For
example:

```json
{
  "version": 1,
  "entries": {
    "main.launch": {
      "label": "Applications"
    },
    "main.uninstall": {
      "enabled": false
    }
  }
}
```

See [`docs/menu-configuration.md`](../docs/menu-configuration.md) for the menu
schema, adding entries and submenus, and direct menu commands.

## Notification Icon Drawings

Personal notification drawings belong under `user/quickshell/icons/`. Point a
lowercase application or icon-name override at one with a descriptor such as
`{"kind":"component","source":"user/RingIcon.qml"}` in `shell.json`.
The QML file's root `Item` exposes writable `progress` and `theme` properties;
the shell gives it the configured icon-sized canvas, a 0–100 notification
value (or `-1`), and the live semantic theme object. The shipped audio and
battery drawings use the identical loader contract. See
[`docs/shell-configuration.md`](../docs/shell-configuration.md) for a complete
Canvas example.

## Themes

Personal theme bundles and same-name overlays belong under
`user/themes/<name>/`. Build a complete palette-derived bundle with
`hk-theme build <source> [name]`, or place a complete hand-authored bundle
there. A directory sharing a built-in name overlays that built-in during
staging; a unique name is a standalone personal theme.

Wallpaper additions and built-in wallpaper removal markers also persist in
this namespace. The active assembled bundle and selectors live under XDG
state, not here. See [`docs/themes.md`](../docs/themes.md).

## Lifecycle Hooks

Personal lifecycle hooks live under `user/hooks/<event>.d/`. Supported events
are:

- `post-boot` after Hyprland starts the session;
- `post-update` after `hk-update all` or the guided update completes;
- `theme-set` after a theme has been applied; and
- `wallpaper-set` after a wallpaper has been applied.

The runner executes non-hidden regular files with the executable bit set in
lexical filename order. Prefix names with numbers when order matters:

```text
user/hooks/theme-set.d/
├── 10-reload-my-app
└── 20-refresh-generated-files
```

Hooks inherit the action's environment and receive no positional arguments.
Query current state with commands such as `hk-theme current` when needed. A
missing event directory is normal. If one hook fails, later hooks still run;
the owning command reports that its main action completed but a hook failed.
`post-boot` failures are reported through a desktop notification.

## Hyprland

Shipped Hyprland behavior lives under `defaults/hypr/`. To add or override
personal behavior, create any of these optional files under `user/hypr/`:

```text
envs.lua
autostart.lua
monitors.lua
permissions.lua
looknfeel.lua
animations.lua
gum.lua
windows.lua
input.lua
bindings.lua
```

They load in that order after all shipped modules, the active theme, and the
display panel's machine-generated XDG-state monitor layout.
Only create the files you need. A personal monitor override can be as small as:

```lua
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 2 })
```

The files execute directly against Hyprland's `hl` Lua API. They are not
merged structurally: later calls override settings such as monitor and input
values, while additive APIs such as bindings and window rules add entries.
Use `hl.unbind()` before `hl.bind()` when replacing an existing shortcut.

`hk-display` never edits this directory. A rule in `user/hypr/monitors.lua`
loads after its generated layout and therefore retains the final say.

Run `Hyprland --verify-config` before reloading. A missing optional file is
normal; an unreadable file or Lua error is reported rather than silently
falling back to the shipped behavior.
