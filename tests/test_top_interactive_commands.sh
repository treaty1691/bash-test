#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

bash -c '
  source "$0/scripts/top.sh"
  order_field=cpu
  process_count=10
  delay=2
  exit_requested=0

  handle_command_string ":o mem"
  [[ "$order_field" == "mem" ]]

  handle_command_string ":o command"
  [[ "$order_field" == "command" ]]

  handle_command_string ":n 25"
  [[ "$process_count" == "25" ]]

  handle_command_string ":d 0.5"
  [[ "$delay" == "0.5" ]]

  handle_command_string ":q"
  [[ "$exit_requested" == "1" ]]
' "$PROJECT_ROOT"

echo "All tests passed."
