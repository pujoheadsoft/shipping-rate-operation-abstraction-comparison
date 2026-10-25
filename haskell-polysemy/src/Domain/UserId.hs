module Domain.UserId (UserId(..)) where

newtype UserId = UserId String
  deriving (Eq, Show)
