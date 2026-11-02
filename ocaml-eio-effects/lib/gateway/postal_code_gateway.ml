let fetch_postal_code user_id =
  match
    User_api_client.fetch_user
      User_api_client.{ user_id = Domain.User_id.value user_id }
  with
  | Ok user -> Ok (Domain.Postal_code.make user.postal_code)
  | Error User_api_client.User_api_user_not_found ->
      Error Usecase.Postal_code_port.Postal_code_not_found
  | Error User_api_client.User_api_operation_failed ->
      Error Usecase.Postal_code_port.Fetch_postal_code_failed

let run_as_postal_code_port action =
  Usecase.Postal_code_port.run ~fetch:fetch_postal_code action
