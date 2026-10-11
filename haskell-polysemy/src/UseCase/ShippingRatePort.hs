module UseCase.ShippingRatePort where

import           Domain.Shipment      (Shipment)
import           Domain.ShippingRates (ShippingRates)
import           Polysemy             (makeSem)

data FetchShippingRatesError = FetchShippingRatesFailed deriving (Eq, Show)

data ShippingRatePort m a where
  FetchShippingRates
    :: Shipment
    -> ShippingRatePort m (Either FetchShippingRatesError ShippingRates)

makeSem ''ShippingRatePort
