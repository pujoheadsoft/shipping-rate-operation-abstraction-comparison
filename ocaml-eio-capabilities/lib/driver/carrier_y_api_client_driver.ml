module Client = Gateway.Carrier_y_api_client

type environment = { base_url : string }

let encode_request (request : Client.request) =
  `Assoc
    [
      ("postalCode", `String request.postal_code);
      ("weight", `Int request.weight);
    ]
  |> Yojson.Safe.to_string

let decode_response response : Client.response =
  let json = Json_helpers.require_success response in
  {
    price = Json_helpers.int "price" json;
    service_name = Json_helpers.string "serviceName" json;
  }

let fetch_rate http environment request =
  match
    http.Http_client.post
      {
        url = environment.base_url ^ "/rates/quote";
        body = encode_request request;
      }
  with
  | Error _ -> Error Client.Carrier_y_api_operation_failed
  | Ok response -> (
      try Ok (decode_response response)
      with
      | Json_helpers.Invalid_response | Yojson.Json_error _
      | Yojson.Safe.Util.Type_error _
      ->
        Error Client.Carrier_y_api_operation_failed)

let create ~http environment : Client.t =
  { fetch_rate = fetch_rate http environment }
