import { Accessor, createEffect } from "ags"
import { Gtk } from "ags/gtk4"

type Props = {
  volume: Accessor<number>
  muted: Accessor<boolean>
}

const HEIGHT = 14
const WAVE_RADII = [3.0, 4.8, 6.6, 8.4]
const SPEAKER_END_X = 9.2
const MUTE_SLASH_END_X = 11.8
const STROKE_PADDING = 1.2

const MAX_WIDTH = resolveWidth(4, true)

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

function resolveWidth(waveCount: number, isMuted: boolean) {
  const waveEndX = waveCount > 0
    ? 7.4 + WAVE_RADII[waveCount - 1] + STROKE_PADDING
    : SPEAKER_END_X

  return Math.ceil(isMuted ? Math.max(waveEndX, MUTE_SLASH_END_X) : waveEndX)
}

export default function AudioIndicator({ volume, muted }: Props) {
  return (
    <drawingarea
      contentWidth={MAX_WIDTH}
      contentHeight={HEIGHT}
      class="widget-audio-indicator"
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
      $={(self) => {
        createEffect(() => {
          muted()
          volume()
          self.queue_draw()
        })

        self.set_draw_func((area, context) => {
          const style = area.get_style_context()
          const color = style.get_color()
          const isMuted = muted()
          const waveCount = isMuted ? 0 : countVisibleWaves(volume())
          const centerY = HEIGHT / 2
          const offset = (MAX_WIDTH - resolveWidth(waveCount, isMuted)) / 2

          context.translate(offset, 0)
          context.setSourceRGBA(color.red, color.green, color.blue, color.alpha)
          context.setLineWidth(1.4)
          context.setLineCap(1)
          context.setLineJoin(1)

          context.moveTo(1.5, centerY - 2)
          context.lineTo(4.5, centerY - 2)
          context.lineTo(8.5, centerY - 5)
          context.lineTo(8.5, centerY + 5)
          context.lineTo(4.5, centerY + 2)
          context.lineTo(1.5, centerY + 2)
          context.closePath()
          context.stroke()

          WAVE_RADII.slice(0, waveCount).forEach((radius) => {
            context.newPath()
            context.arc(7.4, centerY, radius, -0.78, 0.78)
            context.stroke()
          })

          if (isMuted) {
            context.newPath()
            context.moveTo(3.0, centerY - 5.2)
            context.lineTo(11.0, centerY + 5.2)
            context.stroke()
          }
        })
      }}
    />
  )
}
