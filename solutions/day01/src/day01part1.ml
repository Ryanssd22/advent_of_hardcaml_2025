open Hardcaml
open Signal

module Mod = Hardcaml_circuits.Modulo 

(* Divider spec *)
module Div_spec = struct
  let width = 13
  let signedness = Hardcaml.Signedness.Unsigned
  let architecture = Hardcaml_circuits.Divider.Architecture.Combinational
end

module Div = Hardcaml_circuits.Divider.Make(Div_spec)

(* Inputs *)
module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; mov : 'a[@bits 10]
    ; dir : 'a
    ; stop : 'a
    }
  [@@deriving hardcaml]
end

(* Outputs *)
module O = struct
  type 'a t =
    { count_a : 'a[@bits 12]
    ; count_b : 'a[@bits 13]
    ; pos : 'a[@bits 12]
    ; state : 'a[@bits 2]
    }
  [@@deriving hardcaml]
end

(* States *)
module States = struct
  type t =
    | Initialize
    | Solving 
    | Stop
  [@@deriving sexp_of, compare ~localize, enumerate]
end

(* Creating circuit logic *)
let create (i : _ I.t) =
  let reg_spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let count_reg_a = Always.Variable.reg reg_spec ~width:12 in 
  let count_reg_b = Always.Variable.reg reg_spec ~width:13 in 
  let sm = Always.State_machine.create (module States) ~enable:vdd reg_spec in

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
  
  Always.(compile [
    sm.switch [
      Initialize, [
        pos_reg <-- (Signal.of_int ~width:12 50);
        sm.set_next Solving;
      ];

      Solving, [
        if_ i.stop [
          sm.set_next Stop;
        ] [];

        pos_reg <-- (uresize next_pos 12);

        (* Part 1 - Counts Zeroes *)
        if_ (next_pos ==:. 0) [
          count_reg_a <-- count_reg_a.value +:. 1; 
        ] [];

        (* Part 2 - Counts Crosses *)
        count_reg_b <-- count_reg_b.value +: crosses;
        (* count_reg_b <-- crosses; *)
      ];

      Stop, [
        (* Idk what i was doing here *)
      ];
    ];
  ]);
  
  { O.pos = Always.Variable.value pos_reg ; O.count_a = count_reg_a.value ; O.count_b = count_reg_b.value ; O.state = sm.current }

