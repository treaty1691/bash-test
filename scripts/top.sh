#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: bash scripts/top.sh [options]

Options:
  -0, --once       Run one snapshot and exit
  -d SECONDS       Delay between updates when running continuously (default: 2)
  -h, --help       Show this help message
EOF
}

get_uptime() {
  if [[ -r /proc/uptime ]]; then
    awk '{seconds=$1; days=int(seconds/86400); seconds-=days*86400; hours=int(seconds/3600); seconds-=hours*3600; mins=int(seconds/60); printf "%s days, %02d:%02d", days, hours, mins}' /proc/uptime
  else
    uptime -p 2>/dev/null || echo "N/A"
  fi
}

get_load_averages() {
  if [[ -r /proc/loadavg ]]; then
    awk '{printf "%s, %s, %s", $1, $2, $3}' /proc/loadavg
  else
    uptime 2>/dev/null | sed -n 's/.*load average[s]\?: \(.*\)$/\1/p' || echo "N/A"
  fi
}

get_memory_summary() {
  if [[ -r /proc/meminfo ]]; then
    awk 'BEGIN {total=free=avail=buffer=cached=0} /^MemTotal:/ {total=$2} /^MemFree:/ {free=$2} /^Buffers:/ {buffer=$2} /^Cached:/ {cached=$2} /^MemAvailable:/ {avail=$2} END {used=total-free-buffer-cached; if (used<0) used=0; printf "KiB Mem : %7d total, %7d used, %7d free, %7d buff/cache, %7d avail\n", total, used, free, buffer+cached, avail}' /proc/meminfo
  elif command -v free >/dev/null 2>&1; then
    free -k | awk 'NR==2 {printf "KiB Mem : %7s total, %7s used, %7s free, %7s buff/cache, %7s avail\n", $2, $3, $4, $6+$7, $7}'
  else
    printf "KiB Mem : N/A\n"
  fi
}

get_cpu_summary() {
  if [[ -r /proc/stat ]]; then
    read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    total=$((user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice))
    busy=$((total - idle))
    if [[ $total -gt 0 ]]; then
      cpu_usage=$(awk -v busy="$busy" -v total="$total" 'BEGIN {printf "%.1f", busy/total*100}')
      idle_pct=$(awk -v cpu="$cpu_usage" 'BEGIN {printf "%.1f", 100 - cpu}')
      printf "%%Cpu(s): %5s us,  0.0 sy,  0.0 ni, %5s id\n" "$cpu_usage" "$idle_pct"
      return 0
    fi
  fi
  printf "%%Cpu(s): N/A\n"
}

print_header() {
  printf "top - %s  up %s,  load average: %s\n" "$(date '+%H:%M:%S')" "$(get_uptime)" "$(get_load_averages)"
}

print_tasks() {
  if command -v ps >/dev/null 2>&1; then
    local total running sleeping stopped zombies
    total=$(ps -e --no-headers 2>/dev/null | wc -l | tr -d ' ')
    running=$(ps -e -o stat --no-headers 2>/dev/null | grep -c '^R' || true)
    sleeping=$(ps -e -o stat --no-headers 2>/dev/null | grep -c '^S' || true)
    stopped=$(ps -e -o stat --no-headers 2>/dev/null | grep -c '^T' || true)
    zombies=$(ps -e -o stat --no-headers 2>/dev/null | grep -c '^Z' || true)
    printf "Tasks: %s total, %s running, %s sleeping, %s stopped, %s zombie\n" "$total" "$running" "$sleeping" "$stopped" "$zombies"
  else
    printf "Tasks: N/A\n"
  fi
}

print_process_table() {
  printf "  %5s %-8s %-5s %5s %5s %8s %8s %8s %s\n" PID USER STAT CPU%% MEM%% VSZ RSS TIME COMMAND
  if command -v ps >/dev/null 2>&1; then
    ps -eo pid,user,stat,pcpu,pmem,vsz,rss,time,comm --sort=-pcpu 2>/dev/null | awk 'NR>1 {printf "  %5s %-8s %-5s %5s %5s %8s %8s %8s %s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9}' | head -n 10
  else
    printf "  [process list unavailable]\n"
  fi
}

main() {
  local single_shot=0
  local delay=2

  if [[ $# -eq 0 ]]; then
    show_help
    exit 0
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -0|--once)
        single_shot=1
        shift
        ;;
      -d|--delay)
        shift
        delay="${1:-2}"
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        printf 'Unknown option: %s\n' "$1" >&2
        show_help
        exit 1
        ;;
    esac
  done

  while true; do
    if [[ $single_shot -eq 0 ]]; then
      clear
    fi
    print_header
    print_tasks
    get_cpu_summary
    get_memory_summary
    print_process_table

    if [[ $single_shot -eq 1 ]]; then
      break
    fi
    sleep "$delay"
  done
}

main "$@"
