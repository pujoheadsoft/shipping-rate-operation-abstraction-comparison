type fetch_error = Postal_code_not_found | Fetch_postal_code_failed

type _ Effect.t +=
  | Fetch_postal_code_by_user_id :
      Domain.User_id.t
      -> (Domain.Postal_code.t, fetch_error) result Effect.t

let fetch_postal_code_by_user_id user_id =
  Effect.perform (Fetch_postal_code_by_user_id user_id)

let run : type a.
    fetch:(Domain.User_id.t -> (Domain.Postal_code.t, fetch_error) result) ->
    (unit -> a) ->
    a =
 fun ~fetch action ->
  Effect.Deep.try_with action ()
    {
      effc =
        (fun (type b) (eff : b Effect.t) ->
          match eff with
          | Fetch_postal_code_by_user_id user_id ->
              Some
                (fun (continuation : (b, _) Effect.Deep.continuation) ->
                  Effect.Deep.continue continuation (fetch user_id))
          | _ -> None);
    }
