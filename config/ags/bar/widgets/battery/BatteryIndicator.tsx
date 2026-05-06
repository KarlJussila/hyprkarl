import { Accessor, createEffect } from "ags"
import { Gtk } from "ags/gtk4"
import Pango from "gi://Pango"
import PangoCairo from "gi://PangoCairo"
import {
  type NormalizedBatteryIndicatorMetrics,
} from "../../configuration"
import { type BarOrientation } from "../../layout/placement"

function clamp(value: number, min = 0, max = 1) {
  return Math.min(max, Math.max(min, value))
}

type Props = {
  orientation: BarOrientation
  level: Accessor<number>
  charging?: Accessor<boolean>
  lowThreshold: number
  metrics: NormalizedBatteryIndicatorMetrics
}

export default function BatteryIndicator({
  orientation,
  level,
  charging,
  lowThreshold,
  metrics,
}: Props) {
  const CANVAS_MARGIN = 2
  const isVertical = orientation === "vertical"
  const horizontalWidth = metrics.width + (metrics.terminalWidth * 2) + (CANVAS_MARGIN * 2)
  const horizontalHeight = metrics.height + (CANVAS_MARGIN * 2)
  const totalWidth = isVertical ? horizontalHeight : horizontalWidth
  const totalHeight = isVertical ? horizontalWidth : horizontalHeight

  return (
    <drawingarea
      contentWidth={totalWidth}
      contentHeight={totalHeight}
      class="battery-indicator"
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
      $={(self) => {
        let pangoLayout: Pango.Layout | null = null

        createEffect(() => {
          level()
          charging?.()
          self.queue_draw()
        })

        self.set_draw_func((area, context, _width, drawHeight) => {
          const style = area.get_style_context()

          // Battery visuals are drawn manually, but the colors still come from CSS so
          // theme.scss remains the high-level appearance entrypoint for the whole bar.
          const getColor = (classString: string) => {
            style.save()

            classString.split(/\s+/).forEach((className) => {
              if (className) style.add_class(className)
            })

            const color = style.get_color()
            style.restore()
            return color
          }

          const bodyColor = getColor("battery-body")
          const borderColor = getColor("battery-border")
          const fillColor = getColor("battery-fill")
          const lowColor = getColor("battery-fill low")
          const chargingColor = getColor("battery-fill charging")
          const glyphColor = getColor("battery-glyph")
          const clampedLevel = clamp(level())
          const isCharging = charging ? charging() : false
          const currentFillColor = clampedLevel <= lowThreshold
            ? lowColor
            : isCharging
              ? chargingColor
              : fillColor
          const bodyX = CANVAS_MARGIN + metrics.terminalWidth
          const bodyY = CANVAS_MARGIN
          const tipHeight = Math.max(
            metrics.borderWidth + 1,
            Math.floor(metrics.height * metrics.terminalHeightRatio),
          )
          const tipX = bodyX + metrics.width
          const tipY = bodyY + Math.floor((metrics.height - tipHeight) / 2)
          const innerInset = metrics.borderWidth
          const innerWidth = Math.max(0, metrics.width - (innerInset * 2))
          const innerHeight = Math.max(0, metrics.height - (innerInset * 2))
          const rawFillWidth = innerWidth * clampedLevel
          const minFillWidth = clampedLevel > 0 ? Math.max(1, metrics.borderWidth) : 0
          const fillWidth = Math.min(innerWidth, Math.max(minFillWidth, rawFillWidth))

          const drawRoundedRect = (x: number, y: number, width: number, height: number, radius: number) => {
            context.newPath()
            context.arc(x + width - radius, y + radius, radius, -Math.PI / 2, 0)
            context.arc(x + width - radius, y + height - radius, radius, 0, Math.PI / 2)
            context.arc(x + radius, y + height - radius, radius, Math.PI / 2, Math.PI)
            context.arc(x + radius, y + radius, radius, Math.PI, Math.PI * 1.5)
            context.closePath()
          }

          if (isVertical) {
            context.save()
            context.translate(0, drawHeight)
            context.rotate(-Math.PI / 2)
          }

          if (bodyColor.alpha > 0.01) {
            context.setSourceRGBA(bodyColor.red, bodyColor.green, bodyColor.blue, bodyColor.alpha)
            drawRoundedRect(bodyX, bodyY, metrics.width, metrics.height, 0)
            context.fill()
          }

          if (fillWidth > 0 && innerHeight > 0) {
            context.setSourceRGBA(
              currentFillColor.red,
              currentFillColor.green,
              currentFillColor.blue,
              currentFillColor.alpha,
            )
            drawRoundedRect(
              bodyX + innerInset,
              bodyY + innerInset,
              fillWidth,
              innerHeight,
              0,
            )
            context.fill()
          }

          context.setSourceRGBA(borderColor.red, borderColor.green, borderColor.blue, borderColor.alpha)
          context.setLineWidth(metrics.borderWidth)
          drawRoundedRect(bodyX, bodyY, metrics.width, metrics.height, 0)
          context.stroke()

          context.rectangle(tipX, tipY, metrics.terminalWidth, tipHeight)
          context.fill()

          if (isVertical) {
            context.restore()
          }

          if (isCharging) {
            if (!pangoLayout) {
              pangoLayout = PangoCairo.create_layout(context)
              pangoLayout.set_font_description(
                Pango.FontDescription.from_string(
                  `${metrics.chargingGlyphFontFamily} ${metrics.chargingGlyphFontSize}`,
                ),
              )
            }

            pangoLayout.set_text(metrics.chargingGlyph, -1)

            const [, logicalRect] = pangoLayout.get_pixel_extents()
            const glyphMetrics = logicalRect || { x: 0, y: 0, width: 0, height: 0 }
            const glyphCenterX = bodyX + (metrics.width / 2)
            const glyphCenterY = bodyY + (metrics.height / 2)
            const drawX = isVertical ? glyphCenterY : glyphCenterX
            const drawY = isVertical ? drawHeight - glyphCenterX : glyphCenterY

            context.setSourceRGBA(glyphColor.red, glyphColor.green, glyphColor.blue, glyphColor.alpha)
            context.moveTo(
              drawX - (glyphMetrics.width / 2) - glyphMetrics.x,
              drawY - (glyphMetrics.height / 2) - glyphMetrics.y,
            )
            PangoCairo.show_layout(context, pangoLayout)
          }
        })
      }}
    />
  )
}

