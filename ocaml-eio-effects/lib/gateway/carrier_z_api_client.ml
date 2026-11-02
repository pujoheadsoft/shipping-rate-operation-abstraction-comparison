type request = { postal_code : string; weight : int }
type response = { amount : int; service_code : string }
type error = Carrier_z_api_operation_failed
type _ Effect.t += Fetch_rate : request -> (response, error) result Effect.t

let fetch_rate request = Effect.perform (Fetch_rate request)

let run : type a.
    fetch:(request -> (response, error) result) -> (unit -> a) -> a =
 fun ~fetch action ->
  Effect.Deep.try_with action ()
    {
      effc =
        (fun (type b) (eff : b Effect.t) ->
          match eff with
          | Fetch_rate request ->
              Some
                (fun (continuation : (b, _) Effect.Deep.continuation) ->
                  Effect.Deep.continue continuation (fetch request))
          | _ -> None);
    }
