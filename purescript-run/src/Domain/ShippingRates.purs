module Domain.ShippingRates (ShippingRates(..), findCheapest) where

import Prelude
import Data.Foldable (foldl)
import Domain.ShippingRate (ShippingRate(..))

newtype ShippingRates = ShippingRates { head :: ShippingRate, tail :: Array ShippingRate }

derive newtype instance Eq ShippingRates
derive newtype instance Show ShippingRates

findCheapest :: ShippingRates -> ShippingRate
findCheapest (ShippingRates rates) = foldl chooseCheaper rates.head rates.tail
  where
  chooseCheaper cheapest@(ShippingRate current) candidate@(ShippingRate next)
    | next.amount < current.amount = candidate
    | otherwise = cheapest
