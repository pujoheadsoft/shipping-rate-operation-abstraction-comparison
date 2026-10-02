module Domain.Shipment (Shipment(..)) where

newtype Shipment = Shipment
  { destinationPostalCode :: String
  , weight :: Int
  }
