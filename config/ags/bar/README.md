# AGS Bar

Edit these files first:

- `config/layout.config.ts`: move the bar and rearrange widget instance IDs
- `config/widgets.config.ts`: change widget behavior and widget-specific options
- `theme.scss`: adjust spacing, radii, fonts, borders, and other bar styling

## Layout Example

```ts
start: ["menu", "workspaces"],
center: {
  start: [],
  anchor: "clock",
  end: ["caffeine"],
},
end: ["tray", "battery"],
```

## Widget Example

```ts
clock: {
  kind: "clock",
  display: {
    horizontal: "%a %-I:%M %p",
    vertical: {
      top: "%H",
      middle: "%M",
      bottom: "%Z",
    },
  },
},
```

## Styling Example

```scss
$bar-font-size: 13px;
$bar-island-radius: 12px;
$bar-button-padding-inline: 10px;
$bar-low-battery-color: #c4746e;
```

GTK remains the source of bar colors. `theme.scss` exposes the rest of the look-and-feel knobs that are meant to be adjusted by hand.

## Troubleshooting

- Run `npm run check` from `config/ags` to run the pure config tests and confirm the bar still bundles.
- If the bar shows a config error fallback, fix `config/layout.config.ts` for layout IDs and edge mistakes, or `config/widgets.config.ts` for widget kinds and option values.
- The fallback bar keeps the UI visible and logs the full validation error to the terminal for the detailed reason.
