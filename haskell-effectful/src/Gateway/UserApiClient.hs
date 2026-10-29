module Gateway.UserApiClient where

import Data.Aeson (FromJSON)
import Effectful
import Effectful.Dispatch.Dynamic (send)
import GHC.Generics (Generic)

newtype UserRequest = UserRequest { userId :: String }
  deriving (Eq, Show)

newtype UserResponse = UserResponse { postalCode :: String }
  deriving (Eq, Generic, Show)

instance FromJSON UserResponse

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
