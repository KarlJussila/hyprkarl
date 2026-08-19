# Shell Product Brief

This brief defines the product direction for Hyprkarl's production Quickshell
bar and feature panels. The structural foundation and cutover are complete;
the brief remains the standard for continued visual and interaction
refinement.

The bar implements this brief's foundation: audio, network, Bluetooth,
battery/power, and clock/calendar now use a shared per-monitor panel host and
separate feature-owned compositions. Those five panels validate the host plus
its header, section, row, and action baseline without forcing feature-specific
summaries, sliders, calendar cells, or navigation into generic controls.
Visual refinement follows the structural foundation; the current panel styling
is not the final aesthetic.

Two service limitations remain explicit rather than becoming invented UI
state. The installed Quickshell Bluetooth API does not expose pairing-agent
prompts or device-action failure reasons, and PowerProfiles exposes confirmed
profile state but no per-write result. The bar keeps advanced Bluetooth
management reachable and shows only service-confirmed progress/state while a
future supported boundary is evaluated for actionable failures.

## Design Position

The Quickshell bar should keep the retired AGS bar's compact, information-dense
character while replacing its flyouts with intentionally designed feature
panels. Omarchy and macOS are references for control quality, hierarchy, and
direct manipulation. They are not layout templates.

Hyprkarl should feel:

- compact and quiet when no panel is open;
- fast to scan without turning the bar into a row of unrelated pills;
- precise rather than spacious for its own sake;
- cohesive across features without forcing every feature into the same card
  tree; and
- visibly part of the active theme rather than a neutral shell painted with
  one accent color.

## What the AGS Bar Establishes

A live capture of the retired AGS bar establishes these qualities to retain:

- a thin bar with a 22-logical-pixel baseline that can grow to fit its tallest
  naturally padded widget;
- strong start, centered, and end composition;
- a clock held at the monitor midpoint rather than merely centered in leftover
  space;
- dense typography and concise status readouts;
- small, intentional gaps and dividers instead of bulky widget chrome; and
- islands that read as a related set while preserving their separate roles,
  including configurable screen/content/outer/inner corners, borders, and
  spacing rather than one pill treatment applied everywhere.

The complete bar palette is theme-derived. Text, surfaces, transparent or
opaque backgrounds, borders, accents, warnings, errors, hover states, pressed
states, selected states, and disabled states must be expressed as semantic
theme values. The current theme's magenta border is one example, not the only
themed part of the bar.

The AGS flyout dimensions, widget hierarchy, and interaction patterns are not
requirements. They are useful only as evidence of current functionality and
of problems the replacement must avoid.

## Feature Panel Model

Each substantial status feature owns an independent panel:

- **Network/Wi-Fi:** radio and connection state, current network, scanning,
  available networks, connection progress and failure, and a route to advanced
  settings.
- **Bluetooth:** adapter state, connected and paired devices, available
  devices, connection progress and failure, device battery where available,
  and a route to advanced settings.
- **Audio:** output volume and mute, output-device selection, microphone state
  and input level, and later per-application streams if the interaction remains
  clear.
- **Battery and power:** charge, charging state, estimated time where reliable,
  power profile, and relevant power actions. The widget and panel may be absent
  when the system exposes no battery; whether power profiles remain separately
  reachable on battery-less systems should follow an actual desktop use case.
- **Clock and calendar:** date, calendar navigation, and time-related actions
  that earn a place there.
- **Display:** brightness and monitor controls are a desired later panel. It
  waits for a cohesive integration that owns monitor discovery, supported
  modes, live application, persistence, and failures.

These are separate surfaces, not summaries inside one combined quick-settings
window. A feature can link to another feature or system settings when useful,
but it does not become their container.

In the battery and network panels, charge and connection facts each have one
visual owner. Their headers do not repeat state already shown by the battery
summary or selectable network rows.

## Shared Panel Language

One panel shell should own the behavior that must be consistent:

- anchoring to the invoking widget on the correct monitor;
- staying inside monitor bounds;
- choosing inward expansion for top and bottom bars;
- focus, keyboard traversal, Escape dismissal, and outside-click dismissal;
- border, background, shadow, radius, padding, and transition treatment;
- contact-aware corners: when a panel is flush with both the bar and a monitor
  side, the corner at that junction becomes sharp while exposed corners retain
  the active theme's radius; and
