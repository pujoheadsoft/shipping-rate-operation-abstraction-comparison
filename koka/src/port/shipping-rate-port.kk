module port/shipping-rate-port

import effect/fail
import domain/shipment
import domain/shipping-rates
import port/shipping-rate-error

pub effect shipping-rate-port
  fun fetch-shipping-rates(value : shipment) : result<shipping-rates, fetch-shipping-rates-error>
