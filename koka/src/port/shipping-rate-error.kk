module port/shipping-rate-error

pub type fetch-shipping-rates-error
  FetchShippingRatesFailed

pub fun fetch-shipping-rates-error/(==)(
  a : fetch-shipping-rates-error,
  b : fetch-shipping-rates-error
) : bool
  True

pub fun fetch-shipping-rates-error/show(error : fetch-shipping-rates-error) : string
  "FetchShippingRatesFailed"