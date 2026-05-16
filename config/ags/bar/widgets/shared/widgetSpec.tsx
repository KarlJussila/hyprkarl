import { Gdk } from "ags/gtk4"
import { type BarPlacement } from "../../layout/placement.ts"

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

type WidgetSpecDefinition<TKind extends string, TRawConfig, TResolvedConfig, TDefaults> = {
  kind: TKind
  defaults: TDefaults
  resolve: (
    id: string,
    definition: TRawConfig,
    defaults: TDefaults,
  ) => TResolvedConfig
  render: (args: WidgetRenderArgs<TResolvedConfig>) => JSX.Element
}

export function createWidgetSpec<
  TKind extends string,
  TRawConfig,
  TResolvedConfig,
  TDefaults,
>(
  spec: WidgetSpecDefinition<TKind, TRawConfig, TResolvedConfig, TDefaults>,
): WidgetSpec<TKind, TRawConfig, TResolvedConfig> {
  return {
    kind: spec.kind,
    resolve(id, definition) {
      return spec.resolve(id, definition, spec.defaults)
    },
    render: spec.render,
  }
}
