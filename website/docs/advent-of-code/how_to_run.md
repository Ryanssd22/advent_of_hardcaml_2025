---
sidebar_position: 0
---

# Running Solutions

The solutions for this challenge can be found inside the [`solutions`](https://github.com/Ryanssd22/advent_of_hardcaml_2025/tree/main/solutions) folder in the repository.
Each day should have its own folder.

Run `dune exec day01` to execute the simulator for each day:

```bash title="terminal"
cd solutions/
dune exec day01
```

The main design of the Hardcaml circuit is found within `src/`, while the simulation is found within `test/`

There is also the `day01/inputs/` folder, which houses some example and puzzle inputs. These files are read
and parsed directly inside the simulator file. The filename is hardcoded into the file, so feel free to change
the name or add your own inputs.
