#!/usr/bin/env bash
set -euo pipefail

# Demonstrates basic Bash error-handling techniques.
# Usage: bash scripts/bash-error-techniques.sh [--demo] [--require-file FILE] [--temp-demo] [--fail-func]

ERROR_CODE_GENERIC=1

error() {
  local msg="$1"
  local code=${2:-$ERROR_CODE_GENERIC}
  printf "ERROR: %s\n" "$msg" >&2
  return "$code"
}

info() { printf "INFO: %s\n" "$1"; }

on_error() {
  local exit_code=$?
  local lineno=${1:-${LINENO}}
  local cmd=${BASH_COMMAND:-}
  printf "\n---\nScript failed with exit code %d\nCommand: %s\nLine: %s\n---\n" "$exit_code" "$cmd" "$lineno" >&2
}

cleanup() {
  if [[ -n "${TMPFILE:-}" && -e "$TMPFILE" ]]; then
    rm -f "$TMPFILE" || true
    info "Removed temp file: $TMPFILE"
  fi
}

trap 'on_error $LINENO' ERR
trap cleanup EXIT

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --demo             Run the non-destructive demo showing techniques
  --require-file F   Exit with error if file F does not exist
  --temp-demo        Create a temp file and show cleanup on exit
  --fail-func        Demonstrate returning a non-zero code from a function
  --help             Show this help
EOF
}

# Run a command with a timeout (seconds). Uses GNU `timeout` if available,
# otherwise falls back to a background watcher that kills the process.
run_with_timeout() {
  local seconds="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
    return $?
  else
    "$@" &
    local pid=$!
    (
      sleep "$seconds"
      if kill -0 "$pid" 2>/dev/null; then
        info "Command timed out after ${seconds}s; killing pid $pid"
        kill -TERM "$pid" 2>/dev/null || true
        sleep 1
        kill -KILL "$pid" 2>/dev/null || true
      fi
    ) &
    local watcher=$!
    wait "$pid" 2>/dev/null || true
    kill -9 "$watcher" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    return $?
  fi
}

demo_strict_mode() {
  info "Strict mode is enabled: set -euo pipefail"
  info "This causes the script to exit on errors, undefined variables, or failing pipelines."
}

demo_function_return() {
  info "Demonstrating function return codes"
  failing_fn() {
    printf "Doing something that fails...\n" >&2
    return 42
  }

  if failing_fn; then
    info "failing_fn unexpectedly succeeded"
  else
    info "failing_fn returned non-zero as expected"
  fi
}

demo_tempfile() {
  TMPFILE=$(mktemp) || error "mktemp failed" 2
  info "Created temp file: $TMPFILE"
  printf "temporary data\n" >"$TMPFILE"
  info "Wrote to temp file"
  # file will be removed by the EXIT trap
}

demo_pipeline() {
  info "Demonstrating safe pipelines (pipefail enabled)"
  # the following pipeline will fail because grep exits 1; pipefail makes the script treat it as failure
  if printf "one\ntwo\n" | grep -q "three" ; then
    info "found three"
  else
    info "did not find three (grep returned non-zero)"
  fi
}

main() {
  if [[ ${#@} -eq 0 ]]; then
    usage
    return 0
  fi

  local demo=0
  local temp_demo=0
  local fail_func=0
  local require_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --demo) demo=1; shift ;;
      --timeout-demo) timeout_demo=1; shift ;;
      --temp-demo) temp_demo=1; shift ;;
      --fail-func) fail_func=1; shift ;;
      --require-file) require_file="$2"; shift 2 ;;
      --help) usage; exit 0 ;;
      *) error "Unknown option: $1" 2; usage; exit 2 ;;
    esac
  done

  demo_strict_mode

  if [[ -n "$require_file" ]]; then
    if [[ ! -e "$require_file" ]]; then
      error "Required file '$require_file' does not exist" 3
      exit 3
    else
      info "Found required file: $require_file"
    fi
  fi

  if [[ $demo -eq 1 ]]; then
    info "--- DEMO START ---"
    demo_function_return
    demo_pipeline
    info "--- DEMO END ---"
  fi

  if [[ ${timeout_demo:-0} -eq 1 ]]; then
    info "--- TIMEOUT DEMO START ---"
    info "Running a command that sleeps 5s with a 2s timeout"
    if run_with_timeout 2 sleep 5; then
      info "sleep completed before timeout (unexpected)"
    else
      info "sleep was terminated due to timeout (expected)"
    fi
    info "--- TIMEOUT DEMO END ---"
  fi

  if [[ $temp_demo -eq 1 ]]; then
    info "--- TEMPFILE DEMO START ---"
    demo_tempfile
    info "--- TEMPFILE DEMO END ---"
  fi

  if [[ $fail_func -eq 1 ]]; then
    info "--- FAIL-FUNC DEMO START ---"
    demo_function_return
    info "--- FAIL-FUNC DEMO END ---"
  fi

  return 0
}

main "$@"
