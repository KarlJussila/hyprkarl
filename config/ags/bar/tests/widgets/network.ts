import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedNetworkWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "network" }>

test("normalizes network widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["network"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      network: { kind: "network" },
    },
  )

  const network = resolved.widgets.network as ResolvedNetworkWidgetConfig
  assert.equal(network.command, "hk-launch-wifi")
})

test("allows network widgets to override their launch command", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["network"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      network: {
        kind: "network",
        command: "custom-network-command",
      },
    },
  )

  const network = resolved.widgets.network as ResolvedNetworkWidgetConfig
  assert.equal(network.command, "custom-network-command")
})
