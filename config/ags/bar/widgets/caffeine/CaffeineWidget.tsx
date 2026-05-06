import { createState } from "ags"
import app from "ags/gtk4/app"
import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { type NormalizedCaffeineWidgetConfig } from "../../configuration"
import { type BarOrientation } from "../../layout/placement"
import Switch from "../../primitives/Switch"

const [active, setActive] = createState(false)

const syncStatus = async () => {
  try {
    const status = await execAsync("systemctl --user show hypridle.service --property=ActiveState")
    const isHypridleActive = status.trim() === "ActiveState=active"
    setActive(!isHypridleActive)
  } catch {
    setActive(false)
  }
}

syncStatus()

app.connect("request", (_app, args, response) => {
  if (args[0] === "caffeine-sync") {
    syncStatus()
    response("ok")
  }
})

type Props = {
  orientation: BarOrientation
  config: NormalizedCaffeineWidgetConfig
}

export default function CaffeineWidget({ orientation, config }: Props) {
  const isVertical = orientation === "vertical"

  return (
    <Switch
      class={`caffeine-button orientation-${orientation}`}
      hexpand={isVertical}
      halign={isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      orientation={orientation}
      glyph={config.glyph}
      metrics={config.switch}
      active={active}
      onToggle={(next) => {
        setActive(next)
        execAsync(`${config.command} ${next ? "on" : "off"}`).catch(print)
      }}
    />
  )
}

