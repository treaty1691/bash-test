#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

output=$(bash "$PROJECT_ROOT/scripts/top.sh" -0 -o mem -n 20)

if [[ "$output" != *"top -"* ]]; then
  echo "Expected top header in output, got:\n$output"
  exit 1
fi

if [[ "$output" != *"PID USER"* ]]; then
  echo "Expected process table header in output, got:\n$output"
  exit 1
fi

if [[ "$output" != *"order: mem"* ]]; then
  echo "Expected order field to show 'order: mem', got:\n$output"
  exit 1
fi

echo "All tests passed."
