module UseCase.GetShippingRates (getShippingRates) where

import Control.Monad.Reader.Trans (ReaderT)
import Domain.Shipment (Shipment)
import Domain.ShippingRates (ShippingRates)
import Partial.Unsafe (unsafeCrashWith)
import Port.ShippingRatePort (ShippingRatePort)

getShippingRates
  :: forall m
   . Shipment
  -> ReaderT ShippingRatePort m ShippingRates
getShippingRates _ = unsafeCrashWith "Not implemented"
