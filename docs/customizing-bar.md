# Customizing the Bar

Hyprkarl's bar is built with Quickshell. Its shipped placement and behavior
live in `defaults/shell.json`; personal changes belong in the optional
`user/shell.json`. Appearance is entirely
theme-derived from `themes/<theme>/quickshell.json`.

## Override the Shipped Configuration

Create `user/shell.json` with only the values you want to
change. Objects merge recursively over the shipped defaults. Arrays replace as
complete ordered values, so use `bar.layoutEdits` when you only need to move,
insert, override, or remove one widget by its stable ID.

For example, this moves the bar to the bottom without copying any upstream
layout:

```json
{
  "version": 1,
  "bar": {
    "edge": "bottom"
  }
}
```

Deleting the user file returns to the shipped configuration. Valid edits apply
live; an invalid edit is rejected and the last valid layout remains running.
Version 1 supports top and bottom bars.

See [Shell Configuration](shell-configuration.md) for the full merge contract,
widget schema, and layout-edit examples.

## Reorder, Add, or Remove Widgets

Each layout entry defines a widget instance inline. `id` is the stable instance
identity and `kind` selects its built-in implementation. The bar has `start`,
`center`, and `end` islands; the center island uses `before`, an optional
midpoint `anchor`, and `after` so its anchor can remain exactly centered.

Prefer `bar.layoutEdits` for focused personal changes. Replace a whole layout
array only when you intend to own its complete ordering.

## Change the Appearance

Every bar color, plus typography, thickness, spacing, borders, radii, panel
sizing, and transition timing, comes from
`themes/<theme>/quickshell.json`. Add a corresponding value to every theme when
introducing a new required theme token. The running shell watches the selected
theme and applies both theme switches and edits to its JSON without a restart.

## Manage and Inspect the Bar

Hyprland starts the bar through the same public lifecycle commands used for
development and troubleshooting:

```bash
hk-shell start
hk-shell stop
hk-shell restart
hk-shell status
hk-shell logs --tail 100 --no-color
```

Use `qs -p config/quickshell` only when a foreground development process is
useful. See `config/quickshell/README.md` for the implemented interactions,
internal structure, and validation commands.

## Related Docs

- [Using Hyprkarl](using-hyprkarl.md)
- [Configuration Map](configuration-map.md)
- [Themes](themes.md)
- [Extending Hyprkarl](extending-hyprkarl.md)
