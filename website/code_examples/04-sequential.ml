open Hardcaml
open Hardcaml.Signal

(* Inputs *)
module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; data_in : 'a[@bits 4]
    }
  [@@deriving hardcaml]
end

(* Outputs *)
module O = struct
  type 'a t =
    { data_out : 'a[@bits 4]
    }
  [@@deriving hardcaml]
end

let create (i : _ I.t) =
  { O.data_out =
      let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
      reg spec ~enable:Signal.vdd i.data_in
  }

let () =
  (* Initializing circuit *)
  let module MyCircuit = Circuit.With_interface(I)(O) in
  let circuit = MyCircuit.create_exn ~name:"My_Circuit" create in
  Rtl.print Verilog circuit;

  (* Initializing simulator *)
  let module Simulator = Cyclesim.With_interface(I)(O) in
  let sim = Simulator.create create in
  let inputs : _ I.t = Cyclesim.inputs sim in
  let outputs : _ O.t = Cyclesim.outputs sim in
  let cycle_count = ref 0 in

  (* Creating a step function *)
  let step value = 
    inputs.data_in := Bits.of_string value;

    Stdio.printf "Cycle %d: " !cycle_count;
    incr cycle_count;

    Stdio.printf "data_in='%s'\tdata_out='%s'\n" (Bits.to_string !(inputs.data_in)) (Bits.to_string !(outputs.data_out));
    Cyclesim.cycle sim
  in

  (* Running simulation steps *)
  step "1010";
  step "0010";
  step "1111";
  step "0000"



