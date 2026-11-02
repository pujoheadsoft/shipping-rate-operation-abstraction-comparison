type runner = { run : 'a. (unit -> 'a) -> 'a }

val run : runner:runner -> (unit -> 'a) -> 'a
