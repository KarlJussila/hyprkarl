import { createConnection, createState } from "ags"
import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"
import { type TrayPlacement } from "../../layout/placement"
import TrayExpander from "./TrayExpander"
import TrayItems from "./TrayItems"
import type {
  NormalizedTrayRevealConfig,
  TrayDirection,
} from "./types.ts"

type Props = {
  placement: TrayPlacement
  direction: TrayDirection
  mirrorTrigger: boolean
  reveal: NormalizedTrayRevealConfig
}

export default function TrayWidget({ placement, direction, mirrorTrigger, reveal }: Props) {
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
    />
  )

  const [startContent, endContent] = direction === "start"
    ? [trayPanel, trayExpander]
    : [trayExpander, trayPanel]

  return (
    <box
      class={`widget-tray widget-group orientation-${placement.orientation} is-${placement.orientation}`}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      vexpand={!placement.isVertical}
      valign={!placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      orientation={placement.layoutOrientation}
    >
      {startContent}
      {endContent}
    </box>
  )
}
