import type { WidgetDefinitions } from "../widgets/index.ts"

// Edit this file to change widget behavior without touching rendering code.
// Each entry is keyed by an instance ID (a name you pick); `kind` selects the
// widget implementation. Multiple entries can share the same `kind`.
//
// Every field shown here is optional — each widget has a `defaults` object
// next to its component. Fields you omit fall back to those defaults. See
// `bar/widgets/SPEC.md` for the full list of knobs.
const widgetDefinitions = {
  menu: {
    kind: "menu",
    icon: "",
    commands: { primary: "hk-menu" },
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
  },

  clock: {
    kind: "clock",
    format: {
      primary: "%a %-I:%M %p",
      alt: "%a %-I:%M:%S %p",
      vertical: "%I\n%M\n%p",
      verticalAlt: "%I\n%M\n%S\n%p",
    },
    tooltip: "%c",
  },

  caffeine: {
    kind: "toggle",
    commands: {
      on: "hk-caffeine on",
      off: "hk-caffeine off",
      sync: "hk-caffeine status",
    },
    endpoint: "caffeine-sync",
    tooltip: {
      active: "Caffeine: on",
      inactive: "Caffeine: off",
    },
    switch: {
      glyphs: {
        on: { glyph: "", glyphOffset: [1, 0] },
        off: { glyph: "󰽖", glyphOffset: [0, 0] },
      },
    },
  },

  cpu: {
    kind: "cpu",
    format: {
      primary: "{temp}°",
      alt: "{temp}° | {usage}%",
      verticalAlt: "{usage}%",
    },
    tooltip: "CPU: {usage}%\n{cores}",
  },

  ram: {
    kind: "ram",
    icon: "",
    format: {
      primary: "{ram}%",
      alt: "{ram_used}/{ram_total} | {swap_used}/{swap_total}",
      vertical: "{ram}%",
      verticalAlt: "{ram_used}\n{swap_used}",
    },
    tooltip: "RAM: {ram_used}/{ram_total}\nSwap: {swap_used}/{swap_total}",
    interval: 5000,
  },

  network: {
    kind: "network",
  },

  bluetooth: {
    kind: "bluetooth",
  },

  audio: {
    kind: "audio",
    showPercentage: false,
    commands: { secondary: "hk-launch-audio" },
    tooltip: {
      active: "{device} {percentage}",
      muted: "Muted {device}",
      unavailable: "Audio unavailable",
    },
  },

  battery: {
    kind: "battery",
    showPercentage: true,
    lowThreshold: 0.15,
    tooltip: {
      charging: "{power}↑ {time}",
      discharging: "{power}↓ {time}",
      plugged: "Plugged in {percentage}",
      fallback: "{percentage}",
    },
  },
  batteryCompact: {
    kind: "battery",
    showPercentage: false,
    lowThreshold: 0.15,
    tooltip: {
      charging: "{power}↑ {time}",
      discharging: "{power}↓ {time}",
      plugged: "Plugged in {percentage}",
      fallback: "{percentage}",
    },
  },
  recording: {
    kind: "recording",
  },
} satisfies WidgetDefinitions

export default widgetDefinitions
