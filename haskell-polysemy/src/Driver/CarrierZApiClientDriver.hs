{-# LANGUAGE OverloadedStrings #-}

module Driver.CarrierZApiClientDriver
  ( CarrierZApiEnvironment (..)
  , runCarrierZApiClient
  ) where

import           Data.Aeson
import           Data.Bifunctor            (first)
import           Driver.DriverError
import           Driver.HttpClient         (postJson)
import           Gateway.CarrierZApiClient
import           Polysemy
import           Polysemy.Error            (Error, runError)
import           Polysemy.Reader           (Reader, ask, runReader)

newtype CarrierZApiEnvironment = CarrierZApiEnvironment
  { baseUrl :: String
  }

runCarrierZApiClient
  :: Member (Embed IO) r
  => CarrierZApiEnvironment
  -> Sem (CarrierZApiClient ': r) a
  -> Sem r a
runCarrierZApiClient environment = interpret \case
  FetchRateZ request -> do
    result <- runError @DriverError
      $ runReader environment
      $ performFetchRate request
    pure $ first (const CarrierZApiOperationFailed) result

performFetchRate
  :: Members
       '[ Reader CarrierZApiEnvironment
        , Error DriverError
        , Embed IO
        ] r
  => CarrierZRateRequest
  -> Sem r CarrierZRateResponse
performFetchRate request = do
  environment <- ask @CarrierZApiEnvironment
  postJson
    (baseUrl environment)
    "/shipping/quote"
    (encodeRateRequest request)

encodeRateRequest :: CarrierZRateRequest -> Value
encodeRateRequest request = object
  [ "postalCode" .= postalCode request
  , "weight" .= weight request
  ]
