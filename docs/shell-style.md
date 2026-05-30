# Shell Style

## Goals

Scripts in this repo run in a known, controlled environment: CachyOS + Hyprland, a single user session, with all Hyprkarl dependencies and the full suite of `hk-*` commands always available. There's no need to defend against a minimal POSIX shell or an absent dependency.

The goal is readability over robustness theater. Scripts should read top-to-bottom like a clear sequence of steps. No strict mode, minimal defensive wrappers. Handle the errors you actually care about; ignore the ones you don't.

---

## Structure

```bash
#!/bin/bash
# hk-example
# One-line description of what this script does.

# --- Constants ---
SOME_DIR="$HYPRKARL_PATH/some/path"

# --- Functions ---
do_thing() { ... }

# --- Script Body ---
input="${1:-}"

if [[ -z "$input" ]]; then
  echo "Usage: hk-example <input>" >&2
  exit 1
fi

do_thing "$input"
```

- Script body runs at the top level — no `main()` wrapper
- For multi-phase scripts (parse → prompt → validate → run), a `main()` that calls named phase functions is appropriate: `main "$@"` at the bottom

---

## Error Handling

No `set -euo pipefail`. Guard clauses use `if` blocks:

```bash
if [[ ! -f "$input" ]]; then
  echo "File not found: $input" >&2
  exit 1
fi
```

Use `||` only for true one-liners where the exit naturally fits on the same line:

```bash
command -v ffmpeg &>/dev/null || exit 1
```

---

## Output & Logging

Use `gum log` for user-facing output:

```bash
dbg()   { [[ "${DEBUG:-0}" -ne 0 ]] && gum log --level debug "$*"; }
info()  { gum log --level info  "$*"; }
warn()  { gum log --level warn  "$*"; }
error() { gum log --level error "$*"; exit 1; }
```

Plain `echo` is fine for simple status lines. `printf` for structured/aligned output. Errors always go to stderr (`>&2`).

---

## Variables

```bash
# Script-level constants: UPPER_SNAKE_CASE
POLL_INTERVAL=30

# Working variables: lower_snake_case
input_file="$1"

# Always quote expansions
cp "$src" "$dst"
[[ -f "$path" ]]

# Use ${} when adjacent to other identifier characters
echo "${prefix}_suffix"

# Safe defaults
input="${1:-}"
port="${PORT:-8080}"
required="${VAR:?VAR is required}"
```

`readonly` is available but not required — UPPER_CASE is sufficient signal.

---

## Functions

```bash
process_file() {
  local path="$1"
  local result
  result="$(some_command "$path")"   # split so failure is catchable
  echo "$result"
}
```

- Every variable inside a function is `local`
- Declare and assign on separate lines when assigning from a subshell
- Functions return data via stdout (`$()`), booleans via exit code

---

## Dispatchers

Dispatcher scripts route a subcommand to `hk-noun-action` implementations:

```bash
action=${1:-}
shift || true

case "$action" in
  start|stop|status) exec "hk-docker-$action" "$@" ;;
  ""|-h|--help|help) usage; exit 0 ;;
  *) usage >&2; exit 1 ;;
esac
```

`exec` replaces the shell process. `shift || true` drops the action before passing `"$@"` along.

For usage display: a one-liner inline for simple scripts; a `usage()` heredoc function for dispatchers with multiple subcommands.

---

## Quick Reference

| | Do | Don't |
|---|---|---|
| Shebang | `#!/bin/bash` | `#!/usr/bin/env bash` |
| Strict mode | — | `set -euo pipefail` |
| Guard clauses | `if [[ ... ]]; then ... exit 1; fi` | overuse `\|\|` / `&&` |
| One-liner guards | `cmd \|\| exit 1` | stretching `\|\|` to carry a message |
| Constants | `UPPER_SNAKE_CASE` | `readonly` (optional) |
| Logging | `gum log --level info/warn/error` | custom echo wrappers |
| Conditionals | `[[ ]]` | `[ ]` |
| Command sub | `$(cmd)` | `` `cmd` `` |
| Local vars | `local x; x=$(cmd)` | `local x=$(cmd)` |
| Array iteration | `"${arr[@]}"` | `${arr[*]}` or `$arr` |
