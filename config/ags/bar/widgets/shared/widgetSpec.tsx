import { Gdk } from "ags/gtk4"
import { type BarPlacement } from "../../layout/placement.ts"
import { widgetContext, type ValidationContext } from "./normalize.ts"

export type FieldNormalizer<TRaw, TResolved = TRaw> = (
  ctx: ValidationContext,
  val: TRaw | undefined,
  fallback: TResolved,
) => TResolved

export type WidgetConfig<TKind extends string, TProps extends object = Record<string, never>> = {
  kind: TKind
} & TProps

export type WidgetRenderArgs<TConfig> = {
  id: string
  config: TConfig
  placement: BarPlacement
  monitor: Gdk.Monitor
}

export type WidgetSpec<TKind extends string, TRawConfig, TResolvedConfig> = {
  kind: TKind
  resolve: (id: string, definition: TRawConfig) => TResolvedConfig
  render: (args: WidgetRenderArgs<TResolvedConfig>) => JSX.Element
}

type WidgetSchema = Record<string, FieldNormalizer<any, any>>

type InferResolvedConfig<TKind extends string, TSchema extends WidgetSchema> = {
  kind: TKind
} & {
  [K in keyof TSchema]: TSchema[K] extends FieldNormalizer<any, infer TResolved>
    ? TResolved
    : never
}

type InferRawConfig<TKind extends string, TSchema extends WidgetSchema> = WidgetConfig<
  TKind,
  {
    [K in keyof TSchema]?: TSchema[K] extends FieldNormalizer<infer TRaw, any> ? TRaw : never
  }
>

export function createWidgetSpec<
  TKind extends string,
  TSchema extends WidgetSchema,
  TDefaults,
>(spec: {
  kind: TKind
  defaults: TDefaults
  schema: TSchema
  render: (args: WidgetRenderArgs<InferResolvedConfig<TKind, TSchema>>) => JSX.Element
}): WidgetSpec<TKind, InferRawConfig<TKind, TSchema>, InferResolvedConfig<TKind, TSchema>>

export function createWidgetSpec<
  TKind extends string,
  TRaw,
  TResolved,
  TDefaults,
>(spec: {
  kind: TKind
  defaults: TDefaults
  resolve: (id: string, definition: TRaw, defaults: TDefaults) => TResolved
  render: (args: WidgetRenderArgs<TResolved>) => JSX.Element
}): WidgetSpec<TKind, TRaw, TResolved>

export function createWidgetSpec(spec: any): any {
  if ("schema" in spec) {
    return {
      kind: spec.kind,
      resolve(id: string, definition: Record<string, unknown>) {
        const resolved: Record<string, unknown> = { kind: spec.kind }
        for (const [field, normalizer] of Object.entries(spec.schema)) {
          resolved[field] = (normalizer as FieldNormalizer<unknown, unknown>)(
            widgetContext(id, field),
            definition[field],
            (spec.defaults as Record<string, unknown>)[field],
          )
        }
        return resolved
      },
      render: spec.render,
    }
  }
  return {
    kind: spec.kind,
    resolve(id: string, definition: unknown) {
      return spec.resolve(id, definition, spec.defaults)
    },
    render: spec.render,
  }
}
