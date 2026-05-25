import { Accessor, createComputed } from "ags"
import { Gtk } from "ags/gtk4"
import { type BarOrientation } from "../../layout/placement"
import Button from "../../primitives/Button"
import type { NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"

type Props = {
  orientation: BarOrientation
  icons: {
    collapsed: string
    expanded: string
  }
  hasItems: Accessor<boolean>
  open: Accessor<boolean>
  onToggle: () => void
  tooltip: NormalizedSimpleTooltipConfig
}

export default function TrayExpander({
  orientation,
  icons,
  hasItems,
  open,
  onToggle,
  tooltip,
}: Props) {
  const isVertical = orientation === "vertical"
  const triggerIcon = createComputed(() => open() ? icons.expanded : icons.collapsed)
  const buttonStateClass = hasItems((itemsAvailable) =>
    `widget-tray-toggle-button widget-glyph-button${itemsAvailable ? "" : " is-empty"}`,
  )

  return (
    <box
      class="widget-tray-toggle widget-group-item"
      hexpand={isVertical}
      halign={isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
    >
      <Button
        class={buttonStateClass}
        orientation={orientation}
        tooltipText={tooltip.enabled && tooltip.text ? tooltip.text : undefined}
        execPrimary={onToggle}
      >
        <box
          class="widget-tray-toggle-content"
          hexpand={isVertical}
          halign={Gtk.Align.CENTER}
        >
          <image class="widget-tray-toggle-icon" iconName={triggerIcon} pixelSize={14} />
        </box>
      </Button>
    </box>
  )
}
