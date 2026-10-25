module Gateway.PostalCodeGateway (fetchPostalCode) where

import Prelude
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Domain.PostalCode (PostalCode(..))
import Domain.UserId (UserId(..))
import Gateway.UserApiClient as UserApi
import Run (Run)
import UseCase.PostalCodePort (FetchPostalCodeError(..))

fetchPostalCode
  :: forall r
   . UserId
  -> Run
       (userApiClient :: UserApi.USER_API_CLIENT | r)
       (Either FetchPostalCodeError PostalCode)
fetchPostalCode =
  toUserRequest
    >>> UserApi.fetchUser
    >>> map (lmap toFetchPostalCodeError >>> map toPostalCode)
  where
  toUserRequest (UserId id) = { id }
  toFetchPostalCodeError UserApi.UserApiUserNotFound = PostalCodeNotFound
  toFetchPostalCodeError UserApi.UserApiOperationFailed = FetchPostalCodeFailed
  toPostalCode response = PostalCode response.postalCode
