module Driver.CarrierYApiClientDriver
  ( CarrierYApiEnvironment(..)
  , createCarrierYApiClient
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT, runExceptT)
import Control.Monad.Reader.Trans (ReaderT, ask, lift, runReaderT)
import Data.Bifunctor (lmap)
import Driver.HttpClient (HttpPost, decodeJson, toHttpResult)
import Driver.HttpTypes (HttpError)
import Effect.Aff (Aff)
import Gateway.CarrierYApiClient
  ( CarrierYApiClient
  , CarrierYApiError(..)
  , CarrierYRateRequest
  , CarrierYRateResponse
  )
import Yoga.JSON (writeJSON)

newtype CarrierYApiEnvironment = CarrierYApiEnvironment
  { baseUrl :: String
  , post :: HttpPost
  }

createCarrierYApiClient :: CarrierYApiEnvironment -> CarrierYApiClient
createCarrierYApiClient environment =
  { fetchRate: \request ->
      lmap (const CarrierYApiRequestFailed)
        <$> runExceptT (runReaderT (performFetchRate request) environment)
  }

performFetchRate
  :: CarrierYRateRequest
  -> ReaderT CarrierYApiEnvironment
       (ExceptT HttpError Aff)
       CarrierYRateResponse
performFetchRate request = do
  CarrierYApiEnvironment environment <- ask
  lift do
    body <- toHttpResult $ environment.post
      (environment.baseUrl <> "/rates/quote")
      (writeJSON request)
    decodeJson body
