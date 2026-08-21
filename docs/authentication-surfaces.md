# Authentication Surfaces

Hyprkarl uses `hyprlock` for session locking and a shell-native Quickshell
agent for polkit privilege prompts. The two surfaces have different security
and lifecycle requirements and are not hidden behind one generic
authentication controller.

This document records the capability decision for the currently installed
Quickshell 0.3.0-2.1 and Qt 6.11.1 baseline. It was checked against the exact
[v0.3.0 source](https://git.outfoxxed.me/quickshell/quickshell/src/tag/v0.3.0)
and the upstream
[post-release changelog](https://git.outfoxxed.me/quickshell/quickshell/src/branch/master/changelog/next.md).

## Decision Summary

- Keep the completed polkit prompt in the existing long-running shell process.
  Quickshell 0.3.0 includes the required `PolkitAgent` and `AuthFlow` APIs;
  `hyprpolkitagent` is no longer started or installed.
- Keep `hyprlock` as the production lock screen. Although this build
  exposes `WlSessionLock`, its release does not include later upstream fixes
  for session-lock crashes around sleep, wake, DPMS, and unlocking.
- Re-audit the lock screen after Hyprkarl admits a Quickshell release carrying
  those fixes. Do not reproduce the missing protocol or authentication
  behavior locally.
- Keep lock and polkit state independent. They happen to request credentials,
  but they have different protocol owners, windows, cancellation behavior,
  and failure consequences.

## Current Ownership

| Concern | Current owner | Replacement decision |
| --- | --- | --- |
| Secure Wayland session lock | `hyprlock`, launched by `hk-lock` | Retain |
| Idle and suspend lock requests | `hypridle` through `hk-lock` | Retain |
| Password and fingerprint unlock | `hyprlock` plus PAM/fprintd | Retain |
| Polkit agent registration and prompts | Quickshell `features/polkit/` | Complete |

The inactive `hypridle` service is normal while the caffeine toggle is on; it
does not change these ownership boundaries.

## Polkit Design

The root `shell.qml` retains exactly one `PolkitState` singleton. That object
owns Quickshell's single `PolkitAgent`, while `PolkitWindow.qml` owns one
presentation surface per output and activates only the focused output chosen
when the request begins. Do not put polkit into the feature-panel host:
an authorization request is a modal system interaction, not a bar flyout.

At the start of a request, the prompt targets the focused output and requests
keyboard focus. It presents:

- the request message and resolved application/action icon;
- an identity selector only when more than one identity is available;
- the current PAM prompt and supplementary information;
- a text field only when `AuthFlow.isResponseRequired` is true, with echo mode
  taken directly from `AuthFlow.responseVisible`;
- explicit Authenticate and Cancel actions; and
- service-reported failure state without inventing a second retry model.

Enter submits the current response and Escape cancels the authorization
request. A failed attempt clears the response and keeps the same flow visible;
Quickshell starts the next authentication conversation itself. Requests that
are waiting on a fingerprint or another no-response PAM step remain legible
without showing a fake password requirement. The prompt must also handle a
request being cancelled externally.

The surface should use the shell's semantic theme and existing typography,
borders, title-band language, and input controls where they genuinely fit.
It should be a compact centered authorization surface on a transparent modal
input plane, not a feature panel and not a copy of the current agent window.
There is no new public IPC command: polkit's D-Bus request is the public event.

`PolkitAgent` queues requests and owns the active `AuthFlow`; Hyprkarl should
bind to that contract rather than adding its own queue or PAM layer. The
upstream implementation transfers the registered listener to a new QML
generation during a live reload, so the view must bind to the current flow
instead of snapshotting it.

The installed QML type metadata does not resolve `AuthFlow` correctly when
`qmllint` follows `PolkitAgent.flow`; the exact upstream v0.3.0 manual example
produces that warning too. Treat that specific warning as a tooling limitation
and make the live registration and prompt exercise authoritative. Do not add a
wrapper or weaken the QML types merely to silence it.

The cutover removed the old agent from Hyprland autostart and the installation
package list, and added it to `packages/remove.txt` for existing installations.
The live acceptance pass covered exclusive agent registration, a real
fingerprint authorization, the fingerprint-timeout transition to a password
prompt, Escape cancellation, and clean process completion. Password and
multiple-identity presentation remain direct bindings to `AuthFlow`; exercise
them when those PAM and account states are available on the test machine.

Running both agents is not supported because only one session agent can own
the polkit registration. An already-installed `hyprpolkitagent` package is
harmless after its user service is disabled; the normal update flow removes it.

## Lock-Screen Capability and Deferral

The installed build does expose the right basic primitives:

- `WlSessionLock` requests the secure `ext-session-lock-v1` protocol, reports
  when the compositor confirms the secure state, and creates one
  `WlSessionLockSurface` per output.
- `PamContext` supports an asynchronous PAM conversation, custom PAM files,
  hidden or visible responses, status messages, abort, and completion.
- `WlSessionLock` is reload-aware and its source accounts for output changes.

Those APIs are sufficient in shape, but not yet in release stability. The
upstream post-0.3.0 changelog records fixes for session-lock crashes during
sleep, wake, DPMS, and unlocking, as well as a crash when reading a lock
surface's visibility before its backing surface exists. Those fixes are not
part of Hyprkarl's installed 0.3.0-2.1 contract.

That is a release boundary, not an invitation to add Hyprkarl workarounds.
`hyprlock`, `hk-lock`, the `hypridle` lock path, the package, and the existing
theme output stay in place until the fixed Quickshell version is admitted.

When the version boundary is revisited, the preferred ownership is a small,
short-lived Quickshell lock process launched by `hk-lock`, separate from the
long-running desktop shell. A secure lock has a deliberately harsher process
lifecycle: if its client exits without unlocking, the compositor stays locked
with no interactive surface. Isolating it prevents an unrelated bar restart
or shell failure from becoming a lock-screen recovery problem. It may import
the shared semantic theme, but it should not instantiate bar services or
depend on the main shell's IPC.

One lock-process context owns authentication and shares it across the
per-output surfaces. Password and fingerprint authentication must remain
available in either order; do not force the user to wait for a fingerprint
timeout before entering a password. The exact PAM composition should be
verified against the admitted release before implementation rather than
encoded against the current unstable lock lifecycle.

The later acceptance pass must cover:

- wrong and correct passwords;
- fingerprint success, failure, retry, and password use while fingerprint
  authentication is available;
- monitor add/remove while locked;
- DPMS off/on;
- suspend and resume;
- unlock and immediate relock;
- a safe failed launch that leaves `hk-lock` reporting failure; and
- the compositor's secure fallback if the lock process crashes.

Only after that pass should Hyprkarl remove `hyprlock` or its theme artifacts.
