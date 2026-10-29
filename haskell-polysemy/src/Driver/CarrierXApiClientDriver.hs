{-# LANGUAGE OverloadedStrings #-}

module Driver.CarrierXApiClientDriver
  ( CarrierXApiEnvironment (..)
  , runCarrierXApiClient
  ) where

import           Data.Aeson
import           Data.Bifunctor            (first)
import           Driver.DriverError
import           Driver.HttpClient         (postJson)
import           Gateway.CarrierXApiClient
import           Polysemy
import           Polysemy.Error            (Error, runError)
import           Polysemy.Reader           (Reader, ask, runReader)

newtype CarrierXApiEnvironment = CarrierXApiEnvironment
  { baseUrl :: String
  }

runCarrierXApiClient
  :: Member (Embed IO) r
  => CarrierXApiEnvironment
  -> Sem (CarrierXApiClient ': r) a
  -> Sem r a
runCarrierXApiClient environment = interpret \case
  FetchRateX request -> do
    result <- runError @DriverError
      $ runReader environment
      $ performFetchRate request
    pure $ first (const CarrierXApiOperationFailed) result

performFetchRate
  :: Members
       '[ Reader CarrierXApiEnvironment
        , Error DriverError
        , Embed IO
        ] r
  => CarrierXRateRequest
  -> Sem r CarrierXRateResponse
performFetchRate request = do
  environment <- ask @CarrierXApiEnvironment
  postJson
    (baseUrl environment)
    "/shipping-rates"
    (encodeRateRequest request)

encodeRateRequest :: CarrierXRateRequest -> Value
encodeRateRequest request = object
  [ "destination" .= destination request
  , "weightGrams" .= weightGrams request
  ]
