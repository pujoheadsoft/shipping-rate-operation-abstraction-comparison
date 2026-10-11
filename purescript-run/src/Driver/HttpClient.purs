module Driver.HttpClient (decodeJson, fetchPost, toDriverResult) where

import Prelude
import Data.Bifunctor (lmap)
import Driver.Error (DriverError(..))
import Effect.Aff (Aff, attempt, throwError)
import Effect.Exception (error)
import Fetch (Method(..), fetch)
import Run (AFF, Run, liftAff)
import Run.Except as RunExcept
import Type.Row (type (+))
import Yoga.JSON (class ReadForeign, readJSON)

fetchPost :: String -> String -> Aff String
fetchPost url body = do
  response <- fetch url { method: POST, body, headers: { "Content-Type": "application/json" } }
  if response.ok then response.text
  else throwError $ error $ "HTTP " <> show response.status <> " " <> response.statusText

toDriverResult
  :: forall a r
   . Aff a
  -> Run (RunExcept.EXCEPT DriverError + AFF + r) a
toDriverResult action = do
  result <- liftAff $ lmap (const DriverOperationFailed) <$> attempt action
  RunExcept.rethrow result

decodeJson
  :: forall a r
   . ReadForeign a
  => String
  -> Run (RunExcept.EXCEPT DriverError + r) a
decodeJson = RunExcept.rethrow <<< lmap (const DriverOperationFailed) <<< readJSON
