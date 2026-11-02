type error = Shipping_destination_not_found | Get_cheapest_shipping_rate_failed

val get_cheapest_shipping_rate :
  Postal_code_port.t ->
  Shipping_rate_port.t ->
  Domain.User_id.t ->
  Domain.Weight.t ->
  (Domain.Shipping_rate.t, error) result
