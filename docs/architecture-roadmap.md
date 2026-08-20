# Architecture Roadmap: Extensible Shell and User-Owned Configuration

This roadmap describes how Hyprkarl can adopt the strongest ideas from modern
Omarchy without becoming a distribution or giving up its central model: install
the repository once, then edit that repository directly.

This is a living roadmap rather than a complete description of current
behavior. Workstreams 1 through 3 are complete: `config/quickshell/` is the
production bar, its three explicit widget-extension lanes are implemented,
AGS has been removed, and shipped/user ownership boundaries are established.
Later workstreams build on those public contracts without treating every
internal QML detail as a compatibility constraint.

## Outcome

The intended end state has four properties:

1. Ordinary personalization lives in stable, user-owned paths that upstream
   never edits, so routine updates do not require Git conflict resolution.
2. Hyprkarl still runs from `~/.local/share/hyprkarl`; it does not become an
   Arch package, a system image, or a distribution.
3. One long-running Quickshell process owns shell integration, with small
   public configuration and extension contracts and no plugin marketplace.
4. Themes use a typed token graph, with common rendering logic owned once and
   generated runtime state kept out of the Git working tree.

## Product and Visual Direction

The AGS bar is a useful aesthetic reference, not the product specification for
the new shell. Preserve the qualities that make its bar feel like Hyprkarl:
its restraint, compact density, island-based composition, typography, borders,
and relationship to the active theme. The Quickshell bar should feel like a
more capable continuation of that visual language rather than an Omarchy
reskin.

The AGS widget flyouts, popup shapes, and current feature depth are not the
endgame. Do not preserve their component structure or use pixel-for-pixel AGS
parity as the acceptance standard for new shell surfaces.

The intended interaction model is closer to macOS quick settings and modern
Omarchy:

- compact, coherent control-center surfaces rather than isolated utility
  popups;
- clear grouping and visual hierarchy across related controls;
- direct manipulation through tiles, sliders, toggles, device rows, and
  expandable detail;
- useful status and primary actions visible before drilling into details;
- consistent anchoring and motion between bar triggers and their surfaces;
- enough space for controls to feel intentional without losing Hyprkarl's
  cleaner, denser character.

Those products are references for interaction quality and surface scope, not
layout templates. Hyprkarl should curate its own grouping, proportions,
navigation, motion, iconography, and information density. When an Omarchy
surface demonstrates a desired capability, specify the underlying user goal
and design a Hyprkarl-native arrangement rather than copying its card tree.

Before shared popup or panel primitives become stable, create a small visual
and interaction brief covering:

- bar appearance on top and bottom edges;
- panel width, padding, radius, borders, and relationship to the bar;
- reusable control forms such as tiles, sliders, toggles, rows, and sections;
- keyboard, pointer, scroll, and touch-friendly interaction where applicable;
- transitions between summary and detailed state;
- responsive behavior at narrow monitors, without making later vertical bars
  require a new panel-window architecture;
- representative audio, network, Bluetooth, power, and clock/calendar panels.

Screenshots and prototypes should be evaluated against that brief. Historical
AGS and prototype behavior remains useful for discovering requirements, but it
does not decide the final surface shape.

### Resolved Product Decisions

- Feature panels remain independent surfaces. Network/Wi-Fi, Bluetooth,
  audio, battery/power, clock/calendar, and display controls each have
  enough distinct state and interaction depth to own their information
  architecture.
- Those panels share a visual and windowing vocabulary, not one combined
  control-center layout. A bar widget opens its feature's panel directly.
- The display panel delegates monitor discovery, live application,
  persistence, and error reporting to one `hk-display` backend. Its first
  per-output slice covers internal-backlight brightness, cleaned scale
  presets, and output enablement; mode/position editing and external DDC
  brightness remain later work. Global text sizing is a separate
  accessibility/theme concern.
- Top and bottom bars are first-class in the initial production shell.
  Vertical bars are intentionally deferred. Orientation should remain an
  explicit layout concern at the bar and panel-window boundaries where that
  avoids a future rewrite, but unused left/right branches should not be spread
  through every widget today.
- The deliberate Quickshell cutover is complete. `hk-shell` owns production
  lifecycle, and there is no legacy bar selection or compatibility layer.
