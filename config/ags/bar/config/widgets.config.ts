import type { BarWidgetDefinitions } from "../widgets/catalog"

// Edit this file to change widget behavior without touching rendering code.
// Keep this file focused on high-level behavior and content, not low-level drawing metrics.
// Widget IDs are instance names, not fixed kind names. You can define multiple
// entries with the same `kind` when you want different variants on the bar.
const widgetDefinitions = {
  menu: {
    kind: "menu",
    icon: "",
    commands: {
      primary: "hk-menu",
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
    format: {
      primary: "%a %-I:%M %p",
      alt: "%a %-I:%M:%S %p",
      vertical: "%I\n%M\n%p",
      verticalAlt: "%I\n%M\n%S\n%p",
    },
    flyout: {
      align: "center",
      gap: 0,
    },
    tooltip: {
      text: "%c"
    }
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
        off: { glyph: "󰽖"},
      }
    }
  },

  cpu: {
    kind: "cpu",
    format: {
      primary: "{temp}°",
      alt: "{temp}° | {usage}%",
      verticalAlt: "{usage}%",
    },
    tooltip: {
      text: "CPU: {usage}%\n{cores}",
    },
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
    decimals: {
      primary: 0,
    },
    tooltip: {
      text: "RAM: {ram_used}/{ram_total}\nSwap: {swap_used}/{swap_total}",
    },
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
    commands: {
      secondary: "hk-launch-audio",
    },
    flyout: {
      align: "center",
      gap: 0,
    },
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
    flyout: {
      align: "center",
      gap: 0,
    },
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
    flyout: {
      align: "center",
      gap: 0,
    },
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
} satisfies BarWidgetDefinitions

export default widgetDefinitions
