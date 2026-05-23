import app from "ags/gtk4/app"
import type { BarVisibilityController } from "./barVisibilityController"

const controllers: BarVisibilityController[] = []
let registered = false

export function registerBarCliHandler(controller: BarVisibilityController): () => void {
  controllers.push(controller)

  if (!registered) {
    registered = true

    app.connect("request", (_app, args: string[], respond: (s: string) => void) => {
      if (args[0] !== "bar") return

      switch (args[1]) {
        case "autohide":
          return handleToggle(args[2], {
            on: () => controllers.forEach((c) => c.setAutohide(true)),
            off: () => controllers.forEach((c) => c.setAutohide(false)),
            toggle: () => controllers.forEach((c) => c.setAutohide(!c.getStatus().autohide)),
          }, respond)

        case "exclusive":
          return handleToggle(args[2], {
            on: () => controllers.forEach((c) => c.setExclusive(true)),
            off: () => controllers.forEach((c) => c.setExclusive(false)),
            toggle: () => controllers.forEach((c) => c.setExclusive(!c.getStatus().exclusive)),
          }, respond)

        case "show":
          controllers.forEach((c) => c.forceShow())
          return respond("ok")

        case "hide":
          controllers.forEach((c) => c.forceHide())
          return respond("ok")

        case "toggle": {
          const status = controllers[0]?.getStatus()
          if (status && !status.hidden && !status.autohide) {
            controllers.forEach((c) => c.forceHide())
          } else {
            controllers.forEach((c) => c.forceShow())
          }
          return respond("ok")
        }

        case "status": {
          const status = controllers[0]?.getStatus() ?? { autohide: false, exclusive: true, hidden: false }
          return respond(JSON.stringify(status))
        }

        default:
          return respond(`unknown bar subcommand: ${args[1] ?? "(none)"}`)
      }
    })
  }

  return () => {
    const i = controllers.indexOf(controller)
    if (i !== -1) controllers.splice(i, 1)
  }
}

function handleToggle(
  arg: string | undefined,
  handlers: { on: () => void; off: () => void; toggle: () => void },
  respond: (s: string) => void,
) {
  switch (arg) {
    case "on": handlers.on(); return respond("ok")
    case "off": handlers.off(); return respond("ok")
    case "toggle": handlers.toggle(); return respond("ok")
    default: return respond(`expected on, off, or toggle; got: ${arg ?? "(none)"}`)
  }
}
