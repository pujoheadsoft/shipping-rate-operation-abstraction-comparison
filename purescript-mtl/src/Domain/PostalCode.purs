module Domain.PostalCode (PostalCode(..)) where

import Prelude

newtype PostalCode = PostalCode String

derive newtype instance Eq PostalCode
derive newtype instance Show PostalCode
