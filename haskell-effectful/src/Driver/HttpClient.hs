{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications  #-}

module Driver.HttpClient (postJson) where

import           Control.Exception         (try)
import           Data.Aeson                (Value, eitherDecode)
import           Driver.DriverError
import           Effectful
import           Effectful.Error.Static    (Error, throwError)
import           Network.HTTP.Simple
import           Network.HTTP.Types.Status (statusCode)

postJson
  :: (IOE :> es, Error DriverError :> es)
  => String
  -> String
  -> Value
  -> Eff es Value
postJson baseUrl path body = do
  attempted <- liftIO $ try @HttpException do
    initial <- parseRequest $ baseUrl <> path
    response <- httpLBS
      $ setRequestBodyJSON body
      $ setRequestHeader "Content-Type" ["application/json"]
      $ setRequestMethod "POST" initial
    let code = statusCode $ getResponseStatus response
    pure $
      if code >= 200 && code < 300
        then eitherDecode $ getResponseBody response
        else Left $ "HTTP " <> show code

  case attempted of
    Left _               -> throwError DriverOperationFailed
    Right (Left _)       -> throwError DriverOperationFailed
    Right (Right result) -> pure result
