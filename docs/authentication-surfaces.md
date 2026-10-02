# Authentication surfaces

Quickshell provides session locking and polkit prompts. The lock feature lives
under `config/quickshell/modules/lock/` and shares the shell's theme and
components. `hk-lock` starts its `lock.qml` entry point as a separate process, so
restarting the bar does not affect an active lock.

## Locking and authentication

`hk-lock` locks the session. Repeated calls reuse the running locker.
`hk-suspend` only suspends: Hypridle's `before_sleep_cmd` runs `hk-lock`, and
`inhibit_sleep = 3` holds suspend until the lock is secure. The lock engages
before it reads the theme, so a broken theme cannot leave the session unlocked.

Password and fingerprint authentication run side by side, so you can type a
password while the reader scans. Fingerprint scanning is on when fingers are
enrolled (`hk-fingerprint list`). A default install has no fprintd; run
`hk-fingerprint setup` to install it and enroll a finger. Scanning stops before
sleep and restarts on resume.

Submitted password dots dim during verification. A rejected password clears
them and shakes the field with a red border. A fingerprint failure shakes and
tints its icon. Escape clears the password attempt.

If the lock process crashes, Hyprland keeps the session locked; recovery then
needs access from outside the session. Read diagnostics with:

```bash
qs -p ~/.config/quickshell/lock.qml log
```

## Customizing the lock

Appearance lives in personal theme sources under `shell.lock`: `width`,
`padding`, `spacing`, `radius`, `inputHeight`, `inputFontSize`,
`clockFontSize`, `dateFontSize`, `dimOpacity`, `clockFormat`, `dateFormat`,
`transitionDuration`, `fadeDuration`, `failureDuration`, `fingerprintSize`,
and `fingerprintCompleteDuration`. Run `hk-theme set <name>` to apply them.

Password authentication uses the system's `/etc/pam.d/login` stack. Fingerprint
uses `config/quickshell/modules/lock/pam/fingerprint`, which runs only
`pam_fprintd`. PAM resolves includes inside a custom directory, so that file
cannot include `/etc/pam.d` stacks.

To replace the lock entirely, put your own `hk-lock` in `~/.local/bin/`; see
[Replace a built-in](extending-hyprkarl.md#replace-a-built-in). Keybindings and
Hypridle call `hk-lock`, so they use yours. A Quickshell lock can reuse the
shipped authentication by importing `modules/lock` from
`~/.config/quickshell/`.

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
