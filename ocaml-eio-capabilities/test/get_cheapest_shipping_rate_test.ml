open Shipping_rate_eio_capabilities

let rates =
  Domain.Shipping_rates.make
    (Domain.Shipping_rate.make ~carrier:"X" ~amount:300)
    [ Domain.Shipping_rate.make ~carrier:"Y" ~amount:200 ]

let success () =
  let postal : Usecase.Postal_code_port.t =
    {
      fetch_postal_code_by_user_id =
        (fun _ -> Ok (Domain.Postal_code.make "111-1111"));
    }
  in
  let shipping : Usecase.Shipping_rate_port.t =
    { fetch_shipping_rates = (fun _ -> Ok rates) }
  in
  match
    Usecase.Get_cheapest_shipping_rate.get_cheapest_shipping_rate postal
      shipping (Domain.User_id.make "U1") (Domain.Weight.make 1000)
  with
  | Ok rate ->
      Alcotest.(check string) "carrier" "Y" rate.carrier;
      Alcotest.(check int) "amount" 200 rate.amount
  | Error _ -> Alcotest.fail "expected success"

let postal_failure_short_circuits () =
  let shipping_called = ref false in
  let postal : Usecase.Postal_code_port.t =
    {
      fetch_postal_code_by_user_id =
        (fun _ -> Error Usecase.Postal_code_port.Postal_code_not_found);
    }
  in
  let shipping : Usecase.Shipping_rate_port.t =
    {
      fetch_shipping_rates =
        (fun _ ->
          shipping_called := true;
          Ok rates);
    }
  in
  let result =
    Usecase.Get_cheapest_shipping_rate.get_cheapest_shipping_rate postal
      shipping (Domain.User_id.make "U1") (Domain.Weight.make 1000)
  in
  Alcotest.(check bool) "shipping port not called" false !shipping_called;
  match result with
  | Error Usecase.Get_cheapest_shipping_rate.Shipping_destination_not_found -> ()
  | _ -> Alcotest.fail "expected ShippingDestinationNotFound"

let cases =
  [
    Alcotest.test_case "returns the cheapest rate" `Quick success;
    Alcotest.test_case "postal failure short-circuits shipping" `Quick
      postal_failure_short_circuits;
  ]
