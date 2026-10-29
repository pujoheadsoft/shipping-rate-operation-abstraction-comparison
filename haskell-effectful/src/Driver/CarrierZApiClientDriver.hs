{-# LANGUAGE OverloadedStrings #-}

module Driver.CarrierZApiClientDriver
  ( CarrierZApiEnvironment (..)
  , runCarrierZApiClient
  ) where

import           Data.Aeson
import           Data.Bifunctor             (first)
import           Driver.DriverError
import           Driver.HttpClient          (postJson)
import           Effectful
import           Effectful.Dispatch.Dynamic (interpret)
import           Effectful.Error.Static     (Error, runErrorNoCallStack)
import           Effectful.Reader.Static    (Reader, ask, runReader)
import           Gateway.CarrierZApiClient

newtype CarrierZApiEnvironment = CarrierZApiEnvironment
  { baseUrl :: String
  }

runCarrierZApiClient
  :: IOE :> es
  => CarrierZApiEnvironment
  -> Eff (CarrierZApiClient : es) a
  -> Eff es a
runCarrierZApiClient environment = interpret $ \_ -> \case
  FetchRateZ request -> do
    result <- runErrorNoCallStack @DriverError
      $ runReader environment
      $ performFetchRate request
    pure $ first (const CarrierZApiOperationFailed) result

performFetchRate
  :: ( Reader CarrierZApiEnvironment :> es
     , Error DriverError :> es
     , IOE :> es
     )
  => CarrierZRateRequest
  -> Eff es CarrierZRateResponse
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
