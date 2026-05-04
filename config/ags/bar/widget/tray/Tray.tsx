import { createConnection, createState } from "ags"
import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"
import { type TrayPlacement } from "../../barPlacement"
import TrayExpander from "./TrayExpander"
import TrayItems from "./TrayItems"

type Props = {
  placement: TrayPlacement
  direction?: "start" | "end"
  mirrorTrigger?: boolean
}

export default function Tray({
  placement,
  direction = "start",
  mirrorTrigger = false,
}: Props) {
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
    />
  )

  const trayExpander = (
    <TrayExpander
      fill={placement.isVertical}
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
      class={`tray-group segmented-group orientation-${placement.orientation}`}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      orientation={placement.layoutOrientation}
    >
      {startContent}
      {endContent}
    </box>
  )
}
