open Shipping_rate_eio_effects

let rates =
  Domain.Shipping_rates.make
    (Domain.Shipping_rate.make ~carrier:"X" ~amount:300)
    [ Domain.Shipping_rate.make ~carrier:"Y" ~amount:200 ]

let run ~postal ~shipping action =
  Usecase.Postal_code_port.run ~fetch:postal @@ fun () ->
  Usecase.Shipping_rate_port.run ~fetch:shipping action

let success () =
  let result =
    run
      ~postal:(fun _ -> Ok (Domain.Postal_code.make "111-1111"))
      ~shipping:(fun _ -> Ok rates)
      (fun () ->
        Usecase.Get_cheapest_shipping_rate.get_cheapest_shipping_rate
          (Domain.User_id.make "U1") (Domain.Weight.make 1000))
  in
  match result with
  | Ok rate ->
      Alcotest.(check string) "carrier" "Y" rate.carrier;
      Alcotest.(check int) "amount" 200 rate.amount
  | Error _ -> Alcotest.fail "expected success"

let postal_failure_short_circuits () =
  let shipping_called = ref false in
  let result =
    run
      ~postal:(fun _ -> Error Usecase.Postal_code_port.Postal_code_not_found)
      ~shipping:(fun _ ->
        shipping_called := true;
        Ok rates)
      (fun () ->
        Usecase.Get_cheapest_shipping_rate.get_cheapest_shipping_rate
          (Domain.User_id.make "U1") (Domain.Weight.make 1000))
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
