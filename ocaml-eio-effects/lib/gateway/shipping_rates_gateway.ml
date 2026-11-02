module Carrier_x = Carrier_x_api_client
module Carrier_y = Carrier_y_api_client
module Carrier_z = Carrier_z_api_client

let to_carrier_x_request (shipment : Domain.Shipment.t) : Carrier_x.request =
  {
    destination = shipment.destination_postal_code;
    weight_grams = shipment.weight;
  }

let to_carrier_y_request (shipment : Domain.Shipment.t) : Carrier_y.request =
  { postal_code = shipment.destination_postal_code; weight = shipment.weight }

let to_carrier_z_request (shipment : Domain.Shipment.t) : Carrier_z.request =
  { postal_code = shipment.destination_postal_code; weight = shipment.weight }

let require_success = function
  | Ok response -> response
  | Error _ -> Fetch_error.fail Fetch_error.Fetch_shipping_rates_failed

let fetch_shipping_rates shipment =
  let x, y, z =
    Runtime.Parallel.all3
      (fun () -> Carrier_x.fetch_rate (to_carrier_x_request shipment))
      (fun () -> Carrier_y.fetch_rate (to_carrier_y_request shipment))
      (fun () -> Carrier_z.fetch_rate (to_carrier_z_request shipment))
  in
  let x = require_success x in
  let y = require_success y in
  let z = require_success z in
  let x = Domain.Shipping_rate.make ~carrier:"CarrierX" ~amount:x.amount in
  let y = Domain.Shipping_rate.make ~carrier:"CarrierY" ~amount:y.price in
  let z = Domain.Shipping_rate.make ~carrier:"CarrierZ" ~amount:z.amount in
  Domain.Shipping_rates.make x [ y; z ]

let run_as_shipping_rate_port action =
  Usecase.Shipping_rate_port.run
    ~fetch:(fun shipment ->
      match Fetch_error.run (fun () -> fetch_shipping_rates shipment) with
      | Ok rates -> Ok rates
      | Error Fetch_error.Fetch_shipping_rates_failed ->
          Error Usecase.Shipping_rate_port.Fetch_shipping_rates_failed)
    action
