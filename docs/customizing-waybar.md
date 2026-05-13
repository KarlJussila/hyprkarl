# Customizing Waybar

Waybar is Hyprkarl's current bar.

## Files That Matter

- `config/waybar/config.jsonc`
  Module layout and module behavior
- `config/waybar/style.css`
  Shared structural CSS
- `themes/<theme>/waybar.css`
  Theme-specific Waybar colors
- `scripts/waybar/`
  Support scripts for custom modules

`config/waybar/style.css` imports the active theme's `waybar.css`.

Keep this split:

- put behavior and placement in `config/waybar/config.jsonc`
- put shared styling in `config/waybar/style.css`
- put theme-specific colors in `themes/<theme>/waybar.css`

For full bar, module, and styling reference, see the official Waybar docs:
[Configuration](https://github.com/Alexays/Waybar/wiki/Configuration) and
[Styling](https://github.com/Alexays/Waybar/wiki/Styling).

## Reorder, Add, or Remove Modules

Module placement lives in the three arrays near the top of
`config/waybar/config.jsonc`:

- `modules-left`
- `modules-center`
- `modules-right`

To move a module, reorder those arrays. To remove one, delete it from an array.
To add one, add its module ID to an array and define its config block in the
same file.

The current config includes:

- built-in modules such as `clock`, `network`, `battery`, and `bluetooth`
- grouped modules such as `group/audio-expander`
- custom modules such as `custom/gpu`

## Add a Script-Backed Module

For a custom Waybar module:

- put the script in `scripts/waybar/`
- reference it from `config/waybar/config.jsonc` with `exec`
- set `return-type: "json"` if the script prints JSON

Current examples:

- `scripts/waybar/gpu-info`
- `scripts/waybar/check-recording.sh`
- `scripts/waybar/check-caffeine.sh`

## Reload Waybar

To apply Waybar changes, run:

```bash
hk-waybar-restart
```

Theme switches already restart Waybar.

## Related Docs

- [Using Hyprkarl](using-hyprkarl.md)
- [Configuration Map](configuration-map.md)
- [Themes](themes.md)
