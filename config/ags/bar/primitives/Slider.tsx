import { Accessor, createEffect } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import { type NormalizedSliderMetrics } from "./sliderTypes.ts"
import { type BarOrientation } from "../layout/placement.ts"

type SliderProps = {
  class?: string
  hexpand?: boolean
  halign?: Gtk.Align
  orientation: BarOrientation
  value: Accessor<number>
  min?: number
  max?: number
  onChange?: (next: number) => void
  metrics: NormalizedSliderMetrics
}

function clamp(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value))
}

export default function Slider({
  class: className = "",
  hexpand = false,
  halign = Gtk.Align.CENTER,
  orientation,
  value,
  min = 0,
  max = 1,
  onChange,
  metrics,
}: SliderProps) {
  const isVertical = orientation === "vertical"
  const strokeInset = Math.max(1, Math.ceil(metrics.borderWidth / 2))
  const startInset = Math.max(strokeInset, metrics.thumbVisible ? metrics.thumbWidth / 2 : 0)
  const horizontalWidth = Math.ceil(metrics.trackLength + (startInset * 2))
  const horizontalHeight = Math.ceil(
    Math.max(metrics.trackThickness, metrics.thumbVisible ? metrics.thumbHeight : 0) + (strokeInset * 2),
  )
  const totalWidth = isVertical ? horizontalHeight : horizontalWidth
  const totalHeight = isVertical ? horizontalWidth : horizontalHeight

  function normalizedValue() {
    const range = max - min
    if (range <= 0) return 0
    return clamp((value() - min) / range, 0, 1)
  }

  function drawRoundedRect(
    context: any,
    x: number,
    y: number,
    width: number,
    height: number,
    radius: number,
  ) {
    context.newPath()
    context.arc(x + width - radius, y + radius, radius, -Math.PI / 2, 0)
    context.arc(x + width - radius, y + height - radius, radius, 0, Math.PI / 2)
    context.arc(x + radius, y + height - radius, radius, Math.PI / 2, Math.PI)
    context.arc(x + radius, y + radius, radius, Math.PI, Math.PI * 1.5)
    context.closePath()
  }

  function valueFromPointer(
    x: number,
    y: number,
    width: number,
    height: number,
  ) {
    const axis = isVertical
      ? clamp((height - y) - startInset, 0, metrics.trackLength)
      : clamp(x - startInset, 0, metrics.trackLength)
    const ratio = metrics.trackLength > 0 ? axis / metrics.trackLength : 0
    return min + ((max - min) * ratio)
  }

  return (
    <drawingarea
      contentWidth={totalWidth}
      contentHeight={totalHeight}
      class={`widget-slider-control ${className}`.trim()}
      hexpand={hexpand}
      halign={halign}
      valign={Gtk.Align.CENTER}
      vexpand={false}
      $={(self) => {
        const click = new Gtk.GestureClick({
          button: Gdk.BUTTON_PRIMARY,
          propagationPhase: Gtk.PropagationPhase.CAPTURE,
        })
        const drag = new Gtk.GestureDrag({
          button: Gdk.BUTTON_PRIMARY,
          propagationPhase: Gtk.PropagationPhase.CAPTURE,
        })
        let dragStartX = 0
        let dragStartY = 0

        click.connect("pressed", (_gesture, _pressCount, x, y) => {
          onChange?.(valueFromPointer(x, y, self.get_width(), self.get_height()))
        })

        drag.connect("drag-begin", (_gesture, startX, startY) => {
          dragStartX = startX
          dragStartY = startY
          onChange?.(valueFromPointer(startX, startY, self.get_width(), self.get_height()))
        })

        drag.connect("drag-update", (_gesture, offsetX, offsetY) => {
          onChange?.(
            valueFromPointer(
              dragStartX + offsetX,
              dragStartY + offsetY,
              self.get_width(),
              self.get_height(),
            ),
          )
        })

        self.add_controller(click)
        self.add_controller(drag)

        createEffect(() => {
          value()
          self.queue_draw()
        })

        self.set_draw_func((area, context, _drawWidth, drawHeight) => {
          const style = area.get_style_context()

          const getColor = (classString: string) => {
            style.save()

            classString.split(/\s+/).forEach((currentClass) => {
              if (currentClass) style.add_class(currentClass)
            })

            const color = style.get_color()
            style.restore()
            return color
          }

          const trackColor = getColor("bar-slider-track")
          const fillColor = getColor("bar-slider-fill")
          const borderColor = getColor("bar-slider-border")
          const thumbColor = getColor("bar-slider-thumb")
          const thumbBorderColor = getColor("bar-slider-thumb-border")
          const trackX = startInset
          const trackY = (horizontalHeight - metrics.trackThickness) / 2
          const trackRadius = Math.min(metrics.trackRadius, metrics.trackThickness / 2, metrics.trackLength / 2)
          const currentNormalizedValue = normalizedValue()
          const fillWidth = metrics.trackLength * currentNormalizedValue
          const thumbCenterX = trackX + fillWidth
          const thumbX = thumbCenterX - (metrics.thumbWidth / 2)
          const thumbY = (horizontalHeight - metrics.thumbHeight) / 2
          const fillRadius = Math.min(metrics.fillRadius, metrics.trackThickness / 2, fillWidth / 2)
          const thumbRadius = Math.min(
            metrics.thumbRadius,
            metrics.thumbWidth / 2,
            metrics.thumbHeight / 2,
          )

          if (isVertical) {
            context.save()
            context.translate(0, drawHeight)
            context.rotate(-Math.PI / 2)
          }

          context.setSourceRGBA(trackColor.red, trackColor.green, trackColor.blue, trackColor.alpha)
          drawRoundedRect(context, trackX, trackY, metrics.trackLength, metrics.trackThickness, trackRadius)
          context.fillPreserve()

          if (metrics.borderWidth > 0) {
            context.setSourceRGBA(borderColor.red, borderColor.green, borderColor.blue, borderColor.alpha)
            context.setLineWidth(metrics.borderWidth)
            context.stroke()
          } else {
            context.newPath()
          }

          if (fillWidth > 0) {
            context.setSourceRGBA(fillColor.red, fillColor.green, fillColor.blue, fillColor.alpha)
            drawRoundedRect(
              context,
              trackX,
              trackY,
              fillWidth,
              metrics.trackThickness,
              fillRadius,
            )
            context.fill()
          }

          if (metrics.thumbVisible) {
            context.setSourceRGBA(thumbColor.red, thumbColor.green, thumbColor.blue, thumbColor.alpha)
            drawRoundedRect(
              context,
              thumbX,
              thumbY,
              metrics.thumbWidth,
              metrics.thumbHeight,
              thumbRadius,
            )
            context.fillPreserve()

            if (metrics.borderWidth > 0) {
              context.setSourceRGBA(
                thumbBorderColor.red,
                thumbBorderColor.green,
                thumbBorderColor.blue,
                thumbBorderColor.alpha,
              )
              context.setLineWidth(metrics.borderWidth)
              context.stroke()
            }
          }

          if (isVertical) {
            context.restore()
          }
        })
      }}
    />
  )
}
