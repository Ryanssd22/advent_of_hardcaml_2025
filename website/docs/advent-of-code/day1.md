Install bignum ig

```
open Hardcaml
module Sol = Day01part1

(* Puzzle input file path - Feel free to change *)
let filename = "day01/inputs/example.txt"

type direction = Left | Right

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

(* Parses given input file from inputs/ *)
let read_file filename =
  Stdio.In_channel.with_file filename ~f:(fun ic ->
    Stdio.In_channel.input_lines ic
    |> List.map parse_line
  )

let () =
  (* Initialize Data *)
  let data = read_file filename in
  let print_puzzle (dir, num) =
    let dir_str = if dir = Left then "Left" else "Right" in
    Stdio.printf "dir:%s ; num:%d\n" dir_str num
  in
  List.iter print_puzzle data;

  (* Initialize Simulator *)
  let module Sim = Cyclesim.With_interface(Sol.I)(Sol.O) in
  let sim = Sim.create Sol.create in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  let send_data dir num =

    let dir_signal = if dir = Left then (Bits.of_string "1") else (Bits.of_string "0") in
    inputs.mov := (Bits.of_int ~width:10 num);
    inputs.dir := dir_signal;

    Cyclesim.cycle sim;

    Stdio.printf "count:%d ; pos:%d\n" (Bits.to_int !(outputs.count)) (Bits.to_sint !(outputs.pos))
  in

  Cyclesim.cycle sim;
  send_data Left 10;
  send_data Left 10;
  send_data Left 50
```

```
open Hardcaml
open Signal

(* Inputs *)
module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; mov : 'a[@bits 10]
    ; dir : 'a
    }
  [@@deriving hardcaml]
end

(* Outputs *)
module O = struct
  type 'a t =
    { count : 'a[@bits 8]
    ; pos : 'a[@bits 11]
    }
  [@@deriving hardcaml]
end

(* Creating circuit logic *)
let create (i : _ I.t) =
  let reg_spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  (* let count_reg = Always.Variable.Reg reg_spec ~width:8 in  *)
  let pos_reg = Always.Variable.reg reg_spec ~width:11 in

  Always.(compile [
    if_ (i.dir ==: vdd) [
      pos_reg <-- pos_reg.value -: (Signal.ue i.mov);
    ] [
      pos_reg <-- pos_reg.value +: (Signal.ue i.mov);
    ];
  ]);

  { O.pos = Always.Variable.value pos_reg ; O.count = Signal.zero 8 }
```
