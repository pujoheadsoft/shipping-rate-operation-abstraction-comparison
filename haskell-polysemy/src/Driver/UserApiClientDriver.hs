{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Driver.UserApiClientDriver
  ( UserApiEnvironment (..)
  , runUserApiClient
  ) where

import Control.Exception (try)
import Data.Aeson (Value, eitherDecode)
import Data.Aeson.Types (parseEither, withObject, (.:))
import Data.Bifunctor (first)
import Gateway.UserApiClient
import Network.HTTP.Simple
import Network.HTTP.Types.Status (statusCode, statusIsSuccessful)
import Polysemy (Embed, Member, Sem, embed, interpret)

newtype UserApiEnvironment = UserApiEnvironment { baseUrl :: String }

runUserApiClient
  :: Member (Embed IO) r
  => UserApiEnvironment
  -> Sem (UserApiClient ': r) a
  -> Sem r a
runUserApiClient environment = interpret \case
  FetchUser request -> embed $ performFetchUser environment request

performFetchUser
  :: UserApiEnvironment
  -> UserRequest
  -> IO (Either UserApiError UserResponse)
performFetchUser environment request = do
  attempted <- try @HttpException do
    initial <- parseRequest $ baseUrl environment <> "/users/" <> userId request
    httpLBS $ setRequestMethod "GET" initial
  pure case attempted of
    Left _ -> Left UserApiOperationFailed
    Right response
      | statusCode (getResponseStatus response) == 404 -> Left UserApiUserNotFound
      | not (statusIsSuccessful $ getResponseStatus response) -> Left UserApiOperationFailed
      | otherwise ->
          first (const UserApiOperationFailed)
            $ eitherDecode (getResponseBody response)
            >>= decodeUserResponse

decodeUserResponse :: Value -> Either String UserResponse
decodeUserResponse = parseEither
  $ withObject "UserResponse"
  $ \value -> UserResponse <$> value .: "postalCode"
