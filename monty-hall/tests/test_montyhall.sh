#!/usr/bin/env bash
set -euo pipefail

SCRIPT="monty-hall/scripts/montyhall.sh"

output=$(bash "$SCRIPT" --trials 100 --strategy switch --seed 123 2>&1)
printf '%s\n' "$output" | grep -q "Strategy: switch"
printf '%s\n' "$output" | grep -q "Win rate"

echo "Monty Hall simulation passed"
