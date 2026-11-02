module Client = Gateway.Carrier_x_api_client

type environment = { base_url : string }

let encode_request (request : Client.request) =
  `Assoc
    [
      ("destination", `String request.destination);
      ("weightGrams", `Int request.weight_grams);
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
        url = environment.base_url ^ "/shipping-rates";
        body = encode_request request;
      }
  with
  | Error _ -> Error Client.Carrier_x_api_operation_failed
  | Ok response -> (
      try Ok (decode_response response)
      with
      | Json_helpers.Invalid_response | Yojson.Json_error _
      | Yojson.Safe.Util.Type_error _
      ->
        Error Client.Carrier_x_api_operation_failed)

let create ~http environment : Client.t =
  { fetch_rate = fetch_rate http environment }
