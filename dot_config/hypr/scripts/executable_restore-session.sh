#!/bin/bash
set -euo pipefail

STATE_DIR="$HOME/.local/state/hypr"
PROFILE="${1:-last-session}"
PROFILE_SAFE=$(printf '%s' "$PROFILE" | tr -cd '[:alnum:]_.-')
[[ -n "$PROFILE_SAFE" ]] || PROFILE_SAFE="last-session"
STATE_FILE="$STATE_DIR/${PROFILE_SAFE}.json"
MAP_FILE="$HOME/.config/hypr/session-restore.map"

[[ -f "$STATE_FILE" ]] || exit 0

# Wait until Hyprland is ready
for _ in {1..30}; do
  hyprctl -j monitors >/dev/null 2>&1 && break
  sleep 0.2
done
sleep 2

resolve_command() {
  local app_class="$1"

  # User overrides (highest priority): CLASS=command
  if [[ -f "$MAP_FILE" ]]; then
    local mapped
    mapped=$(awk -F'=' -v key="$app_class" 'BEGIN{IGNORECASE=1} $1==key {sub(/^[^=]*=/, "", $0); print $0; exit}' "$MAP_FILE" || true)
    if [[ -n "$mapped" ]]; then
      printf '%s\n' "$mapped"
      return 0
    fi
  fi

  # Built-in defaults
  case "$app_class" in
    firefox|Firefox) echo "omarchy-launch-browser" ;;
    Alacritty|alacritty) echo "uwsm-app -- xdg-terminal-exec" ;;
    kitty|Kitty) echo "uwsm-app -- kitty" ;;
    code-oss|Code|code-url-handler) echo "uwsm-app -- code" ;;
    obsidian|Obsidian) echo "uwsm-app -- obsidian" ;;
    signal|Signal|signal-desktop) echo "uwsm-app -- signal-desktop" ;;
    spotify|Spotify) echo "uwsm-app -- spotify" ;;
    nautilus|org.gnome.Nautilus) echo "uwsm-app -- nautilus --new-window" ;;
    chromium|Chromium) echo "uwsm-app -- chromium" ;;
    Google-chrome|google-chrome|google-chrome-stable) echo "uwsm-app -- google-chrome-stable" ;;
    *) return 1 ;;
  esac
}

jq -c '.[]' "$STATE_FILE" | while read -r item; do
  ws=$(jq -r '.workspace' <<< "$item")
  class=$(jq -r '.class' <<< "$item")
  initial_class=$(jq -r '.initialClass' <<< "$item")

  app_class="$class"
  [[ -n "$app_class" ]] || app_class="$initial_class"

  if cmd=$(resolve_command "$app_class"); then
    if [[ "$ws" != "-1" ]]; then
      # Launch directly into target workspace (more reliable than switching first)
      hyprctl dispatch exec "[workspace $ws silent] $cmd" >/dev/null 2>&1 || true
    else
      hyprctl dispatch exec "$cmd" >/dev/null 2>&1 || true
    fi
    sleep 0.15
  fi
done

echo "restored profile '$PROFILE_SAFE' from $STATE_FILE"