- The AGS bar is the visual reference for the compact bar itself, not for its
  flyout geometry or information architecture. Its complete palette is
  theme-derived: text, fills, borders, accents, status colors, and interaction
  states must continue to come from semantic theme values.

The lasting product and public-data boundaries are developed further in the
[Shell Product Brief](shell-product-brief.md) and
[Shell Configuration and State Contract](shell-configuration.md).

### Current Foundation Progress

The production Quickshell bar has a per-bar feature-panel host exercised by
separate display, audio, network, Bluetooth, battery/power, and clock/calendar
panels.
The host owns monitor-local active state, anchoring, bounds, focus and
dismissal, scrolling, transitions, and contact-aware corners. Header, section,
row, and action controls have now survived six different feature compositions
and form the stable baseline vocabulary; summaries, sliders, calendar cells,
and navigation remain feature-owned. Network scanning and Bluetooth discovery
each have a feature-owned, application-global request owner so multiple
monitor panels compose correctly; Bluetooth panels register only after an
explicit scan action. Power composes UPower and PowerProfiles directly. Clock
has one application-wide current-time owner and panel-local month navigation.
The superseded flyout boundary has been deleted. `hk-shell`
now provides the bar's start, stop, restart, structured status, and log
boundary. It launches under UWSM and verifies the registered instance so a
daemonized QML load failure cannot masquerade as a successful start. Hyprland
session startup now enters through that same boundary. Cutover hardening has
exercised every feature panel on top and bottom bars, live theme switching,
and Hyprland reloads. Bottom-bar popup gravity expands panels inward instead
of clipping them at the output edge, and theme selection watches the canonical
theme-name file rather than retaining a watcher on an old symlink target.
Monitor add/remove has also been exercised with a temporary headless output,
including removing the output while its monitor-local feature panel was open;
the shared shell process and remaining bar survived without a runtime warning.
The shared island renderer now restores the retired AGS bar's theme-controlled
logical corner shapes, selective borders, and screen/outer/content margins
without making individual widgets own surface geometry.
Bar content height is resolved once from the tallest natural widget, subject
to a theme minimum, then shared by all three islands and the exclusive zone.
The old static Rofi menu tree has also been replaced directly by a
shell-native Quickshell surface. `defaults/menu.json` owns built-in navigation,
`user/menu.json` deep-merges additions and overrides by stable entry ID, and
bindings and scripts call the shell's menu IPC directly. Dynamic providers and
in-process search now cover themes, live keybindings, Nerd Font icons, Docker
services, and the full fingerprint workflow. The launcher/open-with chooser,
calculator, and wallpaper thumbnail picker now use dedicated Quickshell
overlays with one exclusive focused-surface owner. Rofi and its calculator
plugin have been removed. The command-menu renderer retains the original
menu's compact width, centered icon-and-label rows, title band, nested frame,
and bordered selection. Its semantic palette, typography, rounded geometry,
borders, and accent states now come from the shell theme, so the result shares
the shell's visual language without becoming a generic feature panel.
The pinned authentication capability audit admitted Quickshell's polkit agent
for the next migration but retained `hyprlock`: post-0.3.0 upstream fixes for
session-lock crashes during sleep, wake, DPMS, and unlock are absent from the
installed release. The eventual secure lock is isolated in a short-lived
Quickshell process rather than tying its failure lifecycle to the desktop
shell. The resolved boundary is documented in
[Authentication Surfaces](authentication-surfaces.md).

## Constraints and Non-Goals

- Keep CachyOS as the base system and GNU Stow as the dotfile installation
  mechanism.
- Keep the repository as the source-editing surface and allow advanced users
  to modify implementation files on their own branches.
- Do not adopt Omarchy's `/etc/skel`, package split, pacman guard, factory
  reset, multi-user provisioning, or distribution migrations.
- Do not add a generic override or merge engine for every application config.
  Public override contracts belong only at surfaces where users actually need
  them.
- Do not add a plugin marketplace or manifest-based shell plugin system.
  Hyprkarl owns defaults and suggests personal paths; users own anything they
  place beyond those defaults.
- Do not silently rewrite curated user configuration to insert new defaults.
  Show new capabilities and let the owner adopt them explicitly.
- Do not target unpinned `quickshell-git` behavior. The supported Quickshell
  and Qt versions must be explicit and tested.
