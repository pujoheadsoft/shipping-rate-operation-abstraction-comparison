module Gateway.UserApiClient where

import Polysemy (makeSem)

newtype UserRequest = UserRequest { userId :: String }
  deriving (Eq, Show)

newtype UserResponse = UserResponse { postalCode :: String }
  deriving (Eq, Show)

data UserApiError
  = UserApiUserNotFound
  | UserApiOperationFailed
  deriving (Eq, Show)

data UserApiClient m a where
  FetchUser
    :: UserRequest
    -> UserApiClient m (Either UserApiError UserResponse)

makeSem ''UserApiClient
