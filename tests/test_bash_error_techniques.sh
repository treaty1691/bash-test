#!/usr/bin/env bash
set -euo pipefail

SCRIPT="scripts/bash-error-techniques.sh"

echo "Running demo (should succeed)"
output=$(bash "$SCRIPT" --demo) || { echo "Demo run failed"; echo "$output"; exit 1; }
echo "$output" | grep -q "DEMO START" || { echo "Demo output missing expected markers"; echo "$output"; exit 1; }

echo "Testing require-file with missing file (should fail)"
if bash "$SCRIPT" --require-file missing_hopefully_12345.txt >/dev/null 2>err.log; then
  echo "Expected failure when requiring missing file"; cat err.log; exit 1
else
  grep -q "ERROR: Required file" err.log || { echo "Did not find expected error message"; cat err.log; exit 1; }
fi

echo "Testing temp-demo creates then cleans temp file"
tmpout=$(bash "$SCRIPT" --temp-demo) || { echo "temp-demo failed"; echo "$tmpout"; exit 1; }
tmpfile=$(echo "$tmpout" | grep -oE "/tmp/tmp[[:alnum:]]+" || true)
if [[ -n "$tmpfile" ]]; then
  if [[ -e "$tmpfile" ]]; then
    echo "Temp file still exists after script exit: $tmpfile"; exit 1
  fi
fi

echo "All checks passed"
exit 0
