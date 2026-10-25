module Domain.ShippingRates
  ( ShippingRates(..)
  , findCheapest
  ) where

import Prelude

import Data.Array.NonEmpty (NonEmptyArray)
import Data.Array.NonEmpty as NonEmptyArray
import Data.Foldable (foldl)
import Domain.ShippingRate (ShippingRate(..))

newtype ShippingRates = ShippingRates (NonEmptyArray ShippingRate)

derive newtype instance Eq ShippingRates
derive newtype instance Show ShippingRates

findCheapest :: ShippingRates -> ShippingRate
findCheapest (ShippingRates rates) =
  foldl chooseCheaper (NonEmptyArray.head rates) (NonEmptyArray.tail rates)
  where
  chooseCheaper cheapest@(ShippingRate current) candidate@(ShippingRate next)
    | next.amount < current.amount = candidate
    | otherwise = cheapest
