open Hardcaml
open Hardcaml.Signal
open Hardcaml_waveterm

(* Inputs *)
module I = struct
  type 'a t =
    { input_a : 'a[@bits 8]
    ; input_b : 'a[@bits 8]
    }
  [@@deriving hardcaml]
end

(* Outputs *)
module O = struct
  type 'a t =
    { output_c : 'a[@bits 8]
    ; output_d : 'a[@bits 16]
    }
  [@@deriving hardcaml]
end

(* Creating circuit logic *)
let create (i : _ I.t) =
  { O.output_c = i.input_a +: i.input_b
  ; output_d = i.input_a *: i.input_b
  }

let () =
  (* Creating circuit *)
  let module My_Circuit = Circuit.With_interface(I)(O) in
  let circuit = My_Circuit.create_exn ~name:"My_Circuit" create in

  (* Printing Verilog *)
  Rtl.print Verilog circuit;

  (* Creating circuit sim *)
  let module Simulator = Cyclesim.With_interface(I)(O) in
  let sim = Simulator.create create in

  (* Creating waveform *)
  let waves, simulator = Waveform.create sim in

  (* Creating simulator ports *)
  let inputs : _ I.t = Cyclesim.inputs sim in

  (* Running circuit sim *)
  inputs.input_a := Bits.of_string "10100011";
  inputs.input_b := Bits.of_string "00101100";
  Cyclesim.cycle simulator;
  inputs.input_a := Bits.of_string "00000001";
  inputs.input_b := Bits.of_string "01000100";
  Cyclesim.cycle simulator;

  (* Print waveform *)
  Waveform.print ~display_height:14 waves


