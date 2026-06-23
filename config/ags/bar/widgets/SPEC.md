# Widget reference

One section per widget kind. Every field is optional in `widgets.config.ts` —
the value next to each name is the default that applies when you omit it.

Common conventions:

- **`commands`** is `{ primary?: string; secondary?: string; tertiary?: string }`. Each value is a shell command, or a token like `{flyout}` / `{toggle-alt}` / `{toggle-label}` that's wired by the widget. Omit the whole object to keep the default click behavior. Set a specific key to `""` to suppress that click.
- **`flyout`** is `{ align: "start" | "center" | "end"; gap: number }`. Default `{ align: "center", gap: 0 }`.
- **`tooltip`** is a plain `string` for simple widgets; widgets that vary the tooltip by state expose a small object instead (battery, audio, bluetooth, network, toggle). Empty strings disable the corresponding tooltip; set every state to `""` to disable the tooltip entirely.
- Rendering metrics (the `indicator`, `slider`, and `switch` objects on a few widgets) are tuned defaults — you can override them in `widgets.config.ts` but you rarely need to.

---

## `clock`

| Field      | Type   | Default                              | Description                                                 |
| ---------- | ------ | ------------------------------------ | ----------------------------------------------------------- |
| `format.primary`     | string | `"%a %-I:%M %p"`                     | Horizontal bar primary format (`strftime`).                 |
| `format.alt`         | string | `""`                                 | Horizontal alt format; toggled by secondary click.          |
| `format.vertical`    | string | `"%I\n%M\n%p"`                       | Vertical bar primary format.                                |
| `format.verticalAlt` | string | `""`                                 | Vertical alt format.                                        |
| `tooltip`            | string | `""`                                 | `strftime` template for the tooltip; empty disables.        |
| `commands`           | clicks | primary opens the calendar flyout    | Click overrides; secondary toggles `alt` when defined.      |
| `flyout`             | flyout | `{ align: "center", gap: 0 }`        | Calendar flyout placement relative to the clock.            |

---

## `menu`

| Field      | Type     | Default                | Description                            |
| ---------- | -------- | ---------------------- | -------------------------------------- |
| `icon`     | string   | `""`                  | Glyph shown in the button.             |
| `commands` | clicks   | `{ primary: "hk-menu" }` | Click handlers.                      |
| `tooltip`  | string   | `""`                   | Plain tooltip text.                    |

---

## `cpu`

| Field      | Type   | Default                              | Description                                                  |
| ---------- | ------ | ------------------------------------ | ------------------------------------------------------------ |
| `icon`     | string | `"󰍛"`                                | Leading glyph.                                               |
| `format.*` | string | empty strings                        | Reveal label template. Tokens: `{usage}`, `{temp}`, `{cores}`. |
| `decimals.*` | number | `0`                                | Decimal precision per format slot.                            |
| `tooltip`  | string | `"CPU: {usage}%\n{cores}"`            | Tooltip template.                                            |
| `interval` | number | `5000`                                | Poll interval in ms.                                         |
| `reveal.durationMs` | number | `200`                       | Reveal animation duration in ms.                             |
| `commands` | clicks | primary toggles the reveal label; secondary toggles the alt format | Click overrides. |

---

## `gpu`

| Field      | Type   | Default                              | Description                                                  |
| ---------- | ------ | ------------------------------------ | ------------------------------------------------------------ |
| `icon`     | string | `"󰢮"`                                | Leading glyph.                                               |
| `card`     | string | `""` (auto-select)                   | DRM card to pin (e.g. `"card1"`). Empty auto-selects the most capable active GPU, skipping runtime-suspended cards (reading them never wakes them). |
| `format.*` | string | see `widgets.config.ts`              | Reveal label template. Tokens: `{usage}`, `{vram}`, `{vram_used}`, `{vram_total}`, `{temp}`, `{name}`. |
| `decimals.*` | number | `0`                                | Decimal precision per format slot (VRAM sizes are always 1 decimal). |
| `tooltip`  | string | usage/VRAM/temp                      | Tooltip template; same tokens as `format`.                   |
| `interval` | number | `5000`                               | Poll interval in ms. A suspendable discrete GPU's live sensors are read no faster than its autosuspend delay regardless, so it isn't pinned awake. |
| `reveal.durationMs` | number | `200`                       | Reveal animation duration in ms.                             |
| `commands` | clicks | primary toggles the reveal label; secondary toggles the alt format | Click overrides. |

