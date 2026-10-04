module Driver.HttpClient
  ( HttpPost
  , decodeJson
  , fetchPost
  , toHttpResult
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT(..))
import Data.Bifunctor (lmap)
import Driver.HttpTypes (HttpError(..))
import Effect.Aff (Aff, attempt, throwError)
import Effect.Exception (error)
import Fetch (Method(..), fetch)
import Yoga.JSON (class ReadForeign, readJSON)

type HttpPost = String -> String -> Aff String

fetchPost :: HttpPost
fetchPost url body = do
  response <- fetch url
    { method: POST
    , body
    , headers: { "Content-Type": "application/json" }
    }
  if response.ok then response.text
  else throwError $ error $ "HTTP " <> show response.status <> " " <> response.statusText

toHttpResult :: forall a. Aff a -> ExceptT HttpError Aff a
toHttpResult action =
  ExceptT $ lmap (const HttpRequestFailed) <$> attempt action

decodeJson :: forall a. ReadForeign a => String -> ExceptT HttpError Aff a
decodeJson value =
  ExceptT $ pure $ lmap (const HttpRequestFailed) $ readJSON value
