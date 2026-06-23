import { Accessor, createBinding, createComputed, For } from "ags"
import { Gtk } from "ags/gtk4"
import AstalBluetooth from "gi://AstalBluetooth"
import Button from "../../primitives/Button.tsx"

type Props = {
  devices: Accessor<Array<AstalBluetooth.Device>>
}

// Nerd Font glyph per BlueZ device-class icon name. `AstalBluetooth.Device.icon`
// can only ever be one of these standard freedesktop names, so this table is the
// full taxonomy. Using glyphs keeps the flyout consistent with the rest of the
// bar (and theme-colored via SCSS) instead of pulling Yaru's purple-accented
// audio icons. Paste the glyph between the quotes; empty falls back to FALLBACK_GLYPH.
const DEVICE_GLYPHS: Record<string, string> = {
  "audio-headphones": "󰋋", // nf-md-headphones
  "audio-headset": "󰋎", //    nf-md-headset
  "audio-card": "󰓃", //       nf-md-speaker
  "input-keyboard": "󰌌", //   nf-md-keyboard
  "input-mouse": "󰍽", //      nf-md-mouse
  "input-gaming": "󰊴", //     nf-md-controller
  "input-tablet": "󰓶", //     nf-md-tablet
  computer: "󰌢", //           nf-md-laptop
  phone: "󰄜", //              nf-md-cellphone
  "video-display": "󰍹", //    nf-md-monitor
  "multimedia-player": "󰝚", //nf-md-music
  "camera-photo": "󰄀", //     nf-md-camera
  "camera-video": "󰕧", //     nf-md-video
  printer: "󰐪", //            nf-md-printer
  scanner: "󰚫", //            nf-md-scanner
  "network-wireless": "󰖩", // nf-md-wifi
  modem: "󰑩", //              nf-md-router-wireless
}

// Shown for unknown classes and any entry left blank above.
const FALLBACK_GLYPH = "󰂯" // nf-md-bluetooth

function deviceGlyph(device: AstalBluetooth.Device) {
  return DEVICE_GLYPHS[device.icon] || FALLBACK_GLYPH
}

function deviceLabel(device: AstalBluetooth.Device) {
  return device.alias || device.name || device.address
}

function toggleConnection(device: AstalBluetooth.Device) {
  if (device.connected) {
    device.disconnect_device((_, res) => {
      try {
        device.disconnect_device_finish(res)
      } catch (err) {
        console.error("bluetooth disconnect failed", err)
      }
    })
  } else {
    device.connect_device((_, res) => {
      try {
        device.connect_device_finish(res)
      } catch (err) {
        console.error("bluetooth connect failed", err)
      }
    })
  }
}

function DeviceRow({ device }: { device: AstalBluetooth.Device }) {
  const connected = createBinding(device, "connected")
  const connecting = createBinding(device, "connecting")
  const rowClass = connected((isConnected) =>
    isConnected ? "flyout-row active" : "flyout-row",
  )

  return (
    <Button
      class={rowClass}
      hexpand
      halign={Gtk.Align.FILL}
      execPrimary={() => toggleConnection(device)}
    >
      <box spacing={8} hexpand halign={Gtk.Align.FILL}>
        <label class="flyout-row-glyph" label={deviceGlyph(device)} />
        <label hexpand xalign={0} label={deviceLabel(device)} />
        <label
          class="flyout-row-status"
          halign={Gtk.Align.END}
          visible={connecting}
          label="…"
        />
        <image
          halign={Gtk.Align.END}
          class="flyout-row-check"
          iconName="object-select-symbolic"
          visible={createComputed(() => connected() && !connecting())}
        />
      </box>
    </Button>
  )
}

export default function DeviceMenu({ devices }: Props) {
  const paired = devices((list) => list.filter((device) => device.paired))

  return (
    <box orientation={Gtk.Orientation.VERTICAL} hexpand>
      <For each={paired}>
        {(device: AstalBluetooth.Device) => <DeviceRow device={device} />}
      </For>
      <label
        class="flyout-empty"
        xalign={0}
        label="No paired devices"
        visible={paired((list) => list.length === 0)}
      />
    </box>
  )
}
