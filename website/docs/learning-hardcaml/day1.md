# Initializing OCaml

<img src={require('/assets/ocamlmeme.jpg').default} alt="OCaml meme" width="400px" />

:::note

OCaml stands for "oh, caml"

:::

The folks at Jane Street stated that we can use _any_ hardware descriptive language
for this challenge, like the more common **Verilog** or **VHDL**.
But I thought it would be more fun to try out funtional programming;
I've heard many praise the language _(or at least haskel)_, so it could help me learn some more
programming paradigms.

But before we delve into the weeds of what OCaml actually is, or
how it works, we first have to setup our environment.

## Installing OCaml

:::warning

Although you can install OCaml on Windows, the module `ppx_hardcaml` is only available
on Linux hardware. Here, I will go over the Linux installation. If you are on Windows,
you can use **WSL** _(goated)_.

:::

### 1. Install the OPAM package manager

:::note
**OPAM** stands for "Ocaml P Ackage Manager."
I don't know what a "P Ackage" is either.
:::

```bash
bash -c "sh <(curl -fsSL https://OPAM.ocaml.org/install.sh)"
```

### 2. Initialize OPAM

Create an **OPAM switch**, which is a type of environment. Think Python's virtual environments.

```bash
opam init -y
```

### 3. Activate OPAM switch

After you initialize, it should print out the command you should run, which is:

```bash
eval $(opam env)
```

### 4. Set up development environment

Now with OPAM, you can install some OCaml platform tools:

```bash
opam install ocaml-lsp-server odoc ocamlformat utop
```

Now once you've installed everything needed for OCaml, I recommend running
`utop` and trying out what OCaml has to offer.
Try out this handy [Tour of OCaml](https://ocaml.org/docs/tour-of-ocaml) so you could
see the basics of OCaml.

Other than that, we can start setting up our main project

## Setting up your Dune project

:::note

Dune stands for the hit 1984 film directed by David Lynch. I recommend The Straight Story.

:::

Go to your favorite directory and create a new dune project. You can name `my_project`
with whatever name you want.

```bash
dune init proj my_project
```

The folder structure should be similar to this. Be sure to understand
what each folder and file is for. And remember, there are multiple `dune` files,
so don't get them mixed up...

```bash
.
├── bin
│   ├── dune
│   └── main.ml
├── _build
│   └── log
├── dune-project
├── lib
│   └── dune
├── my_project.opam
└── test
    ├── dune
    └── test_my_project.ml
```

- **`dune-project`** - Metadata for your project

- **`my_project.opam`** - OPAM package file. Automatically generated from `dune-project`

- **`dune files`** - Build config for your executables (`bin/`), library (`lib/`) or tests (`test/`)

- **`bin/main.ml`** - Main entry point for the program

- **`test/test_my_project.ml`** - Where you test your executables and libraries.

## Learning OCaml

From here, I'd recommend writing a quick little program inside `bin/main.ml`.
There's bunch of tutorials to learn out there, so find one you like.

Or use AI, I ain't your dad.

Here's a little [fibonacci sequence](https://www.literateprograms.org/fibonacci_numbers__ocaml_.html) in OCaml using recursion:

```jsx title="./bin/main.ml"
let rec fibonacci a b n =
  Printf.printf "Solving: %d\n" n;
  match n with
  | 0 -> a
  | 1 -> b
  | n when n > 1 -> fibonacci b (a+b) (n-1)
  | _ -> raise (Invalid_argument "Fibonacci numbers only defined when k >= 0")

let () =
  let result = fibonacci 0 1 5000 in
  Printf.printf "Fibonacci result: %d\n" result
```
