module UseCase.ShippingRatePort where

import           Domain.Shipment            (Shipment)
import           Domain.ShippingRates       (ShippingRates)
import           Effectful
import           Effectful.Dispatch.Dynamic (send)

data FetchShippingRatesError = FetchShippingRatesFailed
  deriving (Eq, Show)

data ShippingRatePort :: Effect where
  FetchShippingRates
    :: Shipment
    -> ShippingRatePort m (Either FetchShippingRatesError ShippingRates)

type instance DispatchOf ShippingRatePort = Dynamic

fetchShippingRates
  :: ShippingRatePort :> es
  => Shipment
  -> Eff es (Either FetchShippingRatesError ShippingRates)
fetchShippingRates shipment = send $ FetchShippingRates shipment
