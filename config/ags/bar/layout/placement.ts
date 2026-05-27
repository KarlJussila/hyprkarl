import { Astal, Gtk } from "ags/gtk4"
import { type BarEdge } from "../types"
import { type TrayDirection } from "../widgets/tray/spec.tsx"

export type BarOrientation = "horizontal" | "vertical"
export type FlyoutDirection = "down" | "up" | "right" | "left"
export type IslandSlot = "start" | "center" | "end"
export type BarWindowMargins = {
  top: number
  right: number
  bottom: number
  left: number
}

type BarSlotLayout = {
  halign: Gtk.Align
  valign: Gtk.Align
  hexpand: boolean
  vexpand: boolean
}

type TrayExpanderIcons = {
  collapsed: string
  expanded: string
}

type BarWindowOriginArgs = {
  monitorWidth: number
  monitorHeight: number
  rootAllocation: Gtk.Allocation
}

export type BarPlacement = {
  edge: BarEdge
  classes: string
  orientation: BarOrientation
  isVertical: boolean
  layoutOrientation: Gtk.Orientation
  window: {
    anchor: number
    margins: BarWindowMargins
    origin: (args: BarWindowOriginArgs) => { x: number; y: number }
  }
  flyout: {
    direction: FlyoutDirection
    halign: Gtk.Align
    valign: Gtk.Align
    anchorHalign: Gtk.Align
    anchorValign: Gtk.Align
  }
  island: Record<IslandSlot, BarSlotLayout>
  tray: {
    revealTransition: Record<TrayDirection, Gtk.RevealerTransitionType>
    expanderIcons: (direction: TrayDirection, mirrorTrigger: boolean) => TrayExpanderIcons
  }
}

export type FlyoutPlacement = Pick<BarPlacement, "edge" | "orientation" | "isVertical" | "window" | "flyout">
export type TrayPlacement = Pick<BarPlacement, "edge" | "orientation" | "isVertical" | "layoutOrientation" | "tray">

export function barOrientation(edge: BarEdge): BarOrientation {
  return edge === "left" || edge === "right" ? "vertical" : "horizontal"
}

export function createBarWindowMargins(overrides: Partial<BarWindowMargins> = {}): BarWindowMargins {
  return {
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    ...overrides,
  }
}

function horizontalSlotLayout(): Record<IslandSlot, BarSlotLayout> {
  return {
    start: {
      halign: Gtk.Align.START,
      valign: Gtk.Align.CENTER,
      hexpand: true,
      vexpand: false,
    },
    center: {
      halign: Gtk.Align.CENTER,
      valign: Gtk.Align.CENTER,
      hexpand: true,
      vexpand: false,
    },
    end: {
      halign: Gtk.Align.END,
      valign: Gtk.Align.CENTER,
      hexpand: true,
      vexpand: false,
    },
  }
}

function verticalSlotLayout(crossAlign: Gtk.Align): Record<IslandSlot, BarSlotLayout> {
  return {
    start: {
      halign: crossAlign,
      valign: Gtk.Align.START,
      hexpand: false,
      vexpand: false,
    },
    center: {
      halign: crossAlign,
      valign: Gtk.Align.CENTER,
      hexpand: false,
      vexpand: false,
    },
    end: {
      halign: crossAlign,
      valign: Gtk.Align.END,
      hexpand: false,
      vexpand: false,
    },
  }
}

function horizontalTrayIcons(mirrorTrigger: boolean): TrayExpanderIcons {
  return mirrorTrigger
    ? { collapsed: "pan-start-symbolic", expanded: "pan-end-symbolic" }
    : { collapsed: "pan-end-symbolic", expanded: "pan-start-symbolic" }
}

function verticalTrayIcons(direction: TrayDirection): TrayExpanderIcons {
  return direction === "start"
    ? { collapsed: "pan-up-symbolic", expanded: "pan-down-symbolic" }
    : { collapsed: "pan-down-symbolic", expanded: "pan-up-symbolic" }
}

function verticalTrayRevealTransition(): Record<TrayDirection, Gtk.RevealerTransitionType> {
  return {
    start: Gtk.RevealerTransitionType.SLIDE_UP,
    end: Gtk.RevealerTransitionType.SLIDE_DOWN,
  }
}

