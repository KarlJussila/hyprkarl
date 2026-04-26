import { createBinding, type Accessor } from "ags"
import AstalHyprland from "gi://AstalHyprland"
import Button from "../../button/Button"

type Props = {
  id: number
  isEmpty?: boolean | Accessor<boolean>
}

function workspaceButtonClass(isEmpty: boolean | Accessor<boolean>) {
  if (typeof isEmpty === "boolean") {
    return isEmpty
      ? "workspace-button workspace-empty segmented-group-item"
      : "workspace-button segmented-group-item"
  }

  return isEmpty((empty) =>
    empty
      ? "workspace-button workspace-empty segmented-group-item"
      : "workspace-button segmented-group-item",
  )
}

export default function WorkspaceButton({
  id,
  isEmpty = false,
}: Props) {
  const hyprland = AstalHyprland.get_default()
  const focusedWorkspaceId = createBinding(hyprland, "focusedWorkspace")(
    (workspace) => workspace?.id ?? 0,
  )
  const isActive = focusedWorkspaceId((activeId) => activeId === id)

  return (
    <Button
      class={workspaceButtonClass(isEmpty)}
      hexpand={false}
      execPrimary={() => hyprland.dispatch("workspace", `${id}`)}
    >
      <box spacing={0}>
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
