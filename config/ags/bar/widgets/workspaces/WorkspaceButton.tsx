import { createBinding, createComputed, type Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import AstalHyprland from "gi://AstalHyprland"
import { type BarOrientation } from "../../layout/placement"
import Button from "../../primitives/Button"

type Props = {
  id: number
  orientation: BarOrientation
  isEmpty?: boolean | Accessor<boolean>
}

function workspaceButtonClass({
  isEmpty,
  isActive,
  orientation,
}: {
  isEmpty: boolean | Accessor<boolean>
  isActive: Accessor<boolean>
  orientation: BarOrientation
}) {
  return createComputed(() => {
    const empty = typeof isEmpty === "boolean" ? isEmpty : isEmpty()
    const active = isActive()
    const classes = [
      "widget-workspace-button",
      "widget-group-item",
      `orientation-${orientation}`,
      `is-${orientation}`,
    ]
    if (empty) classes.push("is-empty")
    if (active) classes.push("is-active")
    return classes.join(" ")
  })
}

export default function WorkspaceButton({
  id,
  orientation,
  isEmpty = false,
}: Props) {
  const hyprland = AstalHyprland.get_default()
  const focusedWorkspaceId = createBinding(hyprland, "focusedWorkspace")(
    (workspace) => workspace?.id ?? 0,
  )
  const isActive = focusedWorkspaceId((activeId) => activeId === id)

  return (
    <Button
      class={workspaceButtonClass({ isEmpty, isActive, orientation })}
      hexpand={orientation === "vertical"}
      halign={orientation === "vertical" ? Gtk.Align.FILL : Gtk.Align.CENTER}
      execPrimary={() => hyprland.dispatch("workspace", `${id}`)}
    >
      <box
        class="widget-workspace-content"
        spacing={0}
        hexpand={orientation === "vertical"}
        halign={Gtk.Align.CENTER}
      >
        <label
          class="workspace-bracket"
          label="["
          opacity={isActive((active) => active ? 1 : 0)}
        />
        <label
          class="workspace-label"
          xalign={0.5}
          label={`${id}`}
        />
        <label
          class="workspace-bracket"
          label="]"
          opacity={isActive((active) => active ? 1 : 0)}
        />
      </box>
    </Button>
  )
}
