import { createConnection, createState } from "ags"
import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"
import { type TrayPlacement } from "../../layout/placement.ts"
import TrayExpander from "./TrayExpander.tsx"
import TrayItems from "./TrayItems.tsx"
import type { WidgetRenderArgs } from "../shared/widgetSpec.tsx"
import type { NormalizedRevealConfig, NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"
import type { TrayDirection } from "./spec.tsx"

type Config = {
  direction: TrayDirection
  mirrorTrigger: boolean
  reveal: NormalizedRevealConfig
  tooltip: NormalizedSimpleTooltipConfig
}

type Props = Omit<WidgetRenderArgs<Config>, "placement"> & { placement: TrayPlacement }

export default function TrayWidget({ config, placement }: Props) {
  const { direction, mirrorTrigger, reveal, tooltip } = config
  const trayService = AstalTray.get_default()
  const trayItems = createConnection(
    [...trayService.items],
    [trayService, "item-added", () => [...trayService.items]],
    [trayService, "item-removed", () => [...trayService.items]],
    [trayService, "notify::items", () => [...trayService.items]],
  )
  const hasTrayItems = trayItems((currentItems) => currentItems.length > 0)
  const [trayOpen, setTrayOpen] = createState(false)

  function toggleTray() {
    if (!hasTrayItems()) return
    setTrayOpen(!trayOpen())
  }

  const trayPanel = (
    <TrayItems
      placement={placement}
      direction={direction}
      items={trayItems}
      open={trayOpen}
      revealDurationMs={reveal.durationMs}
    />
  )

  const trayExpander = (
    <TrayExpander
      orientation={placement.orientation}
      icons={placement.tray.expanderIcons(direction, mirrorTrigger)}
      hasItems={hasTrayItems}
      open={trayOpen}
      onToggle={toggleTray}
      tooltip={tooltip}
    />
  )

  const [startContent, endContent] = direction === "start"
    ? [trayPanel, trayExpander]
    : [trayExpander, trayPanel]

  return (
    <box
      class={`widget-tray is-${placement.orientation}`}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      vexpand={!placement.isVertical}
      valign={Gtk.Align.FILL}
      orientation={placement.layoutOrientation}
    >
      {startContent}
      {endContent}
    </box>
  )
}
