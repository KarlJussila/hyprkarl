import { createConnection, createState } from "ags"
import AstalTray from "gi://AstalTray"
import TrayExpander from "./TrayExpander"
import TrayItems from "./TrayItems"

type Props = {
  direction?: "start" | "end"
  mirrorTrigger?: boolean
}

export default function Tray({ direction = "start", mirrorTrigger = false }: Props) {
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
      direction={direction}
      items={trayItems}
      open={trayOpen}
    />
  )

  const trayExpander = (
    <TrayExpander
      hasItems={hasTrayItems}
      mirrorTrigger={mirrorTrigger}
      open={trayOpen}
      onToggle={toggleTray}
    />
  )

  const [startContent, endContent] = direction === "start"
    ? [trayPanel, trayExpander]
    : [trayExpander, trayPanel]

  return (
    <box class="segmented-group">
      {startContent}
      {endContent}
    </box>
  )
}
