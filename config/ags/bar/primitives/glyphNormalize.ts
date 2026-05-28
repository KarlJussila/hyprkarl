import {
  composeObject,
  fail,
  normalizeStringValue,
  type FieldNormalizer,
  type ValidationContext,
} from "../widgets/shared/normalize.ts"

export type NormalizedGlyph = {
  glyph: string
  glyphOffset: [number, number]
}

function normalizeGlyphOffset(
  ctx: ValidationContext,
  value: [number, number] | undefined,
  fallback: [number, number],
): [number, number] {
  if (value === undefined) return fallback
  if (!Array.isArray(value) || value.length !== 2 || !Number.isFinite(value[0]) || !Number.isFinite(value[1])) {
    fail(ctx, "must be a [x, y] pair of finite numbers")
  }
  return [value[0], value[1]]
}

export const glyphOffsetNormalizer: FieldNormalizer<[number, number], [number, number]> = normalizeGlyphOffset

export const normalizeGlyph = composeObject({
  glyph: normalizeStringValue,
  glyphOffset: glyphOffsetNormalizer,
})
