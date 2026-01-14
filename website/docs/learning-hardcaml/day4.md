# Day 4 - Hardcaml Sequential Logic

<img src={require('/assets/flipflop.jpeg').default} alt="OCaml meme" width="400px" />

So we've created **Circuits**, but they are only combinational, meaning that the outputs
are determined by the current inputs. That's great when we want to make a simple calculator,
but real, awesome computation happens in states and sequences. The computer revolution is built on malleable
logic!

This is where we introduce the sequential powerhouse tool: **REGISTERS**

## Registers and Clocks

As you know, clocks are what run the world, and they are what run computers. Clocks
and their cycles are especially used with registers. A register receives an input,
stores that input, waits for a clock cycle, then outputs its stored value.

In hardware, a register actually takes in 3 inputs:

1. `clock`
2. `clear` _(Resets the register when high, aka `Bits.vdd`)_
3. An input value

Let's see it in practice:

```ocaml title="bin/sequential.ml"
open Hardcaml
open Hardcaml.Signal

(* Inputs *)
module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    }
  [@@deriving hardcaml]
end

(* Outputs *)
module O = struct
  type 'a t =
    { data_out : 'a[@bits 8]
    }
  [@@deriving hardcaml]
end
```

Firstly, let's initialize two inputs `clock` and `clear`. We also initialize one output,
`data_out`.

Now we'll initialize a register:

```ocaml title="bin/sequential.ml
let create (i : _ I.t) =
  { O.data_out =
      let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
      reg spec ~enable:Signal.vdd i.data_in
  }
```

Let's take a closer look on what all of this is...

We got our boilerplate `create` function with our RTL logic, which is only setting our one
output, `data_out`, equal to our register.

Creating the register follows this simple procedure:

1. Create the register's specification using `Reg_spec.create`, specifying the `clock` and `clear`
2. Create the register using `reg`, passing in an `enable` and `data_in`

Congratulations, we have a sequential circuit now! Let's simulate it:

```ocaml title="bin/sequential.ml
let () =
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
```

```shell title="Output"
Cycle 0: data_in='1010' data_out='0000'
Cycle 1: data_in='0010' data_out='1010'
Cycle 2: data_in='1111' data_out='0010'
Cycle 3: data_in='0000' data_out='1111'
```

As you can see from the output, `data_in` goes in, and then comes out into `data_out` on the
_next_ clock cycle.

:::note
You simulate this circuit just like any other. Here, I made a `step` function that takes
in a value for `data_in`, prints out the cycle count and data out, and then goes forward
a step.

`Cyclesim.cycle` automatically goes through a clock cycle for you, how convenient!
:::

## States and `Always` DSL

- _[4.3 - Designing State Machines](https://github.com/janestreet/hardcaml/blob/master/docs/state_machine_always_api.md)_

Let's create a more advanced circuit, with different **states** which define what our circuit
does depending on an input.

Fortunately, Hardcaml gifts us with [`Always` DSL](https://ocaml.org/p/hardcaml/latest/doc/hardcaml/Hardcaml/Always/index.html),
which allows us to create our circuit using variables, `if_` statements, and `switch` statements.
These are very useful for someone "software brained." But nobody likes these software people, so we'll
create a hardware staple: An **ALU**

### What is an ALU?

An ALU is an **Arithmitic Logic Unit**, it performs arithmetic and logical operations on registers. They are as follows:

1. Add/Subtract
2. Multiply/Divide
3. Logical Shifts Left/Right
4. And/or/not

Let's stick with the first 3 in the list, so `6` states will be used for each of these operations.

### Initializing Inputs, Outputs, and States

We'll make this ALU deal with 4-bit inputs:

```ocaml title="bin/alu.ml"

```

Now introducing our states module:

```ocaml title="bin/alu.ml"

```

### Implementing `Always`

`Always.compile` returns our needed output ports, so we can use it with `Circuit.create_exn`.
