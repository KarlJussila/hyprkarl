import { createState } from "ags"
import app from "ags/gtk4/app"
import { execAsync } from "ags/process"

type ToggleCommands = {
  on: string
  off: string
  sync: string
}

type ToggleController = {
  active: ReturnType<typeof createState<boolean>>[0]
  toggle: (commands: ToggleCommands, next: boolean) => void
  syncStatus: () => Promise<void>
}

const controllers = new Map<string, ToggleController>()

export function getToggleController(commands: ToggleCommands, endpoint: string): ToggleController {
  const existing = controllers.get(endpoint)
  if (existing) {
    return existing
  }

  const [active, setActive] = createState(false)

  const syncStatus = async () => {
    try {
      await execAsync(commands.sync)
      setActive(true)
    } catch {
      setActive(false)
    }
  }

  void syncStatus()

  app.connect("request", (_app, args, respond) => {
    if (args[0] !== endpoint) {
      return
    }

    void syncStatus().finally(() => respond("ok"))
  })

  const controller: ToggleController = {
    active,
    toggle: (cmds, next) => {
      setActive(next)
      void execAsync(next ? cmds.on : cmds.off).catch(print)
    },
    syncStatus,
  }

  controllers.set(endpoint, controller)
  return controller
}
