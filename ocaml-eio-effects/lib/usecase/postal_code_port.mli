type fetch_error = Postal_code_not_found | Fetch_postal_code_failed

val fetch_postal_code_by_user_id :
  Domain.User_id.t -> (Domain.Postal_code.t, fetch_error) result

val run :
  fetch:(Domain.User_id.t -> (Domain.Postal_code.t, fetch_error) result) ->
  (unit -> 'a) ->
  'a
