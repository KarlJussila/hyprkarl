import { Accessor, createEffect } from "ags"
import { Gtk } from "ags/gtk4"
import Pango from "gi://Pango"
import PangoCairo from "gi://PangoCairo"
import { type BarOrientation } from "../../layout/placement"
import type { NormalizedBatteryIndicatorMetrics } from "./types"
import { fontScaleFactor } from "../shared/drawScale.ts"

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

// metrics values are base pixel dimensions at font-size 12px; they scale with font size.
export default function BatteryIndicator({
  orientation,
  level,
  charging,
  lowThreshold,
  metrics,
}: Props) {
  const BASE_CANVAS_OFFSET_Y = 1
  const isVertical = orientation === "vertical"

  function contentSize(s: number) {
    const w = Math.ceil((metrics.width + metrics.terminalWidth * 2) * s)
    const h = Math.ceil((metrics.height + BASE_CANVAS_OFFSET_Y * 2) * s)
    return {
      totalWidth: isVertical ? h : w,
      totalHeight: isVertical ? w : h,
    }
  }

  const { totalWidth, totalHeight } = contentSize(1)

  return (
    <drawingarea
      contentWidth={totalWidth}
      contentHeight={totalHeight}
      class="widget-battery-indicator"
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
      $={(self) => {
        let pangoLayout: Pango.Layout | null = null
        let lastScale = -1

        self.connect("realize", () => {
          const s = fontScaleFactor(self)
          const { totalWidth: w, totalHeight: h } = contentSize(s)
          self.set_content_width(w)
          self.set_content_height(h)
        })

        createEffect(() => {
          level()
          charging?.()
          self.queue_draw()
        })

        self.set_draw_func((area, context, _width, drawHeight) => {
          const style = area.get_style_context()
          const s = fontScaleFactor(area)

          if (s !== lastScale) {
            lastScale = s
            pangoLayout = null
          }

          const getColor = (classString: string) => {
            style.save()

            classString.split(/\s+/).forEach((className) => {
              if (className) style.add_class(className)
            })

            const color = style.get_color()
            style.restore()
            return color
          }

          const bodyColor = getColor("battery-indicator-surface")
          const borderColor = getColor("battery-indicator-border")
          const fillColor = getColor("battery-indicator-fill")
          const lowColor = getColor("battery-indicator-fill is-low")
          const chargingColor = getColor("battery-indicator-fill is-charging")
          const glyphColor = getColor("battery-indicator-glyph")
          const clampedLevel = clamp(level())
          const isCharging = charging ? charging() : false
          const currentFillColor = clampedLevel <= lowThreshold
            ? lowColor
            : isCharging
              ? chargingColor
              : fillColor
          const bodyX = metrics.terminalWidth * s
          const bodyY = BASE_CANVAS_OFFSET_Y * s
          const tipHeight = Math.max(s, metrics.terminalHeight * s)
          const tipX = bodyX + metrics.width * s
          const tipY = bodyY + Math.floor((metrics.height * s - tipHeight) / 2)
          const innerInset = metrics.borderWidth * s
          const innerWidth = Math.max(0, metrics.width * s - innerInset * 2)
          const innerHeight = Math.max(0, metrics.height * s - innerInset * 2)
          const rawFillWidth = innerWidth * clampedLevel
          const minFillWidth = clampedLevel > 0 ? Math.max(s, metrics.borderWidth * s) : 0
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
            drawRoundedRect(bodyX, bodyY, metrics.width * s, metrics.height * s, 0)
            context.fill()
          }

          if (fillWidth > 0 && innerHeight > 0) {
            context.setSourceRGBA(
              currentFillColor.red,
              currentFillColor.green,
              currentFillColor.blue,
              currentFillColor.alpha,
            )
            drawRoundedRect(bodyX + innerInset, bodyY + innerInset, fillWidth, innerHeight, 0)
            context.fill()
          }

          context.setSourceRGBA(borderColor.red, borderColor.green, borderColor.blue, borderColor.alpha)
          context.setLineWidth(metrics.borderWidth * s)
          drawRoundedRect(bodyX, bodyY, metrics.width * s, metrics.height * s, 0)
          context.stroke()

          context.rectangle(tipX, tipY, metrics.terminalWidth * s, tipHeight)
          context.fill()

          if (isVertical) {
            context.restore()
          }

          if (isCharging) {
            if (!pangoLayout) {
              pangoLayout = PangoCairo.create_layout(context)
              pangoLayout.set_font_description(
                Pango.FontDescription.from_string(
                  `${metrics.chargingGlyphFontFamily} ${metrics.chargingGlyphFontSize * s}`,
                ),
              )
            }

            pangoLayout.set_text(metrics.chargingGlyph, -1)

            const [, logicalRect] = pangoLayout.get_pixel_extents()
            const glyphMetrics = logicalRect || { x: 0, y: 0, width: 0, height: 0 }
            const glyphCenterX = bodyX + (metrics.width * s / 2)
            const glyphCenterY = bodyY + (metrics.height * s / 2)
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
