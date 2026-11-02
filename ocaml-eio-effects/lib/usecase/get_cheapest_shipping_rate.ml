type error = Shipping_destination_not_found | Get_cheapest_shipping_rate_failed

let get_cheapest_shipping_rate user_id weight =
  match Postal_code_port.fetch_postal_code_by_user_id user_id with
  | Error Postal_code_port.Postal_code_not_found ->
      Error Shipping_destination_not_found
  | Error Postal_code_port.Fetch_postal_code_failed ->
      Error Get_cheapest_shipping_rate_failed
  | Ok postal_code -> (
      let shipment =
        Domain.Shipment.make
          ~destination_postal_code:(Domain.Postal_code.value postal_code)
          ~weight:(Domain.Weight.value weight)
      in
      match Shipping_rate_port.fetch_shipping_rates shipment with
      | Ok rates -> Ok (Domain.Shipping_rates.find_cheapest rates)
      | Error Shipping_rate_port.Fetch_shipping_rates_failed ->
          Error Get_cheapest_shipping_rate_failed)
