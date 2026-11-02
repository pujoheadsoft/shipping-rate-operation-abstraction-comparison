open Shipping_rate_eio_capabilities
open Test_support

let check_x_request (request : X.request) =
  Alcotest.(check string) "X destination" "111-1111" request.destination;
  Alcotest.(check int) "X weight" 1000 request.weight_grams

let check_y_request (request : Y.request) =
  Alcotest.(check string) "Y postal code" "111-1111" request.postal_code;
  Alcotest.(check int) "Y weight" 1000 request.weight

let check_z_request (request : Z.request) =
  Alcotest.(check string) "Z postal code" "111-1111" request.postal_code;
  Alcotest.(check int) "Z weight" 1000 request.weight

let success () =
  Eio_mock.Backend.run @@ fun () ->
  let dependencies =
    dependencies
      ~x:(fun request ->
        check_x_request request;
        Ok x_response)
      ~y:(fun request ->
        check_y_request request;
        Ok y_response)
      ~z:(fun request ->
        check_z_request request;
        Ok z_response)
  in
  match
    Gateway.Shipping_rates_gateway.fetch_shipping_rates dependencies shipment
  with
  | Ok rates -> check_rates "X/Y/Z rates" expected_rates rates
  | Error _ -> Alcotest.fail "expected success"

let failure () =
  Eio_mock.Backend.run @@ fun () ->
  let dependencies =
    dependencies
      ~x:(fun _ -> Ok x_response)
      ~y:(fun _ -> Error Y.Carrier_y_api_operation_failed)
      ~z:(fun _ -> Ok z_response)
  in
  match
    Gateway.Shipping_rates_gateway.fetch_shipping_rates dependencies shipment
  with
  | Error Usecase.Shipping_rate_port.Fetch_shipping_rates_failed -> ()
  | Ok _ -> Alcotest.fail "expected FetchShippingRatesFailed"

let cases =
  [
    Alcotest.test_case "requests all carriers and preserves X/Y/Z order" `Quick
      success;
    Alcotest.test_case "maps a Carrier failure" `Quick failure;
  ]
