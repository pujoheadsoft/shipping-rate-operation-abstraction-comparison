type fetch_error = Fetch_shipping_rates_failed

type t = {
  fetch_shipping_rates :
    Domain.Shipment.t -> (Domain.Shipping_rates.t, fetch_error) result;
}
