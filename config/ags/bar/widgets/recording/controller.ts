import { createState } from "ags"
import app from "ags/gtk4/app"
import GLib from "gi://GLib?version=2.0"

const RUNTIME_DIR = GLib.getenv("XDG_RUNTIME_DIR") ?? "/tmp"
const PID_FILE = `${RUNTIME_DIR}/hyprkarl/screenrecording.pid`

type RecordingController = {
  active: ReturnType<typeof createState<boolean>>[0]
  syncStatus: () => void
}

let recordingController: RecordingController | null = null

export function getRecordingController(): RecordingController {
  if (recordingController) {
    return recordingController
  }

  const [active, setActive] = createState(false)

  const syncStatus = () => {
    const [ok, contents] = GLib.file_get_contents(PID_FILE)
    if (!ok) { setActive(false); return }
    const pid = parseInt(new TextDecoder().decode(contents).trim(), 10)
    if (!Number.isInteger(pid) || pid <= 0) { setActive(false); return }
    setActive(GLib.file_test(`/proc/${pid}`, GLib.FileTest.EXISTS))
  }

  syncStatus()

  app.connect("request", (_app, args, respond) => {
    if (args[0] !== "recording-sync") {
      return
    }

    syncStatus()
    respond("ok")
  })

  recordingController = { active, syncStatus }
  return recordingController
}
