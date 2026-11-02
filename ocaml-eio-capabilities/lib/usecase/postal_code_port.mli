type fetch_error = Postal_code_not_found | Fetch_postal_code_failed

type t = {
  fetch_postal_code_by_user_id :
    Domain.User_id.t -> (Domain.Postal_code.t, fetch_error) result;
}
