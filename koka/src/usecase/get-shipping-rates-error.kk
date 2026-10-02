module usecase/get-shipping-rates-error

pub type get-shipping-rates-error
  GetShippingRatesFailed

pub fun get-shipping-rates-error/(==)(
  a : get-shipping-rates-error,
  b : get-shipping-rates-error
) : bool
  True

pub fun get-shipping-rates-error/show(error : get-shipping-rates-error) : string
  "GetShippingRatesFailed"
