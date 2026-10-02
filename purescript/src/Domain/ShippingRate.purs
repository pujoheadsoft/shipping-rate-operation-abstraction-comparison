module Domain.ShippingRate (ShippingRate(..)) where

newtype ShippingRate = ShippingRate
  { carrier :: String
  , amount :: Int
  }
