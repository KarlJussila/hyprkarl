# AGENTS.md

Guidance for coding agents working on the Quickshell bar.

## Goals

Optimize for configurability, extensibility, simplicity, and readability. The
bar has a small configuration layer for casual edits and cohesive QML modules
for implementation. Do not recreate framework services or introduce generic
controllers when a Quickshell singleton already owns the state.

The repository-wide trust-user rule is especially important here. Hyprkarl
ships a default shell and documents suggested personal paths; it is not a
plugin marketplace and never needs marketplace-style path allowlists,
capability policing, manifests, approval, or sandboxing. Validate shell-owned
data needed for shell invariants, but pass user-authored QML and its private
settings through to the QML runtime. Helpful load errors are appropriate;
preventing an advanced user from leaving the documented contract is not.

## Editing surfaces

- `../../defaults/shell.json`: shipped bar behavior, widget order, and widget
  instances.
- `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/shell.json`: optional sparse user override.
- `../../defaults/menu.json`: shipped static command-menu hierarchy.
- `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/menu.json`: optional sparse menu additions and overrides.
- `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/<source>.qml`: one optional application-wide user root
  explicitly named by `userRoot.source`.
- the active XDG-state bundle's `quickshell.json`: semantic colors, typography,
  metrics, and island geometry.
- `widgets/*.qml`: one implementation per widget kind.

The integrated compiler's typed `theme-generator/defaults/theme.yaml` supplies
the complete final `shell` object serialized as `quickshell.json`. Add new
required appearance values there, not as literals in the consumer template.
Theme authors may derive that stable consumer object from arbitrary custom
structures; do not make the shell depend on the source vocabulary. The shell
reads only the selected immutable XDG-state artifact, never authoring source
under `themes/` or the personal configuration root.

Shell JSON is data-only. Widget definitions live inline in the layout; `id`
identifies the instance and `kind` selects the implementation loaded by
`WidgetHost.qml`. Ordinary user objects merge recursively over the shipped
default, while arrays replace as complete ordered values. Surgical layout
changes use ordered `bar.layoutEdits` operations keyed by stable widget ID;
do not infer deletion or array ordering from an ordinary deep merge, and do
not restore a separate widget-definition map.

`kind: "qml"` is the documented user-code widget lane. Its `source` normally
names a file relative to `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/modules/`, but this is a resolution
base rather than a sandbox: do not validate the path or the module's private
settings in an attempt to constrain user-authored QML. The module root declares
`required property var context`. `widgets/qml.qml` owns that context and
exposes the documented per-bar values and operations: stable ID, settings,
semantic theme, edge/orientation, output, owning bar window, command execution,
and shared panel open/close helpers. It also adapts optional root `tooltip`,
`tooltipSuppressed`, `widgetVisible`, and `hostMainPaddingOffset` properties to
existing shell contracts. Do not add discovery, manifests, install hooks, or
implicit enable state. Each `WidgetHost` owns one module instance per rendered
bar/output; application-wide state is not implicitly created for user modules.
Dynamically referenced sources are outside Quickshell's static reload graph, so
source edits require `hk-shell restart`.

The top-level `modules` object owns built-in runtime selection. It has nine
booleans: `bar`, `panels`, `notifications`, `osd`, `polkit`, `menu`,
`applications`, `calculator`, and `wallpaper`. ShellConfig latches this object
when the process starts. JSON reloads may update ordinary settings live, but a
changed module choice only logs a warning; the owner must run `hk-shell
restart`. Do not try to unload already-created global services on a live JSON
change.

`modules.bar` controls instantiation, not merely visibility. When false, do
not retain per-output bar windows or run the system monitor and command-widget
providers used only by them. `modules.panels` controls the `FeaturePanelHost`.
It intentionally leaves status widgets in the bar; an owner removes those with
`bar.layoutEdits` when desired. The remaining switches gate both a module's
windows and the state, watchers, timers, service registrations, processes, and
IPC targets that exist only for it. A disabled implementation does not rewrite
its existing keybindings, command widgets, or menu entries, so users remove or
replace those entry points in their own configuration.

`config/UserRoot.qml` loads one trusted application-wide user QML root for
independent surfaces or a replacement bar. Its direct context fields expose
the resolved configuration, theme, outputs, and requested overlay; its direct
methods open, replace, toggle, or close that overlay. Keep the optional
`notificationPosition(outputName)` hook. Do not turn any of this into directory
discovery or a plugin registry.

