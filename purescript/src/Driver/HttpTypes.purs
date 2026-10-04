module Driver.HttpTypes (HttpError(..)) where

import Prelude

data HttpError
  = HttpRequestFailed

derive instance Eq HttpError

instance Show HttpError where
  show HttpRequestFailed = "HttpRequestFailed"
