type request = { user_id : string }
type response = { postal_code : string }
type error = User_api_user_not_found | User_api_operation_failed

type _ Effect.t += Fetch_user : request -> (response, error) result Effect.t

let fetch_user request = Effect.perform (Fetch_user request)

let run : type a.
    fetch:(request -> (response, error) result) -> (unit -> a) -> a =
 fun ~fetch action ->
  Effect.Deep.try_with action ()
    {
      effc =
        (fun (type b) (eff : b Effect.t) ->
          match eff with
          | Fetch_user request ->
              Some
                (fun (continuation : (b, _) Effect.Deep.continuation) ->
                  Effect.Deep.continue continuation (fetch request))
          | _ -> None);
    }
