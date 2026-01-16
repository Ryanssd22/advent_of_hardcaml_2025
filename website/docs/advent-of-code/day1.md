---
keywords:
  - 15 Jan 2025
---

# Advent of Hardcaml - Day 01

_Finished 15 Jan 2025_

_Better late than never_

[Advent of Code Day 1](https://adventofcode.com/2025/day/1) consists of some easy modulo and divison arithmetic.
It took some time finding the right way to piece the arithmetic together, but eventually we got there.

The simulation parsed the inputs first, so the circuit was able to easily read in all of the numbers and directions
in a single clock cycle. Additionally, the entire arithmetic takes one cycle, which did not do wonders on our clock speed.
Most of the complexity came from the divison.

## File parsing

The puzzle input is as so:

```
L68
L30
R48
...
```

So I used Ocaml to read each line and separate out the **direction** (`L` or `R`), and the **distance**.
It then stores it inside `data` as a list of tuples: `(dir, dist)`

```ocaml title="day01/test/test_day01.ml"
type direction = Left | Right

(* Parses given input file from inputs/ *)
let read_file filename =
  Stdio.In_channel.with_file filename ~f:(fun ic ->
    Stdio.In_channel.input_lines ic
    |> List.map parse_line
  )

(* Parses line *)
let parse_line line =
  let dir_char = String.get line 0 in
  let num = String.sub line 1 (String.length line - 1) in
  let value = int_of_string num in
  let dir =
    match dir_char with
    | 'L' -> Left
    | 'R' -> Right
    | _ -> failwith "Invalid direction in input"
  in
  (dir, value)
```

## Turning the dial

Most of the heavy lifting was done by `hardcaml_circuits`, as they included a
built-in `modulo` and `divider` module. **Part 1** just needed `modulo`, while **part 2** used the `divider`.

```ocaml title="day01/src/day01.ml
  (* Position math - Mainly part 1 *)
  let pos_reg = Always.Variable.reg reg_spec ~width:12 in
  let raw_pos =
    mux2 i.dir (pos_reg.value -: (uresize i.mov 12)) (pos_reg.value +: (uresize i.mov 12))
  in
  let safe_pos = (* Modulo only does positive numbers - gotta make raw_pos safe *)
    mux2 (raw_pos <+ zero 12) (raw_pos +: (of_int ~width:12 1000)) raw_pos
  in
  let next_pos =
    uresize (Mod.unsigned_by_constant (module Signal) safe_pos 100) 12
  in
```

Here's what each register/wire calculates, each building off the other:

- **`pos_reg`** - Current position of the dial
- **`raw_pos`** - Position + the distance to turn. Also looks at the direction whether
  to subtract (`Left`) or add (`Right`)
- **`safe_pos`** - Modulo only deals with positive numbers, so I had to make sure
  `raw_pos` is positive. I did this by adding `1000`, which should cover the most extreme case
  of `L999`.
- **`next_pos`** - `safe_pos` % 100. Finds the next dial position in suitable range 0-99.

## Counting Crosses Algorithim (Part 2)

**Part 1** is pretty trivial, as I just check if the `pos_reg` is 0 each clock cycle,
and increase the count by one.

**Part 2** requires the use of division, as I need to check not only if a dial movement
crossed 0, but how many times it crossed.

I tried to implement two formulas that should count the amount of crossings, depending
on the direction. If the dial was moving `Right`, it was pretty simple:

$
crossings_r = \frac{pos + dist}{100}
$

For `Left`, it was a bit more tricky, and took me an embarassingly
long time to figure out what was wrong. Yet another edge case:

**`If pos != 0`**

$
crossings_l = \frac{dist + (100 - pos)}{100}
$

**`If pos == 0`**

$
crossings_l = \frac{dist}{100}
$

And here it is in Hardcaml:

```ocaml title="day01/src/day01.ml"
  (* Part 2 crossing math *)
  let scope = Scope.create () in
  let left_extra = mux2 (pos_reg.value ==:. 0) (zero 12) (uresize (of_int ~width:12 100 -: pos_reg.value) 12) in
  let numerator = mux2 i.dir ((uresize i.mov 12) +: left_extra) (pos_reg.value +: (uresize i.mov 12)) in
  let result = Div.create scope {
    clock = i.clock;
    clear = i.clear;
    numerator = (uresize numerator 13);
    denominator = (Signal.of_int ~width:13 100);
    start = Signal.vdd;
  } in

  let crosses = result.quotient in
```

## Synthesis Report

<img src={require('/static/memes/day01_circuit.png').default} alt="OCaml meme" width="800px" />

I ran it through [Vivado](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vivado.html)
just to see how it performs. The circuit definitely looks cool. Had to set the clock period to `25ns` per cycle, which is pretty slow.
Maybe making the division not combinational would've helped

You can find the [Full Design on the Repo](https://github.com/Ryanssd22/advent_of_hardcaml_2025/tree/main/solutions/day01)
