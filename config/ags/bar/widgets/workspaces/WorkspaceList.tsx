import { For, createComputed, createEffect, type Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import { timeout, type Timer } from "ags/time"
import { type BarOrientation } from "../../layout/placement"
import { measureWidgetWidth, requestBarWindowRelayout } from "../../layout/windowSizing"
import WorkspaceButton from "./WorkspaceButton"
import type { NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"
import type { VisibleWorkspace } from "./workspaceVisibility"

type Props = {
  orientation: BarOrientation
  workspaces: Accessor<Array<VisibleWorkspace>>
  tooltip: NormalizedSimpleTooltipConfig
}

export default function WorkspaceList({ orientation, workspaces, tooltip }: Props) {
  const workspaceSignature = createComputed(() =>
    workspaces().map((workspace) => `${workspace.id}:${workspace.isEmpty ? "e" : "o"}`).join(","),
  )

  return (
    <box
      class={`widget-group workspace-list orientation-${orientation} is-${orientation}`}
      spacing={0}
      overflow={Gtk.Overflow.HIDDEN}
      hexpand={orientation === "vertical"}
      halign={orientation === "vertical" ? Gtk.Align.FILL : Gtk.Align.CENTER}
      orientation={orientation === "vertical" ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
      $={(self) => {
        let previousMeasuredWidth = 0
        let widthMeasureTimer: Timer | null = null

        createEffect(() => {
          workspaceSignature()

          widthMeasureTimer?.cancel()
          widthMeasureTimer = timeout(1, () => {
            const nextMeasuredWidth = measureWidgetWidth(self)

            // Workspace buttons can disappear when a workspace becomes empty. On a
            // vertical bar that changes the window's reserved screen width, so we
            // trigger a relayout when the measured content shrinks.
            if (previousMeasuredWidth > 0 && nextMeasuredWidth < previousMeasuredWidth) {
              requestBarWindowRelayout(self)
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
      <For each={workspaces}>
        {(workspace) => (
          <WorkspaceButton
            orientation={orientation}
            id={workspace.id}
            isEmpty={workspace.isEmpty}
            tooltip={tooltip}
          />
        )}
      </For>
    </box>
  )
}