- switching cleanly when another feature trigger is activated.

Only one feature panel should be open on a monitor at a time. Activating its
trigger again closes it; activating another trigger replaces it. The production
bar implements this interaction contract.

Reusable controls should be extracted only after at least two panels need the
same interaction. Likely shared forms are section headings, action tiles,
sliders, switches, selectable device rows, status messages, disclosure rows,
and loading or empty states. Each feature retains ownership of its content
order, hierarchy, and detail transitions.

## Geometry and Bar Edges

Top and bottom bars are first-class for the production cutover. Both must have
equivalent widget behavior, correct exclusion zones, and panels that open
toward the workspace.

Vertical bars are a planned extension, not part of the initial cutover. Keep
orientation explicit at the bar layout and panel-window boundaries so adding
left and right does not require replacing those ownership contracts. Do not
implement or maintain unused vertical branches in every widget before the
vertical design exists.

The panel should have a stable preferred width, then clamp to the available
monitor width. Dense content may scroll inside the panel; the panel itself
must not extend off-screen. Exact widths, padding, motion, and corner treatment
remain visual-design decisions to make with representative panels open.

Corner contact is already an intentional part of Hyprkarl's visual language.
The theme owns the normal panel radius, while the shared panel shell owns the
geometric decision to suppress that radius at a bar-and-screen-edge junction.
Feature panels should not implement that rule independently.

The bar uses the same ownership split. Themes select logical island corners,
borders, radii, curve dimensions, and screen/outer/content margins. One shared
island renderer maps those choices onto top and bottom geometry; individual
widgets and islands do not draw their own surfaces.

## Interaction and Information Principles

- Put current state and the primary action before device or network lists.
- Keep common changes directly manipulable; do not turn every action into a
  submenu.
- Show progress and real external failures where the action occurs.
- Keep advanced or infrequent controls reachable without making the summary
  state noisy.
- Prefer feature-specific empty states over blank shared containers.
- Give keyboard focus and pointer hover distinct theme-derived states.
- Do not make a panel imitate a mobile control center merely because both use
  tiles and sliders.

## Production Baseline

The Quickshell implementation reached its production baseline with:

- the complete default bar layout and core widget behavior;
- solid network, Bluetooth, audio, battery/power, and clock/calendar panels;
- live theme updates using semantic values for the entire surface;
- correct top and bottom behavior;
- correct monitor creation, removal, anchoring, and state ownership; and
- clean cold-start, reload, and runtime logs on the supported Quickshell and Qt
  versions.

The cutover removed AGS startup, packages, controls, implementation, and theme
files together. There is no second selectable production bar.

## AGS Visual Reference Inventory

The retired AGS audio, network, Bluetooth, battery/power, and clock/calendar
flyouts have been captured and inspected. The screenshots remain temporary
because they contain machine-local and device information; the durable design
findings are recorded below. Build representative audio and network panels
first, then test the shared vocabulary against Bluetooth and power before
declaring it stable. That sequence is now complete; this section remains the
historical AGS comparison rather than a description of the new panels.

### Captured AGS Baseline: Audio

The current audio flyout is a narrow vertical volume slider attached directly
below the top-bar trigger, followed by a percentage readout. Its surface,
border, slider track, fill, thumb, and text all use theme-derived values. The
direct manipulation, live readout, compactness, and clear connection to the
trigger are useful qualities to retain.

It is a single control rather than the planned audio panel. It has no mute
action, output chooser, microphone state, input level, per-application stream,
or in-panel route to failure and unavailable states beyond a replacement
label. A secondary click launches the separate audio application, which is
further evidence that the flyout does not yet own the full audio task.

The AGS implementation creates a monitor-sized overlay window and uses an
invisible shield for outside-click dismissal, with a small measured surface
positioned over it. That is required machinery for the current GTK
layer-shell approach, not a product requirement for Quickshell. Preserve the
dismissal behavior and anchored result, not this window structure.

### Captured AGS Baseline: Network/Wi-Fi

