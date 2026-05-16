import { Accessor, createEffect } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import GLib from "gi://GLib"
import Pango from "gi://Pango"
import PangoCairo from "gi://PangoCairo"
import { type NormalizedSwitchMetrics } from "./switchTypes"
import { type BarOrientation } from "../layout/placement"

function interpolate(start: number, end: number, factor: number) {
  return start + (end - start) * factor
}

function interpolateRGBA(start: Gdk.RGBA, end: Gdk.RGBA, factor: number): Gdk.RGBA {
  return new Gdk.RGBA({
    red: interpolate(start.red, end.red, factor),
    green: interpolate(start.green, end.green, factor),
    blue: interpolate(start.blue, end.blue, factor),
    alpha: interpolate(start.alpha, end.alpha, factor),
  })
}

type SwitchProps = {
  class?: string
  hexpand?: boolean
  halign?: Gtk.Align
  orientation: BarOrientation
  active: Accessor<boolean>
  onToggle?: (next: boolean) => void
  glyph: string
  metrics: NormalizedSwitchMetrics
}

export default function Switch({
  class: className = "",
  hexpand = false,
  halign = Gtk.Align.CENTER,
  orientation,
  active,
  onToggle,
  glyph,
  metrics,
}: SwitchProps) {
  const isVertical = orientation === "vertical"
  let drawingArea!: Gtk.DrawingArea
  let pangoLayout: Pango.Layout | null = null

  let animationProgress = active() ? 1 : 0
  let animationTickId = 0

  const ANIMATION_DURATION_US = 140_000
  const STROKE_INSET_X = Math.max(1, Math.ceil(metrics.borderWidth / 2))
  const STROKE_INSET_Y = Math.max(1, Math.ceil(metrics.borderWidth / 2))
  const horizontalWidth = Math.ceil(
    metrics.trackLength + metrics.thumbSize + (STROKE_INSET_X * 2) - (metrics.thumbPadding * 2),
  )
  const horizontalHeight = Math.ceil(
    Math.max(metrics.thumbSize, metrics.trackHeight) + (STROKE_INSET_Y * 2),
  )
  const totalWidth = isVertical ? horizontalHeight : horizontalWidth
  const totalHeight = isVertical ? horizontalWidth : horizontalHeight
  const easeOutCubic = (t: number) => t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2

  function runAnimation(target: number) {
    if (!drawingArea) return
    const startValue = animationProgress
    const startTime = GLib.get_monotonic_time()

    if (animationTickId) drawingArea.remove_tick_callback(animationTickId)

    animationTickId = drawingArea.add_tick_callback(() => {
      const elapsed = GLib.get_monotonic_time() - startTime
      const normalizedTime = Math.min(1, elapsed / ANIMATION_DURATION_US)

      animationProgress = interpolate(startValue, target, easeOutCubic(normalizedTime))
      drawingArea.queue_draw()

      if (normalizedTime >= 1) {
        animationTickId = 0
        return false
      }

      return true
    })
  }

  return (
    <button
      class={`widget-button widget-switch-button ${className}`.trim()}
      hexpand={hexpand}
      halign={halign}
      valign={Gtk.Align.CENTER}
      vexpand={false}
      onClicked={() => onToggle?.(!active())}
    >
      <drawingarea
        contentWidth={totalWidth}
        contentHeight={totalHeight}
        class={active() ? "switch-control is-active" : "switch-control"}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
        vexpand={false}
        $={(self) => {
          drawingArea = self

          createEffect(() => {
            if (active()) {
              self.add_css_class("active")
              runAnimation(1)
            } else {
              self.remove_css_class("active")
              runAnimation(0)
            }
          })

          self.set_draw_func((area, context, _drawWidth, drawHeight) => {
            const style = area.get_style_context()

            // Custom-drawn widgets still read colors from CSS so theme.scss remains
            // the single place to adjust the bar's appearance.
            const getColor = (classString: string) => {
              style.save()

              classString.split(/\s+/).forEach((className) => {
                if (className) style.add_class(className)
              })

              const color = style.get_color()
              style.restore()
              return color
            }

            const bg = getColor("switch-surface")
            const fg = getColor("switch-glyph")
            const trackOff = getColor("switch-track")
            const trackOn = getColor("switch-track is-active")
            const borderOff = getColor("switch-border")
            const borderOn = getColor("switch-border is-active")
            const trackColor = interpolateRGBA(trackOff, trackOn, animationProgress)
            const borderColor = interpolateRGBA(borderOff, borderOn, animationProgress)
            const thumbX = interpolate(
              STROKE_INSET_X,
              horizontalWidth - metrics.thumbSize - STROKE_INSET_X,
              animationProgress,
            )
            const thumbY = (horizontalHeight - metrics.thumbSize) / 2
            const trackX = STROKE_INSET_X + (metrics.thumbSize / 2) - metrics.thumbPadding
            const trackY = (horizontalHeight - metrics.trackHeight) / 2

            const drawRoundedRect = (x: number, y: number, width: number, height: number, radius: number) => {
              context.newPath()
              context.arc(x + width - radius, y + radius, radius, -Math.PI / 2, 0)
              context.arc(x + width - radius, y + height - radius, radius, 0, Math.PI / 2)
              context.arc(x + radius, y + height - radius, radius, Math.PI / 2, Math.PI)
              context.arc(x + radius, y + radius, radius, Math.PI, Math.PI * 1.5)
              context.closePath()
            }

            if (bg.alpha > 0.01) {
              context.setSourceRGBA(bg.red, bg.green, bg.blue, bg.alpha)
              context.paint()
            }

            if (isVertical) {
              context.save()
              context.translate(0, drawHeight)
              context.rotate(-Math.PI / 2)
            }

            context.setSourceRGBA(trackColor.red, trackColor.green, trackColor.blue, trackColor.alpha)
            drawRoundedRect(trackX, trackY, metrics.trackLength, metrics.trackHeight, metrics.trackHeight / 2)
            context.fillPreserve()

            if (metrics.borderWidth > 0) {
              context.setSourceRGBA(borderColor.red, borderColor.green, borderColor.blue, borderColor.alpha)
              context.setLineWidth(metrics.borderWidth)
              context.stroke()
            }

            context.setSourceRGBA(bg.red, bg.green, bg.blue, bg.alpha)
            drawRoundedRect(thumbX, thumbY, metrics.thumbSize, metrics.thumbSize, metrics.thumbSize / 2)
            context.fillPreserve()

            if (metrics.borderWidth > 0) {
              context.setLineWidth(metrics.borderWidth)
              context.setSourceRGBA(borderColor.red, borderColor.green, borderColor.blue, borderColor.alpha)
              context.stroke()
            }

            if (isVertical) {
              context.restore()
            }

            if (glyph) {
              if (!pangoLayout) {
                pangoLayout = PangoCairo.create_layout(context)
                pangoLayout.set_text(glyph, -1)
                pangoLayout.set_font_description(
                  Pango.FontDescription.from_string(`${metrics.fontFamily} ${metrics.fontSize}`),
                )
                pangoLayout.set_alignment(Pango.Alignment.CENTER)
                pangoLayout.set_width(metrics.thumbSize * Pango.SCALE)
              }

              const [, logicalRect] = pangoLayout.get_pixel_extents()
              const glyphMetrics = logicalRect || { x: 0, y: 0, width: 0, height: 0 }
              const glyphCenterX = thumbX + (metrics.thumbSize / 2)
              const glyphCenterY = thumbY + (metrics.thumbSize / 2)
              const drawX = isVertical ? glyphCenterY : glyphCenterX
              const drawY = isVertical ? drawHeight - glyphCenterX : glyphCenterY

              context.setSourceRGBA(fg.red, fg.green, fg.blue, fg.alpha)
              context.moveTo(
                drawX - (glyphMetrics.width / 2) - glyphMetrics.x + metrics.glyphOffsetX,
                drawY - (glyphMetrics.height / 2) - glyphMetrics.y + metrics.glyphOffsetY,
              )
              PangoCairo.show_layout(context, pangoLayout)
            }
          })

          self.connect("destroy", () => {
            if (animationTickId) self.remove_tick_callback(animationTickId)
          })
        }}
      />
    </button>
  )
}
