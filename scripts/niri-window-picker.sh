#!/usr/bin/env bash
## niri-window-picker.sh — Select and focus a niri window with fuzzel.
set -euo pipefail

window_list="$({
  niri msg -j windows |
    jq -r '
      sort_by([(.workspace_id // 0), .id])
      | .[]
      | [
          (.id | tostring),
          ((if .is_focused then "● " else "  " end)
            + "workspace " + ((.workspace_id // 0) | tostring)
            + " · " + (.app_id // "unknown")
            + " — " + ((.title // "(untitled)") | gsub("[\\t\\r\\n]"; " ")))
        ]
      | @tsv
    '
} )"

[[ -n "${window_list}" ]] || exit 0

selected_id="$({
  printf '%s\n' "${window_list}"
} | fuzzel \
  --dmenu \
  --only-match \
  --prompt 'Window> ' \
  --placeholder 'Search windows' \
  --lines 12 \
  --width 100 \
  --tabs 4 \
  --with-nth 2 \
  --match-nth 2 \
  --accept-nth 1 \
  --no-run-if-empty
)" || exit 0

[[ -n "${selected_id}" ]] || exit 0
niri msg action focus-window --id "${selected_id}"
