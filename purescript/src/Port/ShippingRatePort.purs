module Port.ShippingRatePort (ShippingRatePort) where

import Data.Either (Either)
import Domain.Shipment (Shipment)
import Domain.ShippingRates (ShippingRates)
import Effect.Aff (Aff)
import Port.ShippingRateError (FetchShippingRatesError)

type ShippingRatePort =
  { fetchShippingRates
      :: Shipment
      -> Aff (Either FetchShippingRatesError ShippingRates)
  }
