module usecase/shipping-rate-port

import domain/shipment
import domain/shipping-rates

pub fun fetch-shipping-rates-error/show(error : fetch-shipping-rates-error) : string
  "FetchShippingRatesFailed"

pub effect shipping-rate-port
  fun fetch-shipping-rates(value : shipment) : result<shipping-rates,fetch-shipping-rates-error>

pub type fetch-shipping-rates-error
  FetchShippingRatesFailed

pub fun fetch-shipping-rates-error/(==)(
  a : fetch-shipping-rates-error,
  b : fetch-shipping-rates-error
) : bool
  True