When `notifications.edge` is `bar`, `ScreenSurfaces.qml` resolves one reactive
position object per output. The built-in bar supplies the fallback; a user
root's optional `notificationPosition(outputName)` method may override its
`edge`, `extent`, `connected`, and `reachesSide` fields. Explicit `top` and
`bottom` notification edges bypass this provider. `NotificationWindow` owns
only presentation from that position and must not regain a hard dependency on
the built-in bar window.

## Architecture

`shell.qml` creates shared configuration, theme, user-root, and overlay state,
then gates each optional built-in runtime before using one `Variants` model to
create a `ScreenSurfaces` group per screen. `BarRuntime.qml` owns the system
monitor and command registry only while the bar is enabled. The surface group
owns the screen's optional bar, menu, OSD, notification, and polkit windows.
It resolves notification placement from a small reactive position object rather
than exposing the bar window to notification presentation.
It creates one `MenuWindow` per screen. The
menu singleton selects exactly one requested monitor, owns navigation history,
and exposes the public `menu` IPC target. Each inactive window stays hidden and
does not request keyboard focus.
The root also owns one `OsdState` and creates one `OsdWindow` per screen. The
state exposes fixed typed IPC methods, routes each update to the focused
Hyprland monitor, and restarts one dismissal timer so repeated changes
coalesce. OSD windows are click-through and never request keyboard focus.
`config/ShellConfig.qml` alone selects, validates, and watches shell JSON while
retaining the last valid live configuration after a rejected edit. `Bar.qml`
alone owns each bar window and its per-monitor `FeaturePanelHost`. Layout files
own island geometry. Feature directories own feature-specific panel state and
content; bar widgets remain concise status and entry points.

`features/command/CommandState.qml` owns the application-wide command-widget
registry. It creates exactly one provider per configured widget ID rather than
one per screen. Poll mode runs commands through non-login `bash -c`, starts one
process per tick, and skips a tick while the prior process is still running.
Stream mode owns one persistent process and accepts one text value or JSON
object per newline. Do not impose a polling-rate policy in validation, but keep
the CPU, wakeup, and battery cost prominent in user documentation. When no
command widget has a provider command, the registry model must remain empty so
it creates no timers or processes. Static command widgets render configured
text/icons and click actions directly; the shipped menu button is the canonical
example. Click actions inherit `HYPRKARL_OUTPUT` from `ShellButton` so commands
can preserve the clicked monitor. Prefer native Quickshell services or the
shared `SystemState` process for shipped high-frequency widgets.

`layout/IslandSurface.qml` is the single renderer for start, center, and end
islands. Its corner and border names are logical rather than top/bottom
coordinates: `screen` faces the output edge, `content` faces the workspace,
`outer` faces a monitor side, and `inner` faces another island. Preserve that
vocabulary for top and bottom bars. `curve` is the concave join supported at a
`screenInner` corner; on other corners it intentionally resolves to square.
`WidgetHost` balances a side island's bordered edge against the neighboring
divider by insetting the edge widget's loaded content on the border side. Keep
that half-border centering correction in the host; do not reintroduce visual
offsets in individual edge widgets or the tray chevron.
The bar window and exclusive zone include screen- and content-side margins,
while panel and tooltip anchors also account for the content margin.

Bar height is intrinsic. `WidgetHost.qml` adds the theme's universal
`bar.widgetPadding.cross` to each widget's natural height;
`bar.minimumThickness` is only a floor. `BarLayout.qml` owns the maximum across all
three islands and applies that resolved height to each island. Do not restore
fixed `barThickness` bindings in widgets or let islands resolve their final
heights independently.

Version 1 deliberately accepts only top and bottom bars. Layout and widget
code is horizontal until a vertical design exists; keep edge-dependent popup
placement at the panel-window boundary so later vertical support does not need
a new surface ownership model.

`bar.widgetPadding` describes the horizontal-bar design, not coordinate
axes. Its `main` value pads along a top/bottom bar and its `cross` value pads
across the bar's thickness. `WidgetHost.qml` owns both values so built-in and
future widgets get the same outer padding and clickable extent by default.
Widget natural sizes must describe content, not include a second copy of host
padding. A widget may expose `hostMainPaddingOffset` for a concrete compactness
requirement; the host resolves `max(0, main + offset)`. The tray binds that
contract to the theme's `bar.trayPaddingOffset`. Do not offset cross-axis
padding or add an override without a real design requirement. Add a separate
vertical-bar padding object only when vertical bars are supported. Panel
internals use `metrics.controlPadding`; they are not bar-widget padding.

