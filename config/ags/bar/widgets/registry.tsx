import { Gdk } from "ags/gtk4"
import {
  type NormalizedBatteryWidgetConfig,
  type NormalizedBarWidgetDefinition,
  type NormalizedCaffeineWidgetConfig,
  type NormalizedClockWidgetConfig,
  type NormalizedMenuWidgetConfig,
  type NormalizedTrayWidgetConfig,
  type NormalizedWorkspacesWidgetConfig,
} from "../configuration"
import { type BarPlacement } from "../layout/placement"
import BatteryWidget from "./battery/BatteryWidget"
import CaffeineWidget from "./caffeine/CaffeineWidget"
import ClockWidget from "./clock/ClockWidget"
import MenuWidget from "./menu/MenuWidget"
import TrayWidget from "./tray/TrayWidget"
import WorkspacesWidget from "./workspaces/WorkspacesWidget"

type WidgetRenderArgs<TConfig extends NormalizedBarWidgetDefinition> = {
  id: string
  config: TConfig
  placement: BarPlacement
  monitor: Gdk.Monitor
}

type WidgetRendererMap = {
  menu: (args: WidgetRenderArgs<NormalizedMenuWidgetConfig>) => JSX.Element
  workspaces: (args: WidgetRenderArgs<NormalizedWorkspacesWidgetConfig>) => JSX.Element
  tray: (args: WidgetRenderArgs<NormalizedTrayWidgetConfig>) => JSX.Element
  clock: (args: WidgetRenderArgs<NormalizedClockWidgetConfig>) => JSX.Element
  caffeine: (args: WidgetRenderArgs<NormalizedCaffeineWidgetConfig>) => JSX.Element
  battery: (args: WidgetRenderArgs<NormalizedBatteryWidgetConfig>) => JSX.Element
}

const widgetRenderers: WidgetRendererMap = {
  menu: ({ config, placement }) => (
    <MenuWidget
      orientation={placement.orientation}
      config={config}
    />
  ),

  workspaces: ({ config, placement }) => (
    <WorkspacesWidget
      orientation={placement.orientation}
      config={config}
    />
  ),

  tray: ({ config, placement }) => (
    <TrayWidget
      placement={placement}
      config={config}
    />
  ),

  clock: ({ config, placement, monitor }) => (
    <ClockWidget
      placement={placement}
      monitor={monitor}
      config={config}
    />
  ),

  caffeine: ({ config, placement }) => (
    <CaffeineWidget
      orientation={placement.orientation}
      config={config}
    />
  ),

  battery: ({ config, placement, monitor }) => (
    <BatteryWidget
      placement={placement}
      monitor={monitor}
      config={config}
    />
  ),
}

export function renderBarWidget(args: WidgetRenderArgs<NormalizedBarWidgetDefinition>) {
  switch (args.config.kind) {
    case "menu":
      return widgetRenderers.menu({ ...args, config: args.config })
    case "workspaces":
      return widgetRenderers.workspaces({ ...args, config: args.config })
    case "tray":
      return widgetRenderers.tray({ ...args, config: args.config })
    case "clock":
      return widgetRenderers.clock({ ...args, config: args.config })
    case "caffeine":
      return widgetRenderers.caffeine({ ...args, config: args.config })
    case "battery":
      return widgetRenderers.battery({ ...args, config: args.config })
  }
}
