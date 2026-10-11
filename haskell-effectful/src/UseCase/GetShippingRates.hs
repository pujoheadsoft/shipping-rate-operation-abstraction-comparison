module UseCase.GetShippingRates where

import           Domain.Shipment          (Shipment)
import           Domain.ShippingRates     (ShippingRates)
import           Effectful                (Eff, (:>))
import           Effectful.Error.Static   (Error, throwError)
import           UseCase.ShippingRatePort

data GetShippingRatesError = GetShippingRatesFailed
  deriving (Eq, Show)

getShippingRates
  :: (ShippingRatePort :> es, Error GetShippingRatesError :> es)
  => Shipment
  -> Eff es ShippingRates
getShippingRates shipment =
  fetchShippingRates shipment
    >>= either (const $ throwError GetShippingRatesFailed) pure