Themes own the entire visual surface, including colors, typography, bar
minimum thickness, spacing, radii, borders, dividers, and the panel gap. Shell
JSON owns placement and behavior, not visual metrics. `config/Theme.qml` watches
the XDG-state `current/theme.json` selector, then reads the immutable artifact
named there. The selector changes atomically on a theme switch, so the theme
file watcher always follows a stable file.

Keep `bar.margin`, `bar.island.corners`, `bar.island.borders`,
`bar.island.radius`, `bar.island.curveSize`, and `bar.island.curveRadius` in
every theme. Do not move these
appearance decisions into shell JSON or individual island components.

`panels/FeaturePanelHost.qml` is the lasting window boundary for feature
panels. There is one host per bar/monitor. It owns the `PopupWindow`, trigger
anchoring, cross-axis clamping, preferred width, available-height clamping,
focus grab, Escape and outside-click dismissal, one-active-panel state,
transitions, scrolling, and contact-aware corner radii. Panels grow to their
content height or the remaining monitor height, whichever is smaller; do not
restore an arbitrary theme height cap. It whitelists the bar and popup in one
`HyprlandFocusGrab` so another panel trigger switches on the first click.
It also owns edge-dependent popup gravity: top-bar panels expand downward and
bottom-bar panels expand upward while anchoring within the bar surface.
Panel contents must not create their own popup window or reproduce geometry.

Display, audio, network, Bluetooth, battery/power, and clock/calendar now
exercise this host with six different compositions. Their repeated header,
section, row, and action controls are the stable baseline vocabulary;
feature-specific summaries, sliders, calendar cells, and navigation remain
with their features. `components/PanelSlider.qml` owns the shared normalized
slider used by display brightness and audio levels; do not fork its interaction
for another percentage control.
`PanelHeader` owns the compact optional header action; audio, network, and
Bluetooth place their advanced-settings cog there instead of adding a wide
footer action.
Feature-panel actions that launch an external command request it through their
bar entry point, which closes the owning panel before spawning the command.
There is no second feature-window or legacy flyout boundary. In the power and
network panels, facts already owned by the primary content do not become
decorative header subtitles: battery facts belong to `BatterySummary`, and the
connected Wi-Fi network is the selected first entry in the sorted network list.
Every panel content exposes a reactive `preferredWidth`; the host owns clamping
and anchoring. Keep feature-specific widths and drawn-indicator geometry in the
theme and owning components. Canvas indicators must allocate at their rendered
size and resolve thin strokes against `Screen.devicePixelRatio`; do not magnify
a smaller texture with an item transform.

`features/display/DisplayPanel.qml` is a per-output view over `hk-display`.
Opening it and its active-only timer query the bar's output; scale and
brightness act on that same output, while the display rows enable or disable
named outputs. The backend—not QML—owns Hyprland discovery, scale cleanup,
live application, and the generated XDG-state layout. Never disable the last
active output. Internal backlight brightness is shown only when the target
exposes it; external DDC brightness, mode/position editing, and global text
size are not part of this first display slice. Text size is an accessibility
and theme concern, not per-output monitor state.
While brightness is changing, the slider's local value owns presentation and
the state poller pauses. Writes start immediately and collapse any movement
during an active command to the newest value; do not restore an idle debounce
or clear the local value before that newest write succeeds.

Hover text uses `ShellTooltip`, a non-focusable `PopupWindow` with an empty
input mask. Do not replace it with Qt Controls' attached `ToolTip`; that window
does not participate correctly in the shell's layer or input behavior.

CPU, GPU, RAM, and recording state share the single long-running process in
`state/SystemState.qml`; event-driven widgets use Quickshell services directly.
`features/network/NetworkState.qml` is a feature-owned singleton because scan
requests are application-global while panels are per monitor; it reference
counts panel requesters so closing one monitor's panel cannot stop another's
scan. `features/bluetooth/BluetoothState.qml` owns the equivalent
adapter-global discovery lifetime and stops discovery only when this shell
started it. Opening a Bluetooth panel does not request discovery; only its
explicit scan action registers that panel as an owner, and closing the panel
releases it. Bluetooth device and power-profile actions otherwise write the
Quickshell service objects directly; do not add generic controllers around
them. The installed Bluetooth API does not expose pairing-agent prompts or
action failure reasons, so keep `hk-bluetooth-launch` as the advanced route
instead of inventing success or failure state. PowerProfiles likewise exposes
the selected profile but no per-write result; render service-confirmed state
and do not synthesize a profile-change failure.
`features/clock/ClockState.qml` is the one application-wide current-time owner.
Bar labels and every calendar panel bind to it so monitor count cannot create
divergent dates. Viewed-month offset is panel-local transient state and resets
when that panel opens; do not persist it or use Qt's implicit `model.today` as
a second date owner.
The three performance widgets share `ExpandableReadout`; the tray uses the
same clipped expansion for its dynamic item list. `WidgetHost` owns outer
padding, while the tray owns its internal divider and item-row spacing. Keep
the trigger's visible width stable across collapsed and expanded states. Tray
open state is independent from item availability: an open empty tray reveals
no panel or divider, then expands when an item appears.
The root `shell.qml` must retain `//@ pragma UseQApplication`: Quickshell's
installed platform-menu implementation requires `QApplication` for tray item
menus. Tray delegates send primary activation on left click, secondary
activation on middle click, and display the item's native menu on right click;
an `onlyMenu` item displays that menu on left click too.