- Do not preserve prototype-only Quickshell configuration or internal APIs
  through compatibility layers. There are no production users of that surface
  yet.

## Target Ownership Model

Today, many files have four jobs at once:

```text
tracked file = upstream default = live config = user customization
```

The target model separates upstream-owned implementation from user intent
without separating them into different installations:

```text
Hyprkarl checkout
├── defaults/                 upstream-owned behavior and default data
├── config/                   upstream-owned application entry points
├── config/quickshell/        upstream-owned shell implementation
├── themes/                   built-in theme sources
└── user/                     reserved for the owner's configuration
    ├── hypr/
    ├── shell.json
    ├── menu.json
    ├── hooks/
    ├── quickshell/modules/
    └── themes/
```

`user/` remains inside the repository. A user can commit it on their branch
like any other customization, but upstream treats the namespace as reserved
and does not add personal configuration files there. A tracked README and
examples may document the contracts; runtime files belong to the user.

This is not one universal overlay system. Each supported surface has a small,
explicit rule:

- Hyprland loads upstream defaults, then optional Lua files from `user/hypr/`.
- Quickshell recursively merges ordinary objects from `user/shell.json` over
  its shipped defaults, replaces arrays as complete ordered values, then
  applies explicit widget-ID layout operations.
- Menu entries are merged by stable entry ID from `defaults/menu.json` and
  `user/menu.json`.
- Hooks run scripts from the matching `user/hooks/<event>.d/` directory.
- User Quickshell modules are loaded only when referenced by `user/shell.json`.
- A user theme may be selected independently or overlay a built-in theme with
  the same name through a documented theme-specific rule.

Machine-local secrets and environment values remain in the existing
gitignored `config/uwsm/env.local`; they do not move into `user/`.

## Workstream 1: Stabilize and Cut Over the Quickshell Bar

Status: complete.

### Goal

Replace AGS with a production Quickshell bar informed by the current prototype,
without combining the cutover with the later expansion into notifications,
menus, lock screens, and other shell surfaces.

### Work

1. Declare the supported Quickshell package and version in the package lists.
2. Preserve the prototype's useful ownership findings unless a simpler tested
   structure replaces them:
   - `shell.qml` creates shared state and one bar per screen.
   - `Bar.qml` alone owns each `PanelWindow` and exclusion zone.
   - layout components own island geometry.
   - features own service-specific panel state and content while widgets remain
     compact status and entry points.
3. Restructure the prototype before cutover where needed to establish the
   lasting shell host, data-only configuration, and shared primitives. Prefer
   deleting and replacing prototype machinery over wrapping it for
   compatibility.
4. Carry forward the AGS bar's intended aesthetic character through the
   semantic theme and bar layout, without carrying forward its popup design.
5. Complete the visual and interaction brief for shell panels and test the new
   host against Bluetooth and power before treating popup layout or reusable
   controls as stable architecture.
6. Finish the baseline behavior required to remove AGS. This is a migration
   floor, not the product end state:
   - every configured widget works on top and bottom bar edges;
   - feature panels anchor to the correct monitor and bar window;
   - multi-monitor creation and removal do not leak windows or state;
   - theme changes apply without a shell restart where practical;
   - bar restart and failure reporting have an `hk-*` entry point.
7. Keep the implemented `hk-shell` lifecycle boundary limited to `start`,
   `stop`, `restart`, `status`, and `logs` unless a real interaction requires
   another action. The shell-native command menu is that first exception and
   uses `hk-shell menu`; keep lower-level Quickshell details out of user-facing
   keybindings.
8. Change Hyprland autostart from AGS to Quickshell only after the replacement
   passes the cutover checks.
9. Remove AGS packages, startup, commands, theme files, and documentation in
   the same cutover change. Do not retain an unused compatibility layer.

### Acceptance Criteria

- `qmllint` completes with only documented Quickshell qmltypes warnings.
- A cold `qs -p config/quickshell` launch has no runtime QML warnings owned by
  Hyprkarl.
- The shell survives monitor add/remove, theme switch, and Hyprland reload.
- Top and bottom bars are exercised with every core feature panel.
- The production bar retains the curated AGS visual character documented in
  the design brief; visual comparison does not require retaining AGS popup
  geometry or information architecture.
