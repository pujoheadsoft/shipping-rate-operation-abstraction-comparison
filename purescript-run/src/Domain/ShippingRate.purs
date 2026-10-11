module Domain.ShippingRate (ShippingRate(..)) where

import Prelude

newtype ShippingRate = ShippingRate { carrier :: String, amount :: Int }

derive newtype instance Eq ShippingRate
derive newtype instance Show ShippingRate
