import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Creating Hardcaml Circuits

<img src={require('/static/memes/hardcaml_internals.jpg').default} alt="OCaml meme" width="400px" />

:::note
FPGA stands for **Field Programmable Gate Array**
:::

In order to fully grasp the language of Hardcaml,
it is imperative to understand the different aspects of
**FPGA Architecture**.

The tricky thing is how _similar_ yet _different_ hardware
programming (or, as they like to call it, reconfiguration),
is to regular software programming. Instead of writing programs to handle
variables, we're going to be describing the flow of **Signals** and **Wires**.

I believe the best way to learn this subtle concept is to actually see it play out,
so I'll be using Hardcaml to demonstrate these concepts. Be sure to follow along with
the actual code to get the full "i hate programming" experience!

## Signals

In HDL, we are focused in routing signals. You may think of them
as binary varibles. Signals can store "1"s or "0"s. They can even store
vectors, such as "1011" or "11000011."

To start this off in Hardcaml, be sure to open up the Hardcaml module in your
dune project:

```ocaml title="/bin/signals.ml"
open Hardcaml

let () =
```

:::note
Remember, `let () =` is akin to your `int main() {}`. Because OCaml is static,
you need to actually have `let ()` return a unit, or `()`. It's a bit tricky to understand,
so play around in OCaml more.
:::

Let's assign a variable into a signal and print it like so:

```ocaml title="/bin/signals.ml"
let () =
    let my_signal = Signal.of_string "01010" in
    Printf.printf "%s\n" (Signal.to_string my_signal)
```

```bash title="output"
Const[id:5 bits:4 names: deps:] = 01010
```

Here, we created a signal using a **string**. We can also create a signal
with just a plain **int**, and Hardcaml will automatically turn it into binary.
Just make sure to specify the width!

```ocaml title="/bin/signals.ml"
...
let my_signal = Signal.of_int ~width:5 10 in
...
```

```bash title="output"
Const[id:5 bits:4 names: deps:] = 01010
```

## Signal Arithmetic

Now that you have signals, we can write some signal arithmetic and logic!
It works as you would normally expect, but all we have to do is append our symbols
with **`:` (Unsigned)** or **`+` (Signed)**. Many operations don't depend on the
sign, however, so it typically defaults to `:`.

Let's define two signals to work our magic on:

```ocaml
let a = Signal.to_string "1010" in
let b = Signal.to_int ~width:4 5 in
```

<Tabs>
  <TabItem value="Addition" label="Addition" default>
    Widths of the input signals must be the same. The width of
    `sum` is equal to the widths of the inputs.

    ```ocaml
    let sum = a +: b
    ```

  </TabItem>

  <TabItem value="Subtraction" label="Subtraction">
    Widths of the input signals must be the same. The width of
    `difference` is equal to the widths of the inputs.

    ```ocaml
    let difference = a -: b
    ```

  </TabItem>

  <TabItem value="Multiplication" label="Multiplication">
    Operands may have different widths. The `product` width
    is the sum of the operand widths.

    **Unsigned**
    ```ocaml
    let product = a *: b
    ```

    **Signed**
    ```ocaml
    let product = a *+ b
    ```

  </TabItem>

  <TabItem value="AND" label="AND">
    Widths of the input signals must be the same.  
    The result width matches the input width.

    ```ocaml
    let y = a &: b
    ```

  </TabItem>

  <TabItem value="OR" label="OR">
    Widths of the input signals must be the same.  
    The result width matches the input width.

    ```ocaml
    let y = a |: b
    ```

  </TabItem>

  <TabItem value="XOR" label="XOR">
    Widths of the input signals must be the same.  
    The result width matches the input width.

    ```ocaml
    let y = a ^: b
    ```

  </TabItem>

  <TabItem value="NOT" label="NOT">
    Unary logical inversion.  
    The result width matches the input width.

    ```ocaml
    let y = ~:a
    ```

  </TabItem>

  <TabItem value="Equality" label="Equality">
    Widths of the input signals must be the same.  
    The result is always a **1-bit signal**.

    ```ocaml
    let eq  = a ==: b
    let neq = a <>: b
    ```

  </TabItem>

  <TabItem value="Comparison" label="Comparison">
    Widths of the input signals must be the same.  
    The result is always a **1-bit signal**.

    **Unsigned**
    ```ocaml
    let lt  = a <:  b
    let lte = a <=: b
    let gt  = a >:  b
    let gte = a >=: b
    ```

    **Signed**
    ```ocaml
    let lt  = a <+  b
    let lte = a <=+ b
    let gt  = a >+  b
    let gte = a >=+ b
    ```

  </TabItem>
