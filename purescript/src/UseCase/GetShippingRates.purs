module UseCase.GetShippingRates (getShippingRates) where

import Prelude

import Control.Monad.Reader.Trans (ReaderT, ask, lift)
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Domain.Shipment (Shipment)
import Domain.ShippingRates (ShippingRates)
import Effect.Aff (Aff)
import Port.ShippingRateError (FetchShippingRatesError(..))
import Port.ShippingRatePort (ShippingRatePort)
import UseCase.GetShippingRatesError (GetShippingRatesError(..))

getShippingRates
  :: Shipment
  -> ReaderT ShippingRatePort Aff
       (Either GetShippingRatesError ShippingRates)
getShippingRates s = do
  port <- ask
  result <- lift $ port.fetchShippingRates s
  pure $ lmap
    (\FetchShippingRatesFailed -> GetShippingRatesFailed)
    result
