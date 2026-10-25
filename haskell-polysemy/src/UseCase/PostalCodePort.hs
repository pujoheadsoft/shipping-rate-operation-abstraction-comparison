module UseCase.PostalCodePort where

import Domain.PostalCode (PostalCode)
import Domain.UserId (UserId)
import Polysemy (makeSem)

data FetchPostalCodeError
  = PostalCodeNotFound
  | FetchPostalCodeFailed
  deriving (Eq, Show)

data PostalCodePort m a where
  FetchPostalCodeByUserId
    :: UserId
    -> PostalCodePort m (Either FetchPostalCodeError PostalCode)

makeSem ''PostalCodePort
