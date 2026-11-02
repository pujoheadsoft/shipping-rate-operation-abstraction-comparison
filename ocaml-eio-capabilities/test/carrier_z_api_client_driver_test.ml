open Shipping_rate_eio_capabilities
module Client = Gateway.Carrier_z_api_client
module Driver = Driver.Carrier_z_api_client_driver

let request = Client.{ postal_code = "111-1111"; weight = 1000 }
let environment = Driver.{ base_url = "https://carrier-z.example.com" }

let success () =
  let observed = ref None in
  let http : Shipping_rate_eio_capabilities.Driver.Http_client.t =
    {
      post =
        (fun request ->
          observed := Some request;
          Ok
            Shipping_rate_eio_capabilities.Driver.Http_types.
              {
                status = 200;
                body = {|{"amount":3000,"serviceCode":"ECONOMY"}|};
              });
    }
  in
  let client = Driver.create ~http environment in
  (match client.fetch_rate request with
  | Ok response ->
      Alcotest.(check int) "amount" 3000 response.amount;
      Alcotest.(check string) "service code" "ECONOMY" response.service_code
  | Error _ -> Alcotest.fail "expected success");
  match !observed with
  | Some request ->
      Alcotest.(check string)
        "URL" "https://carrier-z.example.com/shipping/quote" request.url;
      Alcotest.(check string)
        "body" {|{"postalCode":"111-1111","weight":1000}|} request.body
  | None -> Alcotest.fail "HTTP client was not called"

let failure () =
  let http : Shipping_rate_eio_capabilities.Driver.Http_client.t =
    {
      post =
        (fun _ ->
          Ok
            Shipping_rate_eio_capabilities.Driver.Http_types.
              { status = 503; body = {|{"error":"down"}|} });
    }
  in
  match (Driver.create ~http environment).fetch_rate request with
  | Error Client.Carrier_z_api_operation_failed -> ()
  | Ok _ -> Alcotest.fail "expected CarrierZApiOperationFailed"

let invalid_json () =
  let http : Shipping_rate_eio_capabilities.Driver.Http_client.t =
    {
      post =
        (fun _ ->
          Ok
            Shipping_rate_eio_capabilities.Driver.Http_types.
              { status = 200; body = {|{"amount":"oops"}|} });
    }
  in
  match (Driver.create ~http environment).fetch_rate request with
  | Error Client.Carrier_z_api_operation_failed -> ()
  | Ok _ -> Alcotest.fail "expected CarrierZApiOperationFailed"

let cases =
  [
    Alcotest.test_case "encodes and decodes Carrier Z HTTP" `Quick success;
    Alcotest.test_case "maps Carrier Z non-2xx" `Quick failure;
    Alcotest.test_case "maps Carrier Z invalid JSON" `Quick invalid_json;
  ]
