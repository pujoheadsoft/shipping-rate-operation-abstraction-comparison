module UseCase.PostalCodePort where

import Domain.PostalCode (PostalCode)
import Domain.UserId (UserId)
import Effectful
import Effectful.Dispatch.Dynamic (send)

data FetchPostalCodeError
  = PostalCodeNotFound
  | FetchPostalCodeFailed
  deriving (Eq, Show)

data PostalCodePort :: Effect where
  FetchPostalCodeByUserId
    :: UserId
    -> PostalCodePort m (Either FetchPostalCodeError PostalCode)

type instance DispatchOf PostalCodePort = Dynamic

fetchPostalCodeByUserId
  :: PostalCodePort :> es
  => UserId
  -> Eff es (Either FetchPostalCodeError PostalCode)
fetchPostalCodeByUserId userId = send $ FetchPostalCodeByUserId userId
