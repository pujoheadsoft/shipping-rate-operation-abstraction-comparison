{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications  #-}

module Driver.HttpClient (postJson) where

import           Control.Exception         (try)
import           Data.Aeson                (Value, eitherDecode)
import           Driver.DriverError
import           Network.HTTP.Simple
import           Network.HTTP.Types.Status (statusCode)
import           Polysemy                  (Embed, Members, Sem, embed)
import           Polysemy.Error            (Error, throw)

postJson
  :: Members '[Embed IO, Error DriverError] r
  => String
  -> String
  -> Value
  -> Sem r Value
postJson baseUrl path body = do
  attempted <- embed $ try @HttpException do
    initial <- parseRequest (baseUrl <> path)
    response <- httpLBS
      $ setRequestBodyJSON body
      $ setRequestHeader "Content-Type" ["application/json"]
      $ setRequestMethod "POST" initial
    let code = statusCode $ getResponseStatus response
    pure $
      if code >= 200 && code < 300
        then eitherDecode $ getResponseBody response
        else Left ("HTTP " <> show code)

  case attempted of
    Left _               -> throw DriverOperationFailed
    Right (Left _)       -> throw DriverOperationFailed
    Right (Right result) -> pure result
