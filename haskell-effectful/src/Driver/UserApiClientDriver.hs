{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE NoFieldSelectors #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Driver.UserApiClientDriver
  ( UserApiEnvironment (..)
  , runUserApiClient
  ) where

import Control.Exception (try)
import Data.Aeson (FromJSON, eitherDecode)
import Data.Bifunctor (first)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)
import Gateway.UserApiClient
import GHC.Generics (Generic)
import Network.HTTP.Simple
import Network.HTTP.Types.Status (statusCode, statusIsSuccessful)

newtype UserApiEnvironment = UserApiEnvironment { baseUrl :: String }

newtype UserResponseJson = UserResponseJson { postalCode :: String }
  deriving (Generic)

instance FromJSON UserResponseJson

runUserApiClient
  :: IOE :> es
  => UserApiEnvironment
  -> Eff (UserApiClient : es) a
  -> Eff es a
runUserApiClient environment = interpret $ \_ -> \case
  FetchUser request -> liftIO $ performFetchUser environment request

performFetchUser
  :: UserApiEnvironment
  -> UserRequest
  -> IO (Either UserApiError UserResponse)
performFetchUser environment request = do
  let UserApiEnvironment environmentBaseUrl = environment
  attempted <- try @HttpException do
    initial <- parseRequest $ environmentBaseUrl <> "/users/" <> userId request
    httpLBS $ setRequestMethod "GET" initial
  pure case attempted of
    Left _ -> Left UserApiOperationFailed
    Right response
      | statusCode (getResponseStatus response) == 404 -> Left UserApiUserNotFound
      | not (statusIsSuccessful $ getResponseStatus response) -> Left UserApiOperationFailed
      | otherwise ->
          first (const UserApiOperationFailed)
            $ toUserResponse <$> eitherDecode (getResponseBody response)

toUserResponse :: UserResponseJson -> UserResponse
toUserResponse (UserResponseJson responsePostalCode) =
  UserResponse responsePostalCode
