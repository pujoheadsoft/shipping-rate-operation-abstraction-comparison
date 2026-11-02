module Client = Gateway.Carrier_z_api_client

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
    amount = Json_helpers.int "amount" json;
    service_code = Json_helpers.string "serviceCode" json;
  }

let fetch_rate http environment request =
  match
    http.Http_client.post
      {
        url = environment.base_url ^ "/shipping/quote";
        body = encode_request request;
      }
  with
  | Error _ -> Error Client.Carrier_z_api_operation_failed
  | Ok response -> (
      try Ok (decode_response response)
      with
      | Json_helpers.Invalid_response | Yojson.Json_error _
      | Yojson.Safe.Util.Type_error _
      ->
        Error Client.Carrier_z_api_operation_failed)

let run ~http environment = Client.run ~fetch:(fetch_rate http environment)
