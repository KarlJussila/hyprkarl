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
      enabled: true,
      align: "center",
      gap: 0,
    },
  },

  caffeine: {
    kind: "caffeine",
    glyph: "",
    command: "hk-caffeine",
    switch: {
      glyphOffsetX: 1
    }
  },

  cpu: {
    kind: "cpu",
    format: {
      primary: "{temp}°",
      alt: "{temp}° | {usage}%",
      verticalAlt: "{usage}%",
    },
    tooltip: "CPU: {usage}%\n{cores}"
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
    tooltip: "RAM: {ram_used}/{ram_total}\nSwap: {swap_used}/{swap_total}",
    interval: 5000,
  },

  network: {
    kind: "network",
    command: "hk-launch-wifi",
  },

  bluetooth: {
    kind: "bluetooth",
    command: "hk-launch-bluetooth",
  },

  audio: {
    kind: "audio",
    showPercentage: false,
    command: "hk-launch-audio",
    flyout: {
      enabled: true,
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
      enabled: true,
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
      enabled: true,
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
} satisfies BarWidgetDefinitions

export default widgetDefinitions
