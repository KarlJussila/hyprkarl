import type {
  FlyoutAlign,
} from "./flyoutTypes.ts"
import {
  composeObject,
  fail,
  normalizeNonNegativeNumber,
  type FieldNormalizer,
  type ValidationContext,
} from "../widgets/shared/normalize.ts"

export function normalizeFlyoutAlign(
  context: ValidationContext,
  value: FlyoutAlign | undefined,
  fallback: FlyoutAlign,
): FlyoutAlign {
  const align = value ?? fallback
  if (align !== "start" && align !== "center" && align !== "end") {
    fail(context, 'must be "start", "center", or "end"')
  }
  return align
}

const flyoutAlignNormalizer: FieldNormalizer<FlyoutAlign, FlyoutAlign> = normalizeFlyoutAlign

export const normalizeFlyoutConfig = composeObject({
  align: flyoutAlignNormalizer,
  gap: normalizeNonNegativeNumber,
})
