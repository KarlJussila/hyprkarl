import { Accessor, createEffect } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import GLib from "gi://GLib"
import Pango from "gi://Pango"
import PangoCairo from "gi://PangoCairo"
import { type NormalizedSwitchMetrics } from "./switchTypes"
import { type BarOrientation } from "../layout/placement"
import { fontScaleFactor } from "../widgets/shared/drawScale.ts"

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
  tooltipText?: Accessor<string> | string
}

// metrics values are base pixel dimensions at font-size 12px; they scale with font size.
export default function Switch({
  class: className = "",
  hexpand = false,
  halign = Gtk.Align.CENTER,
  orientation,
  active,
  onToggle,
  glyph,
  metrics,
  tooltipText,
}: SwitchProps) {
  const isVertical = orientation === "vertical"
  let drawingArea!: Gtk.DrawingArea
  let pangoLayout: Pango.Layout | null = null
  let lastScale = -1

  let animationProgress = active() ? 1 : 0
  let animationTickId = 0

  const ANIMATION_DURATION_US = 140_000
  const easeOutCubic = (t: number) => t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2

  function contentSize(s: number) {
    const strokeInsetX = Math.max(s, Math.ceil(metrics.borderWidth * s / 2))
    const strokeInsetY = Math.max(s, Math.ceil(metrics.borderWidth * s / 2))
    const horizontalWidth = Math.ceil(
      (metrics.trackLength + metrics.thumbSize) * s + strokeInsetX * 2 - metrics.thumbPadding * s * 2,
    )
    const horizontalHeight = Math.ceil(
      Math.max(metrics.thumbSize, metrics.trackHeight) * s + strokeInsetY * 2,
    )
    return {
      totalWidth: isVertical ? horizontalHeight : horizontalWidth,
      totalHeight: isVertical ? horizontalWidth : horizontalHeight,
      horizontalWidth,
      horizontalHeight,
      strokeInsetX,
      strokeInsetY,
    }
  }

  const { totalWidth, totalHeight } = contentSize(1)

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
      valign={Gtk.Align.FILL}
      vexpand={false}
      onClicked={() => onToggle?.(!active())}
      $={tooltipText ? (self) => {
        if (typeof tooltipText === "string") {
          self.set_tooltip_text(tooltipText)
        } else {
          createEffect(() => self.set_tooltip_text(tooltipText()))
        }
      } : undefined}
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

          self.connect("realize", () => {
            const { totalWidth: w, totalHeight: h } = contentSize(fontScaleFactor(self))
            self.set_content_width(w)
            self.set_content_height(h)
          })

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
            const s = fontScaleFactor(area)

            if (s !== lastScale) {
              lastScale = s
              pangoLayout = null
            }

            const { horizontalWidth, horizontalHeight, strokeInsetX, strokeInsetY } = contentSize(s)

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
              strokeInsetX,
              horizontalWidth - metrics.thumbSize * s - strokeInsetX,
              animationProgress,
            )
            const thumbY = (horizontalHeight - metrics.thumbSize * s) / 2
            const trackX = strokeInsetX + (metrics.thumbSize * s / 2) - metrics.thumbPadding * s
            const trackY = (horizontalHeight - metrics.trackHeight * s) / 2

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
            drawRoundedRect(trackX, trackY, metrics.trackLength * s, metrics.trackHeight * s, metrics.trackHeight * s / 2)
            context.fillPreserve()

            if (metrics.borderWidth > 0) {
              context.setSourceRGBA(borderColor.red, borderColor.green, borderColor.blue, borderColor.alpha)
              context.setLineWidth(metrics.borderWidth * s)
              context.stroke()
            }

            context.setSourceRGBA(bg.red, bg.green, bg.blue, bg.alpha)
            drawRoundedRect(thumbX, thumbY, metrics.thumbSize * s, metrics.thumbSize * s, metrics.thumbSize * s / 2)
            context.fillPreserve()

            if (metrics.borderWidth > 0) {
              context.setLineWidth(metrics.borderWidth * s)
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
                  Pango.FontDescription.from_string(`${metrics.fontFamily} ${metrics.fontSize * s}`),
                )
                pangoLayout.set_alignment(Pango.Alignment.CENTER)
                pangoLayout.set_width(Math.ceil(metrics.thumbSize * s) * Pango.SCALE)
              }

              const [, logicalRect] = pangoLayout.get_pixel_extents()
              const glyphMetrics = logicalRect || { x: 0, y: 0, width: 0, height: 0 }
              const glyphCenterX = thumbX + (metrics.thumbSize * s / 2)
              const glyphCenterY = thumbY + (metrics.thumbSize * s / 2)
              const drawX = isVertical ? glyphCenterY : glyphCenterX
              const drawY = isVertical ? drawHeight - glyphCenterX : glyphCenterY

              context.setSourceRGBA(fg.red, fg.green, fg.blue, fg.alpha)
              context.moveTo(
                drawX - (glyphMetrics.width / 2) - glyphMetrics.x + metrics.glyphOffsetX * s,
                drawY - (glyphMetrics.height / 2) - glyphMetrics.y + metrics.glyphOffsetY * s,
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
