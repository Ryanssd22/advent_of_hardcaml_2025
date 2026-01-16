open Hardcaml
open Hardcaml.Signal
open Hardcaml_waveterm

let () =
  (* Creating circuit *)
  let input_a = input "a" 8 in
  let input_b = input "b" 8 in
  let output_c = output "c" (input_a +: input_b) in
  let output_d = output "d" (input_a *: input_b) in
  let circuit = Circuit.create_exn ~name:"My_Circuit" [ output_c; output_d ] in

  (* Printing Verilog *)
  (* Rtl.print Verilog circuit; *)

  (* Printing VHDL *)
  (* Rtl.print Vhdl circuit *)

  (* Creating circuit sim *)
  let simulator = Cyclesim.create circuit in

  (* Creating waveform *)
  let waves, simulator = Waveform.create simulator in

  (* Creating simulator ports *)
  let a_in = Cyclesim.in_port simulator "a" in
  let b_in = Cyclesim.in_port simulator "b" in

  (* !!! When using the waveform simulator, you don't need to create output ports! *)
  (* let c_out = Cyclesim.out_port simulator "c" in *)
  (* let d_out = Cyclesim.out_port simulator "d" in *)

  (* Running circuit sim *)
  a_in := Bits.of_string "10100011";
  b_in := Bits.of_string "00101100";
  Cyclesim.cycle simulator;

  a_in := Bits.of_string "00000001";
  b_in := Bits.of_string "01000100";
  Cyclesim.cycle simulator;

  (* Printf.printf "a: %s\n" (Bits.to_string !a_in); *)
  (* Printf.printf "b: %s\n" (Bits.to_string !b_in); *)
  (* Printf.printf "c: %s\tWidth: %d\n" (Bits.to_string !c_out) (Bits.width !c_out); *)
  (* Printf.printf "c: %s\tWidth: %d\n" (Bits.to_string !d_out) (Bits.width !d_out); *)

  (* Print waveform *)
  Waveform.print ~display_height:14 waves


