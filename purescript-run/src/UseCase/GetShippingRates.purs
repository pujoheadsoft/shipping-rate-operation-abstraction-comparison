module UseCase.GetShippingRates (GetShippingRatesError(..), getShippingRates) where

import Prelude
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Domain.Shipment (Shipment)
import Domain.ShippingRates (ShippingRates)
import Run (Run)
import UseCase.ShippingRatePort (SHIPPING_RATE_PORT, fetchShippingRates)

data GetShippingRatesError = GetShippingRatesFailed

derive instance Eq GetShippingRatesError
instance Show GetShippingRatesError where
  show GetShippingRatesFailed = "GetShippingRatesFailed"

getShippingRates
  :: forall r
   . Shipment
  -> Run (shippingRatePort :: SHIPPING_RATE_PORT | r) (Either GetShippingRatesError ShippingRates)
getShippingRates = map (lmap (const GetShippingRatesFailed)) <<< fetchShippingRates
