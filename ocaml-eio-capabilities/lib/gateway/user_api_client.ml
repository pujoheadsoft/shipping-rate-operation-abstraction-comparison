type request = { user_id : string }
type response = { postal_code : string }
type error = User_api_user_not_found | User_api_operation_failed
type t = { fetch_user : request -> (response, error) result }
