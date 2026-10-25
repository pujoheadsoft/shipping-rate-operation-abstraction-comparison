module Domain.Shipment (Shipment(..)) where

import Prelude

import Domain.PostalCode (PostalCode)
import Domain.Weight (Weight)

newtype Shipment = Shipment
  { destinationPostalCode :: PostalCode
  , weight :: Weight
  }

derive newtype instance Eq Shipment
derive newtype instance Show Shipment