- Popup primitives have been exercised against more than one representative
  feature-panel composition, so the first implemented widget does not decide
  the architecture for every later surface.
- AGS is no longer installed or launched after cutover.
- Human and agent documentation describes only the active bar architecture.

### Migration Risk

The cutover resolved the main risks around popup geometry, per-monitor object
ownership, and framework behavior that differs between the supported package
and upstream Quickshell examples. Those remain regression areas for future
changes.

## Workstream 2: Make Shell Configuration Data-Only and Extensible

Status: complete. Built-in, application-wide command-provider, static command,
and explicitly referenced user-QML widgets all use the versioned default/user
configuration boundary.

### Goal

Let users rearrange, configure, and extend the bar without editing QML
implementation files.

### Configuration Contract

Use the versioned `defaults/shell.json` owned by the shell and an optional
sparse `user/shell.json` override:

```json
{
  "version": 1,
  "bar": {
    "enabled": true,
    "edge": "top",
    "exclusive": true,
    "layout": {
      "start": [
        {
          "id": "menu",
          "kind": "command",
          "icon": "",
          "primaryCommand": "hk-shell menu toggle main"
        },
        { "id": "workspaces", "kind": "workspaces" }
      ],
      "center": {
        "before": [],
        "anchor": {
          "id": "clock",
          "kind": "clock",
          "primary": "ddd h:mm AP"
        },
        "after": []
      },
      "end": [
        { "id": "audio", "kind": "audio" }
      ]
    }
  }
}
```

The schema preserves the useful concepts demonstrated by the former
`BarConfig.qml` without preserving that file's shape.
Avoid separate widget-definition and layout maps unless repeated references
demonstrate that the indirection is useful. Each layout entry should normally
contain the settings for that instance.

Rules:

- The shipped default is used verbatim when no user file exists.
- Ordinary user objects merge recursively over the default. Scalars and arrays
  replace their inherited value; arrays are never implicitly concatenated or
  matched by position.
- Ordered `bar.layoutEdits` apply `insert`, `move`, `override`, and `remove`
  operations by stable widget ID after the ordinary merge. This makes layout
  intent explicit while allowing new upstream widgets to flow through.
- `version` is the only required compatibility boundary initially.
- Validation reports the file, entry, and invalid field. It falls back to the
  shipped default only for a real external boundary failure: missing,
  unreadable, invalid JSON, or unsupported version.
- The running shell watches both configuration files, recomputes the effective
  document, and applies layout or setting changes without restarting when
  Quickshell lifecycle contracts make that safe.

### Extension Lanes

Support three bar-widget sources:

1. **Built-in widget** — `kind` selects a Hyprkarl-owned QML component.
2. **Command widget** — a command produces plain text or a small documented
   JSON result either at a configured polling interval or over a persistent
   newline stream. The shell owns process lifetime and ensures one provider per
   configured instance, not one per monitor. Polling has no artificial minimum,
   but its process-per-tick CPU and battery cost is part of the public contract.
   The same kind supports a static icon/text action without a provider; the
   shipped main-menu button exercises that zero-process form.
3. **QML widget** — `kind: "qml"` loads an explicitly referenced file from
  `user/quickshell/modules/` and injects a small context: theme, orientation,
  bar window, instance settings, and shared tooltip/panel entry points.

One separate application-wide `userRoot.source` may compose independent
surfaces or a replacement bar. The built-in bar can be disabled without
stopping menus, OSD, notifications, or polkit, and the user root may provide a
reactive per-output notification position. This stays one explicit composition
root rather than a discovery or plugin system.

Do not scan the directory for plugins, execute install hooks, or invent enable
state. A module exists because the canonical config references it.

### Commands

Add configuration commands only where they enable a supported UI or scripting
workflow. Likely initial actions are:

- `hk-shell config init` — create a minimal versioned sparse override.
- `hk-shell config diff` — show the sparse override and its effect on the
  current shipped default.
- `hk-shell config reset` — require confirmation, back up the user file, then
  return to shipped defaults.
- `hk-shell reload` — ask the running process to reread configuration.

Runtime gestures such as dragging widgets may persist through the same single
config writer later. Do not add both gesture persistence and a second state
store.

### Acceptance Criteria

- Reordering and configuring built-in widgets requires editing JSON only.
- Two instances of the same built-in kind can carry independent settings.
- One command widget and one user QML widget work on every monitor on top and
  bottom edges.
