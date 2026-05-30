# Monty Hall Problem Report

## Overview

The Monty Hall problem is a probability puzzle based on a game show scenario.
A prize is hidden behind one of three doors. The contestant picks one door.
The host reveals a goat behind one of the remaining doors and then offers the contestant the chance to stay with the original door or switch to the other unopened door.

## Key Question

Should the contestant stay with their first choice or switch after the host reveals a goat?

## Expected outcome

- Staying wins about **1/3** of the time.
- Switching wins about **2/3** of the time.

## Simulation Approach

The Bash script `scripts/montyhall.sh` runs repeated simulations using these steps:

1. Randomly place the prize behind one of three doors.
2. Randomly select the contestant's initial door.
3. The host opens one of the remaining doors that does not contain the prize.
4. The contestant either stays, switches, or chooses randomly based on the selected strategy.
5. The simulation counts wins and losses and reports the win rate.

## Usage

```bash
bash scripts/montyhall.sh --trials 100000 --strategy switch
bash scripts/montyhall.sh --trials 100000 --strategy stay
bash scripts/montyhall.sh --trials 100000 --strategy random
```

## Interpretation

The simulation output confirmed that switching is the best strategy.
When switching, the win rate should approach 66.7% as the number of trials increases.
When staying, the win rate should approach 33.3%.
