import {
  BAR_WIDGETS_SOURCE_FILE,
} from "../configError.ts"
import type {
  BarEdge,
  BarLayoutConfig,
  ResolvedBarConfiguration,
} from "../configuration.ts"
import type {
  BarWidgetDefinitions,
  WidgetKind,
} from "./catalog.ts"
import {
  fail,
  isRecord,
  layoutContext,
  normalizeBarEdge,
  normalizeBoolean,
  normalizeLayoutWidgetId,
  normalizeOptionalLayoutWidgetId,
  indexContext,
} from "./shared/normalize.ts"
import { widgetCatalog } from "./catalog.ts"

type LayoutReference = {
  path: string
  widgetId: string
}

type ResolvedLayoutConfig = ResolvedBarConfiguration["layout"] & {
  edge: BarEdge
  showCornerCurves: boolean
  autohide: boolean
  exclusive: boolean
}

function normalizeLayoutIdList(path: string, value: unknown) {
  const context = layoutContext(path)
  if (!Array.isArray(value)) {
    fail(context, "must be an array of widget IDs")
  }

  return value.map((widgetId, index) => normalizeLayoutWidgetId(indexContext(context, index), widgetId))
}

function normalizeLayoutConfig(layoutConfig: BarLayoutConfig): ResolvedLayoutConfig {
  const rawLayout = layoutConfig as unknown
  if (!isRecord(rawLayout)) {
    fail(layoutContext(""), "must export a layout object")
  }

  const centerLayout = rawLayout.center
  if (!isRecord(centerLayout)) {
    fail(layoutContext("center"), "must be an object")
  }

  const autohide = normalizeBoolean(layoutContext("autohide"), rawLayout.autohide, false)
  const exclusive = normalizeBoolean(layoutContext("exclusive"), rawLayout.exclusive, !autohide)

  return {
    edge: normalizeBarEdge(rawLayout.edge),
    showCornerCurves: normalizeBoolean(
      layoutContext("showCornerCurves"),
      rawLayout.showCornerCurves,
      true,
    ),
    autohide,
    exclusive,
    start: normalizeLayoutIdList("start", rawLayout.start),
    center: {
      start: normalizeLayoutIdList("center.start", centerLayout.start),
      anchor: normalizeOptionalLayoutWidgetId(layoutContext("center.anchor"), centerLayout.anchor),
      end: normalizeLayoutIdList("center.end", centerLayout.end),
    },
    end: normalizeLayoutIdList("end", rawLayout.end),
  }
}

function resolveWidgetDefinition(id: string, definition: unknown) {
  if (!isRecord(definition)) {
    fail({
      sourceFile: BAR_WIDGETS_SOURCE_FILE,
      path: id,
      widgetId: id,
    }, "must be an object")
  }

  if (typeof definition.kind !== "string") {
    fail({
      sourceFile: BAR_WIDGETS_SOURCE_FILE,
      path: `${id}.kind`,
      widgetId: id,
    }, "must specify a widget kind")
  }

  const widgetDefinition = widgetCatalog[definition.kind as keyof typeof widgetCatalog]
  if (!widgetDefinition) {
    fail({
      sourceFile: BAR_WIDGETS_SOURCE_FILE,
      path: `${id}.kind`,
      widgetId: id,
    }, `unknown widget kind "${String(definition.kind)}"`)
  }

  const kind = definition.kind as WidgetKind
  return widgetCatalog[kind].resolve(id, definition as never)
}

function collectLayoutReferences(layoutConfig: ResolvedLayoutConfig): Array<LayoutReference> {
  return [
    ...layoutConfig.start.map((widgetId, index) => ({
      path: `start[${index}]`,
      widgetId,
    })),
    ...layoutConfig.center.start.map((widgetId, index) => ({
      path: `center.start[${index}]`,
      widgetId,
    })),
    ...(layoutConfig.center.anchor
      ? [{
          path: "center.anchor",
          widgetId: layoutConfig.center.anchor,
        }]
      : []),
    ...layoutConfig.center.end.map((widgetId, index) => ({
      path: `center.end[${index}]`,
      widgetId,
    })),
    ...layoutConfig.end.map((widgetId, index) => ({
      path: `end[${index}]`,
      widgetId,
    })),
  ]
}

export function resolveBarConfiguration(
  layoutConfig: BarLayoutConfig,
  widgetDefinitions: BarWidgetDefinitions,
): ResolvedBarConfiguration {
  const resolvedLayout = normalizeLayoutConfig(layoutConfig)

  const rawWidgetDefinitions = widgetDefinitions as unknown
  if (!isRecord(rawWidgetDefinitions)) {
    fail(
      {
        sourceFile: BAR_WIDGETS_SOURCE_FILE,
        path: "",
      },
      "must export a widget definition object",
    )
  }

  const resolvedWidgets = Object.fromEntries(
    Object.entries(rawWidgetDefinitions).map(([id, definition]) => [
      id,
      resolveWidgetDefinition(id, definition),
    ]),
  )

  collectLayoutReferences(resolvedLayout).forEach(({ path, widgetId }) => {
    if (!(widgetId in resolvedWidgets)) {
      fail(layoutContext(path), `references unknown widget ID "${widgetId}"`)
    }
  })

  return {
    edge: resolvedLayout.edge,
    showCornerCurves: resolvedLayout.showCornerCurves,
    autohide: resolvedLayout.autohide,
    exclusive: resolvedLayout.exclusive,
    layout: {
      start: resolvedLayout.start,
      center: resolvedLayout.center,
      end: resolvedLayout.end,
    },
    widgets: resolvedWidgets,
  }
}
