// Stub for all ags/* and gi:// modules in the Node test environment.
// Tests never call render(), so GTK widgets and reactive primitives only need
// to exist, not behave correctly.

function makeAccessor(getValue) {
  const fn = (mapper) => mapper ? mapper(getValue()) : getValue()
  fn.subscribe = () => () => {}
  return fn
}

export function createState(initial) {
  let value = initial
  const accessor = makeAccessor(() => value)
  const setter = (v) => { value = typeof v === "function" ? v(value) : v }
  return [accessor, setter]
}

export function createComputed(fn) {
  return makeAccessor(fn)
}

export function createEffect() {}
export function onCleanup() {}
export function createBinding(v) { return makeAccessor(() => v) }
export function createPoll() { return {} }
export function readFile() { return "" }
export function readFileAsync() { return Promise.resolve("") }
export function execAsync() { return Promise.resolve("") }
export const timeout = () => ({ cancel: () => {} })
export function register() {}
export function signal() {}

export const Gtk = {
  Widget: class {},
  Box: class {},
  Orientation: { HORIZONTAL: 0, VERTICAL: 1 },
  Align: { CENTER: 3, START: 1, END: 2, FILL: 0 },
  Justification: { CENTER: 2, LEFT: 0, RIGHT: 1 },
  RevealerTransitionType: { SLIDE_DOWN: 0, SLIDE_UP: 1, SLIDE_LEFT: 2, SLIDE_RIGHT: 3 },
  GestureClick: class {},
  Overlay: class { set_child() {} add_overlay() {} },
}
export const Gdk = { Monitor: class { get_geometry() { return { width: 1920, height: 1080 } } } }
export const Astal = {
  Window: class { set_child() {} },
  WindowAnchor: { TOP: 1, LEFT: 2, RIGHT: 4, BOTTOM: 8 },
  Exclusivity: { IGNORE: 0 },
  Layer: { OVERLAY: 3 },
  Keymode: { ON_DEMAND: 1 },
}
export const app = { get_window: () => null, add_window: () => {} }

// Default export satisfies any `import GLib from "gi://GLib"` style imports
export default { new_now_local: () => ({ format: () => "", get_second: () => 0, get_microsecond: () => 0 }) }
