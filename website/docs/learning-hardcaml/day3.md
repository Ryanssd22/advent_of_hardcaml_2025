import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Day 3 - Understanding FPGA architecture

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

## Wires

Here's what's separates real, chud reconfiguration from your typical programmer.
Reconfiguration is all about describing the _flow of logic_, meaning we aren't
actually dealing with hard and fast values like **Signals** alone. Our logic is dicatated
by where we actually route our **Wires**

Hardcaml uses an example of a **Graph**, where our logic are the **Verticies** and
wires are the **Edges**. (Helps if you're a graph theory guy)

Also this is mostly conceptual, as Hardcaml kinda abstracts wires away anyways. You're
still able to define wires, but as they themselves put it:

> [Wires] logically do nothing

## Circuits

Now this is where the magic actually happens! Circuits allow us to feed in an **input**,
make it pass through some **logic**, and deliver us a fresh, steaming **output**.

### Defining out inputs

In Hardcaml, our inputs will be a default signal with a given width. We are able to
define them as such:

```ocaml title="/bin/circuit.ml"
let input_a = input "a" 8 in
let input_b = input "b" 8 in
```

Here, we created two input signals, one named `"a"` and the other `"b"`. They both have
a width of `8` bits.

### Defining out outputs

### Creating our circuit

## Good resources

- [Hardcaml Docs - 2.1 Combinational Logic](https://github.com/janestreet/hardcaml/blob/master/docs/combinational_logic.md)
