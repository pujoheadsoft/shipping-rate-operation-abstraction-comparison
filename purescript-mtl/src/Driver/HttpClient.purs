module Driver.HttpClient
  ( decodeJson
  , fetchGet
  , fetchPost
  , toDriverResult
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT(..))
import Data.Bifunctor (lmap)
import Driver.Error (DriverError(..))
import Effect.Aff (Aff, attempt, throwError)
import Effect.Exception (error)
import Fetch (Method(..), Response, fetch)
import Yoga.JSON (class ReadForeign, readJSON)

fetchGet :: String -> Aff Response
fetchGet url = fetch url { method: GET }

fetchPost :: String -> String -> Aff String
fetchPost url body = do
  response <- fetch url
    { method: POST
    , body
    , headers: { "Content-Type": "application/json" }
    }
  if response.ok then response.text
  else throwError $ error $ "HTTP " <> show response.status <> " " <> response.statusText

toDriverResult :: forall a. Aff a -> ExceptT DriverError Aff a
toDriverResult action =
  ExceptT $ lmap (const DriverOperationFailed) <$> attempt action

decodeJson :: forall a. ReadForeign a => String -> ExceptT DriverError Aff a
decodeJson value =
  ExceptT $ pure $ lmap (const DriverOperationFailed) $ readJSON value
