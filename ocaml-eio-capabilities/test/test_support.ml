open Shipping_rate_eio_capabilities
module X = Gateway.Carrier_x_api_client
module Y = Gateway.Carrier_y_api_client
module Z = Gateway.Carrier_z_api_client

let shipment =
  Domain.Shipment.make ~destination_postal_code:"111-1111" ~weight:1000

let rates_to_pairs rates =
  Domain.Shipping_rates.to_list rates
  |> List.map (fun (rate : Domain.Shipping_rate.t) ->
      (rate.carrier, rate.amount))

let rates_testable = Alcotest.(list (pair string int))

let expected_rates =
  Domain.Shipping_rates.make
    (Domain.Shipping_rate.make ~carrier:"CarrierX" ~amount:1000)
    [
      Domain.Shipping_rate.make ~carrier:"CarrierY" ~amount:2000;
      Domain.Shipping_rate.make ~carrier:"CarrierZ" ~amount:3000;
    ]

let check_rates message expected actual =
  Alcotest.check rates_testable message (rates_to_pairs expected)
    (rates_to_pairs actual)

let x_response = X.{ amount = 1000; service_code = "EXPRESS" }
let y_response = Y.{ price = 2000; service_name = "Standard Delivery" }
let z_response = Z.{ amount = 3000; service_code = "ECONOMY" }

let dependencies ~x ~y ~z : Gateway.Shipping_rates_gateway.dependencies =
  {
    carrier_x = { X.fetch_rate = x };
    carrier_y = { Y.fetch_rate = y };
    carrier_z = { Z.fetch_rate = z };
  }
