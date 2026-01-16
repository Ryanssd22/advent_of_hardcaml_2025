open Hardcaml
module Sol = Day01part1

(* Puzzle input file path - Feel free to change *)
let filename = "day01/inputs/puzzle.txt"

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
  (* Initialize Circuit VHDL *)
  let module Day1 = Circuit.With_interface(Sol.I)(Sol.O) in
  let circuit = Day1.create_exn ~name:"Day1" Sol.create in
  Rtl.print Vhdl circuit;

  (* Initialize Data *)
  let data = read_file filename in

  (* Initialize Simulator *)
  let module Sim = Cyclesim.With_interface(Sol.I)(Sol.O) in
  let sim = Sim.create Sol.create in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  let send_data (dir, num) =

    let dir_signal = if dir = Left then (Bits.of_string "1") else (Bits.of_string "0") in
    inputs.mov := (Bits.of_int ~width:10 num);
    inputs.dir := dir_signal;

    Cyclesim.cycle sim;


    let dir_string = if dir = Left then "Left" else "Right" in
    Stdio.printf "dir:%s ; mov:%d\n" dir_string num;
    Stdio.printf "count_a:%d ; count_b:%d ; pos:%d ; state:%d\n" (Bits.to_int !(outputs.count_a)) (Bits.to_int !(outputs.count_b)) (Bits.to_sint !(outputs.pos)) (Bits.to_int !(outputs.state))
  in

  Cyclesim.reset sim;
  Stdio.printf "Initial state:%d\n" (Bits.to_int !(outputs.state));
  Cyclesim.cycle sim;
  List.iter send_data data;

