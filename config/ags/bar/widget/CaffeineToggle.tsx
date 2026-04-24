import { createState } from "ags"
import app from "ags/gtk4/app"
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

export default function CaffeineToggle() {
  return (
    <Switch
      glyph=""
      trackLength={24}
      active={active}
      onToggle={(next) => {
        setActive(next)
        execAsync(`hyprkarl-caffeine ${next ? "on" : "off"}`).catch(print)
      }}
    />
  )
}