- Disabling the built-in bar also stops bar-only polling, while a user root can
  replace its surfaces and notification placement.
- Invalid external configuration produces an actionable error and a usable
  default bar.
- Config reload does not recreate unrelated shared services.
- Updating shipped defaults never modifies `user/shell.json`.

### Migration Risk

Resolved. `BarConfig.qml` was removed in favor of shipped and optional user
JSON before it could become a public compatibility surface. Command providers
are application-wide, static commands create no provider runtime, and user QML
uses an explicit per-bar context without plugin discovery.

## Workstream 3: Establish Upstream Defaults and User Overrides

Status: complete. The Hyprland ownership split, ownership-aware update review,
data-defined shell-native menus, and narrow lifecycle hooks are implemented.

### Hyprland

Implemented. `config/hypr/hyprland.lua` is now the stable bootstrap,
`defaults/hypr/` owns the shipped modules, and matching optional modules under
`user/hypr/` load after the active theme. The public module order is `envs`,
`autostart`, `monitors`, `permissions`, `looknfeel`, `animations`, `gum`,
`windows`, `input`, then `bindings`.

Move Hyprkarl-owned Hyprland behavior behind a stable bootstrap:

1. `config/hypr/hyprland.lua` remains the live entry point.
2. It adds `$HYPRKARL_PATH/defaults` and `user/` to the Lua module path.
3. It loads the upstream-owned defaults in their intentional order.
4. It loads documented optional user modules afterward.
5. Theme overrides retain an explicit and documented position in that order.

Prefer cohesive override files such as `user/hypr/monitors.lua`,
`bindings.lua`, `input.lua`, `looknfeel.lua`, and `autostart.lua`. Do not
require empty files and do not catch internal contract violations as though
they were user input.

The migration should preserve current behavior first. Moving files and
changing ownership is enough; redesigning every binding and rule belongs in
separate changes.

### Menus

Implemented. Static navigation moved directly to Quickshell without an
intermediate Rofi renderer:

- `defaults/menu.json` owns built-in hierarchy, labels, icons, and actions;
- `user/menu.json` adds, replaces, or disables entries by stable dotted ID;
- one per-screen overlay renders on the focused output with exclusive keyboard
  focus, history navigation, and outside-click dismissal;
- the bar and Hyprland bindings use the same in-process state through the
  shell's IPC boundary, with no forwarding command layer;
- wallpaper management, power profiles, and default-app choices are nested
  shell-native menus rather than secondary Rofi navigation menus;
- themes, live keybindings, Nerd Font icons, Docker services, and every
  fingerprint choice use domain-owned providers and refresh when opened;
- searchable menus filter provider entries inside Quickshell;
- the launcher/open-with chooser, calculator, and wallpaper thumbnail picker
  use dedicated shell-native overlays, while package pickers retain their
  focused terminal interfaces.

The implemented `checkedCommand` remains limited to entries such as power
profiles that need external state. Add runtime `when` only when a reachable
entry needs it, and batch evaluations if startup latency becomes measurable.

### Hooks

Implemented. `hk-hook-run` accepts only lifecycle points emitted by existing
public actions:

- `post-boot`
- `post-update`
- `theme-set`
- `wallpaper-set`

Each event runs non-hidden executable regular files from
`user/hooks/<event>.d/` in lexical order. The runner attempts every hook and
returns nonzero after reporting any failures. Theme, wallpaper, and update
commands distinguish a completed primary action from a failed post-action
hook; session startup uses a desktop notification because it has no terminal.
There are no background retries, hook arguments, or metadata.

### Update Behavior

Implemented for the current ownership surfaces. `hk-update check` and the
guided review distinguish upstream configuration under `config/`,
`applications/`, `defaults/`, and `themes/` from review-only personal files
under `user/`. Surface-specific default-vs-user diff commands can be added with
their corresponding configuration contracts.

`hk-update` continues to merge and apply the repository. Its new responsibility
is to distinguish ownership in its review output:

- changes under upstream-owned paths are implementation/default changes;
- files under `user/` are never replaced or generated by an update;
- when a shipped default changes, `hk-update check` may point to the relevant
  user-vs-default diff command but does not edit the user file;
