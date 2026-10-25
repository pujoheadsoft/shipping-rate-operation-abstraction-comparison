module Domain.PostalCode (PostalCode(..)) where

newtype PostalCode = PostalCode String
  deriving (Eq, Show)
