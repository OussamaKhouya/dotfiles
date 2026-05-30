#!/bin/bash
set -euo pipefail

STATE_DIR="$HOME/.local/state/hypr"
mkdir -p "$STATE_DIR"

shopt -s nullglob
files=("$STATE_DIR"/*.json)

if (( ${#files[@]} == 0 )); then
  echo "No saved session profiles in $STATE_DIR"
  exit 0
fi

for f in "${files[@]}"; do
  b=$(basename "$f" .json)
  count=$(jq 'length' "$f" 2>/dev/null || echo '?')
  mtime=$(date -r "$f" '+%Y-%m-%d %H:%M:%S')
  printf '%-20s windows=%-4s updated=%s\n' "$b" "$count" "$mtime"
done | sort