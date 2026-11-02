type dependencies = {
  carrier_x : Carrier_x_api_client.t;
  carrier_y : Carrier_y_api_client.t;
  carrier_z : Carrier_z_api_client.t;
}

val fetch_shipping_rates :
  dependencies ->
  Domain.Shipment.t ->
  (Domain.Shipping_rates.t, Usecase.Shipping_rate_port.fetch_error) result

val create_shipping_rate_port : dependencies -> Usecase.Shipping_rate_port.t
