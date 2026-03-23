#!/bin/sh
# Claude Code status line script

input=$(cat)

YELLOW=$(printf '\033[33m')
RED=$(printf '\033[31m')
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
  short_cwd="${cwd/#$home/\~}"
else
  short_cwd="$(pwd)"
fi

# Git branch (skip optional locks)
git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)

# Model display name
model=$(echo "$input" | jq -r '.model.display_name // empty')

# Context usage
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Rate limits: 5-hour and 7-day
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Build the status line
line="${short_cwd}"

if [ -n "$git_branch" ]; then
  line="${line} | ${git_branch}"
fi

if [ -n "$model" ]; then
  line="${line} | ${model}"
fi

# Context usage with color (warn:70% crit:90%)
if [ -n "$used" ]; then
  used_fmt=$(printf '%.0f' "$used")
  col=$(color_val "$used" 70 90)
  line="${line} | ${col}ctx:${used_fmt}%${RESET}"
fi

# Rate limits with color (warn:50% crit:80%)
if [ -n "$five" ] || [ -n "$week" ]; then
  limits=""
  if [ -n "$five" ]; then
    five_fmt=$(printf '%.0f' "$five")
    col=$(color_val "$five" 50 80)
    limits="${col}5h:${five_fmt}%${RESET}"
  fi
  if [ -n "$week" ]; then
    week_fmt=$(printf '%.0f' "$week")
    col=$(color_val "$week" 50 80)
    if [ -n "$limits" ]; then
      limits="${limits} ${col}7d:${week_fmt}%${RESET}"
    else
      limits="${col}7d:${week_fmt}%${RESET}"
    fi
  fi
  line="${line} | ${limits}"
fi

printf '%s' "$line"
