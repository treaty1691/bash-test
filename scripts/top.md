# `scripts/top.sh`

A lightweight Bash-based `top` emulator for Linux-like systems.

## Purpose

This script provides a simple process summary and live refresh interface using standard shell tools.

## Usage

```bash
bash scripts/top.sh [options]
```

### Options

- `-0`, `--once`
  - Run a single snapshot and exit.
- `-d SECONDS`, `--delay SECONDS`
  - Refresh delay when running continuously. Default: `2`.
- `-o FIELD`, `--order FIELD`
  - Sort processes by one of: `cpu`, `mem`, `pid`, `vsz`, `rss`, `command`.
  - Default: `cpu`.
- `-n COUNT`, `--count COUNT`
  - Number of processes to display. Default: `15`.
- `-h`, `--help`
  - Show help and exit.

## Interactive commands

While `top.sh` is running, press `:` and enter one of the following commands:

- `:o FIELD`
  - Change the sort field at runtime.
  - Supported values: `cpu`, `mem`, `pid`, `vsz`, `rss`, `command`.
  - `command` sorts alphabetically by process name.
- `:n COUNT`
  - Change the number of shown processes.
- `:d SECONDS`
  - Change the refresh delay.
- `:q`
  - Quit the script.

## Examples

Run one snapshot sorted by memory:

```bash
bash scripts/top.sh -0 -o mem
```

Run the live view with 25 processes and a 1-second refresh:

```bash
bash scripts/top.sh -n 25 -d 1
```

Change ordering to command name while running:

1. Start without `-0`.
2. Press `:`.
3. Type `o command` and press Enter.

## Notes

- `scripts/top.sh` uses `ps` and `/proc` where available.
- The interactive prompt reads from `/dev/tty`, so it behaves best in a terminal session.
