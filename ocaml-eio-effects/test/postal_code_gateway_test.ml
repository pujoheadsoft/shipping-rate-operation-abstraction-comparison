open Shipping_rate_eio_effects

let run response =
  Gateway.User_api_client.run ~fetch:(fun _ -> response) @@ fun () ->
  Gateway.Postal_code_gateway.run_as_postal_code_port @@ fun () ->
  Usecase.Postal_code_port.fetch_postal_code_by_user_id
    (Domain.User_id.make "U1")

let success () =
  match run (Ok Gateway.User_api_client.{ postal_code = "111-1111" }) with
  | Ok postal_code ->
      Alcotest.(check string)
        "postal code" "111-1111" (Domain.Postal_code.value postal_code)
  | Error _ -> Alcotest.fail "expected success"

let not_found () =
  match run (Error Gateway.User_api_client.User_api_user_not_found) with
  | Error Usecase.Postal_code_port.Postal_code_not_found -> ()
  | _ -> Alcotest.fail "expected PostalCodeNotFound"

let cases =
  [
    Alcotest.test_case "maps user response" `Quick success;
    Alcotest.test_case "maps user not found" `Quick not_found;
  ]
