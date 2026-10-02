module Port.ShippingRatePort (ShippingRatePort) where

import Domain.Shipment (Shipment)
import Domain.ShippingRates (ShippingRates)

type ShippingRatePort =
  { fetchShippingRates :: Shipment -> ShippingRates
  }
