#!/bin/bash
# Run Bash syntax checks across the repo's shell entrypoints and helpers.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)

files=()

while IFS= read -r file; do
  files+=("$file")
done < <(
  cd "$REPO_ROOT" || exit 1
  {
    printf '%s\n' setup-*.sh
    find bin scripts -type f
  } | sort -u
)

if ((${#files[@]} == 0)); then
  echo "No shell files found." >&2
  exit 1
fi

cd "$REPO_ROOT" || exit 1
bash -n "${files[@]}"
