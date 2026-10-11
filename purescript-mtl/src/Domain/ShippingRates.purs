module Domain.ShippingRates (ShippingRates(..)) where

import Prelude

import Data.Array.NonEmpty (NonEmptyArray)
import Domain.ShippingRate (ShippingRate)

newtype ShippingRates = ShippingRates (NonEmptyArray ShippingRate)

derive newtype instance Eq ShippingRates
derive newtype instance Show ShippingRates
