import { For, createComputed, createEffect, type Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import { timeout, type Timer } from "ags/time"
import { measureWidgetWidth, requestBarWindowRelayout } from "../../barWindowSizing"
import { type BarOrientation } from "../../barPlacement"
import WorkspaceButton from "./WorkspaceButton"
import type { VisibleWorkspace } from "./workspaceVisibility"

type Props = {
  orientation: BarOrientation
  workspaces: Array<VisibleWorkspace> | Accessor<Array<VisibleWorkspace>>
}

export default function WorkspaceList({ orientation, workspaces }: Props) {
  const workspaceList = Array.isArray(workspaces)
    ? null
    : createComputed(() => workspaces().map((workspace) => `${workspace.id}:${workspace.isEmpty ? "e" : "o"}`).join(","))

  return (
    <box
      class={`segmented-group orientation-${orientation}`}
      spacing={0}
      overflow={Gtk.Overflow.HIDDEN}
      hexpand={orientation === "vertical"}
      halign={orientation === "vertical" ? Gtk.Align.FILL : Gtk.Align.CENTER}
      orientation={orientation === "vertical" ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
      $={(self) => {
        if (!workspaceList) return
        let previousMeasuredWidth = 0
        let widthMeasureTimer: Timer | null = null

        createEffect(() => {
          workspaceList()

          widthMeasureTimer?.cancel()
          widthMeasureTimer = timeout(1, () => {
            const nextMeasuredWidth = measureWidgetWidth(self)

            if (previousMeasuredWidth > 0 && nextMeasuredWidth < previousMeasuredWidth) {
              requestBarWindowRelayout(self, orientation)
            }

            previousMeasuredWidth = nextMeasuredWidth
            widthMeasureTimer = null
          })
        })

        self.connect("destroy", () => {
          widthMeasureTimer?.cancel()
          widthMeasureTimer = null
        })
      }}
    >
      {Array.isArray(workspaces)
        ? workspaces.map((workspace) => (
            <WorkspaceButton orientation={orientation} id={workspace.id} isEmpty={workspace.isEmpty} />
          ))
        : (
            <For each={workspaces}>
              {(workspace) => (
                <WorkspaceButton
                  orientation={orientation}
                  id={workspace.id}
                  isEmpty={workspace.isEmpty}
                />
              )}
            </For>
          )}
    </box>
  )
}
