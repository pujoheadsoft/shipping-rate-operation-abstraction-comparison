open Shipping_rate_eio_capabilities
module Client = Gateway.Carrier_y_api_client
module Driver = Driver.Carrier_y_api_client_driver

let request = Client.{ postal_code = "111-1111"; weight = 1000 }
let environment = Driver.{ base_url = "https://carrier-y.example.com" }

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
                body = {|{"price":2000,"serviceName":"Standard Delivery"}|};
              });
    }
  in
  let client = Driver.create ~http environment in
  (match client.fetch_rate request with
  | Ok response ->
      Alcotest.(check int) "price" 2000 response.price;
      Alcotest.(check string)
        "service name" "Standard Delivery" response.service_name
  | Error _ -> Alcotest.fail "expected success");
  match !observed with
  | Some request ->
      Alcotest.(check string)
        "URL" "https://carrier-y.example.com/rates/quote" request.url;
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
  | Error Client.Carrier_y_api_operation_failed -> ()
  | Ok _ -> Alcotest.fail "expected CarrierYApiOperationFailed"

let invalid_json () =
  let http : Shipping_rate_eio_capabilities.Driver.Http_client.t =
    {
      post =
        (fun _ ->
          Ok
            Shipping_rate_eio_capabilities.Driver.Http_types.
              { status = 200; body = {|{"price":"oops"}|} });
    }
  in
  match (Driver.create ~http environment).fetch_rate request with
  | Error Client.Carrier_y_api_operation_failed -> ()
  | Ok _ -> Alcotest.fail "expected CarrierYApiOperationFailed"

let cases =
  [
    Alcotest.test_case "encodes and decodes Carrier Y HTTP" `Quick success;
    Alcotest.test_case "maps Carrier Y non-2xx" `Quick failure;
    Alcotest.test_case "maps Carrier Y invalid JSON" `Quick invalid_json;
  ]
