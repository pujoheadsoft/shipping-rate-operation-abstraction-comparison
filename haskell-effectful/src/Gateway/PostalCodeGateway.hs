module Gateway.PostalCodeGateway (runPostalCodePort) where

import Domain.PostalCode (PostalCode (..))
import Domain.UserId (UserId (..))
import Effectful
import Effectful.Dispatch.Dynamic (interpret)
import Gateway.UserApiClient
import UseCase.PostalCodePort

runPostalCodePort
  :: UserApiClient :> es
  => Eff (PostalCodePort : es) a
  -> Eff es a
runPostalCodePort = interpret $ \_ -> \case
  FetchPostalCodeByUserId (UserId value) ->
    fetchUser (UserRequest value) >>= pure . either toError toPostalCode
  where
    toError UserApiUserNotFound = Left PostalCodeNotFound
    toError UserApiOperationFailed = Left FetchPostalCodeFailed
    toPostalCode = Right . PostalCode . postalCode
