import { Gtk, Gdk } from "ags/gtk4"
import GLib from "gi://GLib"
import Pango from "gi://Pango"
import PangoCairo from "gi://PangoCairo"
import { Accessor, createEffect } from "ags"
import { type BarOrientation } from "../barPlacement"

function interpolate(start: number, end: number, factor: number) {
  return start + (end - start) * factor
}

function interpolateRGBA(start: Gdk.RGBA, end: Gdk.RGBA, factor: number): Gdk.RGBA {
  return new Gdk.RGBA({
    red:   interpolate(start.red,   end.red,   factor),
    green: interpolate(start.green, end.green, factor),
    blue:  interpolate(start.blue,  end.blue,  factor),
    alpha: interpolate(start.alpha, end.alpha, factor),
  })
}

type SwitchProps = {
  class?: string
  hexpand?: boolean
  halign?: Gtk.Align
  orientation?: BarOrientation
  active: Accessor<boolean>
  onToggle?: (next: boolean) => void
  glyph?: string
  thumbSize?: number
  trackHeight?: number
  trackLength?: number
  thumbPadding?: number
  glyphOffsetX?: number
  glyphOffsetY?: number
  borderWidth?: number
  fontSize?: number
  fontFamily?: string
}

export default function Switch({
  class: className = "",
  hexpand = false,
  halign = Gtk.Align.CENTER,
  orientation = "horizontal",
  active,
  onToggle,
  glyph = "",
  thumbSize = 16,
  trackHeight = 12,
  trackLength = 24,
  thumbPadding = 7,
  glyphOffsetX = 0,
  glyphOffsetY = 0,
  borderWidth = 2,
  fontSize = 8,
  fontFamily = "JetBrains Mono Nerd Font Propo"
}: SwitchProps) {
  const isVertical = orientation === "vertical"
  let drawingArea!: Gtk.DrawingArea
  let pangoLayout: Pango.Layout | null = null
  
  let animationProgress = active() ? 1 : 0
  let animationTickId = 0

  const ANIMATION_DURATION_US = 140_000
  const CANVAS_MARGIN = 2
  
  const horizontalWidth = Math.ceil(trackLength + thumbSize + (CANVAS_MARGIN * 2) - (thumbPadding * 2))
  const horizontalHeight = Math.ceil(Math.max(thumbSize, trackHeight) + CANVAS_MARGIN * 2)
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
      class={`switch-button ${className}`.trim()}
      hexpand={hexpand}
      halign={halign}
      onClicked={() => onToggle?.(!active())}
    >
      <drawingarea
        contentWidth={totalWidth}
        contentHeight={totalHeight}
        class={active() ? "switch active" : "switch"}
        halign={Gtk.Align.CENTER}
        $={(self) => {
          drawingArea = self

          // React to active/inactive state
          createEffect(() => {
            if (active()) {
              self.add_css_class("active")
              runAnimation(1)
            } else {
              self.remove_css_class("active")
              runAnimation(0)
            }
          })

          /* MAIN DRAWING FUNCTION */
          self.set_draw_func((area, context, drawWidth, drawHeight) => {
            const style = area.get_style_context()

            // Evil color fetching hack
            const getColor = (classString: string) => {
              style.save()

              classString.split(/\s+/).forEach(c => {
                if (c) style.add_class(c)
              })

              const color = style.get_color()
              style.restore()
              return color
            }

            // Getting colors from CSS
            const bg = getColor("switch-bg")
            const fg = getColor("switch-fg")
            const trackOff = getColor("switch-track")
            const trackOn = getColor("switch-track active")
            const borderOff = getColor("switch-border")
            const borderOn = getColor("switch-border active")

            // Interpolated values
            const trackColor = interpolateRGBA(trackOff, trackOn, animationProgress)
            const borderColor = interpolateRGBA(borderOff, borderOn, animationProgress)
            
            const thumbX = interpolate(CANVAS_MARGIN, horizontalWidth - thumbSize - CANVAS_MARGIN, animationProgress)
            const thumbY = (horizontalHeight - thumbSize) / 2
            const trackX = CANVAS_MARGIN + (thumbSize / 2) - thumbPadding
            const trackY = (horizontalHeight - trackHeight) / 2

            const drawRoundedRect = (x: number, y: number, w: number, h: number, r: number) => {
              context.newPath()
              context.arc(x + w - r, y + r, r, -Math.PI / 2, 0)
              context.arc(x + w - r, y + h - r, r, 0, Math.PI / 2)
              context.arc(x + r, y + h - r, r, Math.PI / 2, Math.PI)
              context.arc(x + r, y + r, r, Math.PI, Math.PI * 1.5)
              context.closePath()
            }

            // Canvas Background
            if (bg.alpha > 0.01) {
              context.setSourceRGBA(bg.red, bg.green, bg.blue, bg.alpha)
              context.paint()
            }

            if (isVertical) {
              context.save()
              context.translate(0, drawHeight)
              context.rotate(-Math.PI / 2)
            }

            // Draw Track
            context.setSourceRGBA(trackColor.red, trackColor.green, trackColor.blue, trackColor.alpha)
            drawRoundedRect(trackX, trackY, trackLength, trackHeight, trackHeight / 2)
            context.fillPreserve()
            
            // Track Border
            if (borderWidth > 0) {
              context.setSourceRGBA(borderColor.red, borderColor.green, borderColor.blue, borderColor.alpha)
              context.setLineWidth(borderWidth)
              context.stroke()
            }

            // Draw Thumb
            context.setSourceRGBA(bg.red, bg.green, bg.blue, bg.alpha)
            drawRoundedRect(thumbX, thumbY, thumbSize, thumbSize, thumbSize / 2)
            context.fillPreserve()

            // Thumb Border
            if (borderWidth > 0) {
              context.setLineWidth(borderWidth)
              context.setSourceRGBA(borderColor.red, borderColor.green, borderColor.blue, borderColor.alpha)
              context.stroke()
            }

            if (isVertical) {
              context.restore()
            }

            // Render Glyph
            if (glyph) {
              if (!pangoLayout) {
                pangoLayout = PangoCairo.create_layout(context)
                pangoLayout.set_text(glyph, -1)
                pangoLayout.set_font_description(Pango.FontDescription.from_string(`${fontFamily} ${fontSize}`))
                pangoLayout.set_alignment(Pango.Alignment.CENTER)
                pangoLayout.set_width(thumbSize * Pango.SCALE)
              }
              const [, logicalRect] = pangoLayout.get_pixel_extents()
              const metrics = logicalRect || { x: 0, y: 0, width: 0, height: 0 }
              const glyphCenterX = thumbX + (thumbSize / 2)
              const glyphCenterY = thumbY + (thumbSize / 2)
              const drawX = isVertical
                ? glyphCenterY
                : glyphCenterX
              const drawY = isVertical
                ? drawHeight - glyphCenterX
                : glyphCenterY
              
              context.setSourceRGBA(fg.red, fg.green, fg.blue, fg.alpha)
              context.moveTo(
                drawX - (metrics.width / 2) - metrics.x + glyphOffsetX,
                drawY - (metrics.height / 2) - metrics.y + glyphOffsetY,
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
