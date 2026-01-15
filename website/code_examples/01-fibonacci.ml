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