- schema-breaking changes require a release note and a narrow explicit
  migration command, not an accumulating general migration framework.

### Acceptance Criteria

- A user can override a default binding, input setting, monitor, and autostart
  command without editing an upstream-owned Lua module.
- A new menu entry and a theme-set hook can be added entirely under `user/`.
- An upstream update that changes the corresponding defaults merges without a
  conflict in those user files.
- `Hyprland --verify-config` succeeds for both the default-only and example
  overridden configuration.
- Documentation identifies every file as upstream-owned, user-owned, or
  generated state.

### Migration Risk

The medium-high migration risk has been retired. Hyprland's load order was
verified before cutover, the old menu definition path was removed with its
replacement, and lifecycle hooks are limited to four successful public action
boundaries rather than a general event system.

## Workstream 4: Grow the Bar into a Cohesive Shell Host

### Goal

Use one long-running Quickshell process for shell-native surfaces where shared
services, theme state, IPC, and window lifecycle materially simplify the
system.

### Host Responsibilities

The root shell should own only application-wide concerns:

- the selected shell configuration;
- semantic theme objects;
- global service instances that must be unique;
- per-screen surface construction;
- IPC endpoint registration and routing;
- on-demand loading of built-in panels and overlays.

Feature directories own their views and feature-specific state. Do not create
generic controllers between a Quickshell service and the feature that already
owns all of the required information.

### Surface Architecture

Do not force every feature through the current panels' shape. The
shell should provide a small visual vocabulary while each feature owns its
information architecture:

- one panel shell owns anchoring, monitor bounds, focus, dismissal, border,
  background, and transition behavior;
- shared controls own genuinely repeated interactions such as tiles, sliders,
  toggles, section headers, device rows, and disclosure;
- a feature composes those controls around its own user tasks;
- network/Wi-Fi, Bluetooth, audio, battery/power, and clock/calendar remain
  distinct panels rather than summaries inside a combined quick-settings
  surface;
- display controls remain another distinct panel over the cohesive
  `hk-display` backend that owns discovery, live application, persistence, and
  failures;
- bar widgets remain concise status and entry points, not compressed copies of
  their full panels.

The shared vocabulary should emerge from representative audio, network,
Bluetooth, and power designs together. Do not generalize a one-off component
after building only the first panel.

### Candidate Migration Order

The main menu has met this rule: its data contract and Quickshell renderer
landed together and deleted the static Rofi navigation path. The OSD did the
same for volume, audio output, microphone, display/keyboard brightness, and
media feedback. Notifications now use one application-wide Quickshell server,
focused-monitor stacks, progress, silence mode, one-item restore, docked
geometry, and data-defined icon presentation; Mako's daemon, control commands,
package, and theme output were deleted together. Migrate the remaining
surfaces one at a time, only when a replacement can delete the old process or
integration path:

1. Polkit is complete. The long-running shell owns the one session agent and
   focused-output prompt; the old process, package, and autostart path were
   removed in the same change.
2. Keep `hyprlock` until Hyprkarl admits a Quickshell release containing the
   documented post-0.3.0 session-lock stability fixes, then repeat the
   capability and lifecycle tests before implementation.
3. Clipboard, emoji, and image-selection overlays as independent later
   features.

This order is not a feature commitment. Each migration needs its own behavior
specification and must remove the superseded implementation in the same
change.

### IPC Contract

`hk-shell` is the only public transport wrapper. QML owns target registration;
shell scripts do not discover window internals. Keep endpoints feature-based,
for example:

```text
hk-shell osd volume 42
hk-shell menu toggle main
hk-shell notifications dismiss-all
```

IPC failure should be explicit for requested actions. Best-effort calls used
only for optional presentation may have a documented quiet mode.

### No Plugin Marketplace

Hyprkarl provides a curated default configuration and suggested personal paths.
It will not discover, install, approve, sandbox, or remove third-party plugins.
Built-in features, command widgets, and directly referenced user QML are the
complete extension model; users remain free to step outside its documented
contract at their own maintenance and debugging cost.

### Acceptance Criteria

- There remains exactly one long-running Quickshell desktop-shell process per
  session. A future secure lock may use one isolated process only while the
  session is locked.
- Global services are instantiated once; per-monitor windows are instantiated
  through explicit screen models.
- Every migrated surface has a written interaction outline or visual prototype
  before its reusable component needs are finalized.