function createBarWindowPlacement({
  anchor,
  edge,
  margins,
}: {
  anchor: number
  edge: BarEdge
  margins: BarWindowMargins
}) {
  return {
    anchor,
    margins,
    origin: ({ monitorWidth, monitorHeight, rootAllocation }: BarWindowOriginArgs) => {
      switch (edge) {
        case "bottom":
          return {
            x: margins.left,
            y: monitorHeight - margins.bottom - rootAllocation.height,
          }

        case "right":
          return {
            x: monitorWidth - margins.right - rootAllocation.width,
            y: margins.top,
          }

        case "left":
          return {
            x: margins.left,
            y: margins.top,
          }

        case "top":
        default:
          return {
            x: margins.left,
            y: margins.top,
          }
      }
    },
  }
}

export function createBarPlacement(edge: BarEdge, margins = createBarWindowMargins()): BarPlacement {
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor
  const orientation = barOrientation(edge)
  const isVertical = orientation === "vertical"
  const classes = `edge-${edge} orientation-${orientation}`

  switch (edge) {
    case "bottom":
      return {
        edge,
        classes,
        orientation,
        isVertical,
        layoutOrientation: Gtk.Orientation.HORIZONTAL,
        window: createBarWindowPlacement({
          anchor: BOTTOM | LEFT | RIGHT,
          edge,
          margins,
        }),
        flyout: {
          direction: "up",
          halign: Gtk.Align.START,
          valign: Gtk.Align.END,
          anchorHalign: Gtk.Align.START,
          anchorValign: Gtk.Align.END,
        },
        island: horizontalSlotLayout(),
        tray: {
          revealTransition: {
            start: Gtk.RevealerTransitionType.SLIDE_RIGHT,
            end: Gtk.RevealerTransitionType.SLIDE_LEFT,
          },
          expanderIcons: (_direction, mirrorTrigger) => horizontalTrayIcons(mirrorTrigger),
        },
      }

    case "left":
      return {
        edge,
        classes,
        orientation,
        isVertical,
        layoutOrientation: Gtk.Orientation.VERTICAL,
        window: createBarWindowPlacement({
          anchor: TOP | BOTTOM | LEFT,
          edge,
          margins,
        }),
        flyout: {
          direction: "right",
          halign: Gtk.Align.START,
          valign: Gtk.Align.START,
          anchorHalign: Gtk.Align.START,
          anchorValign: Gtk.Align.START,
        },
        island: verticalSlotLayout(Gtk.Align.START),
        tray: {
          revealTransition: verticalTrayRevealTransition(),
          expanderIcons: (direction) => verticalTrayIcons(direction),
        },
      }

    case "right":
      return {
        edge,
        classes,
        orientation,
        isVertical,
        layoutOrientation: Gtk.Orientation.VERTICAL,
        window: createBarWindowPlacement({
          anchor: TOP | BOTTOM | RIGHT,
          edge,
          margins,
        }),
        flyout: {
          direction: "left",
          halign: Gtk.Align.END,
          valign: Gtk.Align.START,
          anchorHalign: Gtk.Align.END,
          anchorValign: Gtk.Align.START,
        },
        island: verticalSlotLayout(Gtk.Align.END),
        tray: {
          revealTransition: verticalTrayRevealTransition(),
          expanderIcons: (direction) => verticalTrayIcons(direction),
        },
      }

    case "top":
    default:
      return {
        edge,
        classes,
        orientation,
        isVertical,
        layoutOrientation: Gtk.Orientation.HORIZONTAL,
        window: createBarWindowPlacement({
          anchor: TOP | LEFT | RIGHT,
          edge,
          margins,
        }),
        flyout: {
          direction: "down",
          halign: Gtk.Align.START,
          valign: Gtk.Align.START,
          anchorHalign: Gtk.Align.START,
          anchorValign: Gtk.Align.START,
        },
        island: horizontalSlotLayout(),
        tray: {
          revealTransition: {
            start: Gtk.RevealerTransitionType.SLIDE_RIGHT,
            end: Gtk.RevealerTransitionType.SLIDE_LEFT,
          },
          expanderIcons: (_direction, mirrorTrigger) => horizontalTrayIcons(mirrorTrigger),
        },
      }
  }
}

export function placementClasses(
  placement: Pick<BarPlacement, "edge" | "orientation"> | BarEdge,
) {
  const edge = typeof placement === "string" ? placement : placement.edge
  const orientation = typeof placement === "string"
    ? barOrientation(placement)
    : placement.orientation

  return `edge-${edge} orientation-${orientation} is-${orientation}`
}
