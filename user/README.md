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

They load in that order after all shipped modules and after the active theme.
Only create the files you need. A personal monitor override can be as small as:

```lua
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 2 })
```

The files execute directly against Hyprland's `hl` Lua API. They are not
merged structurally: later calls override settings such as monitor and input
values, while additive APIs such as bindings and window rules add entries.
Use `hl.unbind()` before `hl.bind()` when replacing an existing shortcut.

Run `Hyprland --verify-config` before reloading. A missing optional file is
normal; an unreadable file or Lua error is reported rather than silently
falling back to the shipped behavior.
