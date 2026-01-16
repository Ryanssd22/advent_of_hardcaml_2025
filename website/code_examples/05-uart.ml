open Hardcaml
open Hardcaml.Signal

(* Inputs *)
module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; start : 'a
    ; data_in : 'a[@bits 4]
    }
  [@@deriving hardcaml]
end

(* Outputs *)
module O = struct
  type 'a t =
    { tx : 'a
    ; current_state : 'a[@bits 2]
    }
  [@@deriving hardcaml]
end

(* States *)
module States = struct
  type t =
    | Idle
    | Start
    | Data
    | Stop
  [@@deriving sexp_of, compare ~localize, enumerate]
end

(* RTL Logic *)
let create (i : _ I.t) =
  let reg_spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let state_machine = Always.State_machine.create (module States) ~enable:vdd reg_spec in

  let tx_reg = Always.Variable.reg reg_spec ~width:1 in
  let bit_index = Always.Variable.reg reg_spec ~width:2 in

  Always.(compile [
    state_machine.switch [
      (* Waits for starting signal*)
      Idle, [
        tx_reg <-- vdd;
        if_ (i.start ==: vdd) [
          state_machine.set_next Start;
        ] [];
      ];

      (* Sends start signal *)
      Start, [
        tx_reg <-- gnd;
        bit_index <-- Signal.zero 2;
        state_machine.set_next Data;
      ];

      (* Sends data one bit at a time *)
      Data, [
        tx_reg <-- mux bit_index.value (bits_lsb i.data_in);

        if_ (bit_index.value ==:. 3 ) [
          state_machine.set_next Stop;
        ] [
          bit_index <-- (bit_index.value +:. 1 )
        ];
      ];

      (* Sends ending signal *)
      Stop, [
        tx_reg <-- vdd;
        state_machine.set_next Idle;
      ];
    ]
  ]);

  (* Return outputs *)
  { O.current_state = state_machine.current ; O.tx = tx_reg.value }

(* Simulation *)
let () =
  (* Print circuit for fun *)
  let module StateMachine = Circuit.With_interface(I)(O) in
  let circuit = StateMachine.create_exn ~name:"state_machine" create in
  Rtl.print Verilog circuit;

  (* Initialize simulation *)
  let module StateMachineSim = Cyclesim.With_interface(I)(O) in
  let sim = StateMachineSim.create create in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in

  (* Defining step *)
  Cyclesim.cycle sim;
  let step start data =
    if start then begin
      (* UART Init *)
      Stdio.printf "Transmitting %s\n" data;
      inputs.start := Bits.vdd;
      inputs.data_in := (Bits.of_string data);

      (* Simulating steps *)
      for step = 0 to 7 do
        Stdio.printf "step %d - state:%s ; tx:%s\n" step (Bits.to_string !(outputs.current_state)) (Bits.to_string !(outputs.tx));
        Cyclesim.cycle sim;
        inputs.start := Bits.gnd
      done
    end else
      Stdio.printf "Not starting\n"
  in

  (* Running simulation *)
  step true "0110";
  step true "1000";
  step true "0011"
