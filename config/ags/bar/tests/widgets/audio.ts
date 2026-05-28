import assert from "node:assert/strict"
import test from "node:test"
import {
  formatAudioPercentage,
  formatAudioTooltip,
  formatUnavailableAudioTooltip,
} from "../../widgets/audio/audioTooltip.ts"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedAudioWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "audio" }>

test("normalizes audio widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["audio"],
      center: {
        start: [],
        center: [],
        end: [],
      },
      end: [],
    },
    {
      audio: { kind: "audio" },
    },
  )

  const audio = resolved.widgets.audio as ResolvedAudioWidgetConfig
  assert.equal(audio.showPercentage, true)
  assert.equal(audio.commands.primary, undefined)
  assert.equal(audio.commands.secondary, "hk-launch-audio")
  assert.equal(audio.commands.tertiary, undefined)
  assert.equal(audio.tooltip.active, "{device} {percentage}")
  assert.equal(audio.tooltip.unavailable, "Audio unavailable")
  assert.ok(audio.slider.trackLength > 0)
  assert.ok(audio.slider.trackThickness > 0)
  assert.ok(audio.slider.thumbWidth > 0)
  assert.ok(audio.slider.thumbHeight > 0)
  assert.equal(audio.indicator.height, 14)
  assert.equal(audio.indicator.lineWidth, 1.4)
})

test("allows audio indicator overrides", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["audio"], center: { start: [], center: [], end: [] }, end: [] },
    {
      audio: {
        kind: "audio",
        indicator: { height: 20, lineWidth: 2 },
      },
    },
  )

  const audio = resolved.widgets.audio as ResolvedAudioWidgetConfig
  assert.equal(audio.indicator.height, 20)
  assert.equal(audio.indicator.lineWidth, 2)
})

test("normalizes audio widget overrides", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["audio"],
      center: {
        start: [],
        center: [],
        end: [],
      },
      end: [],
    },
    {
      audio: {
        kind: "audio",
        showPercentage: false,
        commands: {
          secondary: "custom-audio-command",
        },
        flyout: {
          align: "end",
          gap: 6,
        },
        tooltip: {
          active: "{percentage}",
          muted: "quiet",
        },
        slider: {
          trackLength: 260,
          trackThickness: 10,
          trackRadius: 3,
          fillRadius: 2,
          thumbWidth: 14,
          thumbHeight: 12,
          thumbRadius: 4,
          thumbVisible: true,
        },
      },
    },
  )

  const audio = resolved.widgets.audio as ResolvedAudioWidgetConfig
  assert.equal(audio.showPercentage, false)
  assert.equal(audio.commands.secondary, "custom-audio-command")
  assert.equal(audio.flyout.align, "end")
  assert.equal(audio.flyout.gap, 6)
  assert.equal(audio.tooltip.active, "{percentage}")
  assert.equal(audio.tooltip.muted, "quiet")
  assert.equal(audio.tooltip.unavailable, "Audio unavailable")
  assert.equal(audio.slider.trackLength, 260)
  assert.equal(audio.slider.trackThickness, 10)
  assert.equal(audio.slider.trackRadius, 3)
  assert.equal(audio.slider.fillRadius, 2)
  assert.equal(audio.slider.thumbWidth, 14)
  assert.equal(audio.slider.thumbHeight, 12)
  assert.equal(audio.slider.thumbRadius, 4)
  assert.equal(audio.slider.thumbVisible, true)
})

test("audio commands can be fully overridden", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["audio"], center: { start: [], center: [], end: [] }, end: [] },
    {
      audio: {
        kind: "audio",
        commands: {
          primary: "custom-primary",
          secondary: "custom-secondary",
          tertiary: "custom-tertiary",
        },
      },
    },
  )

  const audio = resolved.widgets.audio as ResolvedAudioWidgetConfig
  assert.equal(audio.commands.primary, "custom-primary")
  assert.equal(audio.commands.secondary, "custom-secondary")
  assert.equal(audio.commands.tertiary, "custom-tertiary")
})

test("audio commands can be individually disabled with empty string", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["audio"], center: { start: [], center: [], end: [] }, end: [] },
    {
      audio: {
        kind: "audio",
        commands: { secondary: "" },
      },
    },
  )

  const audio = resolved.widgets.audio as ResolvedAudioWidgetConfig
  assert.equal(audio.commands.secondary, "")
})

test("formats an active audio tooltip", () => {
  assert.equal(
    formatAudioTooltip({
      muted: false,
      volume: 0.42,
      device: "Speakers",
      formats: {
        enabled: true,
        active: "{device} {percentage}",
        muted: "Muted {device}",
        unavailable: "Audio unavailable",
      },
    }),
    "Speakers 42%",
  )
})

test("formats a muted audio tooltip", () => {
  assert.equal(
    formatAudioTooltip({
      muted: true,
      volume: 0.07,
      device: "Headphones",
      formats: {
        enabled: true,
        active: "{device} {percentage}",
        muted: "Muted {device}",
        unavailable: "Audio unavailable",
      },
    }),
    "Muted Headphones",
  )
})

test("collapses empty audio tooltip tokens cleanly", () => {
  assert.equal(
    formatAudioTooltip({
      muted: true,
      volume: 0.07,
      device: "",
      formats: {
        enabled: true,
        active: "{device} {percentage}",
        muted: "Muted {device}",
        unavailable: "Audio unavailable",
      },
    }),
    "Muted",
  )
  assert.equal(
    formatUnavailableAudioTooltip({
      enabled: true,
      active: "{device} {percentage}",
      muted: "Muted {device}",
      unavailable: "Audio unavailable",
    }),
    "Audio unavailable",
  )
})

test("formats audio percentages as whole percents", () => {
  assert.equal(formatAudioPercentage(0), "0%")
  assert.equal(formatAudioPercentage(0.675), "68%")
})
