module Gateway.UserApiClient where

import Effectful
import Effectful.Dispatch.Dynamic (send)

newtype UserRequest = UserRequest { userId :: String }
  deriving (Eq, Show)

newtype UserResponse = UserResponse { postalCode :: String }
  deriving (Eq, Show)

data UserApiError
  = UserApiUserNotFound
  | UserApiOperationFailed
  deriving (Eq, Show)

data UserApiClient :: Effect where
  FetchUser
    :: UserRequest
    -> UserApiClient m (Either UserApiError UserResponse)

type instance DispatchOf UserApiClient = Dynamic

fetchUser
  :: UserApiClient :> es
  => UserRequest
  -> Eff es (Either UserApiError UserResponse)
fetchUser request = send $ FetchUser request
