import {
  composeObject,
  normalizeNonNegativeNumber,
  normalizePositiveNumber,
  normalizeStringValue,
} from "../widgets/shared/normalize.ts"
import { normalizeGlyph } from "./glyphNormalize.ts"

const normalizeGlyphs = composeObject({
  on: normalizeGlyph,
  off: normalizeGlyph,
})

export const normalizeSwitchMetrics = composeObject({
  thumbSize: normalizePositiveNumber,
  trackHeight: normalizePositiveNumber,
  trackLength: normalizePositiveNumber,
  thumbPadding: normalizeNonNegativeNumber,
  borderWidth: normalizeNonNegativeNumber,
  fontSize: normalizePositiveNumber,
  fontFamily: normalizeStringValue,
  glyphs: normalizeGlyphs,
})
