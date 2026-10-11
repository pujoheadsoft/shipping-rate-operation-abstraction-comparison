module Driver.CarrierXApiClientDriver
  ( CarrierXApiEnvironment(..)
  , createCarrierXApiClient
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT, runExceptT)
import Control.Monad.Reader.Trans (ReaderT, ask, lift, runReaderT)
import Data.Bifunctor (lmap)
import Driver.Error (DriverError)
import Driver.HttpClient (decodeJson, fetchPost, toDriverResult)
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
  }

createCarrierXApiClient :: CarrierXApiEnvironment -> CarrierXApiClient
createCarrierXApiClient environment =
  { fetchRate: \request ->
      lmap (const CarrierXApiOperationFailed)
        <$> runExceptT (runReaderT (performFetchRate request) environment)
  }

performFetchRate
  :: CarrierXRateRequest
  -> ReaderT CarrierXApiEnvironment
       (ExceptT DriverError Aff)
       CarrierXRateResponse
performFetchRate request = do
  CarrierXApiEnvironment environment <- ask
  lift do
    body <- toDriverResult $ fetchPost
      (environment.baseUrl <> "/shipping-rates")
      (writeJSON request)
    decodeJson body
