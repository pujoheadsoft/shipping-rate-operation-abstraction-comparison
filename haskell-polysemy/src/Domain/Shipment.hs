module Domain.Shipment (Shipment(..)) where

data Shipment = Shipment
  { destinationPostalCode :: String
  , weight                :: Int
  } deriving (Eq, Show)
