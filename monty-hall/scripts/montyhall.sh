#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --trials N        Number of simulations to run (default: 10000)
  --strategy MODE   Strategy: stay, switch, or random (default: switch)
  --seed N          Optional numeric seed for reproducible results
  --help            Show this help message
EOF
}

error() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

parse_args() {
  trials=10000
  strategy="switch"
  seed=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --trials)
        trials="$2"
        shift 2
        ;;
      --strategy)
        strategy="$2"
        shift 2
        ;;
      --seed)
        seed="$2"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        ;;
    esac
  done

  if ! [[ "$trials" =~ ^[0-9]+$ ]] || [[ "$trials" -le 0 ]]; then
    error "--trials must be a positive integer"
  fi

  case "$strategy" in
    stay|switch|random) ;;
    *) error "--strategy must be stay, switch, or random" ;;
  esac
}

rand_between() {
  local max="$1"
  if [[ -n "$seed" ]]; then
    seed=$(( (seed * 1103515245 + 12345) & 0x7fffffff ))
    printf '%d' $(( seed % max ))
  else
    printf '%d' $(( RANDOM % max ))
  fi
}

run_simulation() {
  local trials_count="$1"
  local wins=0
  local losses=0

  for ((i = 0; i < trials_count; i++)); do
    local prize_choice
    local player_choice
    prize_choice=$(rand_between 3)
    player_choice=$(rand_between 3)

    local host_options=()
    for door in 0 1 2; do
      if [[ "$door" -ne "$player_choice" && "$door" -ne "$prize_choice" ]]; then
        host_options+=("$door")
      fi
    done

    local host_reveal_index
    host_reveal_index=$(rand_between "${#host_options[@]}")
    local host_reveal="${host_options[$host_reveal_index]}"

    local final_choice
    if [[ "$strategy" == "stay" ]]; then
      final_choice="$player_choice"
    elif [[ "$strategy" == "switch" ]]; then
      for door in 0 1 2; do
        if [[ "$door" -ne "$player_choice" && "$door" -ne "$host_reveal" ]]; then
          final_choice="$door"
          break
        fi
      done
    else
      if [[ $(rand_between 2) -eq 0 ]]; then
        final_choice="$player_choice"
      else
        for door in 0 1 2; do
          if [[ "$door" -ne "$player_choice" && "$door" -ne "$host_reveal" ]]; then
            final_choice="$door"
            break
          fi
        done
      fi
    fi

    if [[ "$final_choice" -eq "$prize_choice" ]]; then
      wins=$((wins + 1))
    else
      losses=$((losses + 1))
    fi
  done

  printf 'Strategy: %s\n' "$strategy"
  printf 'Trials: %d\n' "$trials_count"
  printf 'Wins: %d\n' "$wins"
  printf 'Losses: %d\n' "$losses"
  printf 'Win rate: %.2f%%\n' "$(awk "BEGIN { printf 100 * $wins / $trials_count }")"
}

main() {
  parse_args "$@"
  if [[ -n "$seed" ]]; then
    printf 'Using seed: %s\n' "$seed"
  fi
  run_simulation "$trials"
}

main "$@"
