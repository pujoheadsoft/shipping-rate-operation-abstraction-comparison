module Client = Gateway.User_api_client

type environment = { base_url : string }

let decode body =
  try
    match Yojson.Safe.Util.member "postalCode" (Yojson.Safe.from_string body) with
    | `String postal_code -> Ok Client.{ postal_code }
    | _ -> Error Client.User_api_operation_failed
  with _ -> Error Client.User_api_operation_failed

let fetch_user http environment (request : Client.request) =
  match http.User_http_client.get (environment.base_url ^ "/users/" ^ request.user_id) with
  | Error _ -> Error Client.User_api_operation_failed
  | Ok { status = 404; _ } -> Error Client.User_api_user_not_found
  | Ok { status; _ } when status < 200 || status >= 300 ->
      Error Client.User_api_operation_failed
  | Ok { body; _ } -> decode body

let create ~http environment : Client.t =
  { fetch_user = fetch_user http environment }
