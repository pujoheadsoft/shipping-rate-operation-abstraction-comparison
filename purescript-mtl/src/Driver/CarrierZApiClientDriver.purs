module Driver.CarrierZApiClientDriver
  ( CarrierZApiEnvironment(..)
  , createCarrierZApiClient
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT, runExceptT)
import Control.Monad.Reader.Trans (ReaderT(..), runReaderT)
import Data.Bifunctor (lmap)
import Driver.Error (DriverError)
import Driver.HttpClient (decodeJson, fetchPost, toDriverResult)
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
  }

createCarrierZApiClient :: CarrierZApiEnvironment -> CarrierZApiClient
createCarrierZApiClient environment =
  { fetchRate: \request ->
      lmap (const CarrierZApiOperationFailed)
        <$> runExceptT (runReaderT (performFetchRate request) environment)
  }

performFetchRate
  :: CarrierZRateRequest
  -> ReaderT CarrierZApiEnvironment
       (ExceptT DriverError Aff)
       CarrierZRateResponse
performFetchRate =
  fetchRate >>> ReaderT
  where
  fetchRate request (CarrierZApiEnvironment { baseUrl }) =
    fetchAndDecode baseUrl request

  fetchAndDecode baseUrl =
    writeJSON
      >>> fetchPost (baseUrl <> "/shipping/quote")
      >>> toDriverResult
      >=> decodeJson
