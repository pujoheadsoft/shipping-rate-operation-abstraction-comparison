module Domain.ShippingRates (ShippingRates(..), findCheapest) where

import           Data.List.NonEmpty  (NonEmpty (..))
import           Domain.ShippingRate (ShippingRate (..))

newtype ShippingRates = ShippingRates (NonEmpty ShippingRate)
  deriving (Eq, Show)

findCheapest :: ShippingRates -> ShippingRate
findCheapest (ShippingRates (first :| rest)) = foldl cheaper first rest
  where
    cheaper cheapest candidate
      | amount candidate < amount cheapest = candidate
      | otherwise = cheapest
