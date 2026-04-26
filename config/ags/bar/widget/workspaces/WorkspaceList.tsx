import { For, type Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import WorkspaceButton from "./WorkspaceButton"
import type { VisibleWorkspace } from "./workspaceVisibility"

type Props = {
  workspaces: Array<VisibleWorkspace> | Accessor<Array<VisibleWorkspace>>
}

export default function WorkspaceList({ workspaces }: Props) {
  return (
    <box class="segmented-group" spacing={0} overflow={Gtk.Overflow.HIDDEN}>
      {Array.isArray(workspaces)
        ? workspaces.map((workspace) => (
            <WorkspaceButton id={workspace.id} isEmpty={workspace.isEmpty} />
          ))
        : (
            <For each={workspaces}>
              {(workspace) => (
                <WorkspaceButton
                  id={workspace.id}
                  isEmpty={workspace.isEmpty}
                />
              )}
            </For>
          )}
    </box>
  )
}
