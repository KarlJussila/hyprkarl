import { createComputed, type Accessor } from "ags"
import Button from "../../button/Button"

type Props = {
  hasItems: Accessor<boolean>
  mirrorTrigger: boolean
  open: Accessor<boolean>
  onToggle: () => void
}

export default function TrayExpander({
  hasItems,
  mirrorTrigger,
  open,
  onToggle,
}: Props) {
  const collapsedIcon = mirrorTrigger ? "pan-start-symbolic" : "pan-end-symbolic"
  const expandedIcon = mirrorTrigger ? "pan-end-symbolic" : "pan-start-symbolic"
  const triggerIcon = createComputed(() => open() ? expandedIcon : collapsedIcon)
  const triggerClass = hasItems((itemsAvailable) =>
    itemsAvailable ? "tray-trigger" : "tray-trigger tray-empty",
  )

  return (
    <box class="tray-toggle segmented-inline-item">
      <Button
        class={triggerClass}
        hexpand={false}
        execPrimary={onToggle}
      >
        <image iconName={triggerIcon} pixelSize={14} />
      </Button>
    </box>
  )
}
