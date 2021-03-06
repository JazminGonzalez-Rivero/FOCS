(* FoCS Spring 2015

   Homework 9 code


   Name:

   Email:

   Comments:

 *)


  
(* The underlying implementation for streams 
 *
 * You don't need to know anything about this code -- you will
 * use functions fby, head, and tail described below instead.
 *
 * But if you're curious, a stream is a pair of an element and a 
 * "promise" to compute the rest of the stream.
 * 
 * That "promise" is represented as a function
 *
 * The implementation memoizes that function: once the function is
 * called once, it remembers its result, and subsequent calls to the
 * function directly return the result without executing the body of
 * the function
 *
 *)
  
module AbsStream : 
    sig
      type 'a stream 
      val mk : 'a -> (unit -> 'a stream) -> 'a stream 
      val unmk1 : 'a stream -> 'a 
      val unmk2 : 'a stream -> 'a stream 
    end = 
  struct
    
    type 'a stream = R of 'a * (unit -> 'a stream)
	  
    let memoize f = 
      let memoized = ref None in
      let new_f () = 
	match !memoized with
	| None -> let result = f () in memoized := Some result; result
	| Some v -> v   in
      new_f
	
    let mk h t = R (h, memoize t) 
    let unmk1 s = let R (h,t) = s in h
    let unmk2 s = let R (h,t) = s in t ()
  end


(*
 * These are the stream functions you will want to use
 *
 *)

type 'a stream = 'a AbsStream.stream
let head : 'a stream -> 'a = AbsStream.unmk1
let tail : 'a stream -> 'a stream = AbsStream.unmk2
let fby : 'a -> (unit -> 'a stream) -> 'a stream = AbsStream.mk






(* 
 * list n s 
 * nth n s
 * list2 n m s
 *
 *
 * list : returns the list of the first 'n' elements of 's'
 * nth : returns the 'n'th element of stream 's'
 * list2 : returns the list of lists of the first 'm' elements
 *           of each of the first 'n' streams of 's'
 *
 *)


let rec list n s = 
  if n <= 0 then []
  else (head s) :: (list (n-1) (tail s))

let rec list2 n m s = 
  List.map (list m) (list n s)

let rec nth n s = 
  if n <= 0 then head s
  else nth (n - 1) (tail s)


(* 
 * const k : returns the constant stream of 'k's
 * from k : returns the stream of integers starting at 'k'
 * 
 *)

let rec const k = fby k (fun () -> const k)

let rec from k = fby k (fun () -> from (k+1))

let nats = from 0

(*
 * map f s : returns the stream obtained by applying 'f' 
 *             to every element of 's' 
 * filter p s : returns the stream of elements of 's' for which 'p' is true
 *
 *)

let rec map f s = fby (f (head s)) (fun () -> (map f (tail s)))

let plus1 s = map (fun x -> x + 1) s

let evens = map (fun x -> 2 * x) nats

let odds = plus1 evens

let squares = map (fun x -> x * x) nats

let rec filter p s = 
  if (p (head s)) 
  then fby (head s) (fun () -> filter p (tail s))
  else filter p (tail s)

let even s = filter (fun x -> (x mod 2 = 0)) s



(*
 * The Sieve of Eratosthenes
 *
 *)


let not_divisible_by n k = not (k mod n = 0)

let rec sieve s = 
   fby (head s) 
       (fun () -> sieve (filter (not_divisible_by (head s)) (tail s)))

let primes = sieve (from 2)



(* 
 * QUESTION 1 
 * 
 *)

let scale n s = map (fun x -> n*x) s;;

let rec zip s1 s2 =  fby ((head s1, head s2)) (fun () -> zip (tail s1) (tail s2));;

let rec add s1 s2 =  fby ((head s1) + (head s2)) (fun () -> add (tail s1) (tail s2));;

let rec merge s1 s2 = 
  let rec merge_help s1 s2 = fby (head s2) (fun () -> merge s1 (tail s2))
  in
  fby (head s1) (fun () -> merge_help (tail s1) s2);;

let psums s = 
    let rec get_sum lit = List.fold_right (fun x rest -> x + rest) lit 0 
    in
    let rec get_next n s = fby (get_sum  (list n s)) (fun () -> get_next (n+1) s)
    in 
    (get_next 1 s);;

let running_max s = 
    let rec get_max lit b = match lit with
    [] -> b
    | l::ls -> if l > b then (get_max ls l) else (get_max ls b)
    in
    let rec get_next n s = fby (get_max (list n s) (head s)) (fun () -> get_next (n+1) s)
    in 
    (get_next 1 s);;


(*
 * QUESTION 2
 * 
 *)
let rec fromf k = fby k (fun () -> fromf (k+.1.))

let natsf = fromf 0.

let scalef n s = map (fun x -> n*.x) s;;

let rec addf s1 s2 =  fby ((head s1) +. (head s2)) (fun () -> addf (tail s1) (tail s2));;

let psumsf s = 
    let rec get_sumf lit = List.fold_right (fun x rest -> x +. rest) lit 0.0 
    in
    let rec get_nextf n s = fby (get_sumf  (list n s)) (fun () -> get_nextf (n+1) s)
    in 
    (get_nextf 1 s);;

let rec arctan z = psumsf (map (fun k -> (-1.)**(k)  *.  ((z**(2.*.k+.1.))/.(2.*.k+.1.))) natsf);;

let pi () = (addf (scalef 16. (arctan(1./.5.))) (scalef (-4.) (arctan(1./.239.))));;
    
let rec newton f df guess = fby (guess) (fun () -> newton f df (guess -. (f guess)/.(df guess))) ;;

let derivative f x = map (fun n -> ((f (x+.(1./.n)) ) -. (f (x) ))/.(1./.n) ) (tail natsf);;

let limit mx eps s = 
  let absolute v = 
      if (v < 0.)
        then (-.v)
        else v
  in
  let rec find_nth n prev s1 = 
      if (n >= mx) 
          then None 
          else 
              if ((absolute ((head s1) -. prev)) <= eps) 
              then (Some (head s1))
              else find_nth (n+1) (head s1) (tail s1) 
  in
  find_nth 0 (head s) (tail s);;



(* 
 * QUESTION 3 
 * 
 *)

let rec table s1 s2 = failwith "table not implemented"

let rec stripes s = failwith "stripes not implemented"

let rec flatten s = failwith "flatten not implemented"

let pairs s1 s2 = failwith "pairs not implemented"
