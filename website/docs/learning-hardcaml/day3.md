import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Day 3 - Understanding FPGA architecture

<img src={require('/assets/hardcaml_internals.jpg').default} alt="OCaml meme" width="400px" />

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

```ocaml title="/bin/circuit.ml"
let input_a = input "a" 8 in
let input_b = input "b" 8 in
```

Here, we created two input wires, one named `"a"` and the other `"b"`. They both have
a width of `8` bits.

### Defining our outputs

Next, we'll define our output wires in relation to some inputs and logic:

```ocaml titl="/bin/circuit.ml"
let output_c = output "c" (input_a +: input_b) in
```

Notice how `output_c` is defined ONLY by other signals, meaning that even its width
is derived from the widths of our inpts. Thus, the width of `output_c` is also `8`.

### Creating our circuit

Now that we've defined our inputs and our outputs, we are able to define our **circuit**!

Using `Circuit.create_exn`, we are able to encode our RTL (hardware) logic into a hardcaml variable:

```ocaml title="/bin/circuit.ml"
let circuit = Circuit.create_exn ~name:"My Circuit" [ output_c ]
```

:::note
See, as we are creating our circuit, it is only defined by our outputs, not our inputs.
This is because our inputs are already inherently defined in our output!
:::

### Turning our circuit into VHDL or Verilog

Of course, VHDL and Verilog are your prime RTL languages (I haven't met anyone who knows Hardcaml, or even OCaml for that matter).
Now that we've created our circuit, we are able to convert it to VHDL and Verilog using `Rtl.print`!

```ocaml title="/bin/circuit.ml"
Rtl.print Verilog Circuit
```

## Simulating our circuit

That's good and all, but creating our logic is only half the battle. The other half is **verification**!
Thus, our next job is to simulate our circuit, meaning we give it some inputs and verify its outputs.

Using the same circuit, let's create a simulator:

```ocaml title="bin/circuit.ml"
let (simulator : _ Cyclesim.t) = Cyclesim.create circuit
```

And let's create the input signals that we are going to simulate:

```ocaml title="bin/circuit.ml"
let a = Cyclesim.in_port simulator "a"
let b = Cyclesim.in_port simulator "b"
```

## Good resources

- [Hardcaml Docs - 2.1 Combinational Logic](https://github.com/janestreet/hardcaml/blob/master/docs/combinational_logic.md)
