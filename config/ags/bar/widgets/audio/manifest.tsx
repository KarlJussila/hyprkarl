import AudioWidget from "./AudioWidget.tsx"
import { type WidgetManifest } from "../shared/widgetManifest.tsx"

const audioManifest: WidgetManifest<"audio"> = {
  kind: "audio",
  render: ({ id, config, placement, monitor }) => (
    <AudioWidget
      id={id}
      placement={placement}
      monitor={monitor}
      config={config}
    />
  ),
}

export default audioManifest
