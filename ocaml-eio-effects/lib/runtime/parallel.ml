type _ Effect.t +=
  | All3 : (unit -> 'a) * (unit -> 'b) * (unit -> 'c) -> ('a * 'b * 'c) Effect.t

let all3 first second third = Effect.perform (All3 (first, second, third))
