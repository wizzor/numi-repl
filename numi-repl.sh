#!/usr/bin/env bash
# numi-repl.sh — interactive REPL for numi-cli with `prev` substitution + debug mode

set -o pipefail

# --- Colors ---
CLR_WHITE="\033[37m"
CLR_GREEN="\033[32m"
CLR_RED="\033[31m"
CLR_GRAY="\033[90m"
CLR_RESET="\033[0m"

# --- Args & Debug flag ---
DEBUG="${NUMI_REPL_DEBUG:-0}"
for arg in "$@"; do
  case "$arg" in
    -d|--debug) DEBUG=1 ;;
    -h|--help)
      cat <<EOF
Usage: $(basename "$0") [--debug]
Options:
  -d, --debug      Print evaluated command before running numi-cli (gray)
  -h, --help       Show this help
You can also enable debug via environment: NUMI_REPL_DEBUG=1 $(basename "$0")
EOF
      exit 0
      ;;
  esac
done

# --- Clear terminal on open ---
if command -v tput >/dev/null 2>&1; then
  tput clear
elif command -v clear >/dev/null 2>&1; then
  clear
else
  printf "\033[2J\033[H"
fi

# --- Check numi-cli availability ---
if ! command -v numi-cli >/dev/null 2>&1; then
  echo -e "${CLR_RED}numi-cli not found.${CLR_RESET}"
  echo "Please install it by following instructions at: https://github.com/nikolaeu/numi"
  exit 1
fi

# --- Readline/history setup for up/down arrows ---
set -o history 2>/dev/null || true
HISTFILE=/dev/null
shopt -s histappend 2>/dev/null || true

# --- Pick sed extended-regex flag (-E for BSD/GNU, -r for older GNU/busybox) ---
SED_E_FLAG='-E'
if ! printf '' | sed -E 's/a/b/' >/dev/null 2>&1; then
  SED_E_FLAG='-r'
fi

# --- State ---
prev=""

# --- Helpers ---

# Safely substitute whole-word 'prev' with the previous value.
# Word boundary is emulated as: (^|[^[:alnum:]_])prev([^[:alnum:]_]|$)
substitute_prev() {
  local expr="$1" p="$2"

  # If 'prev' appears but we have no previous value, signal that.
  if [[ "$expr" =~ (^|[^[:alnum:]_])prev([^[:alnum:]_]|$) ]] && [[ -z "$p" ]]; then
    echo "__NO_PREV__"
    return 0
  fi

  # Escape replacement for sed replacement context: backslash, ampersand, and slash.
  local rep="$p"
  rep="${rep//\\/\\\\}"
  rep="${rep//&/\\&}"
  rep="${rep//\//\\/}"

  # Perform whole-word replacement with captures to keep surrounding chars.
  printf '%s' "$expr" | sed $SED_E_FLAG "s/(^|[^[:alnum:]_])prev([^[:alnum:]_]|$)/\\1${rep}\\2/g"
}

# Print input (white) and result (green, right-aligned)
print_io() {
  local input="$1"
  local output="$2"

  echo -e "${CLR_WHITE}${input}${CLR_RESET}"

  local cols
  cols=$(tput cols 2>/dev/null) || cols=80

  while IFS= read -r line || [[ -n "$line" ]]; do
    local len=${#line}
    local pad=0
    if (( cols > len )); then pad=$((cols - len)); fi
    printf "%*s" "$pad" ""
    echo -e "${CLR_GREEN}${line}${CLR_RESET}"
  done <<< "$output"
}

echo 'type exit or ctrl-d to exit'

# --- Main loop ---
while true; do
  if ! IFS= read -r -e -p "numi> " line; then
    echo
    break
  fi

  # Empty input => do nothing
  if [[ -z "$line" ]]; then
    continue
  fi

  case "$line" in
    exit|quit) break ;;
  esac

  history -s -- "$line" 2>/dev/null || true

  transformed="$(substitute_prev "$line" "$prev")"
  if [[ "$transformed" == "__NO_PREV__" ]]; then
    echo -e "${CLR_RED}No previous value yet; try an expression without 'prev' first.${CLR_RESET}"
    continue
  fi

  # Debug line shows exactly what will be executed.
  if [[ "$DEBUG" == "1" ]]; then
    echo -e "${CLR_GRAY}[debug] numi-cli -- ${transformed}${CLR_RESET}"
  fi

  result="$(numi-cli -- "$transformed" 2>&1)"
  status=$?

  if (( status != 0 )); then
    print_io "$transformed" ""
    echo -e "${CLR_RED}${result}${CLR_RESET}"
    continue
  fi

  print_io "$transformed" "$result"
  prev="$result"
done

echo "Goodbye!"

