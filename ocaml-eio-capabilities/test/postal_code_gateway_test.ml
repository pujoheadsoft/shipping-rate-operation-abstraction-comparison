open Shipping_rate_eio_capabilities

let run response =
  let user_api : Gateway.User_api_client.t =
    { fetch_user = (fun _ -> response) }
  in
  let port = Gateway.Postal_code_gateway.create user_api in
  port.fetch_postal_code_by_user_id (Domain.User_id.make "U1")

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
