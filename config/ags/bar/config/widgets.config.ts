import type { BarWidgetDefinitions } from "../configuration"

// Edit this file to change widget behavior without touching rendering code.
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
    switch: {
      thumbSize: 16,
      trackHeight: 12,
      trackLength: 24,
      thumbPadding: 7,
      glyphOffsetX: 0,
      glyphOffsetY: 0,
      borderWidth: 2,
      fontSize: 8,
      fontFamily: "JetBrains Mono Nerd Font Propo",
    },
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
    indicator: {
      width: 16,
      height: 10,
      borderWidth: 2,
      terminalWidth: 3,
      terminalHeightRatio: 0.4,
      chargingGlyph: "󱐋",
      chargingGlyphFontSize: 8,
      chargingGlyphFontFamily: "JetBrains Mono Nerd Font Propo",
    },
  },
} satisfies BarWidgetDefinitions

export default widgetDefinitions

