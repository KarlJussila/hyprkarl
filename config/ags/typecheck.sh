#!/bin/bash
# Type-check the bar's own sources with tsc.
#
# `npm run check` only bundles (esbuild strips types without checking them), so
# type errors never fail that command — they show only as editor squiggles. This
# runs a real `tsc --noEmit` and is the command to trust before considering a
# change done.
#
# tsc also reports errors inside AGS's bundled library sources (/usr/share/ags,
# gnim) because our imports pull them in, and skipLibCheck only skips .d.ts
# files. Those are upstream, not ours, so we drop them: keep a "file(line,col):"
# error header (and its indented continuation lines) only when the file is one
# of ours — a project-relative path, not ../ or node_modules.

cd "$(dirname "$0")" || exit 2

output=$(npx tsc --noEmit -p tsconfig.json 2>&1)

ours=$(echo "$output" | awk '
  /^[^ ]/ { keep = /^(bar\/|app\.ts|env\.d\.ts)/ }
  keep
')

if [ -n "$ours" ]; then
  echo "$ours"
  exit 1
fi

echo "No type errors in bar sources."
