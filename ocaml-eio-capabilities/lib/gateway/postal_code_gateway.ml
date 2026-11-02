let create (user_api : User_api_client.t) : Usecase.Postal_code_port.t =
  {
    fetch_postal_code_by_user_id =
      (fun user_id ->
        match
          user_api.fetch_user
            User_api_client.{ user_id = Domain.User_id.value user_id }
        with
        | Ok user -> Ok (Domain.Postal_code.make user.postal_code)
        | Error User_api_client.User_api_user_not_found ->
            Error Usecase.Postal_code_port.Postal_code_not_found
        | Error User_api_client.User_api_operation_failed ->
            Error Usecase.Postal_code_port.Fetch_postal_code_failed);
  }
