module Domain.Shipment (Shipment(..)) where

import Prelude

newtype Shipment = Shipment { destinationPostalCode :: String, weight :: Int }

derive newtype instance Eq Shipment
derive newtype instance Show Shipment
