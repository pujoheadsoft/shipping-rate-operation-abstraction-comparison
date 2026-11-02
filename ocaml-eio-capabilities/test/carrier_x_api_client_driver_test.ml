open Shipping_rate_eio_capabilities
module Client = Gateway.Carrier_x_api_client
module X_driver = Driver.Carrier_x_api_client_driver

let request = Client.{ destination = "111-1111"; weight_grams = 1000 }
let environment = X_driver.{ base_url = "https://carrier-x.example.com" }

let success () =
  let observed = ref None in
  let http : Driver.Http_client.t =
    {
      post =
        (fun request ->
          observed := Some request;
          Ok
            Driver.Http_types.
              {
                status = 200;
                body = {|{"amount":1000,"serviceCode":"EXPRESS"}|};
              });
    }
  in
  let client = X_driver.create ~http environment in
  (match client.fetch_rate request with
  | Ok response ->
      Alcotest.(check int) "amount" 1000 response.amount;
      Alcotest.(check string) "service code" "EXPRESS" response.service_code
  | Error _ -> Alcotest.fail "expected success");
  match !observed with
  | Some request ->
      Alcotest.(check string)
        "URL" "https://carrier-x.example.com/shipping-rates" request.url;
      Alcotest.(check string)
        "body" {|{"destination":"111-1111","weightGrams":1000}|} request.body
  | None -> Alcotest.fail "HTTP client was not called"

let failure () =
  let http : Driver.Http_client.t =
    {
      post =
        (fun _ ->
          Ok Driver.Http_types.{ status = 503; body = {|{"error":"down"}|} });
    }
  in
  let client = X_driver.create ~http environment in
  match client.fetch_rate request with
  | Error Client.Carrier_x_api_operation_failed -> ()
  | Ok _ -> Alcotest.fail "expected CarrierXApiOperationFailed"

let invalid_json () =
  let http : Driver.Http_client.t =
    {
      post =
        (fun _ ->
          Ok Driver.Http_types.{ status = 200; body = {|{"amount":"oops"}|} });
    }
  in
  let client = X_driver.create ~http environment in
  match client.fetch_rate request with
  | Error Client.Carrier_x_api_operation_failed -> ()
  | Ok _ -> Alcotest.fail "expected CarrierXApiOperationFailed"

let cases =
  [
    Alcotest.test_case "encodes and decodes Carrier X HTTP" `Quick success;
    Alcotest.test_case "maps a non-2xx response" `Quick failure;
    Alcotest.test_case "maps an invalid JSON response" `Quick invalid_json;
  ]
