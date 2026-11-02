type t = Fetch_shipping_rates_failed
type _ Effect.t += Fail : t -> 'a Effect.t

let fail error = Effect.perform (Fail error)

let run : type a. (unit -> a) -> (a, t) result =
 fun action ->
  Effect.Deep.match_with action ()
    {
      retc = (fun value -> Ok value);
      exnc = raise;
      effc =
        (fun (type b) (eff : b Effect.t) ->
          match eff with
          | Fail error -> Some (fun _continuation -> Error error)
          | _ -> None);
    }
