let post env (request : Http_client.request) =
  Eio.Switch.run @@ fun sw ->
  let uri = Uri.of_string request.url in
  match
    Piaf.Client.Oneshot.post ~sw env uri
      ~headers:[ ("content-type", "application/json") ]
      ~body:(Piaf.Body.of_string request.body)
  with
  | Error _ -> Error Http_client.Transport_failed
  | Ok response -> (
      match Piaf.Body.to_string response.body with
      | Error _ -> Error Http_client.Invalid_response
      | Ok body ->
          Ok Http_types.{ status = Piaf.Status.to_code response.status; body })

let create ~env : Http_client.t = { post = post env }

let get env url =
  Eio.Switch.run @@ fun sw ->
  let uri = Uri.of_string url in
  match Piaf.Client.Oneshot.get ~sw env uri with
  | Error _ -> Error User_http_client.Transport_failed
  | Ok response -> (
      match Piaf.Body.to_string response.body with
      | Error _ -> Error User_http_client.Invalid_response
      | Ok body ->
          Ok Http_types.{ status = Piaf.Status.to_code response.status; body })

let create_user ~env : User_http_client.t = { get = get env }