Vendor-agnostic: AMD/Intel metrics are read from sysfs in-process; NVIDIA falls back to `nvidia-smi`. Unavailable tokens render empty.

---

## `ram`

| Field      | Type   | Default                              | Description                                                                 |
| ---------- | ------ | ------------------------------------ | --------------------------------------------------------------------------- |
| `icon`     | string | `""`                                | Leading glyph.                                                              |
| `format.*` | string | see `widgets.config.ts`              | Tokens: `{ram}`, `{ram_used}`, `{ram_total}`, `{ram_free}`, `{swap}`, `{swap_used}`, `{swap_total}`, `{swap_free}`. |
| `decimals.*` | number | `0`                                | Decimal precision per format slot.                                          |
| `tooltip`  | string | RAM/Swap usage                       | Tooltip template; same tokens as `format`.                                  |
| `interval` | number | `5000`                               | Poll interval in ms.                                                        |
| `reveal.durationMs` | number | `200`                       | Reveal animation duration in ms.                                            |
| `commands` | clicks | primary toggles the reveal label; secondary toggles the alt format | Click overrides. |

---

## `recording`

| Field      | Type     | Default                                    | Description                                              |
| ---------- | -------- | ------------------------------------------ | -------------------------------------------------------- |
| `icon`     | string   | `"󰻂"`                                       | Glyph shown when recording.                              |
| `commands` | clicks   | `{ primary: "hk-record-screen --stop-recording" }` | Click handlers.                                  |
| `tooltip`  | string   | `"Recording — click to stop"`             | Tooltip text; empty disables.                            |

---

## `bluetooth`

| Field             | Type   | Default                                | Description                                       |
| ----------------- | ------ | -------------------------------------- | ------------------------------------------------- |
| `commands`        | clicks | `{ primary: "hk-launch-bluetooth" }`   | Click handlers.                                   |
| `icons.enabled`   | string | `""`                                  | Glyph when Bluetooth is on.                       |
| `icons.disabled`  | string | `"󰂲"`                                  | Glyph when off.                                   |
| `tooltip.off`     | string | `"Bluetooth off"`                      | Tooltip when off.                                 |
| `tooltip.on`      | string | `"Bluetooth on"`                       | Tooltip when on but no devices connected.         |
| `tooltip.connected` | string | `"Devices connected: {count}"`       | Tooltip when devices are connected. Token: `{count}`. |

---

## `network`

| Field                  | Type   | Default                                 | Description                                        |
| ---------------------- | ------ | --------------------------------------- | -------------------------------------------------- |
| `commands`             | clicks | `{ primary: "hk-launch-wifi" }`         | Click handlers.                                    |
| `icons.disconnected`   | string | `"󰤮"`                                   | Disconnected glyph.                                |
| `icons.ethernet`       | string | `"󰀂"`                                   | Wired connection glyph.                            |
| `icons.wifi`           | [s,s,s,s,s] | five wifi-strength glyphs           | Strength ramp; index 0 = weakest, 4 = strongest.   |
| `tooltip.disconnected` | string | `"Disconnected"`                        | Tooltip when not connected.                        |
| `tooltip.ethernet`     | string | `"Ethernet connected"`                  | Tooltip when wired.                                |
| `tooltip.wifi`         | string | `"{ssid} ({freq} GHz)"`                 | Wi-Fi tooltip with frequency.                      |
| `tooltip.wifiNoFreq`   | string | `"{ssid}"`                              | Fallback when frequency unknown.                   |
| `tooltip.wifiNoSsid`   | string | `"Wi-Fi connected"`                     | Fallback when SSID unknown.                        |

---

## `audio`

| Field            | Type   | Default                                    | Description                                          |
| ---------------- | ------ | ------------------------------------------ | ---------------------------------------------------- |
| `showPercentage` | bool   | `true`                                     | Whether to show the numeric percentage label.        |
| `commands`       | clicks | `{ secondary: "hk-launch-audio" }`         | Click handlers; primary toggles the slider flyout.   |
| `flyout`         | flyout | `{ align: "center", gap: 0 }`              | Slider flyout placement.                             |
| `tooltip.active` | string | `"{device} {percentage}"`                  | Tooltip when audio is unmuted. Tokens: `{device}`, `{percentage}`. |
| `tooltip.muted`  | string | `"Muted {device}"`                         | Tooltip when muted.                                  |
| `tooltip.unavailable` | string | `"Audio unavailable"`                  | Tooltip when no speaker is present.                  |
| `indicator.*`    | metric | tuned                                      | Indicator drawing metrics (`height`, `lineWidth`).   |
| `slider.*`       | metric | tuned                                      | Slider drawing metrics (track + thumb dimensions).   |

