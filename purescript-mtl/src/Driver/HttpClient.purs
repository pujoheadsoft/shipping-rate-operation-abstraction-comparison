module Driver.HttpClient
  ( decodeJson
  , fetchPost
  , toDriverResult
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT(..))
import Data.Bifunctor (lmap)
import Driver.Error (DriverError(..))
import Effect.Aff (Aff, attempt, throwError)
import Effect.Exception (error)
import Fetch (Method(..), fetch)
import Yoga.JSON (class ReadForeign, readJSON)

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