</Tabs>

:::warning
FYI, these are "infix operators," so the `Hardcaml.Signal` module must be open to
use them. You can either:

1. Use `open Hardcaml.Signal` at the beginning of your project
2. Open it locally via `let open Signal in`
3. Use it inline like: `Signal.(a +: b)`
   :::

## Wires

Here's what's separates real reconfigurators from your typical programmer.
Reconfiguration is all about describing the _flow of logic_, meaning we aren't
actually dealing with hard and fast values like **Signals** alone. Our logic is dicatated
by where we actually route our **Wires**

Hardcaml uses an example of a **Graph**, where our logic are the **Verticies** and
wires are the **Edges**. (Helps if you're a graph theory guy)

I hope you're wrapping your mind around this; don't worry, even the Hardcaml guys
themselves put it:

> [Wires] logically do nothing

## Circuits

Now this is where the magic actually happens! Circuits allow us to feed in an **input**,
make it pass through some **logic**, and deliver us a fresh, steaming **output**.

### Defining out inputs

In Hardcaml, our inputs will be a **wire** with a given width. We are able to
define them as such:

```ocaml title="/bin/circuit_sim.ml"
let input_a = input "a" 8 in
let input_b = input "b" 8 in
```

Here, we created two input wires, one named `"a"` and the other `"b"`. They both have
a width of `8` bits.

### Defining our outputs

Next, we'll define our output wires in relation to some inputs and logic:

```ocaml titl="/bin/circuit_sim.ml"
let output_c = output "c" (input_a +: input_b) in
let output_d = output "d" (input_a *: input_b) in
```

Notice how `output_c` is defined ONLY by other signals, meaning that even its width
is derived from the widths of our inpts. Thus, the width of `output_c` is `8`, and `output_d`
`16`.

### Creating our circuit

Now that we've defined our inputs and our outputs, we are able to define our **circuit**!

Using `Circuit.create_exn`, we are able to encode our RTL (hardware) logic into a hardcaml variable:

```ocaml title="/bin/circuit_sim.ml"
let circuit = Circuit.create_exn ~name:"My_Circuit" [ output_c; output_d ] in
```

:::note
See, as we are creating our circuit, it is only defined by our outputs, not our inputs.
This is because our inputs are already inherently defined in our output!
:::

### Turning our circuit into VHDL or Verilog

Of course, VHDL and Verilog are your prime RTL languages (I haven't met anyone who knows Hardcaml, or even OCaml for that matter).
Now that we've created our circuit, we are able to convert it to VHDL and Verilog using `Rtl.print`!

```ocaml title="/bin/circuit_sim.ml"
Rtl.print Verilog circuit;
Rtl.print Vhdl circuit
```

And here is what it outputs:

```verilog title="Verilog"
module My_Circuit (
    b,
    a,
    c,
    d
);

    input [7:0] b;
    input [7:0] a;
    output [7:0] c;
    output [15:0] d;

    wire [15:0] _5;
    wire [7:0] _6;
    assign _5 = a * b;
    assign _6 = a + b;
    assign c = _6;
    assign d = _5;

endmodule
```

```vhdl title="VHDL"
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity My_Circuit is
    port (
        b : in std_logic_vector(7 downto 0);
        a : in std_logic_vector(7 downto 0);
        c : out std_logic_vector(7 downto 0);
        d : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of My_Circuit is

    -- conversion functions
    function hc_uns(a : std_logic)        return unsigned         is variable b : unsigned(0 downto 0); begin b(0) := a; return b; end;
    function hc_uns(a : std_logic_vector) return unsigned         is begin return unsigned(a); end;
    function hc_sgn(a : std_logic)        return signed           is variable b : signed(0 downto 0); begin b(0) := a; return b; end;
    function hc_sgn(a : std_logic_vector) return signed           is begin return signed(a); end;
    function hc_sl (a : std_logic_vector) return std_logic        is begin return a(a'right); end;
    function hc_sl (a : unsigned)         return std_logic        is begin return a(a'right); end;
    function hc_sl (a : signed)           return std_logic        is begin return a(a'right); end;
    function hc_sl (a : boolean)          return std_logic        is begin if a then return '1'; else return '0'; end if; end;
    function hc_slv(a : std_logic_vector) return std_logic_vector is begin return a; end;
    function hc_slv(a : unsigned)         return std_logic_vector is begin return std_logic_vector(a); end;
    function hc_slv(a : signed)           return std_logic_vector is begin return std_logic_vector(a); end;
    signal hc_5 : std_logic_vector(15 downto 0);
    signal hc_6 : std_logic_vector(7 downto 0);

begin

    hc_5 <= hc_slv(hc_uns(a) * hc_uns(b));
    hc_6 <= hc_slv(hc_uns(a) + hc_uns(b));
    c <= hc_6;
    d <= hc_5;

end architecture;
```

Analyzing these programs show us that it successfully created our circuit with our
two outputs!

## Simulating our circuit

That's good and all, but creating our logic is only half the battle. The other half is **verification**!
Thus, our next job is to simulate our circuit, meaning we give it some inputs and verify its outputs.

Using the same circuit, let's create a simulator:

```ocaml title="bin/circuit_sim.ml"
let simulator = Cyclesim.create circuit in
```

And let's create the input and output signals that we are going to simulate:

```ocaml title="bin/circuit_sim.ml"
let a_in = Cyclesim.in_port simulator "a" in
let b_in = Cyclesim.in_port simulator "b" in
let c_out = Cyclesim.out_port simulator "c" in
let d_out = Cyclesim.out_port simulator "d" in
```

### Creating our testbench

In order to actually test our circuit, we'll add some actual numbers to our inputs
and see if they correctly add and multiply those numbers. The inputs are set as such:

```ocaml title="bin/circuit_sim.ml"
a_in := Bits.of_string "10100011";
b_in := Bits.of_string "00101100";
```

Now that we've set the inputs, we'll have to run the simulation a time step with this command.

```ocaml title="bin/circuit_sim.ml"
Cyclesim.cycle simulator;
```

Now that the simulator has run, we can check to see what our variables `c_out` and `d_out` equal!
Remember, all the `Cyclesim` ports we created are references to `Bits.t`, so that's why we'll include the `!`
before the variable.

```ocaml title="bin/circuit_sim.ml"
Printf.printf "a: %s\n" (Bits.to_string !a_in);
Printf.printf "b: %s\n" (Bits.to_string !b_in);
Printf.printf "c: %s\tWidth: %d\n" (Bits.to_string !c_out) (Bits.width !c_out);
Printf.printf "c: %s\tWidth: %d\n" (Bits.to_string !d_out) (Bits.width !d_out);
```

```ocaml title="Output"
a: 10100011
b: 00101100
c: 11001111     Width: 8
c: 0001110000000100     Width: 16
```

:::info
Do the math and see if this is correct!
:::

### Creating a waveform

Hardcaml can create a pretty epic waveform graph of our simulation using `hardcaml_waveterm`.
In order to use it, be sure to include the module:

- Add `open Hardcaml_waveterm` to the beginning of your file
- Add `hardcaml_waveterm` to your libraries in your `dune` file

Let's take our old simulation again and change a few things:

```ocaml title="bin/circuit_sim.ml"
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


(* Print waveform *)
Waveform.print ~display_height:18 waves
```

Notice our changes:

1. Initialized our waveform using `Waveform.create`
2. Commented out our output ports
3. Added another simulation step
4. Printed waveform with `Waveform.print`

And now, our beautiful output:

```ocaml title="Output"
┌Signals────────┐┌Waves──────────────────────────────────────────────┐
│               ││────────┬───────                                   │
│a              ││ A3     │01                                        │
│               ││────────┴───────                                   │
│               ││────────┬───────                                   │
│b              ││ 2C     │44                                        │
│               ││────────┴───────                                   │
│               ││────────┬───────                                   │
│c              ││ CF     │45                                        │
│               ││────────┴───────                                   │
│               ││────────┬───────                                   │
│d              ││ 1C04   │0044                                      │
│               ││────────┴───────                                   │
└───────────────┘└───────────────────────────────────────────────────┘
```

## Circuit convention

Let's organize our code a little bit and make it more _professional_
and _conventional_, and even more, _type safe_!

Instead of listing out our inputs and outputs one by one, we can use
**`modules`**. Let's apply them to our current circuit.

```ocaml title="bin/circuit_sim_conventional.ml"
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
    ; ouput_d : 'a[@bits 16]
    }
  [@@deriving hardcaml]
end
```

Now we've strictly defined both our inputs and our outputs! Next, create a **`create`** function:

```ocaml title="bin/circuit_sim_conventional.ml"
(* Creating circuit logic *)
let create (i : _ I.t) =
  { O.output_c = i.input_a +: i.input_b
  ; output_d = i.input_a *: i.input_b
  }
```

In our main function, we will use the special **`Circuit.With_interface(I)(O)`** to define a circuit module with
our corresponding inputs and outputs:

```ocaml title="bin/circuit_sim_conventional.ml"
let () =
  (* Creating circuit *)
  let module My_Circuit = Circuit.With_interface(I)(O) in
  let circuit = My_Circuit.create_exn ~name:"My_Circuit" create in

  (* Printing Verilog *)
  Rtl.print Verilog circuit;
```

Then, use **`Cyclesim.With_interface(I)(O)`** to define a simulator, where you can gather
all the inputs and outputs with just one function call:

```ocaml title="bin/circuit_sim_conventional.ml"
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
```

Notice the new way we get our inputs with **`Cyclesim.inputs`**.
Our entire file should look like this:

```ocaml title="bin/circuit_sim_conventional.ml"
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
```

I know it's more boilerplate, but look at that, our **Inputs**, **Outputs**, and **RTL Logic** are
all in their own organized modules! When we scale this up, our code will stay organized.

:::note
Learn more in [5.4 - Module Interfaces](https://github.com/janestreet/hardcaml/blob/master/docs/module_interface.md)
:::

## What now?

Awesome! Now we have something tangible to play around with. The problem, though, is that
all of this is **combinational**, meaning it has no **states**. How am I supposed to solve complex
_Advent of Code_ problems with this? Tomorrow, we'll go through Hardcaml's **Sequential** logic!

## Good resources

- [circuit_sim.ml]()
- [circuit_sim_conventional.ml]()
- [Hardcaml Docs - 2.1 Combinational Logic](https://github.com/janestreet/hardcaml/blob/master/docs/combinational_logic.md)
- [Hardcaml Docs - 2.3 Circuits](https://github.com/janestreet/hardcaml/blob/master/docs/combinational_logic.md)
- [Hardcaml Docs - 3.2 Waveforms](https://github.com/janestreet/hardcaml/blob/master/docs/waveforms.md)
