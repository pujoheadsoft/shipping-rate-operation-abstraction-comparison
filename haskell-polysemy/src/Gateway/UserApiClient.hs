module Gateway.UserApiClient where

import Data.Aeson (FromJSON)
import GHC.Generics (Generic)
import Polysemy (makeSem)

newtype UserRequest = UserRequest { userId :: String }
  deriving (Eq, Show)

newtype UserResponse = UserResponse { postalCode :: String }
  deriving (Eq, Generic, Show)

instance FromJSON UserResponse

data UserApiError
  = UserApiUserNotFound
  | UserApiOperationFailed
  deriving (Eq, Show)

data UserApiClient m a where
  FetchUser
    :: UserRequest
    -> UserApiClient m (Either UserApiError UserResponse)

makeSem ''UserApiClient
