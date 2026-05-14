import { Accessor, createEffect } from "ags"
import { Gtk } from "ags/gtk4"
import { type BarOrientation } from "../../layout/placement.ts"

type Props = {
  orientation: BarOrientation
  volume: Accessor<number>
  muted: Accessor<boolean>
}

const HORIZONTAL_HEIGHT = 14
const WAVE_RADII = [3.0, 4.8, 6.6, 8.4]
const SPEAKER_END_X = 9.2
const MUTE_SLASH_END_X = 11.8
const STROKE_PADDING = 1.2

function clamp(value: number, min = 0, max = 1.25) {
  return Math.min(max, Math.max(min, value))
}

function countVisibleWaves(volume: number) {
  const clampedVolume = clamp(volume)

  if (clampedVolume <= 0) return 0
  if (clampedVolume <= 0.25) return 1
  if (clampedVolume <= 0.5) return 2
  if (clampedVolume <= 0.75) return 3
  return 4
}

function resolveHorizontalWidth(waveCount: number, isMuted: boolean) {
  const waveEndX = waveCount > 0
    ? 7.4 + WAVE_RADII[waveCount - 1] + STROKE_PADDING
    : SPEAKER_END_X

  const maxEndX = isMuted
    ? Math.max(waveEndX, MUTE_SLASH_END_X)
    : waveEndX

  return Math.ceil(maxEndX)
}

export default function AudioIndicator({ orientation, volume, muted }: Props) {
  const isVertical = orientation === "vertical"

  return (
    <drawingarea
      contentWidth={isVertical ? HORIZONTAL_HEIGHT : resolveHorizontalWidth(4, true)}
      contentHeight={isVertical ? resolveHorizontalWidth(4, true) : HORIZONTAL_HEIGHT}
      class="widget-audio-indicator"
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
      $={(self) => {
        createEffect(() => {
          const isMuted = muted()
          const waveCount = isMuted ? 0 : countVisibleWaves(volume())
          const horizontalWidth = resolveHorizontalWidth(waveCount, isMuted)

          self.set_content_width(isVertical ? HORIZONTAL_HEIGHT : horizontalWidth)
          self.set_content_height(isVertical ? horizontalWidth : HORIZONTAL_HEIGHT)
          self.queue_draw()
        })

        self.set_draw_func((area, context, _drawWidth, drawHeight) => {
          const style = area.get_style_context()
          const color = style.get_color()
          const isMuted = muted()
          const waveCount = isMuted ? 0 : countVisibleWaves(volume())
          const centerY = HORIZONTAL_HEIGHT / 2

          if (isVertical) {
            context.save()
            context.translate(0, drawHeight)
            context.rotate(-Math.PI / 2)
          }

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

          if (isVertical) {
            context.restore()
          }
        })
      }}
    />
  )
}
