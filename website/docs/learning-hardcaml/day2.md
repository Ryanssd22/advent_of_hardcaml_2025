# Day 2 - Initializing Hardcaml

<img src={require('/assets/hardcamlcrack.jpg').default} alt="OCaml meme" width="400px" />

Truth be told, once I tried to dive deeper into OCaml, I got stuck in the weeds. Anything
past adding two numbers together in a function is past my pay grade.

Instead, let's move onto actually creating some hardware and some waveforms! Most of this can be found
in the [Hardcaml Docs](https://github.com/janestreet/hardcaml)

## Download Hardcaml

This is the easiest part.

```
opam install hardcaml hardcaml_waveterm ppx_hardcaml
```

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

## Hardcaml Bits

:::note
I will be assuming that you have a good grasp on binary. If you do not, read a book.
:::