- Display, audio, network, Bluetooth, power, and clock/calendar panels
  share a recognizable Hyprkarl design language without being forced into
  identical layouts.
- Disabled or unopened surfaces do not keep unnecessary windows or pollers.
- Every migrated surface deletes its former daemon, autostart entry, package,
  and command path where no longer public.
- A cold start and a live Quickshell reload both produce correct ownership and
  state.

### Migration Risk

High if attempted as a rewrite, moderate when migrated one feature at a time.
The largest risks are lifetime differences between cold start and live reload,
per-monitor popup routing, and accidental global state in QML singletons.

## Workstream 5: Build a Typed Theme Graph

### Goal

Own common theme transformations once while preserving hand-written escape
hatches and the repo's transparent editing model.

### Source Model

Implemented. The companion generator owns the shared typed defaults, native
Jinja resolution, consumer templates, explicit per-theme overrides, assets,
validation, and reproducible built-in output. Its source hierarchy is:

```text
defaults/theme.yaml           shared typed vocabulary and consumer defaults
templates/                    shared consumer templates
themes/<name>/
├── theme.yaml               colors and optional token overrides
├── overrides/               exceptional hand-written consumer files
├── wallpapers/
├── icons/
└── previews/
user/themes/<name>/           user theme or documented overlay
```

The companion remains the rendering authority and is exposed for personal
themes through `hk-theme build`; Hyprkarl does not duplicate its renderer.
Source objects deep-merge over the defaults before recursive expressions
resolve. Values retain native string, integer, decimal, and boolean types.
Theme authors may define arbitrary structures and feed them into the final
consumer values; the shipped vocabulary is guidance, not an allowlist.

### Generated State