---

## `battery`

| Field                   | Type   | Default                              | Description                                              |
| ----------------------- | ------ | ------------------------------------ | -------------------------------------------------------- |
| `showPercentage`        | bool   | `true`                               | Whether to show the numeric percentage label.            |
| `lowThreshold`          | number | `0.15`                               | Fraction below which the indicator switches to the low color. |
| `flyout`                | flyout | `{ align: "center", gap: 0 }`        | Power profile flyout placement.                          |
| `tooltip.charging`      | string | `"{power}↑ {time}"`                  | Tooltip while charging.                                  |
| `tooltip.discharging`   | string | `"{power}↓ {time}"`                  | Tooltip while discharging.                               |
| `tooltip.plugged`       | string | `"Plugged in {percentage}"`          | Tooltip when plugged in but no measurable draw.          |
| `tooltip.fallback`      | string | `"{percentage}"`                     | Tooltip fallback. Empty disables the tooltip.            |
| `commands`              | clicks | primary opens the flyout             | Click overrides.                                         |
| `indicator.*`           | metric | tuned                                | Indicator drawing metrics (battery body, terminal, glyphs). |

---

## `toggle`

| Field            | Type   | Default                                    | Description                                                 |
| ---------------- | ------ | ------------------------------------------ | ----------------------------------------------------------- |
| `commands.on`    | string | `"true"`                                   | Command to switch on.                                       |
| `commands.off`   | string | `"true"`                                   | Command to switch off.                                      |
| `commands.sync`  | string | `"false"`                                  | Command whose exit status (0 = on, non-zero = off) reflects current state. |
| `endpoint`       | string | `""`                                       | AGS request endpoint; external scripts call `ags request <endpoint>` to trigger re-sync. |
| `tooltip.active` | string | `""`                                       | Tooltip when on.                                            |
| `tooltip.inactive` | string | `""`                                     | Tooltip when off.                                           |
| `switch.*`       | metric | tuned                                      | Switch drawing metrics (track, thumb, font, glyphs).        |

---

## `tray`

| Field             | Type     | Default                       | Description                                              |
| ----------------- | -------- | ----------------------------- | -------------------------------------------------------- |
| `direction`       | `"start" \| "end"` | `"start"`           | Which side of the trigger the tray panel expands toward. |
| `mirrorTrigger`   | bool     | `false`                       | Whether to mirror the expander icon for the chosen direction (horizontal bars only). |
| `reveal.durationMs` | number | `220`                         | Reveal animation duration in ms.                         |
| `tooltip`         | string   | `""`                          | Tooltip text on the expander button.                     |

---

## `workspaces`

Two modes, discriminated on `mode`:

- **`mode: "dynamic"`** (default) — show focused + occupied workspaces.

  | Field                       | Type    | Default                                | Description                                          |
  | --------------------------- | ------- | -------------------------------------- | ---------------------------------------------------- |
  | `visibility.alwaysShow`     | `number[]` | `[1]`                              | Workspace IDs that are always rendered.              |
  | `visibility.includeFocused` | bool    | `true`                                 | Include the focused workspace.                       |
  | `visibility.includeOccupied`| bool    | `true`                                 | Include any workspace with at least one client.      |
  | `visibility.excludeSpecial` | bool    | `true`                                 | Hide special / scratchpad workspaces.                |
  | `tooltip`                   | string  | `""`                                   | Tooltip template; token `{id}`.                      |

- **`mode: "fixed"`** — show a fixed list of workspace IDs.

  | Field      | Type       | Default | Description                                  |
  | ---------- | ---------- | ------- | -------------------------------------------- |
  | `ids`      | `number[]` | (required) | Workspace IDs to render, in order.        |
  | `tooltip`  | string     | `""`    | Tooltip template; token `{id}`.              |

---

## `_template`

Reference widget used to seed new widget types. See `bar/widgets/_template.tsx`.
