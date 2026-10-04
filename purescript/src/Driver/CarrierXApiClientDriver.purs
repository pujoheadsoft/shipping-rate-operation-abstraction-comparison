module Driver.CarrierXApiClientDriver
  ( CarrierXApiEnvironment(..)
  , createCarrierXApiClient
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT, runExceptT)
import Control.Monad.Reader.Trans (ReaderT, ask, lift, runReaderT)
import Data.Bifunctor (lmap)
import Driver.HttpClient (HttpPost, decodeJson, toHttpResult)
import Driver.HttpTypes (HttpError)
import Effect.Aff (Aff)
import Gateway.CarrierXApiClient
  ( CarrierXApiClient
  , CarrierXApiError(..)
  , CarrierXRateRequest
  , CarrierXRateResponse
  )
import Yoga.JSON (writeJSON)

newtype CarrierXApiEnvironment = CarrierXApiEnvironment
  { baseUrl :: String
  , post :: HttpPost
  }

createCarrierXApiClient :: CarrierXApiEnvironment -> CarrierXApiClient
createCarrierXApiClient environment =
  { fetchRate: \request ->
      lmap (const CarrierXApiRequestFailed)
        <$> runExceptT (runReaderT (performFetchRate request) environment)
  }

performFetchRate
  :: CarrierXRateRequest
  -> ReaderT CarrierXApiEnvironment
       (ExceptT HttpError Aff)
       CarrierXRateResponse
performFetchRate request = do
  CarrierXApiEnvironment environment <- ask
  lift do
    body <- toHttpResult $ environment.post
      (environment.baseUrl <> "/shipping-rates")
      (writeJSON request)
    decodeJson body