The current Wi-Fi flyout is a compact list anchored below the network trigger.
It pins the active SSID first, deduplicates access points by SSID, sorts the
remainder by signal strength, distinguishes networks that need a password, and
uses a theme-derived active row and check mark. Rows expand in place for a
password, show connection progress, and reopen the entry with an error state
when NetworkManager rejects the credential. These are useful task behaviors
to preserve.

Its shape is still determined by the natural size of the access-point list.
There is no panel-level current-connection summary, Wi-Fi radio control, scan
status or explicit refresh action, wired or VPN state, bounded scrolling, or
route to advanced settings inside the surface. A secondary click launches the
separate Wi-Fi application. The production panel should give the list a clear
place inside a stable network surface rather than simply making the list more
decorative.

The implementation scans only when the flyout opens, which is a good lifetime
boundary. It also shells out to `nmcli` to discover and remove saved profiles
because marshalling the corresponding access-point connection array through
GJS can crash while the list changes. That is a confirmed AGS/GJS workaround,
not logic to carry into Quickshell. The replacement should use the supported
Quickshell or system-service boundary selected for network ownership.

### Captured AGS Baseline: Bluetooth

The current Bluetooth flyout lists paired devices and lets each row connect or
disconnect directly. Device-class glyphs make the list quick to scan;
connecting state appears on the row, while the connected device receives the
theme-derived active treatment and check mark. Those direct device rows are a
useful interaction to preserve.

The flyout does not provide a Bluetooth power control, discovery or pairing,
connected/paired/available sections, device battery, trust or forget actions,
or an in-panel route to advanced settings. Connection failures are written to
the log rather than shown on the affected row. The production panel should
make adapter state and connected devices prominent, keep paired devices easy
to reach, and disclose discovery and device management without turning the
default view into an undifferentiated device list.

The AGS implementation uses Nerd Font glyphs instead of colored icons supplied
by the system icon theme so the entire row remains controlled by Hyprkarl's
active theme. Quickshell should preserve that semantic color ownership with
theme-tintable icons or glyphs; it does not need to preserve this exact lookup
table. No additional Bluetooth-specific GJS workaround was identified in the
current surface. Its limitations are primarily product scope rather than
framework machinery.

### Captured AGS Baseline: Battery and Power

The current flyout is a three-row power-profile chooser. It clearly marks the
active profile with the theme-derived active treatment and check mark, changes
the profile directly, and closes after selection. That is an efficient control
worth retaining, although the final presentation does not have to remain a
plain list.

The battery widget already tracks charge percentage, charging state, energy
rate, time to empty or full, presence, the active power profile, and available
profiles. Most of that state is confined to the bar and tooltip while the
flyout shows only profile names. The production panel should compose the
useful battery summary and power-profile control into one surface, omit
unreliable estimates cleanly, and report a real profile-change failure where
the action occurred.

Battery and power-profile state already have separate service owners in AGS
and are composed only by the feature widget. That is the right ownership
shape to preserve: the panel may present them together without inventing a
generic power controller between the system services and the feature. No
battery-specific framework workaround needs to become part of the Quickshell
design.

### Captured AGS Baseline: Clock and Calendar

The current clock flyout centers a month grid below the midpoint-anchored clock
and gives the current date its own header above the weekday labels. Muted days
from adjacent months, theme-derived text and selection colors, and the clear
header-to-grid hierarchy make it feel more like a composed panel than the
utility lists used by several other widgets. Those qualities are useful visual
references.

The calendar is display-only: pointer targeting and month navigation are
disabled, and it offers no time, event, or calendar actions. More importantly,
the captured header showed August 18 while the calendar still highlighted
August 15. The AGS process had started on August 15; its `Gtk.Calendar` was
constructed at shell startup with that date while the separate header state
continued updating. Revealing the flyout did not synchronize the calendar.

The Quickshell feature should have one explicit date owner and bind both header
and grid to it. Opening a long-lived panel after midnight, resuming from sleep,
or navigating away and back must not leave a stale current-day highlight.
Month navigation should be a deliberate supported interaction or be omitted
visually; the panel must not present controls that are intentionally inert.
This is accidental lifecycle behavior in the AGS implementation, not a GTK
layer-shell requirement to reproduce.
