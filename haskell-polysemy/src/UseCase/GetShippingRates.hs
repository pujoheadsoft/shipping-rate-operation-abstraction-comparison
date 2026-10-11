module UseCase.GetShippingRates where

import           Domain.Shipment          (Shipment)
import           Domain.ShippingRates     (ShippingRates)
import           Polysemy                 (Members, Sem)
import           Polysemy.Error           (Error, throw)
import           UseCase.ShippingRatePort

data GetShippingRatesError = GetShippingRatesFailed deriving (Eq, Show)

getShippingRates
  :: Members '[ShippingRatePort, Error GetShippingRatesError] r
  => Shipment
  -> Sem r ShippingRates
getShippingRates shipment =
  fetchShippingRates shipment
    >>= either (const $ throw GetShippingRatesFailed) pure
