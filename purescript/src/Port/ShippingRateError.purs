module Port.ShippingRateError (FetchShippingRatesError(..)) where

import Prelude

data FetchShippingRatesError
  = FetchShippingRatesFailed

derive instance Eq FetchShippingRatesError

instance Show FetchShippingRatesError where
  show FetchShippingRatesFailed = "FetchShippingRatesFailed"
