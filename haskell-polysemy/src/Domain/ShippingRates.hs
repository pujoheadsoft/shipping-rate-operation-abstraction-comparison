module Domain.ShippingRates (ShippingRates(..)) where

import           Data.List.NonEmpty  (NonEmpty)
import           Domain.ShippingRate (ShippingRate)

newtype ShippingRates = ShippingRates (NonEmpty ShippingRate)
  deriving (Eq, Show)
