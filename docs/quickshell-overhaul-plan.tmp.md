# Temporary Quickshell overhaul plan

This is the current work sequence. Remove it when the work is complete;
public behavior belongs in the ordinary manual.

## Current pickup

The shell now groups desktop coordination under `desktop/`, bar-specific code
under `bar/`, functional modules under `modules/`, and shared UI by purpose
under `ui/`. `shell.qml` and `lock.qml` are small process entry points.

The lock module uses the shared theme and ships its PAM policies in
`modules/lock/pam/`. It locks unconditionally and leaves suspend ordering to
Hypridle. Fingerprint scanning follows enrollment; there are no lock settings.

Native password and fingerprint unlock, password rejection, fingerprint
mismatch/retry, immediate relocking, DPMS, and the final animations have live
evidence. Isolated production-QML checks cover secure-before-suspend ordering,
startup failure, sleep/resume, and reader-error recovery. Actual suspend/resume,
output hotplug, and a live locker crash remain to be checked.

## Remaining sequence

1. Complete the lock acceptance checks above.
2. Audit the shipped packages and commands for native personal configuration,
   override order, disable/replacement choices, and reload actions. Close actual
   gaps and document the editing paths.
3. Write concise guidance for an AI customizing an installed Hyprkarl system.
   Route it to personal files and canonical docs. Keep contributor instructions
   separate; no AI runtime integration is planned.
4. Revisit nightlight later. Keep Hyprsunset and the existing `hk-nightlight`
   commands; make enabled/disabled targets personal choices using native config
   where possible.

Hyprpaper, Hypridle, and Hyprshutdown are optional candidates for later
Quickshell consolidation, outside the lock work.

## Settled decisions

- Theme activation owns GTK theme, icon theme, and color preference. Configure
  those synchronized choices in personal theme sources.
- Terminal `local.*` files load after theme/default values through native
  includes and preserve personalization across updates.
- Personal Quickshell JSON belongs in `~/.config/quickshell/settings/`; personal
  QML belongs in `~/.config/quickshell/custom/`. The existing migration command
  moves old copies and preserves conflicts.
- User-authored QML, scripts, themes, and hooks are trusted. Prefer direct files
  and imports over discovery or registration systems.

See [authentication](authentication-surfaces.md),
[configuration ownership](configuration-map.md), and [themes](themes.md).
