module Driver.CarrierZApiClientDriver
  ( CarrierZApiEnvironment(..)
  , createCarrierZApiClient
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT, runExceptT)
import Control.Monad.Reader.Trans (ReaderT, ask, lift, runReaderT)
import Data.Bifunctor (lmap)
import Driver.HttpClient (HttpPost, decodeJson, toHttpResult)
import Driver.HttpTypes (HttpError)
import Effect.Aff (Aff)
import Gateway.CarrierZApiClient
  ( CarrierZApiClient
  , CarrierZApiError(..)
  , CarrierZRateRequest
  , CarrierZRateResponse
  )
import Yoga.JSON (writeJSON)

newtype CarrierZApiEnvironment = CarrierZApiEnvironment
  { baseUrl :: String
  , post :: HttpPost
  }

createCarrierZApiClient :: CarrierZApiEnvironment -> CarrierZApiClient
createCarrierZApiClient environment =
  { fetchRate: \request ->
      lmap (const CarrierZApiRequestFailed)
        <$> runExceptT (runReaderT (performFetchRate request) environment)
  }

performFetchRate
  :: CarrierZRateRequest
  -> ReaderT CarrierZApiEnvironment
       (ExceptT HttpError Aff)
       CarrierZRateResponse
performFetchRate request = do
  CarrierZApiEnvironment environment <- ask
  lift do
    body <- toHttpResult $ environment.post
      (environment.baseUrl <> "/shipping/quote")
      (writeJSON request)
    decodeJson body
