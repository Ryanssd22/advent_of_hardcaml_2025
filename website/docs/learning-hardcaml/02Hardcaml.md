# Initializing Hardcaml

<img src={require('/static/memes/hardcamlcrack.jpg').default} alt="OCaml meme" width="400px" />

Truth be told, once I tried to dive deeper into OCaml, I got stuck in the weeds. Anything
past adding two numbers together in a function is past my pay grade.

Instead, let's move onto actually creating some hardware and some waveforms! Most of this can be found
in the [Hardcaml Docs](https://github.com/janestreet/hardcaml)

## Download Hardcaml

This is the easiest part.

```
opam install hardcaml hardcaml_waveterm ppx_hardcaml
```

Grab yourself a sandwich while it downloads all **520** packages.

Next, you want to add the required dependencies to your dune project.

:::warning
Make sure it is in `/bin/dune`. Don't make my mistake :(
:::

```jsx title="/bin/dune"
(executable
 (public_name hardcaml_test)
 (name main)
 (libraries hardcaml_test base hardcaml)
 (preprocess (pps ppx_jane ppx_hardcaml)))
```

## Hardcaml Bits and Arithmetic

:::note
I will be assuming that you have a good grasp on binary. If you do not, read a book.
:::

Here are some examples of using Hardcaml to perform binary arithmetic!

```ocaml title="/bin/main.ml"
open Hardcaml.Signal

let () =
  (* String to signed int *)
  let x = of_string "11001001" in
  let y = to_sint x in
  Printf.printf "String to int: %d\n" y;
  Printf.printf "Width of bits: %d\n" (width x);

  (* Int to bits *)
  let x = of_int ~width:10 (-2) in
  Printf.printf "Int to bits: %s\n" (to_string x);

  (* Addition *)
  let x = of_int ~width:5 (10) in
  let y = of_int ~width:5 (3) in
  let sum = x +: y in
  Printf.printf "SUM:\n%s + %s = %s\n" (to_string x) (to_string y) (to_string sum);

  (* Subtraction *)
  let x = of_int ~width:5 (12) in
  let y = of_int ~width:5 (-3) in
  let difference = x -: y in
  Printf.printf "DIFFERENCE:\n%s - %s = %s\n" (to_string x) (to_string y) (to_string difference);
```
