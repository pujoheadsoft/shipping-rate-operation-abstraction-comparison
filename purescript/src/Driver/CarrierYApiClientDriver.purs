module Driver.CarrierYApiClientDriver
  ( CarrierYApiEnvironment(..)
  , createCarrierYApiClient
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT, runExceptT)
import Control.Monad.Reader.Trans (ReaderT, ask, lift, runReaderT)
import Data.Bifunctor (lmap)
import Driver.Error (DriverError)
import Driver.HttpClient (decodeJson, fetchPost, toDriverResult)
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
  }

createCarrierYApiClient :: CarrierYApiEnvironment -> CarrierYApiClient
createCarrierYApiClient environment =
  { fetchRate: \request ->
      lmap (const CarrierYApiOperationFailed)
        <$> runExceptT (runReaderT (performFetchRate request) environment)
  }

performFetchRate
  :: CarrierYRateRequest
  -> ReaderT CarrierYApiEnvironment
       (ExceptT DriverError Aff)
       CarrierYRateResponse
performFetchRate request = do
  CarrierYApiEnvironment environment <- ask
  lift do
    body <- toDriverResult $ fetchPost
      (environment.baseUrl <> "/rates/quote")
      (writeJSON request)
    decodeJson body
