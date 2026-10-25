module Gateway.PostalCodeGateway (runPostalCodePort) where

import Domain.PostalCode (PostalCode (..))
import Domain.UserId (UserId (..))
import Gateway.UserApiClient
import Polysemy (Member, Sem, interpret)
import UseCase.PostalCodePort

runPostalCodePort
  :: Member UserApiClient r
  => Sem (PostalCodePort ': r) a
  -> Sem r a
runPostalCodePort = interpret \case
  FetchPostalCodeByUserId (UserId value) ->
    fetchUser (UserRequest value) >>= pure . either toError toPostalCode
  where
    toError UserApiUserNotFound = Left PostalCodeNotFound
    toError UserApiOperationFailed = Left FetchPostalCodeFailed
    toPostalCode = Right . PostalCode . postalCode