The active theme now renders into generation-named artifacts under:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/themes/<name>.<generation>/
```

The current theme name, artifact selector, and wallpaper selection share that
state tree. Selection stages and validates the complete source/overlay result,
then swaps the active link and selector atomically so consumers never observe
a half-assembled bundle.

### Semantic Shell Theme

The flat Quickshell JSON bag has been replaced with a small semantic API:

- palette roles such as foreground, background, accent, muted, and urgent;
- surface roles for bar, popup, tooltip, and notification;
- typography scale;
- spacing, radius, and border metrics.

Keep the public token set proportional to actual variation. Do not reproduce
Omarchy's full theme surface before Hyprkarl has corresponding components.

### User Extension

The runtime supports two clear cases:

1. A complete user theme selected by name.
2. A documented overlay on a built-in theme for changed consumer values,
   wallpapers, or exceptional consumer output.

User-wide templates may be added later if users need to theme applications
Hyprkarl does not support. They should replace a named built-in template, not
participate in an ambiguous multi-layer merge.

### Acceptance Criteria

- Adding one common themed consumer requires one template, not one file per
  existing theme.
- Every built-in theme renders all required consumers from a documented typed
  graph plus explicit exceptions.
- Switching themes does not dirty the Git worktree.
- A failed render leaves the previous active theme intact.
- Quickshell updates semantic theme values without rebuilding unrelated shell
  state.
- Existing custom themes have a documented conversion path.

### Migration Risk

Resolved. The source rename and checked-in outputs span repository boundaries,
so the generator validates every built-in before syncing all bundles together.
The generated Quickshell contract remains stable while its former template
literals move into the shared graph.

## Delivery Sequence

The workstreams have dependencies but should not become one long-lived mega
branch. Deliver them as reviewable vertical changes:

1. **Record contracts and pin the runtime.** Decide supported Quickshell/Qt
   versions, target state paths, JSON versioning, and `user/` ownership.
2. **Define the shell's visual and interaction direction.** Capture the AGS
   bar qualities to retain, design representative feature-panel surfaces,
   and document where Hyprkarl intentionally differs from Omarchy and macOS.
3. **Reshape the Quickshell prototype around lasting ownership.** Introduce
   shell JSON, lightweight modules, host-level state, and shared primitives
   derived from multiple representative surfaces while AGS remains live;
   freely remove prototype-only structure.
4. **Complete the production Quickshell bar and cut over.** Complete. The bar
   was validated against the new structure and AGS was removed in the same
   change.
5. **Introduce `user/` and split Hyprland defaults from overrides.** Complete.
   The stable bootstrap preserves shipped behavior and loads optional user
   modules afterward; update review reports both ownership classes separately.
6. **Convert menus to data and add narrow lifecycle hooks.** Complete. Static
   and dynamic menus use the direct Quickshell renderer, while four public
   actions own the narrow user hook events.
7. **Move runtime theme state and adopt typed theme rendering.** Complete.
   The companion generator owns typed token resolution and production, while
   Hyprkarl stages built-in/user sources into atomic XDG-state artifacts.
8. **Migrate shell-native surfaces individually.** In progress. The OSD,
   notification service, and polkit prompt are complete; each deleted its old
   integration in full. The lock screen remains on `hyprlock` until a fixed
   Quickshell release is admitted. Clipboard, emoji, and image-selection
   overlays are independent later candidates. Require each later feature to
   delete an older integration path and meet the visual brief.
9. **Keep extensions direct and user-owned.** Complete. There is no plugin
   marketplace or manifest lifecycle to build or maintain.

Every delivered change must update the relevant human-facing and agent-facing
documentation in the same commit.

## Verification Strategy

There is no repository-wide automated test suite, so each workstream needs a
small, authoritative signal rather than a broad testing framework.

- **Hyprland:** `Hyprland --verify-config`, followed by a controlled reload.
- **Quickshell:** `qmllint`, a cold launch, live reload, runtime log inspection,
  multi-monitor exercise, and top and bottom bar edges initially. Add left and
  right edge coverage when vertical bars become supported.
- **Surface design:** screenshot comparison against the visual brief at the
  target scale, plus keyboard and pointer walkthroughs of summary, expanded,
  and dismissed states. Omarchy and macOS references are evaluated for user
  goals, not pixel similarity.
- **Configuration:** parse and schema fixtures for default, user, missing,
  malformed, and unsupported-version files; no tests that antagonistically
  call internal functions.
- **Menus:** shipped JSON parsing, sparse live-merge and removal exercise,
  invalid-ID IPC behavior, and pointer/keyboard walkthrough of the real
  renderer.
- **Hooks:** one end-to-end public action per event, with success and reachable
  script-failure behavior.
- **Themes:** render comparison for every built-in theme, atomic-failure test,
  and one live theme switch.
- **Updates:** the existing sandbox harnesses must cover a branch containing
  user-owned files and an upstream change to the corresponding default.

For each phase, inspect the final diff for duplicated ownership, unused
compatibility paths, and fallback behavior that no public action can reach.

## Decisions to Make Before Implementation

These choices materially affect the architecture and should be resolved in
small design changes before dependent work begins:

1. How Quickshell package updates are admitted after the initial 0.3.0-2.1 and
   Qt 6.11.1 baseline.
2. Resolved: the companion theme generator remains an external sibling by
   default, with `HYPRKARL_THEME_GENERATOR_PATH` as an explicit relocation
   override. `hk-theme build` is the narrow integration boundary.
3. Resolved: `hk-display` owns Hyprland discovery, live scale and output-state
   changes, internal backlight control, and the generated XDG-state layout.
   The Quickshell display panel is a per-output view over that backend, while
   `user/hypr/monitors.lua` loads afterward and retains the final say.
4. Resolved: polkit belongs to the long-running shell, while the eventual
   secure lock uses an isolated short-lived process. Lock implementation is
   deferred beyond Quickshell 0.3.0-2.1 because the installed release predates
   required upstream session-lock stability fixes.

Plugin marketplaces are an explicit non-goal. Compatibility with arbitrary
internal QML modules, multi-user provisioning, and cross-distribution packaging
are outside the roadmap.

## Completion Definition

This roadmap is complete when:

- AGS has been replaced by the pinned Quickshell shell;
- normal shell, Hyprland, menu, hook, and theme personalization can live under
  `user/` without editing upstream-owned files;
- update review clearly distinguishes upstream defaults from user intent;
- built-in and user command/QML bar modules share one documented config
  contract;
- the bar preserves Hyprkarl's curated AGS-derived visual character while
  feature panels follow the independently designed richer surface
  model;
- theme switching renders token-driven state outside the repository;
- additional shell surfaces run in the same process only where doing so
  deletes older integration machinery; and
- personal extensions remain direct user-owned files and references rather
  than a plugin platform.
