# Command Script Style

## Goals

Scripts in this repo run in a known, controlled environment: CachyOS + Hyprland, a single user session, with all Hyprkarl dependencies and the full suite of `hk-*` commands always available. There's no need to defend against a minimal POSIX shell or an absent dependency. The session environment is part of that guarantee: `HYPRKARL_PATH` (set in `config/uwsm/env`) is always present inside a Hyprkarl session, so scripts use it without fallbacks. Only the install/update path (`bin/lib/update.sh` and the `setup-*.sh` scripts), which must work from a TTY before any session exists, carries a default.

The goal is readability over robustness theater. Scripts should read top-to-bottom like a clear sequence of steps. Handle the errors you actually care about; ignore the ones you don't.

## Choosing Bash or Python

Use Bash when the command is primarily a short sequence of other commands,
redirections, or simple conditionals. Use Python when it owns structured data,
JSON generation, substantial parsing, or nontrivial string transformation.
Do not preserve a dense `jq`, `sed`, or `awk` pipeline merely to keep a command
in Bash when ordinary Python data structures express the work directly.

Dynamic menu providers should normally be Python executables using the standard
library `json` module. Construct lists and dictionaries, then serialize them;
do not assemble JSON strings by hand. No third-party JSON package is needed.
A provider that only validates and prints an already-generated JSON file may
remain Bash because Bash is cleanest for that job.

Prefer making the whole command a small Python executable over embedding a
large `python3 -c` program inside Bash. Shared Python logic used by multiple
commands belongs in `bin/lib/*.py`, just as shared Bash logic belongs in
`bin/lib/*.sh`.

---

## Bash Structure

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

## Python Structure

Use `#!/usr/bin/env python3`, standard Python data structures, and a
`main() -> int` entry point:

```python
#!/usr/bin/env python3
"""Print example dynamic menu entries."""

import json
import sys


def main() -> int:
    entries = [
        {
            "id": "example.notes",
            "label": "Notes",
            "action": {"type": "command", "command": "foot -D ~/Notes"},
        }
    ]
    json.dump(entries, sys.stdout, ensure_ascii=False, separators=(",", ":"))
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

Catch failures at real external boundaries and report concise errors to
stderr. Let internal helpers rely on their contracts instead of wrapping every
operation in broad exception handling.
Prefer one exception boundary around a user-initiated external workflow over
translating and re-catching individual exception types. Use a per-item boundary
only when skipping one failed item lets the command return useful remaining
results.

---

## Bash Error Handling

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

## Bash Output & Logging

Use `gum log` for user-facing output:

```bash
dbg()   { [[ "${DEBUG:-0}" -ne 0 ]] && gum log --level debug "$*"; }
info()  { gum log --level info  "$*"; }
warn()  { gum log --level warn  "$*"; }
error() { gum log --level error "$*"; exit 1; }
```

Plain `echo` is fine for simple status lines. `printf` for structured/aligned output. Errors always go to stderr (`>&2`).

---

## Bash Variables

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

## Bash Functions

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

## Comments

Comment the *why*, not the *what* — ordering constraints, non-obvious behavior,
empirically verified gotchas — rather than restating the code. Exception: when
the code itself is genuinely hard to read and can't reasonably be simplified
(dense `jq`/`awk` pipelines, regexes, parameter-expansion tricks), a plain
"what" comment is acceptable and helpful. Use `# --- Section ---` headers to
break up longer scripts.

---

## Bash Dispatchers

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

## Bash Quick Reference

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
