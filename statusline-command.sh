#!/bin/sh
# Claude Code status line script

input=$(cat)

BOLD=$(printf '\033[1m')
YELLOW=$(printf '\033[1;33m')
RED=$(printf '\033[1;31m')
RESET=$(printf '\033[0m')

color_val() {
  val=$1
  warn=$2
  crit=$3
  if [ "$(printf '%.0f' "$val")" -ge "$crit" ] 2>/dev/null; then
    printf '%s' "$RED"
  elif [ "$(printf '%.0f' "$val")" -ge "$warn" ] 2>/dev/null; then
    printf '%s' "$YELLOW"
  fi
}

# Current directory (use cwd from input)
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
if [ -n "$cwd" ]; then
  home="$HOME"
  short_cwd=$(basename "$cwd")
else
  short_cwd="$(pwd)"
fi

# Git branch (skip optional locks)
git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)

# Model display name
model=$(echo "$input" | jq -r '.model.display_name // empty')

# Context usage — map percentage to a single block character
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  if   [ "$used_int" -ge 88 ]; then block='█'
  elif [ "$used_int" -ge 76 ]; then block='▇'
  elif [ "$used_int" -ge 63 ]; then block='▆'
  elif [ "$used_int" -ge 51 ]; then block='▅'
  elif [ "$used_int" -ge 38 ]; then block='▄'
  elif [ "$used_int" -ge 26 ]; then block='▃'
  elif [ "$used_int" -ge 13 ]; then block='▂'
  else                               block='▁'
  fi
  col=$(color_val "$used" 70 90)
  ctx_part="${col}ctx:${block}${used_int}%${RESET}"
else
  ctx_part="ctx:▁"
fi

# Helper: map a percentage integer to a block character
pct_block() {
  p=$1
  if   [ "$p" -ge 88 ]; then printf '█'
  elif [ "$p" -ge 76 ]; then printf '▇'
  elif [ "$p" -ge 63 ]; then printf '▆'
  elif [ "$p" -ge 51 ]; then printf '▅'
  elif [ "$p" -ge 38 ]; then printf '▄'
  elif [ "$p" -ge 26 ]; then printf '▃'
  elif [ "$p" -ge 13 ]; then printf '▂'
  else                        printf '▁'
  fi
}

# Rate limits: 5-hour and 7-day (always shown, N/A fallback)
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

five_part="5h:▁N/A"
week_part="7d:▁N/A"
if [ -n "$five" ]; then
  five_fmt=$(printf '%.0f' "$five")
  five_block=$(pct_block "$five_fmt")
  col=$(color_val "$five" 50 80)
  five_part="${col}5h:${five_block}${five_fmt}%${RESET}"
fi
if [ -n "$week" ]; then
  week_fmt=$(printf '%.0f' "$week")
  week_block=$(pct_block "$week_fmt")
  col=$(color_val "$week" 50 80)
  week_part="${col}7d:${week_block}${week_fmt}%${RESET}"
fi

# Build dir | branch segment
dir_branch="${BOLD}${short_cwd}${RESET}"
if [ -n "$git_branch" ]; then
  dir_branch="${dir_branch} ${BOLD}|${RESET} ${BOLD}${git_branch}${RESET}"
fi

printf '%s | %s | %s | %s %s' \
  "$dir_branch" "${model:-N/A}" "$ctx_part" "$five_part" "$week_part"
