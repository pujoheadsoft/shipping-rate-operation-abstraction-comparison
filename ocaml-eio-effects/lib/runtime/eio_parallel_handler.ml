type runner = { run : 'a. (unit -> 'a) -> 'a }

let run : type a. runner:runner -> (unit -> a) -> a =
 fun ~runner action ->
  Effect.Deep.try_with action ()
    {
      effc =
        (fun (type b) (eff : b Effect.t) ->
          match eff with
          | Parallel.All3 (first, second, third) ->
              Some
                (fun (continuation : (b, _) Effect.Deep.continuation) ->
                  let first, (second, third) =
                    Eio.Fiber.pair
                      (fun () -> runner.run first)
                      (fun () ->
                        Eio.Fiber.pair
                          (fun () -> runner.run second)
                          (fun () -> runner.run third))
                  in
                  Effect.Deep.continue continuation (first, second, third))
          | _ -> None);
    }
