# Monty Hall Simulation

This mini repository demonstrates the Monty Hall problem using a Bash script.

## Files

- `scripts/montyhall.sh` — simulation script for stay/switch/random strategies
- `tests/test_montyhall.sh` — simple validation test for the simulator
- `montyhall.md` — report describing the Monty Hall problem and expected results

## Usage

```bash
bash scripts/montyhall.sh --trials 100000 --strategy switch
bash scripts/montyhall.sh --trials 100000 --strategy stay
bash scripts/montyhall.sh --trials 100000 --strategy random
```

## Example

```bash
bash scripts/montyhall.sh --trials 100000 --strategy switch
```

Expected output shows a win rate around 66% for the `switch` strategy and around 33% for `stay`.
