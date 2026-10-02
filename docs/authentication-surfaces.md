# Authentication surfaces

Quickshell provides session locking and polkit prompts. The lock feature lives
under `config/quickshell/modules/lock/` and shares the shell's theme and
components. `hk-lock` starts its `lock.qml` entry point in an independent
process, so restarting the bar preserves an active lock.

## Locking and authentication

`hk-lock` locks the session; `hk-suspend` locks and suspends. Repeated lock calls
reuse the existing process. Suspension waits for the compositor to confirm
secure locking. Password and fingerprint authentication run independently,
so password entry remains available while the reader scans or recovers.

Fingerprint enrollment is detected automatically using `hk-fingerprint list`.
Without enrollment, fingerprint authentication and its icon are disabled.
A default install does not include fprintd. Use `hk-fingerprint setup`, then
`hk-fingerprint enroll <finger-name>` to enable it.

Scanning stops before sleep and starts fresh on resume. Ordinary locking
starts scanning once enrollment and secure locking are confirmed. Mismatches
retry after the configured delay; reader errors retry with increasing delays
from one to ten seconds.

Submitted password dots dim during verification. A rejected password clears
them and briefly shakes the field with a red border. Fingerprint failures
briefly shake and tint its icon. Successful authentication finishes the unlock
animation before releasing the lock. Escape clears the password attempt.

The implementation uses Quickshell 0.3.1's `WlSessionLock` and `PamContext`.
Quickshell and Hyprland own secure output coverage. If the lock process crashes,
Hyprland retains the lock; recovery then requires access outside the locked
session. Read diagnostics with:

```bash
qs -p "$HYPRKARL_PATH/config/quickshell/lock.qml" log
```

## Personal lock configuration

Lock behavior uses the `lock` object in
`~/.config/quickshell/settings/shell.json`:

| Key | Default | Purpose |
| --- | --- | --- |
| `fingerprintEnabled` | `null` | Detect enrollment automatically; `false` disables scanning and its icon; `true` forces scanning |
| `fingerprintRetryDelay` | `200` | Milliseconds between retries after mismatches or exhausted attempts |

For example, disable fingerprint authentication with:

```json
{"version": 1, "lock": {"fingerprintEnabled": false}}
```

Edit native PAM policies directly in `~/.config/quickshell/pam/`:

- `password` starts with `auth include system-auth`.
- `fingerprint` starts with `auth required pam_fprintd.so`.

Setup seeds these files once. Updates preserve edits and deliberate deletion.
PAM edits affect new authentication attempts. PAM requires service files, so these policies
remain files rather than QML strings or additional JSON settings.

Appearance belongs in personal theme sources under `shell.lock`. Available
values are `width`, `padding`, `spacing`, `radius`, `inputHeight`, `inputFontSize`,
`clockFontSize`, `dateFontSize`, `dimOpacity`, `clockFormat`, `dateFormat`,
`transitionDuration`, `fadeDuration`, `failureDuration`, `fingerprintSize`, and
`fingerprintCompleteDuration`. Run `hk-theme set <name>` to apply theme changes.

A complete personal lock configuration can set `HYPRKARL_LOCK_SOURCE` in
`~/.config/uwsm/env.local` to its QML entry file or directory. To support
`hk-suspend`, it must implement `lock suspend` IPC and wait for secure locking
before suspending. Session environment changes require a new session.

## Polkit Design

`desktop/Desktop.qml` retains exactly one `PolkitState` singleton. That object
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
