import { createState } from "ags"
import app from "ags/gtk4/app"
import GLib from "gi://GLib?version=2.0"
import Button from "../../primitives/Button.tsx"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import { mergeConfig, type WidgetClicks, type WidgetProps } from "../shared/types.ts"

export type RecordingConfig = {
  icon?: string
  commands?: WidgetClicks
  tooltip?: string
}

type RecordingDefaults = {
  icon: string
  commands: WidgetClicks
  tooltip: string
}

export const defaults: RecordingDefaults = {
  icon: "󰻂",
  commands: { primary: "hk-record-screen --stop-recording" },
  tooltip: "Recording — click to stop",
}

const decoder = new TextDecoder()

const RUNTIME_DIR = GLib.getenv("XDG_RUNTIME_DIR") ?? "/tmp"
const PID_FILE = `${RUNTIME_DIR}/hyprkarl/screenrecording.pid`

type RecordingController = {
  active: ReturnType<typeof createState<boolean>>[0]
  syncStatus: () => void
}

let recordingController: RecordingController | null = null

function getRecordingController(): RecordingController {
  if (recordingController) {
    return recordingController
  }

  const [active, setActive] = createState(false)

  const syncStatus = () => {
    try {
      const [, contents] = GLib.file_get_contents(PID_FILE)
      const pid = parseInt(decoder.decode(contents).trim(), 10)
      if (!Number.isInteger(pid) || pid <= 0) { setActive(false); return }
      setActive(GLib.file_test(`/proc/${pid}`, GLib.FileTest.EXISTS))
    } catch {
      setActive(false)
    }
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

export default function Recording({ config, placement }: WidgetProps<RecordingConfig>) {
  const cfg = mergeConfig(defaults, config)
  const { icon, commands, tooltip } = cfg
  const controller = getRecordingController()
  const { execPrimary, execSecondary, execTertiary } = useWidgetCommands({ commands })

  return (
    <Button
      class="widget-recording-button widget-glyph-button"
      orientation={placement.orientation}
      visible={controller.active}
      tooltipText={tooltip || undefined}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execTertiary={execTertiary}
    >
      <label class="widget-recording-glyph" xalign={0.5} label={icon} />
    </Button>
  )
}
