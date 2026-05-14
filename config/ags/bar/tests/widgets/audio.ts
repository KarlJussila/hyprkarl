import assert from "node:assert/strict"
import test from "node:test"
import type { NormalizedAudioWidgetConfig } from "../../configuration.ts"
import {
  formatAudioPercentage,
  formatAudioTooltip,
  formatUnavailableAudioTooltip,
} from "../../widgets/audio/audioTooltip.ts"
import { resolveBarConfiguration } from "../support/index.ts"

test("normalizes audio widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["audio"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      audio: { kind: "audio" },
    },
  )

  const audio = resolved.widgets.audio as NormalizedAudioWidgetConfig
  assert.equal(audio.showPercentage, true)
  assert.equal(audio.command, "hk-launch-audio")
  assert.equal(audio.flyout.enabled, true)
  assert.equal(audio.tooltip.active, "{device} {percentage}")
  assert.equal(audio.tooltip.unavailable, "Audio unavailable")
  assert.ok(audio.slider.trackLength > 0)
  assert.ok(audio.slider.trackThickness > 0)
  assert.ok(audio.slider.thumbWidth > 0)
  assert.ok(audio.slider.thumbHeight > 0)
})

test("normalizes audio widget overrides", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["audio"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      audio: {
        kind: "audio",
        showPercentage: false,
        command: "custom-audio-command",
        flyout: {
          enabled: false,
          align: "end",
          gap: 6,
        },
        tooltip: {
          active: "{percentage}",
          muted: "quiet",
        },
        advanced: {
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
    },
  )

  const audio = resolved.widgets.audio as NormalizedAudioWidgetConfig
  assert.equal(audio.showPercentage, false)
  assert.equal(audio.command, "custom-audio-command")
  assert.equal(audio.flyout.enabled, false)
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

test("formats an active audio tooltip", () => {
  assert.equal(
    formatAudioTooltip({
      muted: false,
      volume: 0.42,
      device: "Speakers",
      formats: {
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
        active: "{device} {percentage}",
        muted: "Muted {device}",
        unavailable: "Audio unavailable",
      },
    }),
    "Muted",
  )
  assert.equal(
    formatUnavailableAudioTooltip({
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
