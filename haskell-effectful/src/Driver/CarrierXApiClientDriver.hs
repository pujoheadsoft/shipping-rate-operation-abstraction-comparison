{-# LANGUAGE OverloadedStrings #-}

module Driver.CarrierXApiClientDriver
  ( CarrierXApiEnvironment (..)
  , runCarrierXApiClient
  ) where

import           Data.Aeson
import           Data.Bifunctor             (first)
import           Driver.DriverError
import           Driver.HttpClient          (postJson)
import           Effectful
import           Effectful.Dispatch.Dynamic (interpret)
import           Effectful.Error.Static     (Error, runErrorNoCallStack)
import           Effectful.Reader.Static    (Reader, ask, runReader)
import           Gateway.CarrierXApiClient

newtype CarrierXApiEnvironment = CarrierXApiEnvironment
  { baseUrl :: String
  }

runCarrierXApiClient
  :: IOE :> es
  => CarrierXApiEnvironment
  -> Eff (CarrierXApiClient : es) a
  -> Eff es a
runCarrierXApiClient environment = interpret $ \_ -> \case
  FetchRateX request -> do
    result <- runErrorNoCallStack @DriverError
      $ runReader environment
      $ performFetchRate request
    pure $ first (const CarrierXApiOperationFailed) result

performFetchRate
  :: ( Reader CarrierXApiEnvironment :> es
     , Error DriverError :> es
     , IOE :> es
     )
  => CarrierXRateRequest
  -> Eff es CarrierXRateResponse
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
