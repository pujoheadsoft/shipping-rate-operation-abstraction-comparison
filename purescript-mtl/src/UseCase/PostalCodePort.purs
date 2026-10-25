module UseCase.PostalCodePort
  ( FetchPostalCodeError(..)
  , PostalCodePort
  ) where

import Prelude

import Data.Either (Either)
import Domain.PostalCode (PostalCode)
import Domain.UserId (UserId)
import Effect.Aff (Aff)

data FetchPostalCodeError
  = PostalCodeNotFound
  | FetchPostalCodeFailed

derive instance Eq FetchPostalCodeError

instance Show FetchPostalCodeError where
  show PostalCodeNotFound = "PostalCodeNotFound"
  show FetchPostalCodeFailed = "FetchPostalCodeFailed"

type PostalCodePort =
  { fetchPostalCodeByUserId
      :: UserId
      -> Aff (Either FetchPostalCodeError PostalCode)
  }
