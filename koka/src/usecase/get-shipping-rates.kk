module usecase/get-shipping-rates

import domain/shipment
import domain/shipping-rates
import port/shipping-rate-port
import port/shipping-rate-error
import usecase/get-shipping-rates-error

pub fun get-shipping-rates(shipment : shipment)
  : shipping-rate-port result<shipping-rates,get-shipping-rates-error>
  match fetch-shipping-rates(shipment)
    Ok(rates) -> Ok(rates)
    Error(FetchShippingRatesFailed) -> Error(GetShippingRatesFailed)
