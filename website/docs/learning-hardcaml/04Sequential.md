# Hardcaml Sequential Logic

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
create a sequential hardware staple: A **UART Transmitter**

### What is an UART Transmitter?

<img src={require('/static/memes/uart_diagram.webp').default} alt="Uart diagram" width="400px" />

:::note
It stands for Universal Asynchronous Receiver Transmitter
:::

A **UART Transmitter** is a protocol that allows devices to asynchronously receive and transmit data.
This tool uses states to define when it's transmitting and not transmitting data. In fact, we'll implement 4
states:

1. **`Idle`** - waits for ready data
2. **`Start`** - sends starting `gnd` signal to receiver
3. **`Data`** - sends data one bit at a time
4. **`Stop`** - sends stop `vdd` signal to receiver

### Initializing Inputs, Outputs, and States

```ocaml title="bin/alu.ml"
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
```

For our inputs, we have:

- `start` - notifies transmitter to start sending data
- `data_in` - the 4-bit data to send

And our outputs are:

- `tx` - the transmitting wire, connected to the receiver (see diagram above)
- `current_state` - outputs the current state for debugging

Now introducing our new **states module**:

```ocaml title="bin/alu.ml"
(* States *)
module States = struct
  type t =
    | Idle
    | Start
    | Data
    | Stop
  [@@deriving sexp_of, compare ~localize, enumerate]
end
```

Just like our inputs and outputs, we are able to explicitly define the states for our
circuit. In order to use these states, however, Hardcaml's `Always` DSL is to be used.

### Implementing `Always`

The `Always` module in Hardcaml bridges the gap between procedural software programming
and the actual hardware logic. It basically makes it easy for us to
create sequential circuits with our states.

To create our state machine, let's first build our `create` function like in our
previous circuits.

```ocaml title="bin/alu.ml"
(* RTL Logic *)
let create (i : _ I.t) =
  let reg_spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let state_machine = Always.State_machine.create (module States) ~enable:vdd reg_spec in

  let tx_reg = Always.Variable.reg reg_spec ~width:1 in
  let bit_index = Always.Variable.reg reg_spec ~width:2 in
```

Before we start defining our logic, we created our state machine (aptly named `state_machine`),
and two registers **`tx_reg`** (What gets sent to our `tx`) and **`bit_index`** (Keeps track on which bit
we are sending from `data_in`).

Then we use `Always` to create our state machine:

```ocaml title="bin/alu.ml"
  Always.(compile [
    state_machine.switch [
      Idle, [
      ];

      Start, [
      ];

      Data, [
      ];

      Stop, [
      ];
    ]
  ]);
```

Would you look at that, it looks just like your typical
switch case statement! It's also a little bit unfortunate the syntax
highlighting is a bit bland :/
Let's add logic one at a time for each state...

#### Idle State

```ocaml title="bin/alu.ml"
(* Waits for starting signal*)
Idle, [
    tx_reg <-- vdd;
    if_ (i.start ==: vdd) [
      state_machine.set_next Start;
    ] [];
];
```

Our `Idle` state waits for `i.start` to become activated. Look at that,
we used an `if_` statement! (`if` is already taken by OCaml, so `if_` will have to do).

Once we pass through that `if_`, it sets the state machine's next state to `Start`.
So when a cycle passes, we will move on to the next state.

#### Start State

```ocaml title="bin/alu.ml"
(* Sends start signal *)
Start, [
    tx_reg <-- gnd;
    bit_index <-- Signal.zero 2;
    state_machine.set_next Data;
];
```

In UART, the transmitter sends a `Start` signal, typically a low signal (as
`tx` usually stays high while idle), to let the receiver know that data is about to come
in. Our circuit does exactly that, and also initializes our `bit_index` to `00`. Then it moves
to the next state.

#### Data State

```ocaml title="bin/alu.ml"
(* Sends data one bit at a time *)
Data, [
    tx_reg <-- mux bit_index.value (bits_lsb i.data_in);

    if_ (bit_index.value ==:. 3 ) [
      state_machine.set_next Stop;
    ] [
      bit_index <-- (bit_index.value +:. 1 )
    ];
];
```

Here's the heart of the circuit. Firstly, let's look at our `bit_index`.
It increases by `1` each cycle, going all the way up until it `==:. 3`.

`tx_reg` is simultaneously being set to the corresponding index in `data_in`.

:::note
`bits_lsb` turns `i.data_in` into a list of bits, starting from the
least significant bit. `mux` is then used to select an item from that list
by using `bit_index.value` as the select input.
:::

#### Stop State

```
(* Sends ending signal *)
Stop, [
    tx_reg <-- vdd;
    state_machine.set_next Idle;
];
```

Finally we end our transmission by sending a `vdd` signal to the receiver.

Feel free to see the [Full UART Circuit](https://github.com/Ryanssd22/advent_of_hardcaml_2025/blob/main/website/code_examples/05-uart.ml)
