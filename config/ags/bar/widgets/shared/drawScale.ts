import Pango from "gi://Pango"
import PangoCairo from "gi://PangoCairo"

// Returns a scale factor by reading the CSS font size from the widget's Pango context.
// Multiply custom-drawn geometry base values by this so changing $font-size in
// theme.scss scales those elements alongside the rest of the bar.
export function fontScaleFactor(widget: { get_pango_context(): Pango.Context }, basePx = 12): number {
  const pangoCtx = widget.get_pango_context()
  const fontDesc = pangoCtx.get_font_description()
  if (!fontDesc) return 1

  const rawSize = fontDesc.get_size()
  if (rawSize <= 0) return 1

  if (fontDesc.get_size_is_absolute()) {
    return (rawSize / Pango.SCALE) / basePx
  }

  // get_size() is in PANGO_SCALE-ths of a point; convert to device pixels via DPI.
  const ptSize = rawSize / Pango.SCALE
  const dpi = PangoCairo.context_get_resolution(pangoCtx)
  const effectiveDpi = dpi > 0 ? dpi : 96
  return (ptSize * (effectiveDpi / 72)) / basePx
}
