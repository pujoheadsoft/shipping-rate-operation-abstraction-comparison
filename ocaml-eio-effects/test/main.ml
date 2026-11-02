let () =
  Alcotest.run "ocaml-eio-effects"
    [
      ("cheapest usecase", Get_cheapest_shipping_rate_test.cases);
      ("postal gateway", Postal_code_gateway_test.cases);
      ("gateway", Shipping_rates_gateway_test.cases);
      ("concurrency", Shipping_rates_gateway_concurrency_test.cases);
      ("driver X", Carrier_x_api_client_driver_test.cases);
      ("driver Y", Carrier_y_api_client_driver_test.cases);
      ("driver Z", Carrier_z_api_client_driver_test.cases);
    ]
