module Domain.Weight (Weight(..)) where

newtype Weight = Weight Int
  deriving (Eq, Show)
