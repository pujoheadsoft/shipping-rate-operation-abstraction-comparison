module Domain.ShippingRates (ShippingRates(..)) where

import Data.Array.NonEmpty (NonEmptyArray)
import Domain.ShippingRate (ShippingRate)

newtype ShippingRates = ShippingRates (NonEmptyArray ShippingRate)