Component and feature directories have checked-in `qmldir` files where runtime
loading or singleton registration requires them. Widget files are loaded from
configuration, so Quickshell's static scanner cannot discover all relative
imports on its own.

`features/menu/MenuState.qml` alone reads, watches, recursively merges, and
validates menu JSON. Entries merge by stable ID; `enabled: false` hides one.
An optional `checkedCommand` is evaluated when its menu opens and replaces the
entry icon with a check mark on success; keep it for cheap state probes such as
the active power profile, not general application logic.
Menus with a `sourceCommand` load a fresh JSON entry array when opened. One
application-wide `Process` in `MenuState` owns this short-lived load and
validates its output; providers own discovery only, while the JSON menu object
owns the title, empty-state label, optional search behavior, and width role.
Menus may also choose left, center, or right entry alignment; keep this a
general data property rather than branching the renderer for a specific menu.
Static and dynamic entries may run a command, navigate to a declared submenu,
switch directly to a Quickshell surface, or dismiss an informational menu.
Surface actions pass an open-ended parameter object through `OverlayState` so
shipped and user-composed surfaces use the same in-process transition instead
of calling back through `hk-shell`. Nested dynamic menus reload the restored
parent when navigating back. Providers and command actions inherit the session
environment through non-login `bash -c`. A dynamic destination is committed
only after its provider returns a complete valid model; do not add per-menu
loading branches or caches.
Providers should query only the state their rows need, and static generated
catalogs should already be in provider-ready JSON. Providers that construct or
transform entries should normally be Python executables using lists,
dictionaries, and the standard `json` module. Bash remains appropriate for a
provider that only validates and prints prebuilt data.
Keep commands as leaf actions and static hierarchy in data. `MenuWindow.qml`
owns hierarchy, menu rows, search filtering, selection, navigation, and Back
behavior. It composes `OverlayWindow` for the full-screen input plane, frame,
search field, focus, outside-click dismissal, and reveal, and
`MomentumScroll` for kinetic touchpad behavior. Do not fork those shared
interactions back into the menu. Keyboard selection positions its row
immediately, including across wrap-around, while pointer selection changes
only on actual pointer motion. Opening a menu or changing its search resets
selection, viewport, and momentum to the first result.
`hk-shell menu` is the only public transport for opening static navigation.
`features/overlay/OverlayState.qml` owns exclusivity and monitor routing across
that menu, the application chooser, calculator, and wallpaper picker. Opening
one replaces the active focused overlay instead of leaving another visible
behind it. `OverlayWindow` owns their shared shell-styled frame, search field,
focus, scrim, and reveal, while each feature owns its body and key semantics.
`MomentumScroll` owns the kinetic touchpad behavior shared by long picker
lists and grids.

`features/applications/` renders launcher and open-with modes through one
picker. Launcher entries come directly from Quickshell's watched
`DesktopEntries` model and launch through `gtk-launch` so desktop-file field
codes and terminal handling remain intact. Open-with runs `hk-open-with
entries` only when requested because Quickshell does not expose MIME
associations; selection returns through the same command for Gio-owned
file-aware launching and optional default-app assignment. Its toggle uses the
same `ToggleIndicator` as bar controls.

`features/calculator/` evaluates the current expression with one short-lived
`qalc` process, copies the chosen result with `wl-copy`, and owns five recent
expression/result pairs under XDG state. `features/wallpaper/` loads the
existing thumbnail cache once per open through `hk-wallpaper-entries` and
directly selects set or remove actions. Neither feature starts a background
poller. Their appearance comes from the shared `menu` tokens plus the
`applicationPicker`, `calculator`, and `wallpaperPicker` theme objects.
The command menu keeps its compact, centered visual identity while deriving
all appearance from the shell theme and its nested `menu` object. Visual
geometry belongs in theme data and the shared overlay components, not agent
instructions. Outside-click and Escape go to the parent from a submenu and
close only at the root.

