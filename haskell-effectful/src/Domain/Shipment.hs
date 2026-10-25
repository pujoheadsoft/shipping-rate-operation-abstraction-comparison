module Domain.Shipment (Shipment(..)) where

import Domain.PostalCode (PostalCode)
import Domain.Weight (Weight)

data Shipment = Shipment
  { destinationPostalCode :: PostalCode
  , weight                :: Weight
  } deriving (Eq, Show)
