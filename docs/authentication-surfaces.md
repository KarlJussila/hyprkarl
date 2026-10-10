# Authentication surfaces

The shell draws the lock screen and the polkit prompt. `hk-lock` runs the lock
screen as its own process, so restarting the shell never affects an active
lock. GNOME Keyring stores application credentials.

## Application credentials

On installation, a one-time migration creates a passwordless `Login` keyring and
makes it the default
when no keyrings or default selection exist. It lives under
`${XDG_DATA_HOME:-$HOME/.local/share}/keyrings/`. Existing keyrings and their
passwords take precedence.

The passwordless keyring needs no unlock prompt, matching Hyprkarl's automatic
login after disk unlock.

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

## Polkit prompt

When an application asks for administrator rights, the prompt opens on the
focused monitor with the request, the application's icon, and an identity
picker when more than one account can approve it. It asks for a password only
when PAM needs one, so a fingerprint request shows its own message. Enter
submits, Escape cancels, and a failed attempt clears the field and asks again.
Its appearance comes from the theme's `shell.polkit` values.

To use another polkit agent, turn the prompt off with `"modules": { "polkit":
false }` in `shell.json`, run `hk-shell restart`, and start your agent; only
one agent can be registered at a time.
