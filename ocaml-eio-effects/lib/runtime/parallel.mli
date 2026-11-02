type _ Effect.t +=
  | All3 : (unit -> 'a) * (unit -> 'b) * (unit -> 'c) -> ('a * 'b * 'c) Effect.t

val all3 : (unit -> 'a) -> (unit -> 'b) -> (unit -> 'c) -> 'a * 'b * 'c
