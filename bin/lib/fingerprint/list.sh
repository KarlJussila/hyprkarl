#!/bin/bash
# List enrolled fingerprints, one finger name per line.
#
# Usage:
#   hk-fingerprint list

if ! command -v fprintd-list &>/dev/null; then
  exit 1
fi

fprintd-list "$USER" 2>/dev/null | awk -F': ' '/^ - #/ {print $2}'
