module Domain.ShippingRates (ShippingRates(..)) where

import Prelude
import Domain.ShippingRate (ShippingRate)

newtype ShippingRates = ShippingRates { head :: ShippingRate, tail :: Array ShippingRate }

derive newtype instance Eq ShippingRates
derive newtype instance Show ShippingRates
