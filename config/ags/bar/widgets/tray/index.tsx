import { createComputed, createConnection, createState } from "ags"
import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"
import { type TrayPlacement, type TrayDirection } from "../../layout/placement.ts"
import TrayExpander from "./Expander.tsx"
import TrayItems from "./Items.tsx"
import { mergeConfig, type WidgetProps } from "../shared/types.ts"

export type TrayConfig = {
  direction?: TrayDirection
  mirrorTrigger?: boolean
  reveal?: { durationMs?: number }
  tooltip?: string
}

type TrayDefaults = {
  direction: TrayDirection
  mirrorTrigger: boolean
  reveal: { durationMs: number }
  tooltip: string
}

export const defaults: TrayDefaults = {
  direction: "start",
  mirrorTrigger: false,
  reveal: { durationMs: 220 },
  tooltip: "",
}

type Props = Omit<WidgetProps<TrayConfig>, "placement"> & { placement: TrayPlacement }

export default function TrayWidget({ config, placement }: Props) {
  const cfg = mergeConfig(defaults, config)
  const { direction, mirrorTrigger, reveal, tooltip } = cfg
  const trayService = AstalTray.get_default()
  const trayItems = createConnection(
    [...trayService.items],
    [trayService, "item-added", () => [...trayService.items]],
    [trayService, "item-removed", () => [...trayService.items]],
    [trayService, "notify::items", () => [...trayService.items]],
  )
  const hasTrayItems = trayItems((currentItems) => currentItems.length > 0)
  const [trayOpen, setTrayOpen] = createState(false)
  const showPanel = createComputed(() => trayOpen() && hasTrayItems())

  function toggleTray() {
    setTrayOpen(!trayOpen())
  }

  const trayPanel = (
    <TrayItems
      placement={placement}
      direction={direction}
      items={trayItems}
      open={showPanel}
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
