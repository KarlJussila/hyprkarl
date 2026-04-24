type CornerPos = "top-left" | "top-right" | "bottom-left" | "bottom-right"

type Props = {
  position?: CornerPos
  size?: number
  radius?: number
  class?: string
}

/* An overengineered solution to concave curves with CSS-defined color */
export default function CornerCurve({
  position = "top-left",
  size = 12,
  radius = 12,
  class: className = ""
}: Props) {
  return (
    <drawingarea
      class={className}
      widthRequest={size}
      heightRequest={size}
      onRealize={(self) => {
        self.set_draw_func((area, cr, width, height) => {
          const ctx = area.get_style_context()
          const color = ctx.get_color()

          cr.setOperator(0)
          cr.paint()
          cr.setOperator(2)

          cr.setSourceRGBA(color.red, color.green, color.blue, color.alpha)

          switch (position) {
            case "top-left":
              cr.moveTo(0, 0)
              cr.lineTo(0, height)
              cr.curveTo(0, 0, radius * 0.6, 0, width, 0)
              break

            case "top-right":
              cr.moveTo(width, 0)
              cr.lineTo(width, height)
              cr.curveTo(width, 0, width - (radius * 0.6), 0, 0, 0)
              break

            case "bottom-right":
              cr.moveTo(width, height)
              cr.lineTo(width, 0)
              cr.curveTo(width, height, width - (radius * 0.6), height, 0, height)
              break

            case "bottom-left":
              cr.moveTo(0, height)
              cr.lineTo(0, 0)
              cr.curveTo(0, height, radius * 0.6, height, width, height)
              break
          }

          cr.closePath()
          cr.fill()
        })
      }}
    />
  )
}