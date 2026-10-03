module UseCase.GetShippingRatesError (GetShippingRatesError(..)) where

import Prelude

data GetShippingRatesError
  = GetShippingRatesFailed

derive instance Eq GetShippingRatesError

instance Show GetShippingRatesError where
  show GetShippingRatesFailed = "GetShippingRatesFailed"
