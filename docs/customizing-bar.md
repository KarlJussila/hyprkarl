# Customizing the Bar

The bar is Hyprkarl's AGS-based status bar. It is configured through TypeScript
files in `config/ags/bar/config/` and styled through SCSS in the active theme.

## Files That Matter

- `config/ags/bar/config/layout.config.ts`
  Bar edge, widget order, corner curves, autohide, and exclusive mode
- `config/ags/bar/config/widgets.config.ts`
  Widget instances and configuration; each key is a widget ID, `kind` picks the
  implementation
- `themes/<theme>/bar.scss`
  Theme-specific bar colors, spacing, radii, and typography

`config/ags/bar/theme.scss` is a symlink managed by `hk-theme set`. It points
to the active theme's `bar.scss`. Switching themes updates the symlink and
restarts AGS.

## Reorder, Add, or Remove Widgets

Widget placement lives in `config/ags/bar/config/layout.config.ts`. Each island
(`start`, `center`, `end`) holds a list of widget IDs. Reordering the lists
reorders the bar. Removing an ID from an island removes that widget from the
bar; adding one shows it.

Widget behavior is configured in `config/ags/bar/config/widgets.config.ts`.
Each entry is a widget ID mapped to a config block with a `kind` field and
widget-specific fields. Two IDs with the same `kind` produce independently
configured instances.

## Restart the Bar

To apply changes, run:

```bash
hk-ags restart
```

Theme switches already restart the bar.

## Runtime Control

The bar can also be controlled without restarting:

```bash
hk-ags autohide on|off|toggle   # change autohide mode
hk-ags exclusive on|off|toggle  # change exclusive mode
hk-ags show|hide|toggle         # force a visibility state
hk-ags status                   # print JSON: {autohide, exclusive, hidden}
```

## Full Widget Reference

See `config/ags/bar/README.md` for the complete widget configuration reference,
tooltip token lists, the styling guide, and architecture notes.

## Related Docs

- [Using Hyprkarl](using-hyprkarl.md)
- [Configuration Map](configuration-map.md)
- [Themes](themes.md)
