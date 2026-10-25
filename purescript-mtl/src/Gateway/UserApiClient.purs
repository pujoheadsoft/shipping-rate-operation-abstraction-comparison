module Gateway.UserApiClient
  ( UserApiClient
  , UserApiError(..)
  , UserRequest
  , UserResponse
  ) where

import Prelude

import Data.Either (Either)
import Effect.Aff (Aff)

type UserRequest =
  { id :: String
  }

type UserResponse =
  { postalCode :: String
  }

data UserApiError
  = UserApiUserNotFound
  | UserApiOperationFailed

derive instance Eq UserApiError

instance Show UserApiError where
  show UserApiUserNotFound = "UserApiUserNotFound"
  show UserApiOperationFailed = "UserApiOperationFailed"

type UserApiClient =
  { fetchUser
      :: UserRequest
      -> Aff (Either UserApiError UserResponse)
  }
