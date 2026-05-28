import { Accessor, createEffect } from "ags"
import { Gtk } from "ags/gtk4"
import { fontScaleFactor } from "../shared/drawScale.ts"

export type AudioIndicatorMetrics = {
  height: number
  lineWidth: number
}

type Props = {
  volume: Accessor<number>
  muted: Accessor<boolean>
  metrics: AudioIndicatorMetrics
}

const BASE_WAVE_RADII = [3.0, 4.8, 6.6, 8.4]
const BASE_STROKE_PADDING = 1.2
const BASE_SPEAKER_END_X = 9.2
const BASE_MUTE_SLASH_END_X = 11.8

function clamp(value: number, min = 0, max = 1.25) {
  return Math.min(max, Math.max(min, value))
}

function countVisibleWaves(volume: number) {
  const clamped = clamp(volume)
  if (clamped <= 0) return 0
  if (clamped <= 0.25) return 1
  if (clamped <= 0.5) return 2
  if (clamped <= 0.75) return 3
  return 4
}

function resolveWidth(waveCount: number, isMuted: boolean, s: number) {
  const waveEndX = waveCount > 0
    ? (7.4 + BASE_WAVE_RADII[waveCount - 1] + BASE_STROKE_PADDING) * s
    : BASE_SPEAKER_END_X * s
  return Math.ceil(isMuted ? Math.max(waveEndX, BASE_MUTE_SLASH_END_X * s) : waveEndX)
}

function maxWidth(s: number) {
  return resolveWidth(4, true, s)
}

export default function AudioIndicator({ volume, muted, metrics }: Props) {
  return (
    <drawingarea
      contentWidth={maxWidth(1)}
      contentHeight={metrics.height}
      class="widget-audio-indicator"
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
      $={(self) => {
        self.connect("realize", () => {
          const s = fontScaleFactor(self)
          self.set_content_width(maxWidth(s))
          self.set_content_height(Math.ceil(metrics.height * s))
        })

        createEffect(() => {
          muted()
          volume()
          self.queue_draw()
        })

        self.set_draw_func((area, context) => {
          const s = fontScaleFactor(area)
          const h = metrics.height * s
          const style = area.get_style_context()
          const color = style.get_color()
          const isMuted = muted()
          const waveCount = isMuted ? 0 : countVisibleWaves(volume())
          const centerY = h / 2
          const mw = maxWidth(s)
          const offset = (mw - resolveWidth(waveCount, isMuted, s)) / 2

          context.translate(offset, 0)
          context.setSourceRGBA(color.red, color.green, color.blue, color.alpha)
          context.setLineWidth(metrics.lineWidth * s)
          context.setLineCap(1)
          context.setLineJoin(1)

          context.moveTo(1.5 * s, centerY - 2 * s)
          context.lineTo(4.5 * s, centerY - 2 * s)
          context.lineTo(8.5 * s, centerY - 5 * s)
          context.lineTo(8.5 * s, centerY + 5 * s)
          context.lineTo(4.5 * s, centerY + 2 * s)
          context.lineTo(1.5 * s, centerY + 2 * s)
          context.closePath()
          context.stroke()

          BASE_WAVE_RADII.slice(0, waveCount).forEach((radius) => {
            context.newPath()
            context.arc(7.4 * s, centerY, radius * s, -0.78, 0.78)
            context.stroke()
          })

          if (isMuted) {
            context.newPath()
            context.moveTo(3.0 * s, centerY - 5.2 * s)
            context.lineTo(11.0 * s, centerY + 5.2 * s)
            context.stroke()
          }
        })
      }}
    />
  )
}
