type fetch_error = Fetch_shipping_rates_failed

val fetch_shipping_rates :
  Domain.Shipment.t -> (Domain.Shipping_rates.t, fetch_error) result

val run :
  fetch:(Domain.Shipment.t -> (Domain.Shipping_rates.t, fetch_error) result) ->
  (unit -> 'a) ->
  'a
