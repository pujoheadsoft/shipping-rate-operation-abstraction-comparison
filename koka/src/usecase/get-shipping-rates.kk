module usecase/get-shipping-rates

import domain/shipment
import domain/shipping-rates
import usecase/shipping-rate-port

pub fun get-shipping-rates-error/show(error : get-shipping-rates-error) : string
  "GetShippingRatesFailed"

pub fun get-shipping-rates(shipment : shipment)
  : shipping-rate-port result<shipping-rates,get-shipping-rates-error>
  match fetch-shipping-rates(shipment)
    Ok(rates) -> Ok(rates)
    Error(FetchShippingRatesFailed) -> Error(GetShippingRatesFailed)

pub type get-shipping-rates-error
  GetShippingRatesFailed

pub fun get-shipping-rates-error/(==)(
  a : get-shipping-rates-error,
  b : get-shipping-rates-error
) : bool
  True
