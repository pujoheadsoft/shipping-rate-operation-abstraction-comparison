module Carrier_x = Carrier_x_api_client
module Carrier_y = Carrier_y_api_client
module Carrier_z = Carrier_z_api_client

type dependencies = {
  carrier_x : Carrier_x.t;
  carrier_y : Carrier_y.t;
  carrier_z : Carrier_z.t;
}

let to_carrier_x_request (shipment : Domain.Shipment.t) : Carrier_x.request =
  {
    destination = shipment.destination_postal_code;
    weight_grams = shipment.weight;
  }

let to_carrier_y_request (shipment : Domain.Shipment.t) : Carrier_y.request =
  { postal_code = shipment.destination_postal_code; weight = shipment.weight }

let to_carrier_z_request (shipment : Domain.Shipment.t) : Carrier_z.request =
  { postal_code = shipment.destination_postal_code; weight = shipment.weight }

let carrier_x_response_to_shipping_rate (response : Carrier_x.response) =
  Domain.Shipping_rate.make ~carrier:"CarrierX" ~amount:response.amount

let carrier_y_response_to_shipping_rate (response : Carrier_y.response) =
  Domain.Shipping_rate.make ~carrier:"CarrierY" ~amount:response.price

let carrier_z_response_to_shipping_rate (response : Carrier_z.response) =
  Domain.Shipping_rate.make ~carrier:"CarrierZ" ~amount:response.amount

let fetch_shipping_rates dependencies shipment =
  let x, (y, z) =
    Eio.Fiber.pair
      (fun () ->
        dependencies.carrier_x.fetch_rate (to_carrier_x_request shipment))
      (fun () ->
        Eio.Fiber.pair
          (fun () ->
            dependencies.carrier_y.fetch_rate (to_carrier_y_request shipment))
          (fun () ->
            dependencies.carrier_z.fetch_rate (to_carrier_z_request shipment)))
  in
  match (x, y, z) with
  | Ok x, Ok y, Ok z ->
      let x = carrier_x_response_to_shipping_rate x in
      let y = carrier_y_response_to_shipping_rate y in
      let z = carrier_z_response_to_shipping_rate z in
      Ok (Domain.Shipping_rates.make x [ y; z ])
  | _ -> Error Usecase.Shipping_rate_port.Fetch_shipping_rates_failed

let create_shipping_rate_port dependencies : Usecase.Shipping_rate_port.t =
  { fetch_shipping_rates = fetch_shipping_rates dependencies }
