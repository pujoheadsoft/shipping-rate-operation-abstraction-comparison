module Domain.UserId (UserId(..)) where

import Prelude

newtype UserId = UserId String

derive newtype instance Eq UserId
derive newtype instance Show UserId
