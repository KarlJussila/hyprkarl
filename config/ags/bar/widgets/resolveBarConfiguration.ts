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

  const autohide = normalizeBoolean(layoutContext("autohide"), rawLayout.autohide as boolean | undefined, false)
  const exclusive = normalizeBoolean(layoutContext("exclusive"), rawLayout.exclusive as boolean | undefined, !autohide)

  const centerStart = normalizeLayoutIdList("center.start", centerLayout.start)
  const centerCenter = normalizeLayoutIdList("center.center", centerLayout.center)
  const centerEnd = normalizeLayoutIdList("center.end", centerLayout.end)

  if (centerCenter.length === 0 && (centerStart.length > 0 || centerEnd.length > 0)) {
    fail(
      layoutContext("center.center"),
      "center.center must have at least one widget when center.start or center.end are used — put all widgets in center.center for a centered group without a pivot",
    )
  }

  return {
    edge: normalizeBarEdge(rawLayout.edge),
    showCornerCurves: normalizeBoolean(
      layoutContext("showCornerCurves"),
      rawLayout.showCornerCurves as boolean | undefined,
      true,
    ),
    autohide,
    exclusive,
    start: normalizeLayoutIdList("start", rawLayout.start),
    center: {
      start: centerStart,
      center: centerCenter,
      end: centerEnd,
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
    ...layoutConfig.center.center.map((widgetId, index) => ({
      path: `center.center[${index}]`,
      widgetId,
    })),
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
