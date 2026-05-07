import type { BarWidgetDefinitions } from "../configuration"

// Edit this file to change widget behavior without touching rendering code.
// Keep this file focused on high-level behavior and content, not low-level drawing metrics.
const widgetDefinitions = {
  menu: {
    kind: "menu",
    icon: "",
    commands: {
      primary: "hyprkarl-menu",
    },
  },

  workspaces: {
    kind: "workspaces",
    mode: "dynamic",
    visibility: {
      alwaysShow: [1],
      includeFocused: true,
      includeOccupied: true,
      excludeSpecial: true,
    },
  },

  tray: {
    kind: "tray",
    direction: "end",
    mirrorTrigger: false,
    reveal: {
      durationMs: 220,
    },
  },

  clock: {
    kind: "clock",
    display: {
      horizontal: "%a %-I:%M %p",
      vertical: {
        top: "%I",
        middle: "%M",
        bottom: "%p",
      },
    },
    dropdown: {
      enabled: true,
      align: "center",
      gap: 0,
    },
  },

  caffeine: {
    kind: "caffeine",
    glyph: "",
    command: "hyprkarl-caffeine",
  },

  battery: {
    kind: "battery",
    showPercentage: true,
    lowThreshold: 0.15,
    dropdown: {
      enabled: true,
      align: "center",
      gap: 0,
    },
  },
} satisfies BarWidgetDefinitions

export default widgetDefinitions
