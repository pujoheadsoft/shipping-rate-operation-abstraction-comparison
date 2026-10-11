module Domain.ShippingRate (ShippingRate(..)) where

data ShippingRate = ShippingRate
  { carrier :: String
  , amount  :: Int
  } deriving (Eq, Show)
