import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedNetworkWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "network" }>

test("normalizes network widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["network"], center: { start: [], center: [], end: [] }, end: [] },
    { network: { kind: "network" } },
  )

  const network = resolved.widgets.network as ResolvedNetworkWidgetConfig
  assert.equal(network.commands.primary, "hk-launch-wifi")
  assert.equal(network.commands.secondary, undefined)
  assert.equal(network.commands.tertiary, undefined)
  assert.equal(network.icons.disconnected, "󰤮")
  assert.equal(network.icons.ethernet, "󰀂")
  assert.equal(network.icons.wifi.length, 5)
  assert.equal(network.tooltip.disconnected, "Disconnected")
  assert.equal(network.tooltip.ethernet, "Ethernet connected")
  assert.equal(network.tooltip.wifiNoSsid, "Wi-Fi connected")
})

test("allows network widgets to override their launch command", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["network"], center: { start: [], center: [], end: [] }, end: [] },
    { network: { kind: "network", commands: { primary: "custom-network-command" } } },
  )

  const network = resolved.widgets.network as ResolvedNetworkWidgetConfig
  assert.equal(network.commands.primary, "custom-network-command")
})

test("allows network widgets to add secondary and tertiary commands", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["network"], center: { start: [], center: [], end: [] }, end: [] },
    {
      network: {
        kind: "network",
        commands: { secondary: "secondary-cmd", tertiary: "tertiary-cmd" },
      },
    },
  )

  const network = resolved.widgets.network as ResolvedNetworkWidgetConfig
  assert.equal(network.commands.primary, "hk-launch-wifi")
  assert.equal(network.commands.secondary, "secondary-cmd")
  assert.equal(network.commands.tertiary, "tertiary-cmd")
})

test("allows network primary click to be disabled with empty string", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["network"], center: { start: [], center: [], end: [] }, end: [] },
    { network: { kind: "network", commands: { primary: "" } } },
  )

  const network = resolved.widgets.network as ResolvedNetworkWidgetConfig
  assert.equal(network.commands.primary, "")
})

test("allows network widgets to override icons", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["network"], center: { start: [], center: [], end: [] }, end: [] },
    {
      network: {
        kind: "network",
        icons: { disconnected: "X", ethernet: "E" },
      },
    },
  )

  const network = resolved.widgets.network as ResolvedNetworkWidgetConfig
  assert.equal(network.icons.disconnected, "X")
  assert.equal(network.icons.ethernet, "E")
})

test("allows network widgets to override tooltip templates", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["network"], center: { start: [], center: [], end: [] }, end: [] },
    {
      network: {
        kind: "network",
        tooltip: { disconnected: "No network", ethernet: "Wired" },
      },
    },
  )

  const network = resolved.widgets.network as ResolvedNetworkWidgetConfig
  assert.equal(network.tooltip.disconnected, "No network")
  assert.equal(network.tooltip.ethernet, "Wired")
})

test("rejects wifi icons that are not an array of exactly 5 strings", () => {
  assert.throws(
    () =>
      resolveBarConfiguration(
        { edge: "top", start: ["network"], center: { start: [], center: [], end: [] }, end: [] },
        { network: { kind: "network", icons: { wifi: ["a", "b"] as any } } },
      ),
    { name: "BarConfigError" },
  )
})

test("rejects whitespace-only command strings", () => {
  assert.throws(
    () =>
      resolveBarConfiguration(
        { edge: "top", start: ["network"], center: { start: [], center: [], end: [] }, end: [] },
        { network: { kind: "network", commands: { primary: "   " } } },
      ),
    { name: "BarConfigError" },
  )
})
