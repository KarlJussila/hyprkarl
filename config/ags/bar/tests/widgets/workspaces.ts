import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedWorkspacesWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "workspaces" }>

test("normalizes dynamic workspace defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["workspaces"],
      center: {
        start: [],
        center: [],
        end: [],
      },
      end: [],
    },
    {
      workspaces: { kind: "workspaces" },
    },
  )

  const workspaces = resolved.widgets.workspaces as ResolvedWorkspacesWidgetConfig
  assert.equal(workspaces.mode, "dynamic")
  if (workspaces.mode !== "dynamic") {
    throw new Error("expected dynamic workspaces config")
  }

  assert.deepEqual(workspaces.visibility.alwaysShow, [1])
  assert.equal(workspaces.visibility.includeFocused, true)
  assert.equal(workspaces.visibility.includeOccupied, true)
  assert.equal(workspaces.visibility.excludeSpecial, true)
})

test("normalizes fixed workspaces and widget-specific overrides", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "left",
      start: ["workspaces"],
      center: {
        start: [],
        center: ["clock"],
        end: [],
      },
      end: [],
    },
    {
      workspaces: {
        kind: "workspaces",
        mode: "fixed",
        ids: [3, 1, 3],
      },
      clock: {
        kind: "clock",
      },
    },
  )

  const workspaces = resolved.widgets.workspaces as ResolvedWorkspacesWidgetConfig
  assert.equal(workspaces.mode, "fixed")
  if (workspaces.mode !== "fixed") {
    throw new Error("expected fixed workspaces config")
  }

  assert.deepEqual(workspaces.ids, [3, 1])
})
