module Driver.UserApiClientDriver
  ( UserApiEnvironment(..)
  , createUserApiClient
  ) where

import Prelude

import Control.Monad.Error.Class (liftEither)
import Control.Monad.Except.Trans (ExceptT(..), runExceptT)
import Control.Monad.Reader.Trans (ReaderT(..), runReaderT)
import Data.Bifunctor (lmap)
import Data.Either (Either(..))
import Driver.HttpClient (fetchGet)
import Effect.Aff (Aff, attempt)
import Fetch (Response)
import Gateway.UserApiClient
  ( UserApiClient
  , UserApiError(..)
  , UserRequest
  , UserResponse
  )
import Yoga.JSON (readJSON)

newtype UserApiEnvironment = UserApiEnvironment
  { baseUrl :: String
  }

createUserApiClient :: UserApiEnvironment -> UserApiClient
createUserApiClient environment =
  { fetchUser: \request ->
      runExceptT $ runReaderT (performFetchUser request) environment
  }

performFetchUser
  :: UserRequest
  -> ReaderT UserApiEnvironment
       (ExceptT UserApiError Aff)
       UserResponse
performFetchUser = fetchUser >>> ReaderT
  where
  fetchUser request (UserApiEnvironment { baseUrl }) =
    fetchAndDecode $ baseUrl <> "/users/" <> request.id

  fetchAndDecode :: String -> ExceptT UserApiError Aff UserResponse
  fetchAndDecode =
    fetchUserResponse
      >=> ensureSuccessfulResponse
      >=> readResponseBody
      >=> decodeUserResponse

  fetchUserResponse :: String -> ExceptT UserApiError Aff Response
  fetchUserResponse = fetchGet >>> liftOperation

  ensureSuccessfulResponse :: Response -> ExceptT UserApiError Aff Response
  ensureSuccessfulResponse =
    validateResponse >>> liftEither

  validateResponse :: Response -> Either UserApiError Response
  validateResponse response
    | response.status == 404 = Left UserApiUserNotFound
    | not response.ok = Left UserApiOperationFailed
    | otherwise = Right response

  readResponseBody :: Response -> ExceptT UserApiError Aff String
  readResponseBody = _.text >>> liftOperation

  decodeUserResponse :: String -> ExceptT UserApiError Aff UserResponse
  decodeUserResponse =
    readJSON
      >>> lmap (const UserApiOperationFailed)
      >>> liftEither

  liftOperation :: forall a. Aff a -> ExceptT UserApiError Aff a
  liftOperation action =
    ExceptT $ lmap (const UserApiOperationFailed) <$> attempt action
