module Driver.CarrierXApiClientDriver
  ( CarrierXApiEnvironment(..)
  , createCarrierXApiClient
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT, runExceptT)
import Control.Monad.Reader.Trans (ReaderT(..), runReaderT)
import Data.Bifunctor (lmap)
import Data.Either (Either)
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

runFetchRate
  :: CarrierXApiEnvironment
  -> CarrierXRateRequest
  -> Aff (Either CarrierXApiError CarrierXRateResponse)
runFetchRate environment =
  performFetchRate
    >>> flip runReaderT environment
    >>> runExceptT
    >>> map (lmap (const CarrierXApiOperationFailed))

createCarrierXApiClient :: CarrierXApiEnvironment -> CarrierXApiClient
createCarrierXApiClient environment =
  { fetchRate: runFetchRate environment
  }

performFetchRate
  :: CarrierXRateRequest
  -> ReaderT CarrierXApiEnvironment
       (ExceptT DriverError Aff)
       CarrierXRateResponse
performFetchRate =
  fetchRate >>> ReaderT
  where
  fetchRate request (CarrierXApiEnvironment { baseUrl }) =
    fetchAndDecode baseUrl request

  fetchAndDecode baseUrl =
    writeJSON
      >>> fetchPost (baseUrl <> "/shipping-rates")
      >>> toDriverResult
      >=> decodeJson
