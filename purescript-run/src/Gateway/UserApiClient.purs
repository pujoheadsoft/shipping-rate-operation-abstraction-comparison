module Gateway.UserApiClient where

import Prelude
import Data.Either (Either)
import Run (Run, lift)
import Type.Proxy (Proxy(..))

type UserRequest = { id :: String }
type UserResponse = { postalCode :: String }

data UserApiError
  = UserApiUserNotFound
  | UserApiOperationFailed

derive instance Eq UserApiError
instance Show UserApiError where
  show UserApiUserNotFound = "UserApiUserNotFound"
  show UserApiOperationFailed = "UserApiOperationFailed"

data UserApiClientF a = FetchUser
  UserRequest
  (Either UserApiError UserResponse -> a)

derive instance Functor UserApiClientF
type USER_API_CLIENT = UserApiClientF

_userApiClient :: Proxy "userApiClient"
_userApiClient = Proxy

fetchUser
  :: forall r
   . UserRequest
  -> Run
       (userApiClient :: USER_API_CLIENT | r)
       (Either UserApiError UserResponse)
fetchUser request = lift _userApiClient $ FetchUser request identity
