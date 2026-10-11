module UseCase.ShippingRatePort
  ( FetchShippingRatesError(..)
  , ShippingRatePort
  ) where

import Prelude

import Data.Either (Either)
import Domain.Shipment (Shipment)
import Domain.ShippingRates (ShippingRates)
import Effect.Aff (Aff)

data FetchShippingRatesError
  = FetchShippingRatesFailed

derive instance Eq FetchShippingRatesError

instance Show FetchShippingRatesError where
  show FetchShippingRatesFailed = "FetchShippingRatesFailed"

type ShippingRatePort =
  { fetchShippingRates
      :: Shipment
      -> Aff (Either FetchShippingRatesError ShippingRates)
  }
