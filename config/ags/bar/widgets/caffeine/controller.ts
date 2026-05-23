import { createState } from "ags"
import app from "ags/gtk4/app"
import { execAsync } from "ags/process"

type CaffeineController = {
  active: ReturnType<typeof createState<boolean>>[0]
  toggle: (command: string, next: boolean) => void
  syncStatus: () => Promise<void>
}

let caffeineController: CaffeineController | null = null

export function getCaffeineController(): CaffeineController {
  if (caffeineController) {
    return caffeineController
  }

  const [active, setActive] = createState(false)

  const syncStatus = async () => {
    try {
      const serviceState = await execAsync(
        "systemctl --user show hypridle.service --property=ActiveState",
      )
      const isHypridleActive = serviceState.trim() === "ActiveState=active"
      setActive(!isHypridleActive)
    } catch {
      setActive(false)
    }
  }

  void syncStatus()

  app.connect("request", (_app, args, respond) => {
    if (args[0] !== "caffeine-sync") {
      return
    }

    void syncStatus().finally(() => respond("ok"))
  })

  caffeineController = {
    active,
    toggle: (command, next) => {
      setActive(next)
      void execAsync(`${command} ${next ? "on" : "off"}`).catch(print)
    },
    syncStatus,
  }

  return caffeineController
}

