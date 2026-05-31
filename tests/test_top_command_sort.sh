#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

bash -c '
  source "$0/scripts/top.sh"
  order_field=command
  get_ps_sort_option
' "$PROJECT_ROOT" | grep -xq 'comm'

echo "All tests passed."
