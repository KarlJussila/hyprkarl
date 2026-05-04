import { createState } from "ags"
import app from "ags/gtk4/app"
import { Gtk } from "ags/gtk4"
import { type BarOrientation } from "../barPlacement"
import Switch from "../button/Switch"
import { execAsync } from "ags/process"

const [active, setActive] = createState(false)

const syncStatus = async () => {
  try {
    const status = await execAsync("systemctl --user show hypridle.service --property=ActiveState")
    const isHypridleActive = status.trim() === "ActiveState=active"
    setActive(!isHypridleActive) 
  } catch (err) {
    setActive(false)
  }
}

// Initial sync
syncStatus()

app.connect("request", (_app, args, response) => {
  if (args[0] === "caffeine-sync") {
    syncStatus()
    response("ok")
  }
})

type Props = {
  orientation: BarOrientation
}

export default function CaffeineToggle({ orientation }: Props) {
  const isVertical = orientation === "vertical"

  return (
    <Switch
      class={`caffeine-button orientation-${orientation}`}
      hexpand={isVertical}
      halign={isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      orientation={orientation}
      glyph=""
      active={active}
      onToggle={(next) => {
        setActive(next)
        execAsync(`hyprkarl-caffeine ${next ? "on" : "off"}`).catch(print)
      }}
    />
  )
}
