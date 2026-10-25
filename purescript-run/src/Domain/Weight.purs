module Domain.Weight (Weight(..)) where

import Prelude

newtype Weight = Weight Int

derive newtype instance Eq Weight
derive newtype instance Show Weight