`features/osd/` owns the shell-native volume, audio-output, microphone,
display-brightness, keyboard-brightness, and media surface. Commands send
semantic state only. `OsdState` chooses fixed labels and indicators;
`OsdWindow` owns the shared geometry and transition. Reuse the drawn
`AudioIndicator` for volume and output, and use theme-font Nerd Font glyphs
for the remaining compact indicators. Do not restore icon-theme lookup or
Mako OSD application rules. Placement and timeouts live under `osd` in shell
JSON; appearance lives under `osd` in each theme's `quickshell.json`.

`features/notifications/NotificationState.qml` is the one application-wide
freedesktop notification server. It sets `tracked` only for notifications the
shell will present, routes new entries to the focused Hyprland monitor,
resolves expiry, synchronous replacement, filters, silence mode, and
one visual restore snapshot, and exposes the `notifications` IPC target.
There is one `NotificationWindow` per output; windows never request keyboard
focus. Toast delegates own hover-paused timers, click-to-dismiss behavior,
content images, and progress rendering. The default stack docks to the bar and
right screen edge, overlaps the bar border, and joins adjacent toasts along a
single shared border. Only corners reached by the adjacent toast sharpen;
width overhangs remain rounded. It sharpens the outer corner that touches both
surfaces, and reveals into the workspace. Do not restore a
permanent close control or generic action-button row without a new interaction
design.

Icon presentation is data, not app-specific QML branching. Notification
content images win because they are part of the message, but they use the same
theme-owned icon size as every other icon source. Otherwise
`notifications.iconOverrides` may match a lowercase application or icon name
and select `icon`, `glyph`, `component`, or `none`; then the sender's
application icon and the configured urgency fallback apply. A `component`
names either a shipped file under `features/notifications/icons/` or a user
file under `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/quickshell/icons/`. Both expose `progress` and `theme` on a
root `Item`; the shipped audio and battery drawings use exactly this public
loader path. Absolute sender icon paths become `file:` URLs before reaching
QML, and a `none` descriptor removes the icon item from layout. Shell JSON owns
selection and application filters; each theme's `notification` object owns
surface color, geometry, icon size, and drawn-indicator scale.

Authentication surfaces have separate owners; do not create a generic auth
controller. `features/polkit/PolkitState.qml` owns the one session
`PolkitAgent`; `PolkitWindow.qml` binds directly to its current `AuthFlow` and
creates the focused modal presentation per output. It honors identities,
response-required and response-visible state, supplementary messages,
cancellation, and service-owned retry behavior. It is not a feature panel and
has no public IPC endpoint. Do not add another agent, request queue, or PAM
layer. The installed qmltypes leave `AuthFlow` unresolved through
`PolkitAgent.flow`, and the exact upstream v0.3.0 manual example produces the
same `qmllint` warning. Do not add an abstraction to hide that tooling defect;
validate registration and a real prompt in the live runtime.

Do not replace `hyprlock` on this runtime. Quickshell's post-0.3.0 changelog
contains session-lock crash fixes for sleep, wake, DPMS, unlocking, and early
surface visibility access that are absent from the installed release. Keep
`hyprlock`, `hk-lock`, and the current idle/suspend path until a release with
those fixes is admitted and re-tested. The eventual lock is a small,
short-lived Quickshell process isolated from the long-running desktop shell;
it may share semantic theme inputs but must not instantiate bar services or
depend on desktop-shell IPC. See `../../docs/authentication-surfaces.md`.

## Checks

From the repository root:

```bash
/usr/lib/qt6/bin/qmllint $(rg --files config/quickshell -g '*.qml' | sort)
hk-shell start
hk-shell logs --tail 100 --no-color
hk-shell stop
```

The live launch is authoritative because Quickshell's installed qmltypes omit
some internal types used by its public QML API. Use `qs -p config/quickshell`
only when a foreground development process is useful.

`hk-shell` is the public lifecycle boundary for the production bar. Hyprland
session startup calls `hk-shell start`; use the same command family for normal
start, stop, restart, status, and log access. A successful stop must mean `qs
list` no longer reports a live instance; restart relies on that observable
boundary instead of racing a process that is still shutting down.
