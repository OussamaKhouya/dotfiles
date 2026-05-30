#!/bin/bash
set -euo pipefail

STATE_DIR="$HOME/.local/state/hypr"
PROFILE="${1:-last-session}"
PROFILE_SAFE=$(printf '%s' "$PROFILE" | tr -cd '[:alnum:]_.-')
[[ -n "$PROFILE_SAFE" ]] || PROFILE_SAFE="last-session"
STATE_FILE="$STATE_DIR/${PROFILE_SAFE}.json"

mkdir -p "$STATE_DIR"

hyprctl -j clients | jq '[.[] | {
  workspace: (.workspace.id // -1),
  class: (.class // ""),
  initialClass: (.initialClass // ""),
  title: (.title // "")
}]' > "$STATE_FILE"

# Keep compatibility with existing auto-restore path
if [[ "$PROFILE_SAFE" != "last-session" ]]; then
  cp -f "$STATE_FILE" "$STATE_DIR/last-session.json"
fi

echo "saved profile '$PROFILE_SAFE' -> $STATE_FILE"