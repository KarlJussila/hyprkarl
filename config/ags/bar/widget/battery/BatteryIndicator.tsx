import { Accessor, createEffect } from "ags"
import { Gtk } from "ags/gtk4"
import Pango from "gi://Pango"
import PangoCairo from "gi://PangoCairo"
import { type BarOrientation } from "../../barPlacement"

function clamp(value: number, min = 0, max = 1) {
  return Math.min(max, Math.max(min, value))
}

type Props = {
  orientation?: BarOrientation
  level: Accessor<number>
  charging?: Accessor<boolean>
  width?: number
  height?: number
  borderWidth?: number
  lowThreshold?: number
  terminalWidth?: number
  terminalHeightRatio?: number
}

export default function BatteryIndicator({
  orientation = "horizontal",
  level,
  charging,
  width = 16,
  height = 10,
  borderWidth = 2,
  lowThreshold = 0.15,
  terminalWidth = 3,
  terminalHeightRatio = 0.4,
}: Props) {
  const CANVAS_MARGIN = 2
  const isVertical = orientation === "vertical"
  const horizontalWidth = width + (terminalWidth * 2) + (CANVAS_MARGIN * 2)
  const horizontalHeight = height + (CANVAS_MARGIN * 2)
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

          const bodyX = CANVAS_MARGIN + terminalWidth
          const bodyY = CANVAS_MARGIN
          const bodyWidth = width
          const bodyHeight = height
          const tipHeight = Math.max(6, Math.floor(height * terminalHeightRatio))
          const tipX = bodyX + bodyWidth
          const tipY = bodyY + Math.floor((height - tipHeight) / 2)

          const innerInset = borderWidth
          const innerWidth = Math.max(0, bodyWidth - (innerInset * 2))
          const innerHeight = Math.max(0, bodyHeight - (innerInset * 2))
          const rawFillWidth = innerWidth * clampedLevel
          const minFillWidth = clampedLevel > 0 ? Math.max(1, borderWidth) : 0
          const fillWidth = Math.min(innerWidth, Math.max(minFillWidth, rawFillWidth))

          const radius = 0

          const drawRoundedRect = (x: number, y: number, rectWidth: number, rectHeight: number, rectRadius: number) => {
            context.newPath()
            context.arc(x + rectWidth - rectRadius, y + rectRadius, rectRadius, -Math.PI / 2, 0)
            context.arc(x + rectWidth - rectRadius, y + rectHeight - rectRadius, rectRadius, 0, Math.PI / 2)
            context.arc(x + rectRadius, y + rectHeight - rectRadius, rectRadius, Math.PI / 2, Math.PI)
            context.arc(x + rectRadius, y + rectRadius, rectRadius, Math.PI, Math.PI * 1.5)
            context.closePath()
          }

          if (isVertical) {
            context.save()
            context.translate(0, drawHeight)
            context.rotate(-Math.PI / 2)
          }

          if (bodyColor.alpha > 0.01) {
            context.setSourceRGBA(bodyColor.red, bodyColor.green, bodyColor.blue, bodyColor.alpha)
            drawRoundedRect(bodyX, bodyY, bodyWidth, bodyHeight, radius)
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
              radius,
            )
            context.fill()
          }

          context.setSourceRGBA(borderColor.red, borderColor.green, borderColor.blue, borderColor.alpha)
          context.setLineWidth(borderWidth)
          drawRoundedRect(bodyX, bodyY, bodyWidth, bodyHeight, radius)
          context.stroke()

          context.rectangle(tipX, tipY, terminalWidth, tipHeight)
          context.fill()

          if (isVertical) {
            context.restore()
          }

          if (isCharging) {
            if (!pangoLayout) {
              pangoLayout = PangoCairo.create_layout(context)
              pangoLayout.set_font_description(Pango.FontDescription.from_string("JetBrains Mono Nerd Font Propo 8"))
            }

            pangoLayout.set_text("󱐋", -1)

            const [, logicalRect] = pangoLayout.get_pixel_extents()
            const metrics = logicalRect || { x: 0, y: 0, width: 0, height: 0 }
            const glyphCenterX = bodyX + (bodyWidth / 2)
            const glyphCenterY = bodyY + (bodyHeight / 2)

            const drawX = isVertical
              ? glyphCenterY
              : glyphCenterX
            const drawY = isVertical
              ? drawHeight - glyphCenterX
              : glyphCenterY

            context.setSourceRGBA(glyphColor.red, glyphColor.green, glyphColor.blue, glyphColor.alpha)
            context.moveTo(
              drawX - (metrics.width / 2) - metrics.x,
              drawY - (metrics.height / 2) - metrics.y,
            )
            PangoCairo.show_layout(context, pangoLayout)
          }
        })
      }}
    />
  )
}
